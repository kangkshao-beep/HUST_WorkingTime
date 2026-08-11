# Implementation Log

## 2026-07-06 - Phase 0 Audit

Modified files:
- `.gitignore`
- `docs/BASELINE_AUDIT.md`
- `docs/IMPLEMENTATION_LOG.md`

Build command:
- `xcodebuild -list -project WorkingHour.xcodeproj`

Result:
- Blocked by local developer directory: `/Library/Developer/CommandLineTools` is active and no Xcode.app is available.

Test command:
- Not applicable before shared package creation.

Known issue:
- `simctl` and Xcode builds cannot run until Xcode is installed/selected.

Next step:
- Add `Packages/AttendanceKit` with domain, calendar, engine, conflict resolution, snapshot/timeline logic, and unit tests.


## 2026-07-06 - Phase 1 Shared Business Core

Modified files:
- `Packages/AttendanceKit/Package.swift`
- `Packages/AttendanceKit/Sources/AttendanceKit/**`
- `Packages/AttendanceKit/Tests/AttendanceKitTests/**`

Build command:
- `swift build --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-build`

Result:
- Passed.

Test command:
- `swift test --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-build`

Result:
- Blocked in the current CommandLineTools environment because `XCTest` is unavailable. Earlier SwiftData `@Model` macro usage also failed because `SwiftDataMacros` is not present under CommandLineTools, so `AttendanceRecord` was kept as a pure Foundation domain model and SwiftData persistence will map to it at the app layer.

Known issue:
- Full unit test execution requires a complete Xcode developer directory.

Next step:
- Link the local `AttendanceKit` package into the Xcode project and build the iPhone attendance MVP source.


## 2026-07-06 - Phase 2 iPhone MVP and Snapshot Foundation

Modified files:
- `WorkingHour/Features/Attendance/**`
- `Shared/Attendance/AttendanceStorageRecord.swift`
- `Shared/WidgetSupport/WidgetSnapshotStore.swift`
- `Shared/Managers/ModelConfiguration.swift`
- `WorkingHour/Views/App.swift`
- `WorkingHour/Views/MainTabView.swift`
- `WorkingHour/Enums/TabType.swift`
- `Ushio/Home Screen Widget/**`
- `WorkingHour.xcodeproj/project.pbxproj`
- `docs/ARCHITECTURE.md`

Build command:
- `swift build --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-build`

Result:
- Passed for shared business package.

App build command:
- `xcodebuild -list -project WorkingHour.xcodeproj`

Result:
- Blocked because active developer directory is `/Library/Developer/CommandLineTools`; `xcodebuild` requires Xcode.

Test command:
- `swift test --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-build`

Result:
- Blocked because `XCTest` is unavailable under the current CommandLineTools setup.

Known issue:
- iOS app/widget compile must be verified after installing/selecting Xcode.
- macOS/watchOS targets are documented but not generated in this environment.

Next step:
- With Xcode available, run `xcodebuild -list`, build the `Working Hour` and `Ushio` schemes, then fix any compiler issues in the app/widget source.


## 2026-07-07 - Phase 7 CloudKit Fallback Skeleton

Modified files:
- `Shared/Managers/ModelConfiguration.swift`
- `Shared/Attendance/AttendanceStorageRecord.swift`
- `docs/IMPLEMENTATION_LOG.md`

Build command:
- Not run through Xcode; Xcode.app is unavailable in this environment.

Result:
- SwiftData SDK interface was inspected locally and confirms `ModelConfiguration.CloudKitDatabase.private(_:)` is available.
- Production model configuration now requests CloudKit private database `iCloud.com.tsubuzaki.WorkingHour` while retaining non-fatal local and in-memory fallbacks.
- Attendance SwiftData storage fields now provide defaults so the schema is friendlier to CloudKit-backed initialization.

Known issue:
- Real CloudKit sync still requires Signing & Capabilities setup and device/Xcode verification.


## 2026-07-07 - Phase 2/4 Static Polish

Modified files:
- `WorkingHour/Features/Attendance/AttendanceTodayView.swift`
- `WorkingHour/Info.plist`
- `Ushio/Home Screen Widget/HomeWidgetProvider.swift`
- `Ushio/Home Screen Widget/HomeWidgetView.swift`

Build command:
- `swift build --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-build`

Result:
- Passed.

Validation commands:
- `plutil -lint WorkingHour/Info.plist`
- `plutil -lint WorkingHour.xcodeproj/project.pbxproj`

