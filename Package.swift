// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [ SwiftSetting ] =
[
 .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
 .enableUpcomingFeature("InferIsolatedConformances"),
 .enableUpcomingFeature("MemberImportVisibility")
]

let package = Package(name: "VLLayoutKit",
                      defaultLocalization: "en",
                      platforms: [ .iOS(.v17), .macOS(.v13) ],
                      products:
                      [
                       .library(name: "VLLayoutKit",
                                targets: [ "VLLayoutKit" ])
                      ],
                      targets:
                      [
                       .target(name: "VLLayoutKit",
                               swiftSettings: swiftSettings),
                       .testTarget(name: "VLLayoutKitTests",
                                   dependencies: [ "VLLayoutKit" ],
                                   swiftSettings: swiftSettings)
                      ])
