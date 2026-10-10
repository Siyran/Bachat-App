# Bachat: Personal Finance & Budget Tracker

Bachat (meaning "Savings") is a robust, SwiftUI-powered personal finance application built to help users track expenses, pace daily spending, achieve savings goals, and effortlessly settle shared expenses with roommates or partners.

It is built with an offline-first architecture using SwiftData, securely backed by Firebase Authentication for true multi-user sandboxing.

---

## Features

### 1. Multi-User Sandboxing & Identity
- **Firebase Auth:** Login via email and password authentication.
- **Data Isolation:** Every budget, account balance, expense, and setting is tightly scoped to the authenticated user's email. If the active session is logged out and a different user authenticates on the same device, they will be presented with an entirely isolated and fresh workspace.
- **Cloud Ready:** Future-proofed to sync with Firestore, ensuring user data persists securely across devices.

### 2. The "Safe to Spend" Daily Engine
- **Smooth Pacing Algorithm:** Instead of providing a static monthly limit, Bachat calculates a dynamic Daily Allowance based on the remaining days in the month and the unspent limit from the previous day.
- **Strict Daily Tracker:** Logging an expense immediately deducts from the daily allowance in real-time. Underspending gracefully distributes the surplus across the remainder of the month, preventing binge-spending habits.

### 3. Expense Tracking & Shared Splits ("Settle Up")
- **Quick Logging:** Rapidly categorize and log expenses (e.g., Food, Transport, Rent).
- **Expense Splitting:** When logging an expense, users can toggle "Share Expense" to split costs with a partner.
- **Automated Settlement:** The dashboard automatically calculates liabilities and credits. For example, if a user spends ₹500 on shared food, the dashboard tracks that their partner owes ₹250. Mutual shared expenses offset dynamically to display a precise Net Balance.
- **Invoice Generation & Email Settlement:** Users can generate itemized PDF invoices for the month's shared expenses and email them directly to their partner with a single tap.

### 4. Dynamic Budgets & Income
- **Flexible Rules:** Configure monthly budgets using a strict Fixed Limit (e.g., ₹15,000) or a Percentage of income (e.g., Spend 60%, Save 40%).
- **Salary Tracking:** Log monthly income and track exact credit dates. The application maintains a comprehensive historical ledger of past salaries.
- **Account Floor Protection:** Link bank accounts and establish minimum balance thresholds (e.g., ₹10,000). The dashboard proactively alerts users if spending pushes balances below the safety floor.

### 5. Target Savings Goals
- **Goal Tracking:** Define specific financial targets (e.g., ₹3,00,000) alongside target completion dates.
- **Progress Snapshot:** Bachat calculates the exact required monthly savings rate to achieve the goal on schedule, factoring in surplus bank balances automatically.

### 6. Interactive Dashboard & Theming
- **Command Center:** The primary Dashboard features interactive widgets for Budgets, Insights, Goals, and Recent Transactions.
- **Dynamic Theming:** A modern, glassmorphic user interface that seamlessly transitions between Dark Mode and Light Mode via a dedicated toggle in the application settings.

---

## Tech Stack & Architecture

- **UI Framework:** SwiftUI (iOS 17+)
- **Local Database:** SwiftData (Offline-first, reactive `@Query` updates)
- **Backend & Auth:** Firebase (FirebaseAuth, FirebaseFirestore)
- **Design Pattern:** MVVM (Model-View-ViewModel) paired with pure Swift utility engines (e.g., `BudgetEngine`, `GoalEngine`)

### Project Structure
- **/Models:** SwiftData schemas (`Expense`, `BudgetConfig`, `AccountBalance`, etc.), uniformly containing `ownerEmail` properties for strict data scoping.
- **/Views:** SwiftUI views categorically grouped by feature (`Dashboard`, `Expense`, `Income`, `Budget`).
- **/ViewModels:** State managers that bridge the gap between SwiftData models and the reactive UI.
- **/Services:** Algorithmic business logic, such as `BudgetEngine.swift` for daily pacing mathematics, and `FirestoreService.swift` for backend connectivity.

---

## Installation & Setup

1. **Clone the Repository:**
   ```bash
   git clone git@github.com:Siyran/Bachat-App.git
   cd Bachat-App
   ```

2. **Open in Xcode:**
   Open the `Bachat.xcodeproj` file in Xcode.

3. **Firebase Setup:**
   *Note: The application requires a valid `GoogleService-Info.plist` file to compile and authenticate.* 
   - Navigate to the [Firebase Console](https://console.firebase.google.com/)
   - Create a project or utilize an existing one.
   - Enable **Authentication (Email/Password)**.
   - Download the `GoogleService-Info.plist` and place it in the root directory of the Xcode project.

4. **Build & Run:**
   - Select the target simulator (e.g., iPhone 15 Pro) or a connected physical device.
   - Press `Cmd + R` to build and execute.

---

## Usage Guidelines

1. **Maintain Accuracy:** Log expenses immediately at the point of sale to ensure the *Safe to Spend Today* metric remains perfectly calibrated.
2. **Configure Partner Details:** Navigate to the Settings view to enter the display name and email of your partner. The dashboard and PDF invoice generator will automatically adopt these credentials for accurate settlements.
3. **Settle Up Monthly:** Use the "Mark as Settled" action to securely clear settled shared expenses from the ledger once a payment is finalized.

---
*Built with precision for flawless personal finance management.*