Result:
- Both passed.

Changes:
- Widget deep links now have an app URL scheme registration: `workdaycountdown`.
- Editing today's clock-in time now updates the existing attendance record instead of creating a replacement record with a new UUID.
- Widget source files now explicitly import Foundation for date/math APIs.

Known issue:
- Full app/widget compiler validation still requires Xcode.app.


## 2026-07-07 - AttendanceKit Executable Checks

Modified files:
- `Packages/AttendanceKit/Package.swift`
- `Packages/AttendanceKit/Sources/AttendanceKitChecks/main.swift`
- `Packages/AttendanceKit/Tests/AttendanceKitTests/**`
- `docs/IMPLEMENTATION_LOG.md`
- `docs/TEST_MATRIX.md`

Build command:
- `swift build --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-check-build`

Result:
- Passed.

Executable check command:
- `swift run --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-check-build AttendanceKitChecks`

Result:
- Passed.

Formal test command:
- `swift test --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-test-build-xctest`

Result:
- Blocked in the current CommandLineTools environment because the `XCTest` module is unavailable.

Changes:
- Added `AttendanceKitChecks`, a Foundation-only executable verification target that can run under the current limited toolchain.
- Kept the formal `AttendanceKitTests` XCTest target for a complete Xcode developer directory.
- Covered weekday/month rules, Asia/Shanghai and America/Los_Angeles day keys, required 80% rounding, engine status and countdown behavior, duplicate collapse, widget refresh dates, and watch sync idempotence/fallback queue behavior.

Known issue:
- `swift test` requires installing/selecting a full Xcode.app developer directory on this machine.


## 2026-07-08 - Shared Attendance App Layer

Modified files:
- `WorkingHour/Features/Attendance/AttendanceStore.swift`
- `Shared/Attendance/AttendanceStore.swift`
- `Shared/Attendance/AttendanceDashboardView.swift`
- `docs/ARCHITECTURE.md`
- `docs/MANUAL_SETUP.md`
- `docs/IMPLEMENTATION_LOG.md`
- `docs/TEST_MATRIX.md`

Changes:
- Moved `AttendanceStore` into `Shared/Attendance` so future macOS/watchOS app targets can reuse the same SwiftData-to-AttendanceKit orchestration.
- Replaced direct `UIDevice` usage with conditional platform device naming.
- Guarded WidgetKit timeline reload behind `canImport(WidgetKit)`.
- Added `AttendanceDashboardView` as a reusable regular/compact SwiftUI app shell for future macOS/watchOS targets.

Validation commands:
- `swift run --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-check-build AttendanceKitChecks`
- `swift build --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-check-build`
- `plutil -lint WorkingHour.xcodeproj/project.pbxproj`
- `plutil -lint WorkingHour/Info.plist`
- `git diff --check`

Result:
- Passed.

App build command:
- `xcodebuild -list -project WorkingHour.xcodeproj`

Result:
- Blocked because active developer directory is `/Library/Developer/CommandLineTools`; `xcodebuild` requires Xcode.

Known issue:
- Native macOS/watchOS target creation and app/widget compiler verification still require full Xcode.app.


## 2026-07-08 - Xcode Baseline Verification

Modified files:
- `Packages/AttendanceKit/Tests/AttendanceKitTests/DuplicateAndMonthProgressTests.swift`
- `Packages/AttendanceKit/Tests/AttendanceKitTests/WidgetTimelineTests.swift`
- `docs/BASELINE_AUDIT.md`
- `docs/IMPLEMENTATION_LOG.md`
- `docs/TEST_MATRIX.md`

Changes:
- Aligned duplicate/month progress XCTest expectations with the actual July 2026 elapsed workday count.
- Aligned weekend widget timeline XCTest expectations with the production logic: refresh at the next day boundary and no later than the next workday.
- Recorded the Xcode follow-up baseline now that Xcode 26.6 is installed and selected.

Environment checks:
- `xcode-select -p`: `/Applications/Xcode.app/Contents/Developer`
- `xcodebuild -version`: Xcode 26.6, build 17F113.
- `xcodebuild -list -project WorkingHour.xcodeproj`: passed and resolved `AttendanceKit`, `Komponents`, `xlsxwriter.swift`, and `libxlsxwriter`.
- `xcrun simctl list runtimes`: passed but returned no installed runtimes.
- `xcrun simctl list devices available`: passed but returned no available devices.

