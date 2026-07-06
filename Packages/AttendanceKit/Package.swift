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
        .library(name: "AttendanceKit", targets: ["AttendanceKit"])
    ],
    targets: [
        .target(name: "AttendanceKit"),
        .testTarget(name: "AttendanceKitTests", dependencies: ["AttendanceKit"])
    ]
)
