// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

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
                       .target(name: "VLLayoutKit")
                      ])
