# Vehicle Management App

A comprehensive iOS app for managing vehicle information, maintenance records, and ownership details.

## Features

- Track multiple vehicles with detailed information
- Record maintenance events and service history
- Manage ownership records and documentation
- Search and filter vehicle records
- Export vehicle data to PDF
- iCloud sync support
- Dark mode support
- VoiceOver accessibility

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 6.0

## Installation

1. Clone the repository
2. Open Vehicle.xcodeproj in Xcode
3. Select your development team in the project settings
4. Build and run the project

## Configuration

### iCloud Setup
1. Enable iCloud capability in your project settings
2. Configure the appropriate container identifiers
3. Test sync functionality with multiple devices

### Privacy Policy & Terms
Update the following URLs in SettingsView.swift:
- Privacy Policy: https://www.genericgroup.net/privacy
- Terms of Use: https://www.genericgroup.net/terms
- Contact: https://www.genericgroup.net/contact
- FAQ: https://genericgroup.net/faq#vehicle-pro

## Development

### Architecture
- SwiftUI for UI
- SwiftData for persistence
- CloudKit for sync
- MVVM architecture

### Key Components
- VehicleDetailView: Main vehicle information display
- EventRowView: Event history display
- OwnershipRecordView: Ownership record management
- ShareSheet: PDF generation and sharing

### Testing
Run the included test suites:
```bash
xcodebuild test -scheme Vehicle -destination 'platform=iOS Simulator,name=iPhone 15'
```

## License

Copyright © 2024 Generic Group. All rights reserved. 