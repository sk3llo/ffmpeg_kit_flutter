// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 full prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64_arm64e,
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.2-full"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "49e64651d054226c89dd4c1db7ebf539f8f89f914ea16eb2c1455f7da0111894"),
    ("libavcodec", "cc51cc4faec995ae7da69c254506b15948190132717e5f95844080153bf5797b"),
    ("libavdevice", "40dfb7d807a018869bc996dc8c0cfdac6607f699764ffca2c6345262d4a71ca3"),
    ("libavfilter", "a8cd456274a0b163cef9beb5f44e4b1f3c6965df8dbf3d69d278821cd2612526"),
    ("libavformat", "54a82bfd57ca56e42b45c6161b214f6f8cb03cd592e522d3f0b837263356922a"),
    ("libavutil", "c0fe643e627c4376ec828d4e1f36e94a7d76e7a86d2d661346199fab297495e7"),
    ("libswresample", "6994edad7fbe472e265836ac4b33ef739f613a40d4e26505725e5d7d34087854"),
    ("libswscale", "ac9f4efc200e8af1f1f5ab7341bb175302fc1bdb6da7617f272ce126e140353d"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_full",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-full", targets: ["ffmpeg_kit_flutter_new_full"])
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
            name: "ffmpeg_kit_flutter_new_full",
            dependencies: ffmpegLibs.map { .target(name: $0.name) },
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_full")
            ]
        )
    ]
)
