# Manual Setup

## Xcode

Install Xcode.app, select it, and install the required platform runtimes before running app builds:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -version
xcrun simctl list devices available
```

Current verification status on 2026-07-08:

- Xcode 26.6 is installed and selected at `/Applications/Xcode.app/Contents/Developer`.
- iOS 26.5 and watchOS 26.5 runtimes are installed and visible to `simctl`.
- `xcodebuild -list -project WorkingHour.xcodeproj` passes.
- `swift test --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-cantonese-lyrics-final` passes with 38 XCTest cases.
- `Working Hour` iOS Simulator Debug build passes.
- `Ushio` iOS Simulator Debug build passes.
- `Working Hour` generic iOS device Debug build passes with signing disabled.
- `Working Hour.app` installs and launches on the iPhone 17 Pro simulator.
- Unsigned simulator builds cannot access the App Group. `SharedModelContainer` detects this before constructing the App Group SwiftData configuration and falls back without crashing. Signing with the configured App Group is still required to validate shared app/widget persistence.
- `xcodebuild -downloadPlatform iOS` was attempted, but the 8.52 GB simulator download stalled at about 9.7% / 830 MB and was cancelled.

Useful verification commands:

```sh
xcrun simctl list runtimes
xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath /private/tmp/WorkingHourDerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project WorkingHour.xcodeproj -scheme "Ushio" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath /private/tmp/WorkingHourDerivedDataUshio CODE_SIGNING_ALLOWED=NO build
xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphoneos -destination "generic/platform=iOS" -derivedDataPath /private/tmp/WorkingHourDerivedDataDevice CODE_SIGNING_ALLOWED=NO build
xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour Mac" -configuration Debug -destination "platform=macOS" -derivedDataPath /private/tmp/WorkingHourMacDerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour Watch" -configuration Debug -sdk watchsimulator -destination "generic/platform=watchOS Simulator" -derivedDataPath /private/tmp/WorkingHourWatchDerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour Watch" -configuration Debug -sdk watchos -destination "generic/platform=watchOS" -derivedDataPath /private/tmp/WorkingHourWatchDeviceDerivedData CODE_SIGNING_ALLOWED=NO build
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

## macOS App Target

Target: `Working Hour Mac`

Current status:
- Builds with Xcode 26.6 for macOS 14.0 or newer.
- Launches and renders the shared attendance dashboard on macOS 26.5.2.
- Uses local SwiftData and shows a non-blocking warning until App Group/CloudKit are configured.

To enable durable cross-device sync, add the owner-controlled App Group and iCloud/CloudKit capabilities to this target, then set these generated Info.plist build settings to `YES`:

- `INFOPLIST_KEY_AttendanceAppGroupEnabled`
- `INFOPLIST_KEY_AttendanceCloudKitEnabled`

The native macOS app and desktop widget use:
- Same CloudKit container for durable sync.
- Mac-local App Group for app-to-widget snapshots.
- `Shared/Attendance/AttendanceDashboardView(displayStyle: .regular)` as the app root content.
- `Shared/Attendance/AttendanceStore` for persistence and snapshot writes.

## macOS Widget Target

Target: `Working Hour Mac Widget`

Current status:
- Builds and embeds in `Working Hour Mac` for macOS 14.0 or newer.
- Supports system small and system medium desktop widgets.
- Reads `AttendanceWidgetSnapshot` and never queries SwiftData or CloudKit during timeline generation.

To share live snapshots, add the same Mac-local App Group capability used by the host app, then set `AttendanceAppGroupEnabled` to `true` in `WorkingHourMacWidget/Info.plist`. Desktop placement and rendering remain a manual Widget Gallery check.

## watchOS App and Widget Targets

Targets: `Working Hour Watch` and `Working Hour Watch Widget`

Current status:
- Both targets build for watchOS Simulator and generic watchOS with Xcode 26.6.
- The Watch app installs and runs on a paired Apple Watch Series 11 simulator.
- The Watch app uses `AttendanceDashboardView(displayStyle: .compact)` and local SwiftData fallback.
- The iPhone and Watch apps include `WatchConnectivityCoordinator`: immediate messages use `sendMessage`, unreachable commands use `transferUserInfo`, and the latest iPhone snapshot uses `applicationContext`.
- The complication extension is embedded and supports accessory inline, circular, and rectangular families.

To share snapshots between the Watch app and complication, add the same Watch-local App Group capability to both targets, then set `AttendanceAppGroupEnabled` to `true` in the widget Info.plist and enable the corresponding app target build setting. Durable CloudKit synchronization still requires owner-controlled capabilities. WatchConnectivity source and simulator builds are complete, but immediate/background delivery must be verified on a paired physical iPhone and Apple Watch.

## Simulator vs Device

Simulator can validate:
- Core business tests.
- Basic iOS app UI.
- Some widget rendering.

Device is required for final validation of:
- Real iCloud/CloudKit sync.
- Final complication placement and rendering on a physical Apple Watch.
- Final macOS desktop Widget Gallery placement and rendering.
- WatchConnectivity behavior.
- Notification permission and delivery behavior.
