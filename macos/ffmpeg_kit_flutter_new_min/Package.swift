// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 min prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64_arm64e,
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.2-min"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "93996363495ec087ca1fe3d6b9dabdeac1c077eb1c00abfdf4fee8431b383e26"),
    ("libavcodec", "4b70fcbbb96e56bca60a096c329d758585d94ca59219d58a552527e72d2218a6"),
    ("libavdevice", "5d71cc5477f952991b3289f88a40448c5d372b2e5f7b9c293c348a70a77943c5"),
    ("libavfilter", "509cf321f0dce858b104c0ca212a21f90cd9cc63a54c6ceee0c400b1ed9cec73"),
    ("libavformat", "a3850dce60f62010707877dc020b1453ee506ffb2a2c272c3ef67b3dfabd303a"),
    ("libavutil", "047d193a69651c8f52792bdb9201ee8123edb28b320f7900502bac4d6430f89b"),
    ("libswresample", "337461124b1ba34d2aedc2e56ad705473f0f884ffb08097b7785049bc1f1a804"),
    ("libswscale", "c21bc33b07a7658c647dca166db8fe68a0915a98469e402397da9034b3925630"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_min",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-min", targets: ["ffmpeg_kit_flutter_new_min"])
    ],
    dependencies: [],
    targets: ffmpegLibs.map { lib in
        .binaryTarget(
            name: lib.name,
            url: "\(ffmpegBase)/\(lib.name).xcframework.zip",
            checksum: lib.checksum
        )
    } + [
        .target(
            name: "ffmpeg_kit_flutter_new_min",
            dependencies: ffmpegLibs.map { .target(name: $0.name) },
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_min")
            ]
        )
    ]
)
