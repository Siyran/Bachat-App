# Calculation Engines Documentation

All business logic algorithms in Bachat are organized as pure functional engines in `Bachat/Services/` and `BachatCore`. This enables complete deterministic unit testing without persistence dependencies.

## 1. BudgetEngine

### Monthly Spending Limit
```swift
BudgetEngine.monthlySpendingLimit(
    savingsRule: .fixedLimit,
    fixedLimit: 12_000,
    comfortableLimit: 15_000,
    isComfortableMode: false,
    savePercentage: 0.65,
    totalIncome: 40_000
)
```
- **Fixed Limit**: Returns either the base lean limit (₹12,000) or comfortable limit (₹15,000).
- **Save Percentage**: Calculates $(1 - \text{savePercentage}) \times \text{totalIncome}$.

### Daily Safe to Spend
```swift
BudgetEngine.safeToSpendToday(
    spendingLimit: 12_000,
    spentBeforeToday: 4_000,
    spentToday: 300,
    daysLeftInMonth: 10
)
```
- Divides remaining budget before today across remaining days in the calendar month.
- Avoids budget inflation from unexpected bonus income.

### Threshold Alerts
Calculates warning states at 50%, 80%, and 100% consumption thresholds for proactive budgeting notifications.

---

## 2. IncomeEngine

### Effective Income
Handles provisional months before actual salary slips or confirmations are credited:
- Uses confirmed actual income when confirmed.
- Automatically falls back to estimated monthly salary when provisional.

### Salary Day Transfer
Recommends automated transfer from operational checking account to high-yield savings account on salary credit date:
$$\text{Transfer Amount} = \max(\text{Total Income} - \text{Spending Limit}, 0)$$

---

## 3. GoalEngine

### Required Monthly Savings
$$\text{Required Rate} = \frac{\text{Target Amount} - \text{Saved So Far}}{\text{Months Remaining}}$$

### Projected Total Savings
Forecasts expected final balance based on current trajectory:
$$\text{Projected Total} = \text{Saved So Far} + (\text{Monthly Savings} \times \text{Months Remaining})$$

### Smoke-Free Milestone Tracking
Computes financial capital preserved and health streaks:
$$\text{Saved} = \text{Streak Days} \times \text{Daily Savings Rate}$$
