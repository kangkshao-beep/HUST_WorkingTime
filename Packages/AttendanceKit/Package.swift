// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AttendanceKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "AttendanceKit", targets: ["AttendanceKit"]),
        .executable(name: "AttendanceKitChecks", targets: ["AttendanceKitChecks"])
    ],
    targets: [
        .target(name: "AttendanceKit"),
        .executableTarget(name: "AttendanceKitChecks", dependencies: ["AttendanceKit"]),
        .testTarget(name: "AttendanceKitTests", dependencies: ["AttendanceKit"])
    ]
)
