// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 min prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.2-min"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "3758f051a89f67442eeb17aa9f2e0aa3386a966338deb09dd2e6769aba4b7972"),
    ("libavcodec", "1e43d72539bbf0fc99fc74b451763dddcdd6aa0cc6ae7d5c9e144a31de2b6cfc"),
    ("libavdevice", "127f9e5290b8e5125a402c9c99482e731ed670c93ec0babf777e4af8274b703c"),
    ("libavfilter", "81ac35ca0961cfc41dd910963b00582e956c0c6ba8f0d49cd6d355ce9f9c840b"),
    ("libavformat", "2996af84ac2de0c782bc407e794ce51b14269b34f832c9b76554d1b31b8ec1d2"),
    ("libavutil", "a1ecbd41172995f3303f71b1486683e5cd47aeb28c58038873d11ec3fdbb6674"),
    ("libswresample", "f1465f88a72da4093ab1edb6cccd5e5d27ad7e00afb9227b2d290d85ed53814d"),
    ("libswscale", "da2802037839a59b6cba113dc923f4565de7d2fdf384f84d2a3503c2a299a363"),
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
