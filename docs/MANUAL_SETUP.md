# Manual Setup

## Xcode

Install Xcode.app and select it before running app builds:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -version
xcrun simctl list devices available
```

## Identifiers To Replace

The source currently contains upstream identifiers:

- App Group: `group.com.tsubuzaki.WorkingHour`
- iCloud container: `iCloud.com.tsubuzaki.WorkingHour`
- App bundle id: `com.tsubuzaki.WorkingHour`

For your own signing setup, create and use placeholders consistently:

- App Group: `group.com.YOUR_DOMAIN.WorkdayCountdown`
- iCloud container: `iCloud.com.YOUR_DOMAIN.WorkdayCountdown`

Do not commit provisioning profiles, certificates, private keys, or secrets.

## iPhone App Target

Target: `Working Hour`

Required capabilities:
- Signing team selected by the owner.
- iCloud > CloudKit enabled with the chosen iCloud container.
- App Groups enabled with the chosen App Group.
- Push/notifications as needed for local notification testing.

## iPhone Widget Target

Target: `Ushio`

Required capabilities:
- App Groups enabled with the same local App Group used by the iPhone app.

Widgets read local App Group snapshots. They should not rely on live CloudKit/network queries.

## Future macOS Targets

Native macOS app and desktop widget should use:
- Same CloudKit container for durable sync.
- Mac-local App Group for app-to-widget snapshots.
- `Shared/Attendance/AttendanceDashboardView(displayStyle: .regular)` as the app root content.
- `Shared/Attendance/AttendanceStore` for persistence and snapshot writes.

## Future watchOS Targets

Watch app and complications should use:
- AttendanceKit shared rules.
- Local durable store where supported.
- WatchConnectivity for fast iPhone/watch sync.
- App Group snapshot for watch complication rendering where applicable.
- `Shared/Attendance/AttendanceDashboardView(displayStyle: .compact)` for the watch app root content.

## Simulator vs Device

Simulator can validate:
- Core business tests.
- Basic iOS app UI.
- Some widget rendering.

Device is required for final validation of:
- Real iCloud/CloudKit sync.
- Apple Watch app and complications.
- WatchConnectivity behavior.
- Notification permission and delivery behavior.
