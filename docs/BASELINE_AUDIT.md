# Baseline Audit

Date: 2026-07-06
Branch at audit start: not a git repository. A baseline repository was initialized locally and the original import was committed before creating `feat/cross-platform-attendance`.

## Commands Run

- `git status --short`: failed before initialization with `fatal: not a git repository`.
- `git branch --show-current`: failed before initialization with `fatal: not a git repository`.
- `find -s . -maxdepth 4 -type f`: succeeded; key files are listed below.
- `find -s . -maxdepth 3 -name '*.xcodeproj' -o -name '*.xcworkspace'`: found `WorkingHour.xcodeproj` and `WorkingHour.xcodeproj/project.xcworkspace`.
- `xcodebuild -list -project WorkingHour.xcodeproj`: blocked because `xcode-select` points at `/Library/Developer/CommandLineTools`.
- `xcrun simctl list devices available`: blocked because `simctl` is not available from the current developer directory.

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

Important risk: `SharedModelContainer` currently calls `fatalError` if container creation fails. That must be replaced by a fallback local store for the new attendance domain.

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

Baseline build could not run in this environment:

- `xcodebuild` error: active developer directory is `/Library/Developer/CommandLineTools`.
- `simctl` error: utility unavailable from the current developer directory.

This is an environment/setup blocker, not yet a source-code compile result. Install/select Xcode and rerun the commands in `docs/MANUAL_SETUP.md`.

## Upstream Feature Handling

- Keep initially: existing SwiftData models, live activity code, notification manager, widget target, localization files.
- Migrate/replace: main app navigation, clock-in/out UI, month summary logic, widget timeline source.
- Hide from primary UX: project/task timesheet features, break tracking, geofencing, export.
- Do not auto-delete: old models or persisted data.

## Main Refactor Risks

- No Xcode.app is currently available, so app/widget/watch target builds cannot be verified yet.
- Existing deployment targets are higher than the requested minimums; lowering requires Xcode verification.
- Current App Group/iCloud identifiers use the upstream author namespace and must be replaced manually by the project owner.
- Adding macOS/watchOS targets without Xcode project generation support is high risk; this pass focuses on shared core, iPhone MVP source, snapshot logic, and documentation, then records remaining target work.
