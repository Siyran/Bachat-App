# Data Models Reference

Bachat leverages SwiftData for high-performance offline caching and Firestore for remote synchronization and multi-user split reconciliation.

## Entity Overview

### 1. `Expense`
Represents an individual financial transaction.
- `id: String`: Unique Firestore document identifier.
- `amount: Double`: The authenticated user's share after split calculations.
- `fullAmount: Double`: Total expense cost before split ratios.
- `categoryRaw: String`: Stored raw value mapped to `ExpenseCategory`.
- `note: String`: Freeform user description or vendor note.
- `date: Date`: Timestamp when the expense occurred.
- `isShared: Bool`: Flag indicating whether the expense is split with a partner.
- `splitRatio: Double`: Fractional responsibility of the payer (0.0 to 1.0).
- `monthKey: String`: Canonical identifier format `yyyy-MM` for fast index queries.
- `paidByEmail: String`: Email of the participant who executed payment.
- `sharedWithEmail: String`: Email of the counterpart roommate/partner.

### 2. `MonthlyIncome`
Tracks base earnings and dynamic additions for a billing cycle.
- `id: UUID`: Local unique primary key.
- `monthKey: String`: Targeted monthly cycle identifier (`yyyy-MM`).
- `ownerEmail: String`: User identifier owning this income profile.
- `baseSalary: Double`: Base salary credited for the cycle.
- `extras: [IncomeEntry]`: Cascade-deleted relationship to supplemental entries.
- `isProvisional: Bool`: Indicates whether the income figure is confirmed or an estimate.
- `creditedDate: Date?`: Timestamp of salary arrival.

### 3. `IncomeEntry`
Supplemental income line items such as bonuses or side projects.
- `id: UUID`: Local unique identifier.
- `amount: Double`: Monetary amount credited.
- `label: String`: Descriptive label (e.g., "Freelance App", "Bonus").
- `typeRaw: String`: Serialized raw value of `IncomeType`.
- `date: Date`: Date credited.
- `transferDone: Bool`: Tracks whether the automated savings allocation was saved.

### 4. `BudgetConfig` & `CategoryBudget`
Controls spending rules and envelope budgeting allocations.
- `savingsRuleRaw: String`: `.fixedLimit` (lean ₹12K vs comfortable ₹15K) or `.savePercentage`.
- `fixedSpendingLimit: Double`: Lean spending limit.
- `comfortableLimit: Double`: Comfortable mode spending limit.
- `savePercentage: Double`: Percentage of income allocated directly to savings.
- `bonusSavingsPercent: Double`: Fraction of unexpected bonuses earmarked for savings.
- `categoryBudgets: [CategoryBudget]`: Proportional breakdown per category summing to $\le 1.0$.

### 5. `SavingsGoal`
Long-term savings target tracker with progress projections.
- `name: String`: Goal description (e.g., "Emergency Fund").
- `targetAmount: Double`: Target financial figure in ₹.
- `targetDate: Date`: Scheduled deadline for achieving target.
- `isActive: Bool`: Indicates the primary active goal shown on the dashboard.

### 6. `AccountBalance`
Monitors bank account liquid balances against minimum balance requirements.
- `name: String`: Bank label (e.g., "HDFC", "ICICI").
- `balance: Double`: Current reported balance.
- `minimumBalance: Double`: Minimum required threshold (e.g., ₹10,000 for HDFC).

### 7. `SalaryAction`
Tracks monthly action items on salary day.
- `actionType: String`: Action category tag (`transfer_to_hdfc`, `bonus_transfer`, `top_up_hdfc`).
- `amount: Double`: Transfer amount required.
- `isCompleted: Bool`: Completed toggle status.
