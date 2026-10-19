# iOS Build and Deployment Guide

## Prerequisites
- macOS 14.0 or higher
- Xcode 15.4+
- Swift 5.9+
- Active Apple Developer Account (Personal Team or Paid Program)

## Development Build

### 1. Project Initialization
1. Clone the repository:
   ```bash
   git clone git@github.com:Siyran/Bachat-App.git
   cd Bachat-App
   ```
2. Open `Bachat.xcodeproj` in Xcode.
3. Allow Swift Package Manager to resolve dependencies (Firebase iOS SDK, GoogleUtilities, etc.).

### 2. Firebase Configuration
Ensure a valid `GoogleService-Info.plist` is bundled with target membership enabled for `Bachat`.

### 3. Physical Device Testing & 7-Day Free Profile Renewal
When using a **Free Personal Team**:
- Apple issues a provisioning certificate valid for **7 days**.
- If the app shows *"Bachat is No Longer Available"*, connect the device to Mac, open Xcode, and press **Run** (`Cmd + R`) to re-sign and refresh the 7-day certificate without data loss.

### 4. Running Tests
Run headless unit tests on `BachatCore`:
```bash
cd BachatCore
swift test
```
