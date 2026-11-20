// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.3 min-gpl prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.3-min-gpl"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "e66878df065aafee17f73d278eb21db5f75226c37e8577f7e11240bd2efc8ed6"),
    ("libavcodec", "1d11ca13537e3736982705d23f192bad8b107dc6e69057ffc75dbeea61d9fef5"),
    ("libavdevice", "a2deef370aa96d1dcd3e9155ec943fbd5d7e4285dfdd9909e17b0e5b78d0402d"),
    ("libavfilter", "3e123b9c22ef83d037158cde937f98d7471c6327cd21995d375975085ca53531"),
    ("libavformat", "d9d5bc121749141e901e54c1b0be41b879d6a87037fc897646db3ce9d0e7543a"),
    ("libavutil", "160eac9c0c6b62bb8efc67252c75022521f647302c816f173dbbcdb24a003370"),
    ("libswresample", "85735fc29a8e85a66a5ad056dfe98177b0befbd6b7f8b8c8360277e51b6d1124"),
    ("libswscale", "42ebe51f5fe5ebd5e6022478d571a3a3362320b72ae138efeb77a6e562281fde"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_min_gpl",
    platforms: [
        .macOS("11.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-min-gpl", targets: ["ffmpeg_kit_flutter_new_min_gpl"])
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
            name: "ffmpeg_kit_flutter_new_min_gpl",
            dependencies: ffmpegLibs.map { .target(name: $0.name) } + [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_min_gpl")
            ]
        )
    ]
)
