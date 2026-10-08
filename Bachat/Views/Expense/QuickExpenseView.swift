import SwiftUI
import SwiftData
import FirebaseAuth

struct QuickExpenseView: View {
    @StateObject private var viewModel = ExpenseViewModel()
    @Query private var settings: [UserSettings]
    
    @State private var amountText: String = ""
    @State private var category: ExpenseCategory = .misc
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var isShared: Bool = false
    @State private var paidByPartner: Bool = false
    @State private var splitRatioText: String = String(format: "%.0f", Constants.defaultSplitRatio * 100)
    @FocusState private var isInputActive: Bool
    
    // Feedback
    @State private var showSuccess: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                
                GeometryReader { proxy in
                    let size = proxy.size
                    Circle()
                        .fill(RadialGradient(colors: [Color.indigo.opacity(0.3), .clear], center: .center, startRadius: 0, endRadius: size.width))
                        .frame(width: size.width * 1.5, height: size.width * 1.5)
                        .offset(x: -size.width/4, y: -size.height/4)
                        .blur(radius: 50)
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerView
                        
                        amountSection
                        detailsSection
                        sharedSection
                        
                        saveButton
                        
                        if showSuccess {
                            Text("Expense added successfully!")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.green)
                                .transition(.opacity)
                                .padding(.top, 10)
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
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
                Text("Add Expense")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Track your spending")
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.6))
            }
            Spacer()
        }
        .padding(.bottom, 8)
    }
    
    private var amountSection: some View {
        glassSection {
            VStack(alignment: .leading, spacing: 16) {
                Text("Amount")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary.opacity(0.8))
                
                HStack(spacing: 8) {
                    Text("₹")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                    
                    TextField("0.00", text: $amountText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .keyboardType(.decimalPad)
                        .focused($isInputActive)
                        .foregroundStyle(.primary)
                        .tint(.cyan)
                }
            }
        }
    }
    
    private var detailsSection: some View {
        glassSection {
            VStack(spacing: 20) {
                HStack {
                    Text("Category")
                        .foregroundStyle(.primary)
                    Spacer()
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .tint(.cyan)
                }
                
                Divider().background(Color.primary.opacity(0.1))
                
                HStack {
                    Text("Note")
                        .foregroundStyle(.primary)
                    Spacer()
                    TextField("Optional", text: $note)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.primary)
                        .tint(.cyan)
                }
                
                Divider().background(Color.primary.opacity(0.1))
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .foregroundStyle(.primary)
                    .tint(.cyan)
            }
        }
    }
    
    private var sharedSection: some View {
        glassSection {
            VStack(spacing: 20) {
                let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
                let userSettings = settings.first(where: { $0.ownerEmail == currentUserEmail })
                
                let partnerEmail = userSettings?.partnerEmail ?? ""
                let pName = userSettings?.partnerName ?? ""
                let partnerName = pName.isEmpty ? (partnerEmail.components(separatedBy: "@").first ?? "Partner") : pName
                let hasPartner = !partnerEmail.isEmpty
                
                Toggle(hasPartner ? "Share Expense with \(partnerName)" : "Configure Partner in Settings to Share", isOn: $isShared)
                    .tint(.cyan)
                    .foregroundStyle(.primary)
                    .disabled(!hasPartner)
                
                if isShared {
                    Divider().background(Color.primary.opacity(0.1))
                    
                    Toggle("Paid by \(partnerName)", isOn: $paidByPartner)
                        .tint(.cyan)
                        .foregroundStyle(.primary)
                    
                    Divider().background(Color.primary.opacity(0.1))
                    
                    HStack {
                        Text("Your Share (%)")
                            .foregroundStyle(.primary)
                        Spacer()
                        TextField("%", text: $splitRatioText)
                            .keyboardType(.numberPad)
                            .focused($isInputActive)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .padding(8)
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundStyle(.primary)
                            .tint(.cyan)
                    }
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button(action: saveExpense) {
            Text("Add Expense")
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
        .disabled(Double(amountText) == nil)
        .opacity(Double(amountText) == nil ? 0.5 : 1)
        .padding(.top, 10)
    }
    
    // MARK: - Reusable UI
    
    private func glassSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Logic
    
    private func saveExpense() {
        guard let amount = Double(amountText) else { return }
        let ratio = isShared ? ((Double(splitRatioText) ?? 50.0) / 100.0) : 1.0
        
        let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        var computedRoommateEmail = ""
        var finalPaidByEmail = currentUserEmail
        
        if isShared {
            let userSettings = settings.first(where: { $0.ownerEmail == currentUserEmail })
            computedRoommateEmail = userSettings?.partnerEmail.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if paidByPartner && !computedRoommateEmail.isEmpty {
                finalPaidByEmail = computedRoommateEmail
            }
        }
        
        viewModel.addExpense(
            amount: amount,
            category: category,
            note: note,
            date: date,
            isShared: isShared,
            splitRatio: ratio,
            sharedWithEmail: computedRoommateEmail,
            paidByEmail: finalPaidByEmail
        )
        
        // Reset and show feedback
        withAnimation {
            amountText = ""
            note = ""
            showSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSuccess = false
            }
        }
    }
}
