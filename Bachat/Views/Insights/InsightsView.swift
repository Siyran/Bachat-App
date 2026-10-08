import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var expenseViewModel = ExpenseViewModel()
    @Query private var allIncomes: [MonthlyIncome]
    @Query private var configs: [BudgetConfig]
    
    private let currentKey = DateHelpers.monthKey()
    
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerView
                        
                        spendingTrendCard
                        savingsRateCard
                        topCategoriesCard
                        projectionCard
                        
                        Spacer().frame(height: 40)
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            
            .onAppear {
                expenseViewModel.startListening(monthKey: currentKey)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Insights")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Analytics & Trends")
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.6))
            }
            Spacer()
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Spending Trend (last 3 months)
    
    private var spendingTrendCard: some View {
        let months = recentMonthKeys(count: 3)
        let monthlyTotals: [(key: String, total: Double)] = months.map { key in
            let total = expenseViewModel.expenses.filter { $0.monthKey == key }.reduce(0) { $0 + $1.amount }
            return (key, total)
        }
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trend")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            
            if monthlyTotals.allSatisfy({ $0.total == 0 }) {
                Text("Not enough data yet.")
                    .foregroundStyle(.primary.opacity(0.5))
                    .font(.subheadline)
            } else {
                let maxTotal = monthlyTotals.map(\.total).max() ?? 1
                
                ForEach(monthlyTotals, id: \.key) { item in
                    HStack(spacing: 16) {
                        Text(item.key)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.primary.opacity(0.8))
                            .frame(width: 60, alignment: .leading)
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.1))
                                
                                Capsule()
                                    .fill(LinearGradient(colors: [.cyan, .indigo], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: maxTotal > 0 ? geo.size.width * CGFloat(item.total / maxTotal) : 0)
                                    .shadow(color: .cyan.opacity(0.5), radius: 5, x: 0, y: 0)
                            }
                        }
                        .frame(height: 12)
                        
                        Text(CurrencyFormatter.compact(item.total))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.primary)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1))
    }
    
    // MARK: - Savings Rate
    
    private var savingsRateCard: some View {
        let currentIncome = allIncomes.first(where: { $0.monthKey == currentKey })?.totalIncome ?? 0
        let currentSpent = expenseViewModel.expenses.filter { $0.monthKey == currentKey }.reduce(0) { $0 + $1.amount }
        let rate = GoalEngine.savingsRate(totalIncome: currentIncome, totalSpent: currentSpent)
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Savings Rate")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            
            HStack {
                Text(String(format: "%.0f%%", rate * 100))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(rate >= 0.5 ? Color.green : (rate >= 0.3 ? Color.orange : Color.red))
                    .shadow(color: (rate >= 0.5 ? Color.green : (rate >= 0.3 ? Color.orange : Color.red)).opacity(0.4), radius: 10, x: 0, y: 5)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text("Income: \(CurrencyFormatter.compact(currentIncome))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary.opacity(0.7))
                    Text("Spent: \(CurrencyFormatter.compact(currentSpent))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary.opacity(0.7))
                    Text("Saved: \(CurrencyFormatter.compact(max(currentIncome - currentSpent, 0)))")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1))
    }
    
    // MARK: - Top Categories
    
    private var topCategoriesCard: some View {
        let monthExpenses = expenseViewModel.expenses.filter { $0.monthKey == currentKey }
        let grouped = Dictionary(grouping: monthExpenses) { $0.category }
        let sorted = grouped.map { (cat: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
        let grandTotal = sorted.reduce(0) { $0 + $1.total }
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Where Your Money Goes")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            
            if sorted.isEmpty {
                Text("No expenses this month.")
                    .foregroundStyle(.primary.opacity(0.5))
                    .font(.subheadline)
            } else {
                ForEach(sorted.prefix(5), id: \.cat) { item in
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(item.cat.color.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Image(systemName: item.cat.icon)
                                .foregroundStyle(item.cat.color)
                        }
                        
                        Text(item.cat.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Text(CurrencyFormatter.format(item.total))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                        
                        Text(grandTotal > 0 ? String(format: "%.0f%%", (item.total / grandTotal) * 100) : "0%")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.cyan)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1))
    }
    
    // MARK: - Projection
    
    private var projectionCard: some View {
        let currentSpent = expenseViewModel.expenses.filter { $0.monthKey == currentKey }.reduce(0) { $0 + $1.amount }
        let daysElapsed = DateHelpers.daysElapsedInMonth()
        let totalDays = DateHelpers.daysInMonth()
        let projected = BudgetEngine.projectedMonthEndSpending(
            spentSoFar: currentSpent,
            daysElapsed: daysElapsed,
            totalDaysInMonth: totalDays
        )
        
        let config = configs.first
        let income = allIncomes.first(where: { $0.monthKey == currentKey })?.totalIncome ?? 0
        let limit = config.map {
            BudgetEngine.monthlySpendingLimit(
                savingsRule: $0.savingsRule,
                fixedLimit: $0.fixedSpendingLimit,
                comfortableLimit: $0.comfortableLimit,
                isComfortableMode: $0.isComfortableMode,
                savePercentage: $0.savePercentage,
                totalIncome: income
            )
        } ?? 0
        
        let willExceed = projected > limit && limit > 0
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Month-End Projection")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projected Spend")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.6))
                    Text(CurrencyFormatter.format(projected))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(willExceed ? .red : .white)
                        .shadow(color: willExceed ? .red.opacity(0.4) : .clear, radius: 5, x: 0, y: 0)
                }
                Spacer()
                if willExceed {
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text("Over limit by \(CurrencyFormatter.format(projected - limit))")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.red)
                    }
                } else if limit > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Under limit")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1))
    }
    
    // MARK: - Helpers
    
    private func recentMonthKeys(count: Int) -> [String] {
        var keys: [String] = []
        var key = currentKey
        for _ in 0..<count {
            keys.append(key)
            key = DateHelpers.previousMonthKey(from: key) ?? key
        }
        return keys.reversed()
    }
}
