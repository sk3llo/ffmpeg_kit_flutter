// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.3 full prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.3-full"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "ac4de6e577aad3097dd7445c3141643c373eb45f177c5d2c19ade46bc49f11f4"),
    ("libavcodec", "404d33029e36b8fab94cb9ef8b99097a8a96834414ef71a2aefe8fe7ba38659a"),
    ("libavdevice", "1ed6a3a473f168de610199159b6869d89bbc74a95d75ae95c8035c501206e536"),
    ("libavfilter", "0bc887a5354cf1ef5adfc488af5ddcd0089ee3efb8715f9d755bb8e6b76fadd1"),
    ("libavformat", "d15057c35d2c08652e86745ac21c50848d0c4e0a5594ba00a1083053ba3f9af4"),
    ("libavutil", "4939cdec30b3f885b4cf9fb65ad5212ba2845d8a754589200b593c7e165c99fd"),
    ("libswresample", "8aa3009d38dc261b1d9194b98b779498e9cf6d5ed1ef0356342c1c1c17cf1a08"),
    ("libswscale", "bcec265fee70a457f801644e2b5a456ed9247620d03379b7c8bd542ecfb60d69"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_full",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-full", targets: ["ffmpeg_kit_flutter_new_full"])
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
            name: "ffmpeg_kit_flutter_new_full",
            dependencies: ffmpegLibs.map { .target(name: $0.name) } + [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_full")
            ]
        )
    ]
)
