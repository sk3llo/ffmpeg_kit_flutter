// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 9.1-beta.1 min prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "9.1-beta.1-min"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "bb6ed724fb60dd65120944d8dd8e5f53d50c08c5c72e910e1a705552707a91fa"),
    ("libavcodec", "f8ba479a607b6fa9bd04e5adc6e08bbb0e5ce182c02dd41f74b0d34f1f590aa0"),
    ("libavdevice", "31f81cbb7d42ad98c5e805be471faa01645fd4c084b0761fc8fc5877078dfdf6"),
    ("libavfilter", "6ac317da76b0101fa8cd45a738ab8f705c70e6bd8f2545c4ad25f5fa4b36bfa7"),
    ("libavformat", "d9424738e4bba9c3f795cc0b93eec6b7f91c4c5ff24fad25489d5f1e5c75eb6e"),
    ("libavutil", "4b622d17971ea6a46974c0d1117cd53ea03ca2aa5ab79b6c3c2e4987d57ffa46"),
    ("libswresample", "b70a23e79bd3adf186d3afad9d412edd785cda091e898778387e29584aa4c36e"),
    ("libswscale", "72b50b79625edde0937a3b4fe8ce6781caa5cf5a81ded9fa2829f5a75a2c6afc"),
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
