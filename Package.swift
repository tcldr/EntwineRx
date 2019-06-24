// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EntwineRx",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(
            name: "EntwineRx",
            targets: ["EntwineRx"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "http://github.com/tcldr/Entwine.git", .branch("develop")),
        .package(url: "http://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "5.0.0")),
    ],
    targets: [
        .target(
            name: "EntwineRx",
            dependencies: ["Entwine", "RxSwift"]),
        .testTarget(
            name: "EntwineRxTests",
            dependencies: ["EntwineRx", "EntwineTest", "RxTest"]),
    ]
)
