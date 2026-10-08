# Bachat: Personal Finance & Budget Tracker 💸

**Bachat** (meaning *Savings*) is a robust, SwiftUI-powered personal finance application built to help you track expenses, pace your daily spending, achieve savings goals, and effortlessly settle up shared expenses with roommates or partners.

It is built with an **offline-first** architecture using **SwiftData**, securely backed by **Firebase Authentication** for true multi-user sandboxing.

---

## 🚀 Features (From A to Z)

### 1. Multi-User Sandboxing & Identity
- **Firebase Auth:** Login via email/password.
- **Data Isolation:** Every single budget, account balance, expense, and setting is tightly scoped to your logged-in email. If you log out and your roommate logs in on the exact same device, they will see an entirely blank, fresh setup specifically for them.
- **Cloud Ready:** Future-proofed to sync with Firestore, meaning your data stays with your account.

### 2. The "Safe to Spend" Daily Engine
- **Smooth Pacing Algorithm:** Instead of just giving you a flat monthly limit, Bachat calculates your *Daily Allowance* based on how many days are left in the month and what your remaining limit was *yesterday*.
- **Strict Daily Tracker:** When you log an expense *today*, it directly subtracts from your daily allowance in real-time. If you under-spend today, the remaining amount is gracefully smoothed over the rest of the month so you don't binge-spend the next day.

### 3. Expense Tracking & Shared Splits ("Settle Up")
- **Quick Logging:** Rapidly log expenses by category (Food, Transport, Rent, etc.).
- **Roommate Splitting:** When logging an expense, you can toggle "Share Expense". 
- **Automated Settle Up:** The dashboard automatically calculates who paid for what. If you spent ₹500 on Food and shared it, the dashboard tracks that your partner owes you ₹250. If they log an expense and share it, it offsets the balance dynamically, showing you exactly who owes who (Net Balance).

### 4. Dynamic Budgets & Income
- **Flexible Rules:** Set your monthly budget using a strict Fixed Limit (e.g. ₹15,000) or a Percentage of your income (e.g. Spend 60%, Save 40%).
- **Salary Tracking:** Log your monthly salary and track the exact date it was credited. The app keeps a historical record of all your past salaries.
- **Account Floor Protection:** Link your bank accounts (like HDFC) and set a minimum balance (e.g. ₹10,000). The dashboard immediately alerts you if your spending pushes you below your safety floor.

### 5. Target Savings Goals
- **Goal Tracking:** Set a specific custom target (e.g. ₹3,00,000) and a target date. 
- **Progress Snapshot:** Bachat calculates exactly how much you need to save *per month* to hit your goal on time, utilizing your surplus bank balances automatically.

### 6. Interactive Dashboard & Theming
- **Command Center:** The Dashboard contains interactive widgets for your Budget, Insights, Goals, and Recent Transactions.
- **Dynamic Theming:** A beautiful glassmorphic UI that seamlessly switches between Dark Mode and Light Mode via a dedicated toggle in the app's settings menu.

---

## 🛠️ Tech Stack & Architecture

- **UI Framework:** SwiftUI (iOS 17+)
- **Local Database:** SwiftData (Offline-first, reactive `@Query` updates)
- **Backend & Auth:** Firebase (FirebaseAuth, FirebaseFirestore)
- **Design Pattern:** MVVM (Model-View-ViewModel) + Pure Swift Engines (`BudgetEngine`, `GoalEngine`)

### Project Structure
- **/Models:** SwiftData schemas (`Expense`, `BudgetConfig`, `AccountBalance`, etc.) all containing `ownerEmail` for strict data scoping.
- **/Views:** SwiftUI views grouped by feature (`Dashboard`, `Expense`, `Income`, `Budget`).
- **/ViewModels:** Handling the reactive state and bridging the gap between SwiftData and the UI.
- **/Services:** Pure algorithmic logic like `BudgetEngine.swift` (handles the complex math for daily pacing and alerts) and `AuthManager.swift` (Firebase connection).

---

## ⚙️ Installation & Setup (For Personal Use)

1. **Clone the Repository:**
   ```bash
   git clone git@github.com:Siyran/Bachat-App.git
   cd Bachat-App
   ```

2. **Open in Xcode:**
   Double click the `Bachat.xcodeproj` file to open it in Xcode.

3. **Firebase Setup:**
   *Note: The app requires a valid `GoogleService-Info.plist`.* 
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Create a project (or use the existing one).
   - Enable **Authentication (Email/Password)**.
   - Download the `GoogleService-Info.plist` and drag it into the root of the Xcode project.

4. **Build & Run:**
   - Select your target simulator (e.g., iPhone 15 Pro) or your plugged-in physical device.
   - Hit `Cmd + R` to build and run.

---

## 💡 Pro-Tips for Daily Use

1. **Keep it Accurate:** Log your expenses immediately at the point of sale so your *Safe to Spend Today* widget stays perfectly accurate.
2. **Name your Partner:** Head to the Settings page and enter your roommate's/partner's Display Name. The dashboard will instantly update all "Settle Up" cards to use their real name.
3. **Change Passwords Easily:** Use the "More" tab to send a secure Firebase password reset directly to your inbox.

---
*Built with precision for flawless personal finance management.*