# Test Matrix

| Case | Setup | Action | Expected Result | Actual Result | Pass/Fail |
| --- | --- | --- | --- | --- | --- |
| 1. Monday, no punch | Fixed Monday workday | Open Today | Shows workday, no record, clock-in CTAs | Not run: Xcode unavailable | Pending |
| 2. Monday, punch now | Fixed Monday workday | Tap now clock-in | Creates one record, target end is +8h | Not run: Xcode unavailable | Pending |
| 3. Manual punch earlier today | Workday, no record | Select earlier time and save | Record uses selected clock-in, no future time allowed | Not run: Xcode unavailable | Pending |
| 4. Countdown crosses relaunch | Existing record | Relaunch app later | Remaining time recalculates from targetEndAt | Core passed via `AttendanceKitChecks`; app relaunch not run | Pending app run |
| 5. Countdown reaches zero | Existing record after target | Open app/widget | Shows target reached/completed state | Core passed via `AttendanceKitChecks`; widget/app not run | Pending app run |
| 6. Saturday | Fixed Saturday | Open Today | Shows rest day and excludes from month denominator | Core passed via `AttendanceKitChecks` | Pending app run |
| 7. Month threshold exactly reached | Valid days equals required | Open Month | Month passed true | Core passed via `AttendanceKitChecks` | Pending app run |
| 8. Month threshold not reached | Valid days below required | Open Month | Month passed false, remaining needed shown | Core passed via `AttendanceKitChecks` | Pending app run |
| 9. Duplicate same-day record | Two records same dayKey | Calculate month | Counts one canonical record | Core passed via `AttendanceKitChecks` | Pending app run |
| 10. iPhone offline -> later sync | Device offline | Clock in, later online | Local works, CloudKit catches up | Not run: device required | Pending |
| 11. Watch offline -> later sync | Watch offline | Clock in on watch | Local-first update, queued sync | Sync protocol mock passed via `AttendanceKitChecks`; watch app not implemented | Pending app run |
| 12. Mac receives CloudKit update | Mac signed in | Sync iPhone record | Mac app shows same record | Shared app shell source prepared; native macOS target not created | Pending |
| 13. iPhone widget before/after punch | Widget added | Clock in | Snapshot updates widget state | Timeline core passed via `AttendanceKitChecks`; widget runtime pending Xcode | Pending |
| 14. Mac desktop widget | Mac target configured | Add widget | Shows same rules from local snapshot | Shared snapshot/timeline rules exist; native macOS widget target not created | Pending |
| 15. Watch complication | Watch target configured | Add complication | Shows active countdown/status | Shared compact dashboard and sync protocol exist; watch target/complication not created | Pending |

## Verification Commands

| Command | Result | Notes |
| --- | --- | --- |
| `swift run --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-check-build AttendanceKitChecks` | Pass | Runs the current-toolchain executable coverage for core rules. |
| `swift build --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-check-build` | Pass | Builds `AttendanceKit` and `AttendanceKitChecks`. |
| `swift test --package-path Packages/AttendanceKit --scratch-path /private/tmp/attendancekit-test-build-xctest` | Blocked | Current CommandLineTools has no `XCTest` module; rerun after selecting full Xcode.app. |
