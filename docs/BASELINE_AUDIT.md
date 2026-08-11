# Baseline Audit

Date: 2026-07-06
Xcode follow-up verification: 2026-07-08
Branch at audit start: not a git repository. A baseline repository was initialized locally and the original import was committed before creating `feat/cross-platform-attendance`.

## Commands Run

- `git status --short`: failed before initialization with `fatal: not a git repository`.
- `git branch --show-current`: failed before initialization with `fatal: not a git repository`.
- `find -s . -maxdepth 4 -type f`: succeeded; key files are listed below.
- `find -s . -maxdepth 3 -name '*.xcodeproj' -o -name '*.xcworkspace'`: found `WorkingHour.xcodeproj` and `WorkingHour.xcodeproj/project.xcworkspace`.
- `xcodebuild -list -project WorkingHour.xcodeproj`: blocked because `xcode-select` points at `/Library/Developer/CommandLineTools`.
- `xcrun simctl list devices available`: blocked because `simctl` is not available from the current developer directory.
- `xcode-select -p`: passed after Xcode install; active developer directory is `/Applications/Xcode.app/Contents/Developer`.
- `xcodebuild -version`: passed with Xcode 26.6, build 17F113.
- `xcodebuild -showsdks`: passed and listed iOS, iOS Simulator, macOS, tvOS, visionOS, and watchOS 26.5 SDKs.
- `xcodebuild -list -project WorkingHour.xcodeproj`: passed after Xcode install; project targets and schemes resolve, including the local `AttendanceKit` package.
- `xcrun simctl list runtimes`: passed after Xcode install but returned no installed runtimes.
- `xcrun simctl list devices available`: passed after Xcode install but returned no available devices.
- `xcodebuild -downloadPlatform iOS`: attempted after Xcode install; download started from 0%, reached about 9.7% / 830 MB of 8.52 GB, then was cancelled because throughput had dropped to less than 1 MB per 30 seconds.
- `xcrun simctl list runtimes`: passed after manual Xcode Components install and listed iOS 26.5 plus watchOS 26.5.
- `xcrun simctl list devices available`: passed after manual Xcode Components install and listed iOS 26.5 plus watchOS 26.5 devices.
- `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath /private/tmp/WorkingHourDerivedData CODE_SIGNING_ALLOWED=NO build`: passed.
- `xcodebuild -project WorkingHour.xcodeproj -scheme "Ushio" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath /private/tmp/WorkingHourDerivedDataUshio CODE_SIGNING_ALLOWED=NO build`: passed.
- `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphoneos -destination "generic/platform=iOS" -derivedDataPath /private/tmp/WorkingHourDerivedDataDevice CODE_SIGNING_ALLOWED=NO build`: passed.
- `xcrun simctl install F6040390-A952-4322-B4EE-EC3FD2E3387A "/private/tmp/WorkingHourDerivedData/Build/Products/Debug-iphonesimulator/Working Hour.app"`: passed.
- `xcrun simctl launch F6040390-A952-4322-B4EE-EC3FD2E3387A com.tsubuzaki.WorkingHour`: passed and returned pid 48599.

## Current File Tree Summary

- `WorkingHour.xcodeproj/`: Xcode project with file-system synchronized groups.
- `WorkingHour/`: iOS app source, localized strings, app icon, entitlements.
- `Shared/`: shared SwiftData models, managers, intents, logging, live activity/session structs.
- `Ushio/`: WidgetKit extension, Live Activity widgets, Control widgets.
- `Assets/`: App Store screenshots and design assets.
- `github/Privacy Policy.pdf`: privacy document.

## Project, Schemes, Targets

- Project: `WorkingHour.xcodeproj`
- Workspace: `WorkingHour.xcodeproj/project.xcworkspace`
- Shared schemes on disk: `Working Hour`, `Ushio`
- Native targets found in `project.pbxproj`:
  - `Working Hour`: iOS application, bundle id `com.tsubuzaki.WorkingHour`, iOS deployment target `18.0`.
  - `Ushio`: Widget extension, bundle id `com.tsubuzaki.WorkingHour.Ushio`, iOS deployment target `26.0`.
