# Architecture Overview

Bachat is built using SwiftUI, SwiftData, and Firebase Firestore, organized cleanly around separation of concerns, testability, and offline-first availability.

## System Topology

```
+--------------------------------------------------------+
|                      SwiftUI Views                     |
|  (Dashboard, Expense, Income, Budget, Goal, Insights)  |
+---------------------------+----------------------------+
                            |
                            v
+--------------------------------------------------------+
|                    ViewModels & State                  |
|          (ExpenseViewModel, DashboardViewModel)        |
+-------------+----------------------------+-------------+
              |                            |
              v                            v
+--------------------------+  +--------------------------+
|       Domain Logic       |  |     Data Persistence     |
| (Pure Calculation Engines|  |  (SwiftData Local Cache  |
| Budget, Income, Goal)    |  |  + Firestore Remote Sync)|
+--------------------------+  +--------------------------+
```

## Architectural Layers

### 1. Pure Calculation Engines (`Bachat/Services/` & `BachatCore`)
Financial algorithms are decoupled from persistence and state containers:
- **`BudgetEngine`**: Computes monthly spending limits, daily safe-to-spend allowance, and alert threshold notifications (50%, 80%, 100%).
- **`IncomeEngine`**: Handles actual vs. provisional income fallbacks, bonuses, side-income totals, and salary transfer recommendations.
- **`GoalEngine`**: Projects savings trajectories, calculates required monthly savings, and tracks smoke-free financial milestones.
- **`CurrencyFormatter`**: Formats amounts following Indian numbering standards (`₹1,00,000`, Lakhs `L`, and Crores `Cr`).

### 2. Domain Models (`Bachat/Models/`)
- **`Expense`**: Individual transaction itemizing category, amount, timestamp, note, and roommate split ratio.
- **`MonthlyIncome`**: Monthly salary ledger recording base salary, credited dates, and linked `IncomeEntry` items.
- **`BudgetConfig` & `CategoryBudget`**: Dynamic budget allocations and lean/comfortable spending modes.
- **`SavingsGoal`**: Long-term target tracker with target dates and required pace metrics.
- **`AccountBalance`**: Bank balance tracker monitoring minimum balances and required top-ups.

### 3. Data Flow & Sync
- **Local Persistence**: Rapid local updates powered by SwiftData for responsive, offline interactions.
- **Remote Synchronization**: Real-time cloud sync with Firebase Firestore for cross-device state convergence and roommate split reconciliation.
- **Document Export**: In-app PDF invoice generation via `UIGraphicsPDFRenderer` for transparent roommate expense settlements.