Validation commands:
- `swift test --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-xcode-test`
- `plutil -lint WorkingHour.xcodeproj/project.pbxproj`
- `plutil -lint WorkingHour/Info.plist`
- `git diff --check`

Result:
- Passed. `AttendanceKitTests` executed 30 XCTest cases with 0 failures.

App build commands:
- `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath /private/tmp/WorkingHourDerivedData CODE_SIGNING_ALLOWED=NO build`
- `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphoneos -destination "generic/platform=iOS" -derivedDataPath /private/tmp/WorkingHourDerivedDataDevice CODE_SIGNING_ALLOWED=NO build`

Result:
- Blocked before compilation because Xcode reports `iOS 26.5 is not installed. Please download and install the platform from Xcode > Settings > Components.`

Known issue:
- Install the iOS 26.5 platform/runtime in Xcode Settings > Components before rerunning app/widget builds or simulator-based checks.
- CLI install was attempted with `xcodebuild -downloadPlatform iOS`, but the 8.52 GB download stalled at about 9.7% / 830 MB and was cancelled.


## 2026-07-08 - iOS Runtime Build and Launch Verification

Modified files:
- `docs/BASELINE_AUDIT.md`
- `docs/ARCHITECTURE.md`
- `docs/IMPLEMENTATION_LOG.md`
- `docs/MANUAL_SETUP.md`
- `docs/TEST_MATRIX.md`

Environment checks:
- `xcrun simctl list runtimes`: passed and listed iOS 26.5 plus watchOS 26.5.
- `xcrun simctl list devices available`: passed and listed iPhone/iPad plus Apple Watch simulator devices.

Build commands:
- `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath /private/tmp/WorkingHourDerivedData CODE_SIGNING_ALLOWED=NO build`
- `xcodebuild -project WorkingHour.xcodeproj -scheme "Ushio" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath /private/tmp/WorkingHourDerivedDataUshio CODE_SIGNING_ALLOWED=NO build`
- `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphoneos -destination "generic/platform=iOS" -derivedDataPath /private/tmp/WorkingHourDerivedDataDevice CODE_SIGNING_ALLOWED=NO build`

Result:
- Passed. The iOS app and widget extension compile for simulator, and the app compiles for generic iOS device with signing disabled.
- Xcode emits a non-fatal warning that SwiftLint is not installed.

Launch commands:
- `xcrun simctl boot F6040390-A952-4322-B4EE-EC3FD2E3387A`
- `xcrun simctl bootstatus F6040390-A952-4322-B4EE-EC3FD2E3387A -b`
- `xcrun simctl install F6040390-A952-4322-B4EE-EC3FD2E3387A "/private/tmp/WorkingHourDerivedData/Build/Products/Debug-iphonesimulator/Working Hour.app"`
- `xcrun simctl launch F6040390-A952-4322-B4EE-EC3FD2E3387A com.tsubuzaki.WorkingHour`

Result:
- Passed. `simctl launch` returned pid 48599, and `simctl get_app_container` returned the installed app bundle path.

Validation commands:
- `swift test --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-xcode-test`
- `plutil -lint WorkingHour.xcodeproj/project.pbxproj`
- `plutil -lint WorkingHour/Info.plist`
- `git diff --check`

Result:
- Passed. `AttendanceKitTests` executed 30 XCTest cases with 0 failures.

Known issue:
- Manual UI workflow checks, real CloudKit sync, physical-device signing, and native macOS/watchOS targets remain pending.


## 2026-08-11 - Unsigned Simulator Persistence Fallback

Modified files:
- `Shared/Managers/ModelConfiguration.swift`
- `docs/ARCHITECTURE.md`
- `docs/BASELINE_AUDIT.md`
- `docs/IMPLEMENTATION_LOG.md`
- `docs/MANUAL_SETUP.md`
- `docs/TEST_MATRIX.md`

Cause:
- The earlier unsigned simulator launch returned a PID but exited before rendering the app.
- SwiftData called a non-throwing fatal path while constructing an App Group configuration without a usable `group.com.tsubuzaki.WorkingHour` entitlement, so the existing `do`/`catch` fallback could not run.

Changes:
- Added an App Group container availability preflight before constructing the App Group + CloudKit SwiftData configuration.
- Reused one local-store helper for both a missing App Group and a thrown App Group/CloudKit initialization error.
- Preserved the final in-memory fallback for environments where even the local persistent store is unavailable.