- Existing signing/team values are present in the project and are preserved.

## Current Persistence

The app already uses SwiftData rather than UserDefaults as the main durable store. `SharedModelContainer` builds a SwiftData schema for `ClockEntry`, `Break`, `Project`, `ProjectTask`, `Workplace`, and `BreakWindow`, configured with App Group `group.com.tsubuzaki.WorkingHour`.

`SharedModelContainer` no longer calls `fatalError` for persistent-store failures. It checks that the App Group container is available before constructing the App Group SwiftData configuration, then falls back to a local store and finally an in-memory store. The last-resort in-memory creation still uses `preconditionFailure` because the app cannot operate without any model container.

## Current Core Models

- `ClockEntry`: clock-in/out, breaks, tasks, active break flag.
- `Break`: start/end break interval.
- `Project`, `ProjectTask`: project/task tracking for timesheets.
- `Workplace`, `BreakWindow`: geofencing and break-window support.

These are legacy timesheet concepts for the new product direction and will not be renamed into attendance concepts.

## Current Navigation

`MainTabView` currently exposes four tabs:

- Time Clock
- History
- Projects
- More

The new primary shell will replace this with Today / Month / History / Settings, while keeping old timesheet/project code available as legacy until the new flow is stable.

## Current Widget Behavior

`UshioHomeWidget` supports `.systemSmall` and `.systemMedium`. Its provider queries SwiftData directly from the widget extension and refreshes every 15 minutes while active or every hour when idle. The refactor will switch widget rendering to App Group snapshots and meaningful timeline boundaries.

## Baseline Build

The first baseline build could not run because the active developer directory was `/Library/Developer/CommandLineTools`.

After Xcode 26.6 was installed and selected, package resolution and unit tests could run:

- `xcodebuild -list -project WorkingHour.xcodeproj`: passed.
- `swift test --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-xcode-test`: passed with 30 XCTest cases.

Before manual Xcode Components install, iOS app compilation could not start because Xcode reported the iOS 26.5 platform/runtime as unavailable:

- `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath /private/tmp/WorkingHourDerivedData CODE_SIGNING_ALLOWED=NO build`: blocked before compilation with `iOS 26.5 is not installed. Please download and install the platform from Xcode > Settings > Components.`
- `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphoneos -destination "generic/platform=iOS" -derivedDataPath /private/tmp/WorkingHourDerivedDataDevice CODE_SIGNING_ALLOWED=NO build`: blocked by the same destination/platform error.

The CLI platform download was also attempted, but it stalled at about 9.7% / 830 MB of 8.52 GB and was cancelled. Using Xcode Settings > Components remains the recommended path for this machine.

After manual Xcode Components install, baseline iOS compilation passed:

- `Working Hour` iOS Simulator Debug build passed.
- `Ushio` iOS Simulator Debug build passed.
- `Working Hour` iPhoneOS generic Debug build passed with signing disabled.
- `Working Hour.app` installed on the iPhone 17 Pro simulator. The first unsigned launch returned a PID but then exited because SwiftData reached a fatal App Group entitlement path.

After adding an App Group availability preflight on 2026-08-11, the same unsigned simulator scenario passed runtime verification: the app rendered its Today screen, retained the same PID across a second launch query, and logged a non-fatal local-store fallback instead of the previous SwiftData fatal error.

## Upstream Feature Handling

- Keep initially: existing SwiftData models, live activity code, notification manager, widget target, localization files.
- Migrate/replace: main app navigation, clock-in/out UI, month summary logic, widget timeline source.
- Hide from primary UX: project/task timesheet features, break tracking, geofencing, export.
- Do not auto-delete: old models or persisted data.

## Main Refactor Risks

- Existing deployment targets are higher than the requested minimums; lowering requires Xcode verification.
- Current App Group/iCloud identifiers use the upstream author namespace and must be replaced manually by the project owner.
- Native macOS/watchOS target creation remains future work; iOS app/widget build verification is now available on this machine.
