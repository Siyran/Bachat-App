# Changelog

All notable changes to the Bachat project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-12

### Added
- **Core Expense Tracking**: Real-time logging of expenses categorized across groceries, food, transport, household, personal, exploring, and misc.
- **Shared Split & Settlement**:
  - Configurable split ratios with roommates/partners.
  - PDF settlement invoice generation (`PDFGenerator`) with itemized transactions and payment summary.
  - In-app email bill delivery with pre-filled statements and PDF attachment via `MFMailComposeViewController`.
  - Settlement clearance action to reconcile shared balance records.
- **Income & Budget Engine**:
  - Support for fixed base salary, provisional months, and dynamic bonus/side-income streams.
  - Automatic category budget rescaling based on percentage allocations.
  - Real-time spending limits, comfort thresholds, and overspend alerting.
- **Savings & Goal Projections**:
  - Target tracking with deadline countdowns and required monthly savings calculations.
  - Smoke-free streak tracker with accumulated financial savings milestones.
- **Architecture & Sync**:
  - Cloud synchronization via Firebase Firestore.
  - Local caching and persistence using SwiftData.
  - Offline-first architecture with automatic multi-device state convergence.
