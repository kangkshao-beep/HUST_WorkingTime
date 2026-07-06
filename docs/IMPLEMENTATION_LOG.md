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
