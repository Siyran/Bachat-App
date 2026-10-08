import SwiftUI
import SwiftData
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query private var configs: [BudgetConfig]
    @Query private var accounts: [AccountBalance]
    
    @State private var userName: String = ""
    @State private var expectedSalary: String = ""
    @State private var splitRatio: String = ""
    @State private var partnerName: String = ""
    @State private var partnerEmail: String = ""
    
    // Budget config
    @State private var savingsRule: SavingsRule = .fixedLimit
    @State private var fixedLimit: String = ""
    @State private var comfortableLimit: String = ""
    @State private var savePercentage: String = ""
    @State private var isComfortableMode: Bool = false
    @State private var bonusSavingsPercent: String = ""
    
    // Accounts
    @State private var hdfcBalance: String = ""
    @State private var iciciBalance: String = ""
    @FocusState private var isInputActive: Bool
    @State private var saved = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                
                GeometryReader { proxy in
                    let size = proxy.size
                    Circle()
                        .fill(RadialGradient(colors: [Color.indigo.opacity(0.3), .clear], center: .center, startRadius: 0, endRadius: size.width))
                        .frame(width: size.width * 1.5, height: size.width * 1.5)
                        .offset(x: size.width/4, y: size.height/4)
                        .blur(radius: 50)
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerView
                        
                        profileSection
                        incomeSection
                        expenseSplitSection
                        budgetRulesSection
                        accountsSection
                        
                        saveButton
                        
                        Spacer().frame(height: 40)
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .onAppear(perform: loadSettings)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isInputActive = false
                    }
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Customize your experience")
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.6))
            }
            Spacer()
        }
        .padding(.bottom, 8)
    }
    
    private var profileSection: some View {
        glassSection(title: "Profile") {
            VStack(spacing: 16) {
                glassTextField("Your Name", text: $userName)
                glassTextField("Partner's Display Name", text: $partnerName)
                glassTextField("Partner's Account Email (for cloud sync)", text: $partnerEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
        }
    }
    
    private var incomeSection: some View {
        glassSection(title: "Income") {
            HStack {
                Text("Expected Monthly Salary")
                    .foregroundStyle(.primary)
                Spacer()
                glassTextField("₹", text: $expectedSalary)
                    .keyboardType(.numberPad)
                    .focused($isInputActive)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
        }
    }
    
    private var expenseSplitSection: some View {
        glassSection(title: "Expense Splitting") {
            HStack {
                Text("Your Default Share (%)")
                    .foregroundStyle(.primary)
                Spacer()
                glassTextField("%", text: $splitRatio)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }
    }
    
    private var budgetRulesSection: some View {
        glassSection(title: "Budget Rules") {
            VStack(spacing: 16) {
                Picker("Savings Strategy", selection: $savingsRule) {
                    ForEach(SavingsRule.allCases) { rule in
                        Text(rule.rawValue).tag(rule)
                    }
                }
                .pickerStyle(.segmented)
                .colorMultiply(.cyan)
                
                if savingsRule == .fixedLimit {
                    Toggle("Comfortable Mode", isOn: $isComfortableMode)
                        .tint(.cyan)
                    
                    HStack {
                        Text(isComfortableMode ? "Comfortable Limit" : "Lean Limit")
                            .foregroundStyle(.primary)
                        Spacer()
                        glassTextField("₹", text: isComfortableMode ? $comfortableLimit : $fixedLimit)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                } else {
                    HStack {
                        Text("Save Percentage")
                            .foregroundStyle(.primary)
                        Spacer()
                        glassTextField("%", text: $savePercentage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                HStack {
                    Text("Bonus → Savings (%)")
                        .foregroundStyle(.primary)
                    Spacer()
                    glassTextField("%", text: $bonusSavingsPercent)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
        }
    }
    
    private var accountsSection: some View {
        glassSection(title: "Bank Accounts") {
            VStack(spacing: 16) {
                HStack {
                    Text("HDFC Balance")
                        .foregroundStyle(.primary)
                    Spacer()
                    glassTextField("₹", text: $hdfcBalance)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }
                
                HStack {
                    Text("ICICI Balance")
                        .foregroundStyle(.primary)
                    Spacer()
                    glassTextField("₹", text: $iciciBalance)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button(action: saveSettings) {
            Text(saved ? "Saved ✓" : "Save Settings")
                .font(.title3.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding()
        }
        .background(
            LinearGradient(colors: [.cyan, .indigo], startPoint: .leading, endPoint: .trailing)
        )
        .foregroundStyle(.primary)
        .cornerRadius(16)
        .shadow(color: .indigo.opacity(0.5), radius: 10, x: 0, y: 5)
        .padding(.top, 10)
    }
    
    // MARK: - Reusable UI Components
    
    private func glassSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            
            content()
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func glassTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding(10)
            .background(Color.primary.opacity(0.1))
            .cornerRadius(10)
            .foregroundStyle(.primary)
            .tint(.cyan)
    }
    
    // MARK: - Logic
    
    private var currentUserEmail: String {
        Auth.auth().currentUser?.email?.lowercased() ?? ""
    }

    private func loadSettings() {
        let s = settings.first(where: { $0.ownerEmail == currentUserEmail }) ?? {
            let newSettings = UserSettings()
            newSettings.ownerEmail = currentUserEmail
            modelContext.insert(newSettings)
            try? modelContext.save()
            return newSettings
        }()
        
        userName = s.userName
        partnerName = s.partnerName
        partnerEmail = s.partnerEmail
        expectedSalary = String(format: "%.0f", s.expectedMonthlySalary)
        splitRatio = String(format: "%.0f", s.defaultSplitRatio * 100)
        
        let c = configs.first(where: { $0.ownerEmail == currentUserEmail }) ?? {
            let newConfig = BudgetConfig()
            newConfig.ownerEmail = currentUserEmail
            modelContext.insert(newConfig)
            try? modelContext.save()
            return newConfig
        }()
        
        savingsRule = c.savingsRule
        fixedLimit = String(format: "%.0f", c.fixedSpendingLimit)
        comfortableLimit = String(format: "%.0f", c.comfortableLimit)
        savePercentage = String(format: "%.0f", c.savePercentage * 100)
        isComfortableMode = c.isComfortableMode
        bonusSavingsPercent = String(format: "%.0f", c.bonusSavingsPercent * 100)
        
        let hdfcAccount = accounts.first(where: { $0.name == "HDFC" && $0.ownerEmail == currentUserEmail })
        let iciciAccount = accounts.first(where: { $0.name == "ICICI" && $0.ownerEmail == currentUserEmail })
        hdfcBalance = String(format: "%.0f", hdfcAccount?.balance ?? Constants.defaultHDFCBalance)
        iciciBalance = String(format: "%.0f", iciciAccount?.balance ?? 0)
    }
    
    private func saveSettings() {
        // UserSettings
        let s = settings.first(where: { $0.ownerEmail == currentUserEmail }) ?? {
            let newSettings = UserSettings()
            newSettings.ownerEmail = currentUserEmail
            modelContext.insert(newSettings)
            return newSettings
        }()
        s.userName = userName
        s.partnerName = partnerName
        let currentUserEmail = FirebaseAuth.Auth.auth().currentUser?.email?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cleanedPartnerEmail = partnerEmail.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedPartnerEmail == currentUserEmail && !cleanedPartnerEmail.isEmpty {
            s.partnerEmail = "" // Prevent setting partner to oneself
            partnerEmail = ""
        } else {
            s.partnerEmail = cleanedPartnerEmail
        }
        
        s.expectedMonthlySalary = Double(expectedSalary) ?? Constants.defaultExpectedSalary
        s.defaultSplitRatio = (Double(splitRatio) ?? 50) / 100.0
        
        // BudgetConfig
        let c = configs.first(where: { $0.ownerEmail == currentUserEmail }) ?? {
            let newConfig = BudgetConfig()
            newConfig.ownerEmail = currentUserEmail
            modelContext.insert(newConfig)
            return newConfig
        }()
        c.savingsRule = savingsRule
        c.fixedSpendingLimit = Double(fixedLimit) ?? Constants.defaultSpendingLimit
        c.comfortableLimit = Double(comfortableLimit) ?? Constants.defaultComfortableLimit
        c.savePercentage = (Double(savePercentage) ?? 65) / 100.0
        c.isComfortableMode = isComfortableMode
        c.bonusSavingsPercent = (Double(bonusSavingsPercent) ?? 80) / 100.0
        
        // Accounts
        if let hdfcAccount = accounts.first(where: { $0.name == "HDFC" && $0.ownerEmail == currentUserEmail }) {
            hdfcAccount.balance = Double(hdfcBalance) ?? Constants.defaultHDFCBalance
        } else {
            let hdfc = AccountBalance(name: "HDFC", balance: Double(hdfcBalance) ?? Constants.defaultHDFCBalance, minimumBalance: Constants.hdfcMinimumBalance)
            hdfc.ownerEmail = currentUserEmail
            modelContext.insert(hdfc)
        }
        
        if let iciciAccount = accounts.first(where: { $0.name == "ICICI" && $0.ownerEmail == currentUserEmail }) {
            iciciAccount.balance = Double(iciciBalance) ?? 0
        } else {
            let icici = AccountBalance(name: "ICICI", balance: Double(iciciBalance) ?? 0)
            icici.ownerEmail = currentUserEmail
            modelContext.insert(icici)
        }
        
        try? modelContext.save()
        
        withAnimation {
            saved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { saved = false }
        }
    }
}
