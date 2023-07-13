// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FolderCrawler",
    products: [
        .library(
            name: "FilesFinder",
            targets: [
                "FilesFinder"
            ]
        )
    ],

    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/Genaro-Chris/SignalHandler", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", branch: "main"),
    ],

    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FilesFinder",
            dependencies: [],
            path: "FilesFinder/",
            cxxSettings: [
                .define("FilesFinder"),
                .unsafeFlags([
                    "-I", "/usr/include/c++/12",
                ]),
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),

        .executableTarget(
            name: "FolderCrawler",
            dependencies: [
                "SignalHandler",
                "FilesFinder",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ],

            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        )
    ],
    cLanguageStandard: .c17
)
