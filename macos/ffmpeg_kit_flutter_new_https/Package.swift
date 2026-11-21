// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 9.1-beta.1 https prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "9.1-beta.1-https"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "9b1a44ab3d89df9e0a77d152f9cdb64c09b399d20b646eb6d76560b90ee09ad5"),
    ("libavcodec", "dae5b958ecba9438e7ed8c034c27147158b09724a75d7c4f65fc357e8bbb7295"),
    ("libavdevice", "b8046de7618f5ab028d0c45af02694dabe572ed70534cb405996759b1f3b5846"),
    ("libavfilter", "ff8bc2b4e316196b2f27f26f6c5cc077a1616fd0ef1ee8a1c2a91e4507e0c985"),
    ("libavformat", "418558bf65107227e2450ea978d5fc0a45efe835d4d005db30444fd09a60f2f7"),
    ("libavutil", "560b46564f5d9fb8b4aff75a3ebc9b3d3c1fb3db51761d393d7b15d12b33709b"),
    ("libswresample", "dca8bf29449e4d1b472db0c062a335f339efe319731593797b9c2b93e906d57e"),
    ("libswscale", "48cf2c742b3af2f3ce0495e18d3968cd9765d66626f21c21dc85162012aed807"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_https",
    platforms: [
        .macOS("11.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-https", targets: ["ffmpeg_kit_flutter_new_https"])
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
            name: "ffmpeg_kit_flutter_new_https",
            dependencies: ffmpegLibs.map { .target(name: $0.name) } + [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_https")
            ]
        )
    ]
)