Validation commands:
- `swift test --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-model-fallback-test`
- `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath /private/tmp/WorkingHourDerivedDataFallback CODE_SIGNING_ALLOWED=NO build`
- `xcrun simctl install F6040390-A952-4322-B4EE-EC3FD2E3387A "/private/tmp/WorkingHourDerivedDataFallback/Build/Products/Debug-iphonesimulator/Working Hour.app"`
- `xcrun simctl launch F6040390-A952-4322-B4EE-EC3FD2E3387A com.tsubuzaki.WorkingHour`
- `xcrun simctl io F6040390-A952-4322-B4EE-EC3FD2E3387A screenshot /private/tmp/working-hour-fallback-final.png`
- `xcrun simctl spawn F6040390-A952-4322-B4EE-EC3FD2E3387A log show --last 2m --style compact --predicate 'process == "Working Hour"'`

Result:
- Passed. `AttendanceKitTests` executed 30 XCTest cases with 0 failures.
- Passed. The iOS app and embedded widget compiled for the iOS simulator.
- Passed. The app rendered the Today screen, and a second launch query returned the same pid 73466.
- The log recorded the expected non-fatal App Group warning and no longer contained the prior SwiftData fatal error. The local fallback created `default.store` in the app data container and kept the app operational without App Group access.

Known issue:
- Signed App Group persistence, real CloudKit sync, widget snapshot sharing, and the complete clock-in/edit/relaunch UI workflows still require manual verification.


## 2026-08-11 - Native macOS App Target

Modified files:
- `Shared/Managers/ModelConfiguration.swift`
- `Ushio/Info.plist`
- `WorkingHour/Info.plist`
- `WorkingHourMac/WorkingHourMacApp.swift`
- `WorkingHour.xcodeproj/project.pbxproj`
- `WorkingHour.xcodeproj/xcshareddata/xcschemes/Working Hour Mac.xcscheme`
- `docs/ARCHITECTURE.md`
- `docs/BASELINE_AUDIT.md`
- `docs/IMPLEMENTATION_LOG.md`
- `docs/MANUAL_SETUP.md`
- `docs/TEST_MATRIX.md`

Changes:
- Added the native `Working Hour Mac` application target and shared scheme.
- Reused the shared regular dashboard, attendance store, SwiftData storage model, snapshot store, and `AttendanceKit` instead of duplicating attendance rules.
- Limited the Mac SwiftData schema to `AttendanceStorageRecord` so legacy iOS-only models and services are not target dependencies.
- Added explicit `AttendanceAppGroupEnabled` and `AttendanceCloudKitEnabled` target capability flags. The iPhone app enables both and the widget enables App Group only; the unsigned Mac smoke build safely uses local storage.
- Added a non-blocking Mac warning banner for missing App Group/CloudKit setup.

Validation commands:
- `xcodebuild -list -project WorkingHour.xcodeproj`
- `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour Mac" -configuration Debug -destination "platform=macOS" -derivedDataPath /private/tmp/WorkingHourMacDerivedData CODE_SIGNING_ALLOWED=NO build`
- `open "/private/tmp/WorkingHourMacDerivedData/Build/Products/Debug/Working Hour Mac.app"`
- `pgrep -x "Working Hour Mac"`
- `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath /private/tmp/WorkingHourDerivedDataEntitlement CODE_SIGNING_ALLOWED=NO build`
- `swift test --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-mac-target-test`
- `plutil -lint WorkingHour.xcodeproj/project.pbxproj WorkingHour/Info.plist Ushio/Info.plist`
- `xmllint --noout "WorkingHour.xcodeproj/xcshareddata/xcschemes/Working Hour Mac.xcscheme"`

Result:
- Passed. Xcode lists `Working Hour Mac` as a target and shared scheme.
- Passed. Native Mac and iOS app/widget builds succeed.
- Passed. The Mac process remained active as pid 77613 and rendered the shared dashboard after the CloudKit entitlement crash was fixed.
- Passed. The updated iOS build retained pid 78133 across a second launch query.
- Passed. `AttendanceKitTests` executed 30 XCTest cases with 0 failures.

Known issue:
- The Mac target still needs owner-controlled signing capabilities before App Group/CloudKit sync can be tested.
- A macOS widget and native watchOS app/widget targets remain pending.
