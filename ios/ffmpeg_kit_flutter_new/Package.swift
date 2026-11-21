// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 9.1-beta.1 full-gpl prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release.
let ffmpegTag = "9.1-beta.1-full-gpl"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "ead0e83efb7729c3bf12332feba47107e2510282c05c6cf32d842d9a8c28f3a3"),
    ("libavcodec", "a4737dee1672dc8f0d0729876141bffc61b76dc7d85ed55c9a06611fc6da0008"),
    ("libavdevice", "b57d96b7db4dae7d9b9e9cebf1102ae2b104f44aa20c2062c83f0dfc7ba0fc2d"),
    ("libavfilter", "4bf28e7c3ce7a310bfbeab863a5d3b28e23d562ce06ceb07deb7f0dcf528cfc9"),
    ("libavformat", "7f9fb0fa5a83b654e6e2530df17749fdfdf03e5d311447031e5fedc2d8fb193e"),
    ("libavutil", "17b4394afd51f6880f70353597e91d9b6893eafdb692f7c69e8c84ef322910ee"),
    ("libswresample", "0144dbad05073ac93b4a75b6b6ce30b8d00508afb80d8823d4b8499b1f14f097"),
    ("libswscale", "98d88f6f17b500647705cac44758dfe3686248e3f8baf647a9db650e3d988d59"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new", targets: ["ffmpeg_kit_flutter_new"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: ffmpegLibs.map { lib in
        .binaryTarget(
            name: lib.name,
            url: "\(ffmpegBase)/\(lib.name).xcframework.zip",
            checksum: lib.checksum
        )
    } + [
        .target(
            name: "ffmpeg_kit_flutter_new",
            dependencies: ffmpegLibs.map { .target(name: $0.name) } + [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new")
            ]
        )
    ]
)
