# Test Matrix

| Case | Setup | Action | Expected Result | Actual Result | Pass/Fail |
| --- | --- | --- | --- | --- | --- |
| 1. Monday, no punch | Fixed Monday workday | Open Today | Shows workday, no record, clock-in CTAs | Core XCTest passed; Today screen and clock-in CTAs rendered on iOS 26.5 simulator | Pass initial UI |
| 2. Monday, punch now | Fixed Monday workday | Tap now clock-in | Creates one record, target end is +8h | Tapped on iOS 26.5 simulator; countdown, dot grid, action row, and metrics rendered without overlap | Pass simulator UI |
| 3. Manual punch earlier today | Workday, no record | Select earlier time and save | Record uses selected clock-in, no future time allowed | Core XCTest passed; app builds, installs, and launches on iOS 26.5 simulator | Pending manual UI |
| 4. Countdown crosses relaunch | Existing record | Relaunch app later | Remaining time recalculates from targetEndAt | Core XCTest passed; stable process launch verified; record/relaunch workflow not manually exercised | Pending manual UI |
| 5. Countdown reaches zero | Existing record after target | Open app/widget | Shows target reached/completed state | Core XCTest passed; widget extension builds; runtime rendering not manually exercised | Pending manual UI |
| 6. Saturday | Fixed Saturday | Open Today | Shows rest day and excludes from month denominator | Core XCTest passed | Pending manual UI |
| 7. Month threshold exactly reached | Valid days equals required | Open Month | Month passed true | Core XCTest passed | Pending manual UI |
| 8. Month threshold not reached | Valid days below required | Open Month | Month passed false, remaining needed shown | Core XCTest passed | Pending manual UI |
| 9. Duplicate same-day record | Two records same dayKey | Calculate month | Counts one canonical record | Core XCTest passed | Pass core |
| 10. iPhone offline -> later sync | Device offline | Clock in, later online | Local works, CloudKit catches up | Not run: device required | Pending |
| 11. Watch offline -> later sync | Watch offline | Clock in on watch | Local-first update, queued sync | `sendMessage` plus `transferUserInfo` fallback are wired; seeded idempotence and payload codec tests pass; actual delayed paired-device delivery not exercised | Pass implementation; pending device delivery |
| 12. Mac receives CloudKit update | Mac signed in | Sync iPhone record | Mac app shows same record | Native Mac app builds and runs with local fallback; signed CloudKit sync not run | Pending sync |
| 13. iPhone widget before/after punch | Widget added | Clock in | Snapshot updates widget state | Timeline XCTest passed; widget extension builds for iOS simulator and generic iOS device | Pending widget UI |
| 14. Mac desktop widget | Mac target configured | Add widget | Shows same rules from local snapshot | Native Mac WidgetKit extension builds, embeds in the host app, and exposes small/medium families; desktop placement not manually exercised | Partial pass |
| 15. Watch complication | Watch target configured | Add complication | Shows active countdown/status | Watch WidgetKit extension builds for simulator/device architectures, embeds in the Watch app, and exposes three accessory families; watch-face placement not manually exercised | Partial pass |

## Verification Commands

| Command | Result | Notes |
| --- | --- | --- |
| `swift run --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-check-build AttendanceKitChecks` | Pass | Runs the current-toolchain executable coverage for core rules. |
| `swift build --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-check-build` | Pass | Builds `AttendanceKit` and `AttendanceKitChecks`. |
| `swift test --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-watch-sync-test` | Pass | Xcode 26.6 selected; executed 32 XCTest cases with 0 failures. |
| `xcodebuild -list -project WorkingHour.xcodeproj` | Pass | Resolves project schemes and package graph under Xcode 26.6. |
| `xcrun simctl list runtimes` | Pass | Lists iOS 26.5 and watchOS 26.5 runtimes. |
| `xcrun simctl list devices available` | Pass | Lists available iPhone/iPad and Apple Watch simulator devices. |
| `xcodebuild -downloadPlatform iOS` | Blocked | Download started from 0%, reached about 9.7% / 830 MB of 8.52 GB, then was cancelled after throughput dropped to less than 1 MB per 30 seconds. |
| `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath /private/tmp/WorkingHourDerivedData CODE_SIGNING_ALLOWED=NO build` | Pass | iOS app and embedded `Ushio.appex` build for simulator. |
| `xcodebuild -project WorkingHour.xcodeproj -scheme "Ushio" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" -derivedDataPath /private/tmp/WorkingHourDerivedDataUshio CODE_SIGNING_ALLOWED=NO build` | Pass | Widget scheme build passes. |
| `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour" -configuration Debug -sdk iphoneos -destination "generic/platform=iOS" -derivedDataPath /private/tmp/WorkingHourDerivedDataDevice CODE_SIGNING_ALLOWED=NO build` | Pass | Generic iOS device build passes with signing disabled. |
| `xcrun simctl install F6040390-A952-4322-B4EE-EC3FD2E3387A "/private/tmp/WorkingHourDerivedData/Build/Products/Debug-iphonesimulator/Working Hour.app"` | Pass | App installs on iPhone 17 Pro simulator. |
| `xcrun simctl launch F6040390-A952-4322-B4EE-EC3FD2E3387A com.tsubuzaki.WorkingHour` | Pass after fallback fix | Latest build returned stable pid 78133; the Today screen was previously screenshot-verified. |
| `xcrun simctl io F6040390-A952-4322-B4EE-EC3FD2E3387A screenshot /private/tmp/working-hour-reference-style-active.png` | Pass | Reference-style active countdown screen visually inspected at 942 x 2048 with no overlap or clipping. |
| `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour Mac" -configuration Debug -destination "platform=macOS" -derivedDataPath /private/tmp/WorkingHourMacDerivedData CODE_SIGNING_ALLOWED=NO build` | Pass | Native Mac app and shared attendance layer compile for macOS. |
| `pgrep -x "Working Hour Mac"` | Pass | Process remained active as pid 77613 after launch; shared dashboard rendered with the expected local-storage warning. |
| `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour Watch" -configuration Debug -sdk watchsimulator -destination "generic/platform=watchOS Simulator" ... build` | Pass | Watch app and embedded WidgetKit complication compile for the simulator. |
| `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour Watch" -configuration Debug -sdk watchos -destination "generic/platform=watchOS" ... build` | Pass | Watch app and complication compile for generic device architectures. |
| `xcrun simctl launch 1E19D673-DB89-4DEE-9894-9B86D4AA7C67 com.tsubuzaki.WorkingHour.watchkitapp` | Pass | Complete Watch bundle retained pid 88322 across a second launch query; screenshot verified the compact layout. |
| `xcodebuild -project WorkingHour.xcodeproj -scheme "Working Hour Mac" -configuration Debug -destination "platform=macOS" ... build` | Pass | Mac host and embedded desktop WidgetKit extension compile successfully. |
| `pgrep -fl "Working Hour Mac"` | Pass | Complete Mac bundle remained active as pid 6918 after ad-hoc signing and relaunch. |
