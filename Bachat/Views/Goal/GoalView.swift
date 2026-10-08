import SwiftUI
import SwiftData

struct GoalView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: GoalViewModel
    
    @State private var goal: SavingsGoal?
    @State private var showingEditGoal = false
    @State private var editTargetAmount: String = ""
    @State private var editTargetDate: Date = Date()
    
    @Query private var balances: [AccountBalance]
    
    let hdfcFloor: Double = 10_000
    
    init(context: ModelContext) {
        _viewModel = StateObject(wrappedValue: GoalViewModel(context: context))
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
                        .offset(x: size.width/4, y: size.height/4)
                        .blur(radius: 50)
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerView
                        
                        if let goal = goal {
                            savingsGoalCard(goal)
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
                goal = viewModel.fetchOrCreateGoal()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Goals")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Track your targets")
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.6))
            }
            Spacer()
        }
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func savingsGoalCard(_ goal: SavingsGoal) -> some View {
        let hdfcBalance = balances.first(where: { $0.name == "HDFC" })?.balance ?? 0
        let usableSavings = max(0, hdfcBalance - hdfcFloor)
        
        let months = GoalEngine.monthsRemaining(to: goal.targetDate)
        let requiredMonthly = GoalEngine.requiredMonthlySavings(
            targetAmount: goal.targetAmount,
            savedSoFar: usableSavings,
            monthsRemaining: months
        )
        let progressFraction = goal.targetAmount > 0 ? min(usableSavings / goal.targetAmount, 1.0) : 0
        let daysLeft = DateHelpers.daysBetween(from: Date(), to: goal.targetDate)
        
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Target Savings")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                Spacer()
                Button("Edit") {
                    editTargetAmount = String(format: "%.0f", goal.targetAmount)
                    editTargetDate = goal.targetDate
                    showingEditGoal = true
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.cyan)
            }
            
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(CurrencyFormatter.format(usableSavings))
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.green)
                        .shadow(color: .green.opacity(0.4), radius: 5, x: 0, y: 0)
                    Text("of \(CurrencyFormatter.format(goal.targetAmount))")
                        .font(.subheadline)
                        .foregroundStyle(.primary.opacity(0.6))
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("By \(goal.targetDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary.opacity(0.8))
                    
                    Text("\(daysLeft) days left")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.cyan)
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(Color.green)
                        .frame(width: geo.size.width * CGFloat(progressFraction), height: 8)
                        .shadow(color: .green.opacity(0.5), radius: 5, x: 0, y: 0)
                }
            }
            .frame(height: 8)
            .padding(.vertical, 4)
            
            if hdfcBalance < hdfcFloor {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Top up \(CurrencyFormatter.format(hdfcFloor - hdfcBalance)) to reach HDFC floor limit.")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.red)
                .padding(.top, 4)
            }
            
            HStack {
                Text("Required Monthly Saving:")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary.opacity(0.8))
                Spacer()
                Text(CurrencyFormatter.format(requiredMonthly))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .padding()
            .background(Color.primary.opacity(0.05))
            .cornerRadius(12)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1))
        .sheet(isPresented: $showingEditGoal) {
            editGoalForm
                .presentationDetents([.fraction(0.4)])
        }
    }
    
    private var editGoalForm: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Text("Edit Goal")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Button(action: { showingEditGoal = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.primary.opacity(0.6))
                    }
                }
                .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Amount")
                        .foregroundStyle(.primary.opacity(0.8))
                    TextField("₹", text: $editTargetAmount)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundStyle(.primary)
                        .tint(.cyan)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Date")
                        .foregroundStyle(.primary.opacity(0.8))
                    DatePicker("", selection: $editTargetDate, displayedComponents: .date)
                        .labelsHidden()
                        
                        .tint(.cyan)
                }
                
                Button("Save Goal") {
                    if let amount = Double(editTargetAmount), let g = goal {
                        g.targetAmount = amount
                        g.targetDate = editTargetDate
                        viewModel.saveGoal()
                        showingEditGoal = false
                    }
                }
                .font(.headline.weight(.bold))
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.cyan)
                .foregroundStyle(.primary)
                .cornerRadius(16)
                
                Spacer()
            }
            .padding()
            .padding(.top, 16)
        }
    }
}
