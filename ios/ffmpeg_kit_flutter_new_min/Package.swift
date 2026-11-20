// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.3 min prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.3-min"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "c87ffc5e2faeaeab5dd857ddb1590e103eda1f7267edfd6b03b2dce534e80ae6"),
    ("libavcodec", "d8a402ab885f738aa323a1dbe204b650baaba6be2e88fdf9ee847b922a090293"),
    ("libavdevice", "a14de6e1100ca96e85b334213b787dec983ad56bf25e01a1f3c478e5478dad34"),
    ("libavfilter", "3d3f170a0b9b65e512525357181074019c192e7142622837e638660b5ea3804e"),
    ("libavformat", "1c610459e867177d212610eebc4ec6bc0101158cfb4c82bc8050c172b21cea15"),
    ("libavutil", "46762445c1f5ee88494567a9569e9b56fb28e702d17250afc80a5db3da7de560"),
    ("libswresample", "29f2ca9a5bd8adb3d8d893071fd444b80eac11bd89a26f84ab77b37d3444a9f2"),
    ("libswscale", "d92404393df92fd480aa8ef1a35bee3e697ce03c9f8de6c408aa193e6d74552a"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_min",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-min", targets: ["ffmpeg_kit_flutter_new_min"])
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
            name: "ffmpeg_kit_flutter_new_min",
            dependencies: ffmpegLibs.map { .target(name: $0.name) } + [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_min")
            ]
        )
    ]
)
