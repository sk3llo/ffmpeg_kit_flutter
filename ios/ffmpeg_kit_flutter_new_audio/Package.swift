// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 audio prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64_arm64e,
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.2-audio"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "668386f380c78b516be140e4b89cd720a0dc3b33c6f4457bff7c23b45468151a"),
    ("libavcodec", "d25d8f2abe4a5d94fc316a6a8d45cde49437cf2b32078cb75b4616eb144946e0"),
    ("libavdevice", "bb5ea9c47edbc40c2445c8a91a4b2748de4bd969acd4c20aeebb5a39ed22ba97"),
    ("libavfilter", "db8cad0c60d4146c9f2bf3f46ffe874487e17201c6814d1d33f99b1474730be9"),
    ("libavformat", "e289576e235bda77a35b492c58a223002a73091ebd7abc9a1de57e90f32fdcd9"),
    ("libavutil", "ef77b9e7b6c2ea3fc900d96788842919dc0a98c8c8c315cbf4cde8238a57b51c"),
    ("libswresample", "67d293412044d28fab98d6006c7d6878931e49383c6711385ee2c8ad1bede92b"),
    ("libswscale", "b79397b957ed086728e644f28f8b52bc62d311c7e9cadd9aecc6bcfa8bfc3616"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_audio",
    platforms: [
        .iOS("14.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-audio", targets: ["ffmpeg_kit_flutter_new_audio"])
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
            name: "ffmpeg_kit_flutter_new_audio",
            dependencies: ffmpegLibs.map { .target(name: $0.name) },
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_audio")
            ]
        )
    ]
)
