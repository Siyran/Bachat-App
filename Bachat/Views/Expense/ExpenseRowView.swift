import SwiftUI
import SwiftData
import FirebaseAuth

struct ExpenseRowView: View {
    let expense: Expense
    let partnerName: String
    let deleteAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Category Icon
                ZStack {
                    Circle()
                        .fill(expense.category.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: expense.category.icon)
                        .foregroundStyle(expense.category.color)
                        .font(.title3)
                }
                
                // Details
                VStack(alignment: .leading, spacing: 6) {
                    Text(expense.category.rawValue)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.primary)
                    if !expense.note.isEmpty {
                        Text(expense.note)
                            .font(.subheadline)
                            .foregroundStyle(.primary.opacity(0.6))
                            .lineLimit(1)
                    }
                    Text(expense.date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.primary.opacity(0.4))
                }
                
                Spacer()
                
                // Amount
                VStack(alignment: .trailing, spacing: 6) {
                    Text(CurrencyFormatter.format(expense.fullAmount))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(expense.isShared ? .white : .white)
                    
                    if expense.isShared {
                        Text("Shared")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cyan.opacity(0.2))
                            .foregroundStyle(.cyan)
                            .cornerRadius(6)
                    }
                }
                
                // Delete button
                Button(role: .destructive, action: deleteAction) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            
            // Split Breakdown
            if expense.isShared {
                Divider().background(Color.primary.opacity(0.1))
                
                HStack {
                    let currentUserEmail = FirebaseAuth.Auth.auth().currentUser?.email?.lowercased() ?? ""
                    let iPaid = (currentUserEmail == expense.paidByEmail.lowercased())
                    
                    let creatorShare = expense.amount
                    let otherShare = expense.fullAmount - expense.amount
                    
                    let mySplit = iPaid ? creatorShare : otherShare
                    let roommateSplit = iPaid ? otherShare : creatorShare
                    
                    let otherEmail = iPaid ? expense.sharedWithEmail : expense.paidByEmail
                    let otherName = partnerName.isEmpty ? (otherEmail.components(separatedBy: "@").first?.capitalized ?? "Partner") : partnerName
                    
                    VStack(alignment: .leading) {
                        Text("My Split")
                            .font(.caption2)
                            .foregroundStyle(.primary.opacity(0.5))
                        Text(CurrencyFormatter.format(mySplit))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(iPaid ? .red : .red)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center) {
                        Text("Paid By")
                            .font(.caption2)
                            .foregroundStyle(.primary.opacity(0.5))
                        Text(iPaid ? "Me" : otherName)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(otherName)'s Split")
                            .font(.caption2)
                            .foregroundStyle(.primary.opacity(0.5))
                        Text(CurrencyFormatter.format(roommateSplit))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.cyan)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
}
