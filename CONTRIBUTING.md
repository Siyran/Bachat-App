# Contributing to Bachat

Thank you for your interest in contributing to Bachat.

## Development Setup

1. **Prerequisites**
   - macOS 14.0 or higher
   - Xcode 15.0 or later
   - Swift 5.9+
   - CocoaPods or Swift Package Manager (dependencies managed through SPM)

2. **Project Setup**
   - Clone the repository:
     ```bash
     git clone git@github.com:Siyran/Bachat-App.git
     ```
   - Open `Bachat.xcodeproj` in Xcode.
   - Ensure the Firebase SDK dependencies resolve completely via Swift Package Manager.
   - Supply a valid `GoogleService-Info.plist` in the `Bachat/` directory for local development and Firestore connectivity.

## Coding Guidelines

- Follow standard Swift style guidelines and idiomatic Swift naming conventions.
- Maintain consistent indentation (4 spaces) as configured in `.editorconfig`.
- Avoid direct force-unwrapping (`!`) where optional binding (`guard let` or `if let`) can be used safely.
- Keep UI components modular within `Bachat/Views/`.
- Isolate business logic and state synchronization inside `Bachat/ViewModels/`.

## Submitting Pull Requests

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Commit your changes with clear, descriptive commit messages adhering to conventional commits (e.g., `feat:`, `fix:`, `docs:`, `refactor:`).
3. Verify that the project builds cleanly without errors or warnings.
4. Push your branch and open a Pull Request against `main`.
