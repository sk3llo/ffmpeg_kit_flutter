// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 9.1-beta.1 audio prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "9.1-beta.1-audio"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "7f4c9e8775e3c968e9da768069aedb95a769219e263f912f7fa20511d5b77b80"),
    ("libavcodec", "3db7ab44faf7c2134ce4421c3610daa534afb901a7815d2e4b0ded1209e9f89f"),
    ("libavdevice", "8f8a101a2052726b309fe8d21e06843db91736f1f56ef298d592d5f070353920"),
    ("libavfilter", "4f5cb38ad1f960c0e19bf4a7115852912b3ac791d6878d01c604578e0458100a"),
    ("libavformat", "9957ba741d5904afc0fbb0c1e2b25c6df12d626c552ea0dca54d4ba63587d478"),
    ("libavutil", "c5a0a54a37e0e88e04ead708ad0bcde992a4593ea69ed440c2ac532c90757f78"),
    ("libswresample", "52cfaba321b94f381f57edb876b7ec525574ef60566f3b0508829ce0d3225e1c"),
    ("libswscale", "d7197e29012e01e7f9d679d501da057703919707c768ea6c465beda32a20d667"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_audio",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-audio", targets: ["ffmpeg_kit_flutter_new_audio"])
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
            name: "ffmpeg_kit_flutter_new_audio",
            dependencies: ffmpegLibs.map { .target(name: $0.name) } + [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_audio")
            ]
        )
    ]
)
