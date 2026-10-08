import SwiftUI
import SwiftData
import FirebaseAuth

struct IncomeEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: IncomeViewModel
    @Query private var settings: [UserSettings]
    
    @State private var currentMonth: MonthlyIncome?
    @State private var allMonths: [MonthlyIncome] = []
    @State private var actualSalaryText: String = ""
    @State private var creditedDate: Date = Date()
    @State private var showingAddExtra = false
    
    // Add extra form
    @State private var newExtraAmount: String = ""
    @State private var newExtraLabel: String = ""
    @State private var newExtraType: IncomeType = .bonus
    
    init(context: ModelContext) {
        // We'll initialize the view model in onAppear, but we need settings
        _viewModel = StateObject(wrappedValue: IncomeViewModel(context: context, settings: UserSettings()))
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
                        .offset(x: size.width/4, y: -size.height/4)
                        .blur(radius: 50)
                }
                .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    header
                    
                    if let month = currentMonth {
                        ScrollView {
                            VStack(spacing: 20) {
                                salarySection(month)
                                extrasSection(month)
                                historySection
                            }
                            .padding(.bottom, 40)
                        }
                        .scrollIndicators(.hidden)
                    } else {
                        Spacer()
                        ProgressView().tint(.cyan)
                        Spacer()
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            
            .onAppear {
                let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
                let userSettings = settings.first(where: { $0.ownerEmail == currentUserEmail })
                if let s = userSettings {
                    viewModel.expectedSalary = s.expectedMonthlySalary
                }
                loadCurrentMonth()
            }
        }
    }
    
    private var header: some View {
        HStack {
            Text("Monthly Income")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)
            Spacer()
            Text(DateHelpers.monthKey())
                .font(.title3.weight(.medium))
                .foregroundStyle(.primary.opacity(0.6))
        }
    }
    
    @ViewBuilder
    private func salarySection(_ month: MonthlyIncome) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Base Salary")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            
            if month.isProvisional {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Provisional Estimate: \(CurrencyFormatter.format(month.baseSalary))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.orange)
                    DatePicker("Credited On", selection: $creditedDate, displayedComponents: .date)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding(.vertical, 4)
                        
                    HStack {
                        TextField("Actual Salary", text: $actualSalaryText)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundStyle(.primary)
                        
                        Button("Confirm") {
                            if let actual = Double(actualSalaryText) {
                                withAnimation {
                                    viewModel.confirmIncome(month: month, actualSalary: actual)
                                    month.creditedDate = creditedDate
                                    try? modelContext.save()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Double(actualSalaryText) == nil ? Color.gray.opacity(0.5) : Color.cyan)
                        .foregroundStyle(.primary)
                        .cornerRadius(12)
                        .disabled(Double(actualSalaryText) == nil)
                    }
                }
                .padding(20)
                .background(Color.orange.opacity(0.15))
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20).stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                .onAppear {
                    actualSalaryText = String(format: "%.0f", month.baseSalary)
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(CurrencyFormatter.format(month.baseSalary))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.green)
                            
                        if let cDate = month.creditedDate {
                            Text("Credited on \(cDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.primary.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    Button("Edit") {
                        withAnimation {
                            month.isProvisional = true
                        }
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.cyan)
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1)
                )
            }
        }
    }
    
    @ViewBuilder
    private func extrasSection(_ month: MonthlyIncome) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Bonuses & Side Income")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: { showingAddExtra.toggle() }) {
                    Label("Add Extra", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.cyan)
                }
                .sheet(isPresented: $showingAddExtra) {
                    addExtraForm(month)
                        .presentationDetents([.fraction(0.4)])
                }
            }
            
            if month.extras.isEmpty {
                Text("No extra income this month.")
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.5))
                    .padding(.vertical)
            } else {
                VStack(spacing: 12) {
                    ForEach(month.extras) { extra in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(extra.label)
                                    .font(.headline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text(extra.type.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(.primary.opacity(0.5))
                            }
                            Spacer()
                            Text(CurrencyFormatter.format(extra.amount))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.primary)
                                
                            Button(action: {
                                withAnimation {
                                    viewModel.deleteExtraIncome(extra)
                                }
                            }) {
                                Image(systemName: "trash.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                            .padding(.leading, 8)
                        }
                        .padding(16)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
            }
            
            Divider()
                .background(Color.primary.opacity(0.2))
                .padding(.vertical, 8)
            
            HStack {
                Text("Total Income")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.primary.opacity(0.8))
                Spacer()
                Text(CurrencyFormatter.format(month.totalIncome))
                    .font(.title.weight(.bold))
                    .foregroundStyle(.green)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Salary History")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            
            let pastMonths = allMonths.filter { !$0.isProvisional && $0.monthKey != currentMonth?.monthKey }
            
            if pastMonths.isEmpty {
                Text("No confirmed past salaries found.")
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.5))
                    .padding(.vertical)
            } else {
                VStack(spacing: 12) {
                    ForEach(pastMonths) { past in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(past.monthKey)
                                    .font(.headline.weight(.medium))
                                    .foregroundStyle(.primary)
                                
                                if let cDate = past.creditedDate {
                                    Text("Credited on \(cDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption2)
                                        .foregroundStyle(.primary.opacity(0.5))
                                } else {
                                    Text("Date not specified")
                                        .font(.caption2)
                                        .foregroundStyle(.primary.opacity(0.5))
                                }
                            }
                            Spacer()
                            Text(CurrencyFormatter.format(past.baseSalary))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.green)
                        }
                        .padding(16)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(12)
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
    
    private func addExtraForm(_ month: MonthlyIncome) -> some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TextField("Amount (₹)", text: $newExtraAmount)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundStyle(.primary)
                    
                    TextField("Label (e.g. Diwali Bonus)", text: $newExtraLabel)
                        .padding()
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundStyle(.primary)
                    
                    Picker("Type", selection: $newExtraType) {
                        ForEach(IncomeType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorMultiply(.cyan)
                    
                    Button("Add Income") {
                        if let amount = Double(newExtraAmount), !newExtraLabel.isEmpty {
                            withAnimation {
                                viewModel.addExtraIncome(to: month, amount: amount, label: newExtraLabel, type: newExtraType)
                            }
                            showingAddExtra = false
                            newExtraAmount = ""
                            newExtraLabel = ""
                        }
                    }
                    .font(.headline.weight(.bold))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Double(newExtraAmount) == nil || newExtraLabel.isEmpty ? Color.gray.opacity(0.5) : Color.cyan)
                    .foregroundStyle(.primary)
                    .cornerRadius(16)
                    .disabled(Double(newExtraAmount) == nil || newExtraLabel.isEmpty)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Add Extra Income")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingAddExtra = false
                        }
                        .foregroundStyle(.cyan)
                    }
                }
            }
            
        }
    }
    
    private func loadCurrentMonth() {
        let key = DateHelpers.monthKey()
        currentMonth = viewModel.fetchOrCreateMonth(key: key)
        allMonths = viewModel.fetchAllMonths()
    }
}
