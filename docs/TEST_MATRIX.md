# Test Matrix

| Case | Setup | Action | Expected Result | Actual Result | Pass/Fail |
| --- | --- | --- | --- | --- | --- |
| 1. Monday, no punch | Fixed Monday workday | Open Today | Shows workday, no record, clock-in CTAs | Core XCTest passed; Today screen and clock-in CTAs rendered on iOS 26.5 simulator | Pass initial UI |
| 2. Monday, punch now | Fixed Monday workday | Tap now clock-in | Creates one record, target end is +8h | Core XCTest passed; app builds, installs, and launches on iOS 26.5 simulator | Pending manual UI |
| 3. Manual punch earlier today | Workday, no record | Select earlier time and save | Record uses selected clock-in, no future time allowed | Core XCTest passed; app builds, installs, and launches on iOS 26.5 simulator | Pending manual UI |
| 4. Countdown crosses relaunch | Existing record | Relaunch app later | Remaining time recalculates from targetEndAt | Core XCTest passed; stable process launch verified; record/relaunch workflow not manually exercised | Pending manual UI |
| 5. Countdown reaches zero | Existing record after target | Open app/widget | Shows target reached/completed state | Core XCTest passed; widget extension builds; runtime rendering not manually exercised | Pending manual UI |
| 6. Saturday | Fixed Saturday | Open Today | Shows rest day and excludes from month denominator | Core XCTest passed | Pending manual UI |
| 7. Month threshold exactly reached | Valid days equals required | Open Month | Month passed true | Core XCTest passed | Pending manual UI |
| 8. Month threshold not reached | Valid days below required | Open Month | Month passed false, remaining needed shown | Core XCTest passed | Pending manual UI |
| 9. Duplicate same-day record | Two records same dayKey | Calculate month | Counts one canonical record | Core XCTest passed | Pass core |
| 10. iPhone offline -> later sync | Device offline | Clock in, later online | Local works, CloudKit catches up | Not run: device required | Pending |
| 11. Watch offline -> later sync | Watch offline | Clock in on watch | Local-first update, queued sync | Sync protocol XCTest passed; watch app not implemented | Pending app run |
| 12. Mac receives CloudKit update | Mac signed in | Sync iPhone record | Mac app shows same record | Shared app shell source prepared; native macOS target not created | Pending |
| 13. iPhone widget before/after punch | Widget added | Clock in | Snapshot updates widget state | Timeline XCTest passed; widget extension builds for iOS simulator and generic iOS device | Pending widget UI |
| 14. Mac desktop widget | Mac target configured | Add widget | Shows same rules from local snapshot | Shared snapshot/timeline rules exist; native macOS widget target not created | Pending |
| 15. Watch complication | Watch target configured | Add complication | Shows active countdown/status | Shared compact dashboard and sync protocol exist; watch target/complication not created | Pending |

## Verification Commands

| Command | Result | Notes |
| --- | --- | --- |
| `swift run --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-check-build AttendanceKitChecks` | Pass | Runs the current-toolchain executable coverage for core rules. |
| `swift build --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-check-build` | Pass | Builds `AttendanceKit` and `AttendanceKitChecks`. |
| `swift test --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-xcode-test` | Pass | Xcode 26.6 selected; executed 30 XCTest cases with 0 failures. |
| `xcodebuild -list -project WorkingHour.xcodeproj` | Pass | Resolves project schemes and package graph under Xcode 26.6. |
| `xcrun simctl list runtimes` | Pass | Lists iOS 26.5 and watchOS 26.5 runtimes. |
| `xcrun simctl list devices available` | Pass | Lists available iPhone/iPad and Apple Watch simulator devices. |
| `xcodebuild -downloadPlatform iOS` | Blocked | Download started from 0%, reached about 9.7% / 830 MB of 8.52 GB, then was cancelled after throughput dropped to less than 1 MB per 30 seconds. |
| `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath /private/tmp/WorkingHourDerivedData CODE_SIGNING_ALLOWED=NO build` | Pass | iOS app and embedded `Ushio.appex` build for simulator. |
| `xcodebuild -project WorkingHour.xcodeproj -scheme "Ushio" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath /private/tmp/WorkingHourDerivedDataUshio CODE_SIGNING_ALLOWED=NO build` | Pass | Widget scheme build passes. |
| `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphoneos -destination "generic/platform=iOS" -derivedDataPath /private/tmp/WorkingHourDerivedDataDevice CODE_SIGNING_ALLOWED=NO build` | Pass | Generic iOS device build passes with signing disabled. |
| `xcrun simctl install F6040390-A952-4322-B4EE-EC3FD2E3387A "/private/tmp/WorkingHourDerivedData/Build/Products/Debug-iphonesimulator/Working Hour.app"` | Pass | App installs on iPhone 17 Pro simulator. |
| `xcrun simctl launch F6040390-A952-4322-B4EE-EC3FD2E3387A com.tsubuzaki.WorkingHour` | Pass after fallback fix | Launch returned stable pid 73466, and a simulator screenshot confirmed the Today screen rendered. |
