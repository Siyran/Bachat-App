import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: BudgetViewModel
    @StateObject private var notifManager = NotificationManager.shared
    @StateObject private var expenseViewModel = ExpenseViewModel()
    
    @Query private var incomes: [MonthlyIncome]
    
    @State private var config: BudgetConfig?
    @State private var selectedMonthKey: String = DateHelpers.monthKey()
    @State private var editingCategory: ExpenseCategory?
    @State private var shareText: String = ""
    
    init(context: ModelContext) {
        _viewModel = StateObject(wrappedValue: BudgetViewModel(context: context))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                
                GeometryReader { proxy in
                    let size = proxy.size
                    Circle()
                        .fill(RadialGradient(colors: [Color.indigo.opacity(0.3), .clear], center: .center, startRadius: 0, endRadius: size.width))
                        .frame(width: size.width * 1.5, height: size.width * 1.5)
                        .offset(x: -size.width/4, y: size.height/4)
                        .blur(radius: 50)
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerView
                        
                        if !notifManager.hasPermission {
                            permissionCard
                        }
                        
                        if let config = config {
                            overallSummaryCard(config: config)
                            categoriesList(config: config)
                        } else {
                            ProgressView().tint(.cyan)
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            
            .onAppear {
                config = viewModel.fetchOrCreateConfig()
                expenseViewModel.startListening(monthKey: selectedMonthKey)
            }
            .sheet(item: $editingCategory) { category in
                editingSheet(category: category)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Budgets")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Manage your limits")
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.6))
            }
            Spacer()
        }
        .padding(.bottom, 8)
    }
    
    private var permissionCard: some View {
        Button(action: {
            notifManager.requestPermission()
        }) {
            HStack {
                Image(systemName: "bell.badge.fill")
                Text("Enable Notifications for Alerts")
                    .font(.subheadline.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange.opacity(0.2))
            .foregroundStyle(.orange)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.4), lineWidth: 1)
            )
        }
    }
    
    private func overallSummaryCard(config: BudgetConfig) -> some View {
        let totalIncome = incomes.first(where: { $0.monthKey == selectedMonthKey })?.totalIncome ?? 0
        let overallLimit = BudgetEngine.monthlySpendingLimit(
            savingsRule: config.savingsRule,
            fixedLimit: config.fixedSpendingLimit,
            comfortableLimit: config.comfortableLimit,
            isComfortableMode: config.isComfortableMode,
            savePercentage: config.savePercentage,
            totalIncome: totalIncome
        )
        let totalSpent = expenseViewModel.expenses
            .filter { $0.monthKey == selectedMonthKey }
            .reduce(0) { $0 + $1.amount }
        let overallLevel = BudgetEngine.alertLevel(spent: totalSpent, limit: overallLimit)
        
        let progress = overallLimit > 0 ? min(totalSpent / overallLimit, 1.0) : 0
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Overall Limit")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            
            HStack(alignment: .lastTextBaseline) {
                Text(CurrencyFormatter.format(totalSpent))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(overallLevel.color)
                    .shadow(color: overallLevel.color.opacity(0.4), radius: 5, x: 0, y: 0)
                
                Text("/ \(CurrencyFormatter.format(overallLimit))")
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.6))
                
                Spacer()
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(overallLevel.color)
                        .frame(width: geo.size.width * CGFloat(progress), height: 8)
                        .shadow(color: overallLevel.color.opacity(0.5), radius: 5, x: 0, y: 0)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1))
    }
    
    private func categoriesList(config: BudgetConfig) -> some View {
        let totalIncome = incomes.first(where: { $0.monthKey == selectedMonthKey })?.totalIncome ?? 0
        let overallLimit = BudgetEngine.monthlySpendingLimit(
            savingsRule: config.savingsRule,
            fixedLimit: config.fixedSpendingLimit,
            comfortableLimit: config.comfortableLimit,
            isComfortableMode: config.isComfortableMode,
            savePercentage: config.savePercentage,
            totalIncome: totalIncome
        )
        
        return VStack(spacing: 16) {
            ForEach(ExpenseCategory.allCases) { category in
                let catBudget = config.categoryBudgets.first(where: { $0.category == category })
                let share = catBudget?.share ?? 0
                let catLimit = BudgetEngine.categoryLimit(share: share, overallLimit: overallLimit)
                
                let spent = expenseViewModel.expenses
                    .filter { $0.category == category && $0.monthKey == selectedMonthKey }
                    .reduce(0) { $0 + $1.amount }
                
                let progress = catLimit > 0 ? min(spent / catLimit, 1.0) : 0.0
                let level = BudgetEngine.alertLevel(spent: spent, limit: catLimit)
                
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: category.icon)
                            .foregroundStyle(category.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(category.rawValue)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            Spacer()
                            if catLimit > 0 {
                                Text("\(CurrencyFormatter.format(spent)) / \(CurrencyFormatter.format(catLimit))")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.primary.opacity(0.8))
                            } else {
                                Text("No budget")
                                    .font(.caption)
                                    .foregroundStyle(.primary.opacity(0.5))
                            }
                        }
                        
                        if catLimit > 0 {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.1))
                                        .frame(height: 6)
                                    
                                    Capsule()
                                        .fill(level.color)
                                        .frame(width: geo.size.width * CGFloat(progress), height: 6)
                                        .shadow(color: level.color.opacity(0.5), radius: 5, x: 0, y: 0)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.05))
                .cornerRadius(16)
                .onTapGesture {
                    editingCategory = category
                    shareText = share > 0 ? String(format: "%.0f", share * 100) : ""
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1))
    }
    
    private func editingSheet(category: ExpenseCategory) -> some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Percentage of your overall spending limit allocated to \(category.rawValue).")
                        .font(.subheadline)
                        .foregroundStyle(.primary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                    
                    HStack {
                        Text("Share")
                            .foregroundStyle(.primary)
                        Spacer()
                        TextField("%", text: $shareText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .padding(10)
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundStyle(.primary)
                            .tint(.cyan)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Set Budget")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingCategory = nil }
                        .tint(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let pct = Double(shareText), let config = config {
                            viewModel.updateCategoryShare(config: config, category: category, share: pct / 100.0)
                            
                            let totalIncome = incomes.first(where: { $0.monthKey == selectedMonthKey })?.totalIncome ?? 0
                            viewModel.checkAlerts(expenses: expenseViewModel.expenses, config: config, totalIncome: totalIncome, monthKey: selectedMonthKey)
                        }
                        editingCategory = nil
                    }
                    .tint(.cyan)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
