import SwiftUI
import SwiftData
import FirebaseAuth
import MessageUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DashboardViewModel
    @StateObject private var expenseViewModel = ExpenseViewModel()
    @Query private var settings: [UserSettings]
    
    @State private var config: BudgetConfig?
    @State private var monthlyIncome: MonthlyIncome?
    @State private var accounts: [AccountBalance] = []
    @State private var goal: SavingsGoal?
    
    @State private var showMailSheet = false
    @State private var showMailErrorAlert = false
    @State private var mailError: Error?
    @State private var settleUpEmailAddress = ""
    @State private var settleUpMessage = ""
    @State private var settleUpPDFData: Data? = nil
    @State private var settleUpPDFName: String = ""
    
    private let monthKey = DateHelpers.monthKey()
    
    init(context: ModelContext) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(context: context))
    }
    
    // MARK: - Computed helpers
    
    private var monthExpenses: [Expense] {
        expenseViewModel.expenses
    }
    
    private var totalSpent: Double {
        monthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        monthlyIncome?.totalIncome ?? 0
    }
    
    private var overallLimit: Double {
        guard let config = config else { return 0 }
        return BudgetEngine.monthlySpendingLimit(
            savingsRule: config.savingsRule,
            fixedLimit: config.fixedSpendingLimit,
            comfortableLimit: config.comfortableLimit,
            isComfortableMode: config.isComfortableMode,
            savePercentage: config.savePercentage,
            totalIncome: totalIncome
        )
    }
    
    private var safeToSpend: Double {
        let calendar = Calendar.current
        let todayExpenses = monthExpenses.filter { calendar.isDateInToday($0.date) }
        let spentToday = todayExpenses.reduce(0) { $0 + $1.amount }
        let spentBeforeToday = totalSpent - spentToday
        
        return BudgetEngine.safeToSpendToday(
            spendingLimit: overallLimit,
            spentBeforeToday: spentBeforeToday,
            spentToday: spentToday,
            daysLeftInMonth: DateHelpers.daysLeftInMonth()
        )
    }
    
    private var hdfc: AccountBalance? {
        accounts.first(where: { $0.name == "HDFC" })
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemBackground).ignoresSafeArea()
                
                GeometryReader { proxy in
                    let size = proxy.size
                    Circle()
                        .fill(RadialGradient(colors: [Color.indigo.opacity(0.3), .clear], center: .center, startRadius: 0, endRadius: size.width))
                        .frame(width: size.width * 1.5, height: size.width * 1.5)
                        .offset(x: -size.width/2, y: -size.height/4)
                        .blur(radius: 50)
                    
                    Circle()
                        .fill(RadialGradient(colors: [Color.purple.opacity(0.2), .clear], center: .center, startRadius: 0, endRadius: size.width * 0.8))
                        .frame(width: size.width * 1.2, height: size.width * 1.2)
                        .offset(x: size.width/2, y: size.height/1.5)
                        .blur(radius: 50)
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerView
                        
                        safeToSpendCard
                        
                        settleUpCard
                        
                        if let hdfc = hdfc, hdfc.isBelowMinimum {
                            hdfcWarningCard(hdfc)
                        }
                        
                        if monthlyIncome?.isProvisional == true {
                            incomeReminderCard
                        }
                        
                        NavigationLink(destination: BudgetView(context: modelContext)) {
                            monthSummaryCard
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink(destination: InsightsView()) {
                            categoryBreakdownCard
                        }
                        .buttonStyle(.plain)
                        
                        if let goal = goal {
                            NavigationLink(destination: GoalView(context: modelContext)) {
                                goalSnapshotCard(goal)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        recentExpensesCard
                        
                        Spacer().frame(height: 40)
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .onAppear(perform: loadData)
            
        }
    }
    
    // MARK: - Cards
    
    private var headerView: some View {
        let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        let userSettings = settings.first(where: { $0.ownerEmail == currentUserEmail })
        let nameInitial = userSettings?.userName.first?.uppercased() ?? "B"
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.6))
            }
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(Auth.auth().currentUser?.email ?? "Not Logged In")
                    .font(.caption2)
                    .foregroundStyle(.primary.opacity(0.5))
                Menu {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    Button(role: .destructive, action: {
                        try? AuthManager.shared.signOut()
                    }) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Circle()
                        .fill(LinearGradient(colors: [.cyan, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                        .overlay(Text(nameInitial).font(.headline).foregroundStyle(.white))
                        .shadow(color: .cyan.opacity(0.3), radius: 10, x: 0, y: 0)
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    private var safeToSpendCard: some View {
        VStack(spacing: 12) {
            Text("Safe to Spend Today")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary.opacity(0.8))
                .textCase(.uppercase)
                .tracking(1.2)
            
            Text(CurrencyFormatter.format(safeToSpend))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(safeToSpend > 0 ? Color.cyan : Color.red)
                .shadow(color: safeToSpend > 0 ? .cyan.opacity(0.3) : .red.opacity(0.3), radius: 10, x: 0, y: 5)
            
            let daysLeft = DateHelpers.daysLeftInMonth()
            Text("\(daysLeft) day\(daysLeft == 1 ? "" : "s") left in \(monthKey)")
                .font(.footnote)
                .foregroundStyle(.primary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
    
    private var settleUpCard: some View {
        let userEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        var userOwes = 0.0
        var roommateOwes = 0.0
        var sharedPersonEmail = ""
        
        for exp in monthExpenses where exp.isShared {
            let expPaidBy = exp.paidByEmail.lowercased()
            let expSharedWith = exp.sharedWithEmail.lowercased()
            
            if expPaidBy == userEmail {
                roommateOwes += exp.roommateShare
                if sharedPersonEmail.isEmpty { sharedPersonEmail = exp.sharedWithEmail }
            } else {
                userOwes += exp.amount // If Amir paid, I owe Amir my share (exp.amount)
                if sharedPersonEmail.isEmpty { sharedPersonEmail = exp.paidByEmail }
            }
        }
        
        let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        let userSettings = settings.first(where: { $0.ownerEmail == currentUserEmail })
        
        let net = roommateOwes - userOwes
        
        var partnerName = userSettings?.partnerName ?? ""
        if partnerName.isEmpty {
            partnerName = sharedPersonEmail.components(separatedBy: "@").first?.capitalized ?? "Roommate"
        }
        
        if net == 0 && sharedPersonEmail.isEmpty {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Settle Up with \(partnerName)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(.cyan)
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("\(partnerName) owes you")
                            .font(.subheadline)
                            .foregroundStyle(.primary.opacity(0.8))
                        Spacer()
                        Text(CurrencyFormatter.format(net > 0 ? net : 0))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(net > 0 ? .green : .primary.opacity(0.5))
                    }
                    
                    HStack {
                        Text("You owe \(partnerName)")
                            .font(.subheadline)
                            .foregroundStyle(.primary.opacity(0.8))
                        Spacer()
                        Text(CurrencyFormatter.format(net < 0 ? abs(net) : 0))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(net < 0 ? .red : .primary.opacity(0.5))
                    }
                    if net != 0 {
                        HStack(spacing: 12) {
                            Button(action: {
                                if !MFMailComposeViewController.canSendMail() {
                                    showMailErrorAlert = true
                                    return
                                }
                                let isYouOwe = net < 0
                                let amountStr = CurrencyFormatter.format(abs(net))
                                let fallbackPartnerEmail = "idaretoshare99@gmail.com"
                                let partnerEmail = userSettings?.partnerEmail.isEmpty == false ? userSettings!.partnerEmail : fallbackPartnerEmail
                                
                                
                                settleUpEmailAddress = partnerEmail
                                
                                if isYouOwe {
                                    settleUpMessage = "Hi \(partnerName),\n\nHere's a note regarding our shared expenses. I currently owe you \(amountStr). Let's settle up!\n\nBest,\n\(userSettings?.userName ?? "Me")"
                                } else {
                                    settleUpMessage = "Hi \(partnerName),\n\nJust a quick reminder regarding our shared expenses. You currently owe me \(amountStr). Let's settle up soon!\n\nBest,\n\(userSettings?.userName ?? "Me")"
                                }
                                
                                let sharedExpenses = monthExpenses.filter { $0.isShared }
                                settleUpPDFData = PDFGenerator.generateSettleUpPDF(
                                    expenses: sharedExpenses,
                                    month: monthKey,
                                    net: net,
                                    partnerName: partnerName,
                                    userName: userSettings?.userName ?? "Me",
                                    isYouOwe: isYouOwe,
                                    userEmail: userEmail
                                )
                                settleUpPDFName = "Settlement_Bill_\(monthKey).pdf"
                                
                                showMailSheet = true
                            }) {
                                Text(net < 0 ? "Email Bill" : "Email Reminder")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.cyan.opacity(0.15))
                                    .foregroundStyle(.cyan)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                Task {
                                    try? await FirestoreService.shared.clearSharedExpenses(monthKey: monthKey)
                                }
                            }) {
                                Text("Mark as Settled")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundStyle(.green)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1)
            )
            .alert("Mail Not Configured", isPresented: $showMailErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please configure an email account on this device (or run on a physical device) to send emails.")
            }
            .sheet(isPresented: $showMailSheet) {
                MailView(isShowing: $showMailSheet,
                         resultError: $mailError,
                         toRecipients: [settleUpEmailAddress],
                         subject: "Bachat Settle Up",
                         messageBody: settleUpMessage,
                         attachmentData: settleUpPDFData,
                         attachmentMimeType: "application/pdf",
                         attachmentFileName: settleUpPDFName)
            }
        )
    }
    
    private func hdfcWarningCard(_ hdfc: AccountBalance) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.title)
                .shadow(color: .red.opacity(0.5), radius: 5, x: 0, y: 0)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("HDFC Below Minimum")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Top up \(CurrencyFormatter.format(hdfc.topUpNeeded)) to reach ₹10,000 floor.")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
            }
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.15))
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var incomeReminderCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "indianrupeesign.circle.fill")
                .foregroundStyle(.orange)
                .font(.title)
                .shadow(color: .orange.opacity(0.5), radius: 5, x: 0, y: 0)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Income Not Confirmed")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Using estimated salary. Confirm actual income for accurate budgets.")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
            }
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.15))
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var monthSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Month")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            
            let level = BudgetEngine.alertLevel(spent: totalSpent, limit: overallLimit)
            let progress = overallLimit > 0 ? min(totalSpent / overallLimit, 1.0) : 0
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.6))
                    Text(CurrencyFormatter.format(totalSpent))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Limit")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.6))
                    Text(CurrencyFormatter.format(overallLimit))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(level.color)
                        .frame(width: geo.size.width * CGFloat(progress), height: 8)
                        .shadow(color: level.color.opacity(0.5), radius: 5, x: 0, y: 0)
                }
            }
            .frame(height: 8)
            .padding(.vertical, 4)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Income")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.6))
                    Text(CurrencyFormatter.format(totalIncome))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Planned Savings")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.6))
                    Text(CurrencyFormatter.format(BudgetEngine.plannedSavings(totalIncome: totalIncome, spendingLimit: overallLimit)))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
    
    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Category")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            
            let grouped = Dictionary(grouping: monthExpenses) { $0.category }
            let sorted = grouped.sorted { $0.value.reduce(0) { $0 + $1.amount } > $1.value.reduce(0) { $0 + $1.amount } }
            
            if sorted.isEmpty {
                Text("No expenses yet this month.")
                    .foregroundStyle(.primary.opacity(0.5))
                    .font(.subheadline)
            } else {
                ForEach(sorted.prefix(5), id: \.key) { category, expenses in
                    let catTotal = expenses.reduce(0) { $0 + $1.amount }
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(category.color.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Image(systemName: category.icon)
                                .foregroundStyle(category.color)
                        }
                        
                        Text(category.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Text(CurrencyFormatter.format(catTotal))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func goalSnapshotCard(_ goal: SavingsGoal) -> some View {
        let hdfcBalance = hdfc?.balance ?? 0
        let usable = max(0, hdfcBalance - Constants.hdfcMinimumBalance)
        let months = GoalEngine.monthsRemaining(to: goal.targetDate)
        let required = GoalEngine.requiredMonthlySavings(
            targetAmount: goal.targetAmount,
            savedSoFar: usable,
            monthsRemaining: months
        )
        let progressFraction = goal.targetAmount > 0 ? min(usable / goal.targetAmount, 1.0) : 0
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(goal.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "target")
                    .foregroundStyle(.cyan)
                    .font(.title3)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(CurrencyFormatter.format(usable))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.cyan)
                    .shadow(color: .cyan.opacity(0.4), radius: 5, x: 0, y: 0)
                
                Text("/ \(CurrencyFormatter.format(goal.targetAmount))")
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.6))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(Color.cyan)
                        .frame(width: geo.size.width * CGFloat(progressFraction), height: 8)
                        .shadow(color: .cyan.opacity(0.5), radius: 5, x: 0, y: 0)
                }
            }
            .frame(height: 8)
            .padding(.vertical, 4)
            
            HStack {
                Text("Need \(CurrencyFormatter.format(required))/mo")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.6))
                Spacer()
                Text("\(months) months left")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.6))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
    
    private var recentExpensesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Transactions")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            
            let recent = Array(monthExpenses.prefix(5))
            
            if recent.isEmpty {
                Text("No recent expenses.")
                    .foregroundStyle(.primary.opacity(0.5))
                    .font(.subheadline)
            } else {
                ForEach(recent) { expense in
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(expense.category.color.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Image(systemName: expense.category.icon)
                                .foregroundStyle(expense.category.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(expense.category.rawValue)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            if !expense.note.isEmpty {
                                Text(expense.note)
                                    .font(.caption2)
                                    .foregroundStyle(.primary.opacity(0.6))
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("-\(CurrencyFormatter.format(expense.amount))")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            Text(expense.date, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.primary.opacity(0.5))
                        }
                    }
                    
                    if expense.id != recent.last?.id {
                        Divider()
                            .background(Color.primary.opacity(0.1))
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        config = viewModel.fetchOrCreateConfig()
        let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        let userSettings = settings.first(where: { $0.ownerEmail == currentUserEmail })
        let salary = userSettings?.expectedMonthlySalary ?? Constants.defaultExpectedSalary
        monthlyIncome = viewModel.fetchOrCreateIncome(monthKey: monthKey, expectedSalary: salary)
        accounts = viewModel.fetchOrCreateAccounts()
        goal = viewModel.fetchGoal()
        expenseViewModel.startListening(monthKey: monthKey)
    }
}
