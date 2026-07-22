// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 video prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.2-video"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "e63f65fb1757c52d15f95c22de1c8477ad1cf4f7176aac3b38816e0f7988663f"),
    ("libavcodec", "626c3594746783a0d32627ef160c6b54c78fe8dc4fc7c1ef0cfc3dd008199338"),
    ("libavdevice", "dce7aef70588acd52e0dcc2a39296feac44389c2817636c3c4f0b9945a78e232"),
    ("libavfilter", "20fc5d65b3f4a1cb07584645d4dce954384ffa7a91f5bc569096cbadc24474c6"),
    ("libavformat", "8dcad3395de9abb223ddf12b1a2e09b2c89402245938611fcd33573926e684ca"),
    ("libavutil", "86f98c24981ab2b34801ca1a453e5f780041d4153f7b82f0e8baeafd7f192e8f"),
    ("libswresample", "a3752c3c955bf0534401ad30df0a9f03152ef0e259c27fcdd97efdc2b5b6b861"),
    ("libswscale", "f7daa92bc54278c7f89e41f95c7c62d3d60ca7790c272b18f55a6c494dc23e1a"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_video",
    platforms: [
        .iOS("14.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-video", targets: ["ffmpeg_kit_flutter_new_video"])
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
            name: "ffmpeg_kit_flutter_new_video",
            dependencies: ffmpegLibs.map { .target(name: $0.name) },
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_video")
            ]
        )
    ]
)
