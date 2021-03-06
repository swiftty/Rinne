// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Rinne",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v7),
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Rinne",
            targets: ["Rinne"]),

        .library(
            name: "RinneSwiftUI",
            targets: ["RinneSwiftUI"]),

        .library(
            name: "RinneTest",
            targets: ["RinneTest"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Rinne",
            dependencies: []),
        .testTarget(
            name: "RinneTests",
            dependencies: ["Rinne", "RinneTest"]),

        .target(
            name: "RinneSwiftUI",
            dependencies: ["Rinne"]),
        .testTarget(
            name: "RinneSwiftUITests",
            dependencies: ["RinneSwiftUI"]),

        .target(
            name: "RinneTest",
            dependencies: ["Rinne"]),
        .testTarget(
            name: "RinneTestTests",
            dependencies: ["RinneTest"]),
    ]
)
