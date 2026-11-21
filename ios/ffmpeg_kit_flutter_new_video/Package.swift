// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 9.1-beta.1 video prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "9.1-beta.1-video"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "3aa3034d00f9fa572cd07f9302f9b918b3159063f72a195023a5fda7723c0791"),
    ("libavcodec", "9780a56195b1281536719226e6cdab0c86e81457b44ee5ef15201eb764c9d6db"),
    ("libavdevice", "70fbc4cd3da4f077e775ef4fa9169bb66a6baf10f6cb322b7cb11f9219edbc86"),
    ("libavfilter", "29910d11d9f0b64d43338964c2f7e428d34019c8484f049c8b0d2c41520a087b"),
    ("libavformat", "021ff7e4d0337fd4e8a7155fa235f15d4046afd532ccfe6498ca76f3a5e8c129"),
    ("libavutil", "bcc732cd136ea2981cfa28829f5a1bb2d018d983a273bd5b3ac8b661f8de779d"),
    ("libswresample", "69ee0740162399f41c55c8cbcc3d2e28a69155c5dc4be06ea52f0c1f33d6fcd1"),
    ("libswscale", "87e913a43ab979c80863c47bbcd4bdeff1eeed707a1eeb3f4ac60ed74a1384e1"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_video",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-video", targets: ["ffmpeg_kit_flutter_new_video"])
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
            name: "ffmpeg_kit_flutter_new_video",
            dependencies: ffmpegLibs.map { .target(name: $0.name) } + [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_video")
            ]
        )
    ]
)
