import SwiftUI
import SwiftData

struct IncomeBanner: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var currentMonthArray: [MonthlyIncome]
    
    init() {
        let key = DateHelpers.monthKey()
        _currentMonthArray = Query(filter: #Predicate { $0.monthKey == key })
    }
    
    var body: some View {
        if let month = currentMonthArray.first, month.isProvisional {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                Text("You haven't confirmed this month's income yet. Using estimated salary.")
                    .font(.subheadline)
                Spacer()
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}
