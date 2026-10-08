import SwiftUI
import SwiftData
import FirebaseAuth

struct ExpenseListView: View {
    @StateObject private var viewModel = ExpenseViewModel()
    @Query private var settings: [UserSettings]
    @State private var selectedMonthKey: String = DateHelpers.monthKey()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                
                GeometryReader { proxy in
                    let size = proxy.size
                    Circle()
                        .fill(RadialGradient(colors: [Color.indigo.opacity(0.3), .clear], center: .center, startRadius: 0, endRadius: size.width))
                        .frame(width: size.width * 1.5, height: size.width * 1.5)
                        .offset(x: size.width/4, y: -size.height/4)
                        .blur(radius: 50)
                }
                .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Expenses")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.primary)
                        Spacer()
                        
                        Picker("Month", selection: $selectedMonthKey) {
                            Text("Current Month").tag(DateHelpers.monthKey())
                            if let prev = DateHelpers.previousMonthKey(from: DateHelpers.monthKey()) {
                                Text("Previous Month").tag(prev)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.cyan)
                    }
                    .padding(.horizontal)
                    
                    let filteredExpenses = viewModel.expenses
                    
                    if !filteredExpenses.isEmpty {
                        expenseSummaryCard
                            .padding(.horizontal)
                    }
                    
                    if filteredExpenses.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "tray")
                                .font(.system(size: 64))
                                .foregroundStyle(.primary.opacity(0.3))
                            Text("No expenses logged yet.")
                                .foregroundStyle(.primary.opacity(0.5))
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
                                let userSettings = settings.first(where: { $0.ownerEmail == currentUserEmail })
                                let pName = userSettings?.partnerName ?? ""
                                
                                ForEach(filteredExpenses) { expense in
                                    ExpenseRowView(expense: expense, partnerName: pName) {
                                        deleteExpense(expense)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .navigationBarHidden(true)
            
            .onAppear {
                viewModel.startListening(monthKey: selectedMonthKey)
            }
            .onChange(of: selectedMonthKey) { _, newKey in
                viewModel.startListening(monthKey: newKey)
            }
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        viewModel.deleteExpense(expense)
    }
    
    private var myTotalExpenses: Double {
        let userEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        var total = 0.0
        for exp in viewModel.expenses {
            if !exp.isShared {
                total += exp.amount
            } else {
                let expPaidBy = exp.paidByEmail.lowercased()
                if expPaidBy == userEmail {
                    total += exp.amount // creator's share
                } else {
                    total += (exp.fullAmount - exp.amount) // other person's share
                }
            }
        }
        return total
    }
    
    private var partnerTotalExpenses: Double {
        let userEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        var total = 0.0
        for exp in viewModel.expenses where exp.isShared {
            let expPaidBy = exp.paidByEmail.lowercased()
            if expPaidBy == userEmail {
                total += exp.roommateShare
            } else {
                total += exp.amount // creator's share
            }
        }
        return total
    }
    
    private var partnerName: String {
        let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        let userSettings = settings.first(where: { $0.ownerEmail == currentUserEmail })
        if let pName = userSettings?.partnerName, !pName.isEmpty {
            return pName
        }
        
        for exp in viewModel.expenses where exp.isShared {
            let expPaidBy = exp.paidByEmail.lowercased()
            if expPaidBy == currentUserEmail {
                return exp.sharedWithEmail.components(separatedBy: "@").first?.capitalized ?? "Partner"
            } else {
                return exp.paidByEmail.components(separatedBy: "@").first?.capitalized ?? "Partner"
            }
        }
        return "Partner"
    }
    
    private var expenseSummaryCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Expenses")
                    .font(.caption2)
                    .foregroundStyle(.primary.opacity(0.6))
                Text(CurrencyFormatter.format(myTotalExpenses))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            Divider().background(Color.primary.opacity(0.2)).frame(height: 30)
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(partnerName)'s Expenses")
                    .font(.caption2)
                    .foregroundStyle(.primary.opacity(0.6))
                Text(CurrencyFormatter.format(partnerTotalExpenses))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.cyan)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
}
