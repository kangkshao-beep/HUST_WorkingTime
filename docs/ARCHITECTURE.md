# Architecture

## Data Flow

```mermaid
flowchart TD
    A[iPhone app] --> B[SwiftData local store]
    C[Future macOS app] --> B
    D[Future watchOS app] --> B
    B --> E[CloudKit durable sync]
    A <--> F[Future WatchConnectivity fast sync]
    D <--> F
    A --> G[App Group snapshot]
    C --> H[Mac App Group snapshot]
    D --> I[Watch snapshot]
    G --> J[iPhone Home/Lock Screen Widget]
    H --> K[Future macOS Desktop Widget]
    I --> L[Future Watch complication]
```

## Shared Business Core

`Packages/AttendanceKit` is the single source for:

- Monday-Friday workday policy.
- 8-hour target calculation.
- 80% monthly attendance requirement using `ceil`.
- Day-key generation through injected `Calendar` and `TimeZone`.
- Duplicate record conflict resolution by `dayKey`.
- Widget timeline refresh logic.

The package is intentionally Foundation-first. `AttendanceRecord` is a pure domain model because the current CommandLineTools environment cannot compile SwiftData macros in Swift Package tests. App persistence maps SwiftData storage objects to this domain type.

## iPhone App

The main navigation is now:

- Today
- Month
- History
- Settings

The old timesheet/project/break/geofencing code remains in the repository as legacy code and is not destructively migrated.

## Shared Attendance App Layer

`Shared/Attendance/AttendanceStore.swift` owns app-level persistence orchestration for the new attendance flow. It maps SwiftData storage to `AttendanceKit`, writes widget snapshots, and avoids direct iOS-only device APIs except behind conditional compilation.

`Shared/Attendance/AttendanceDashboardView.swift` is the reusable SwiftUI entry point for future macOS/watchOS app shells. Platform apps should embed it with `.regular` or `.compact` display style instead of duplicating Today/month formulas outside `AttendanceKit`.

## Persistence

`AttendanceStorageRecord` is the SwiftData storage model for attendance records. It maps to and from `AttendanceKit.AttendanceRecord`.

`SharedModelContainer` now tries:

1. App Group SwiftData store.
2. Local SwiftData store fallback.
3. In-memory fallback.

The first two failure states are non-fatal and exposed in Settings.

## Widget Snapshot

The app writes `AttendanceWidgetSnapshot` JSON into the App Group container. The widget reads this snapshot and uses `WidgetTimelineLogic` for meaningful refresh dates. It does not query CloudKit or SwiftData live during timeline generation.

## Remaining Target Work

Native macOS and watchOS targets still require Xcode project changes and compiler verification. Xcode 26.6 is now installed and selected, but this machine still lacks an installed/registered iOS 26.5 platform/runtime, so iOS app/widget builds cannot start yet. The shared attendance store and dashboard source are prepared for those targets.
