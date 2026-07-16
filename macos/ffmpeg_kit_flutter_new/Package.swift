// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 full-gpl prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64_arm64e,
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release.
let ffmpegTag = "8.1.2-full-gpl"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "0e4851acd5fba57511e4eb16d54b5c6c583307c45895992bd829eca09ec066f1"),
    ("libavcodec", "30e0d1d93c320f07d5e9e6c89b89c8d5cb381a8c9703a689bbf28041839695fa"),
    ("libavdevice", "b8f063cd38f5f431f7d00de63251a340a948d1e42c82be5e4b044b636c99ef51"),
    ("libavfilter", "cbba6728c64002791708daf06ed2e9758e4695d426e4c2428f417c5eaac889be"),
    ("libavformat", "3718358f7f43bf9469178df8392f54459769356618cd2134c1574f59fe8b2204"),
    ("libavutil", "d3df656a0d8232c2360e1676465e8f82b14b5dca43e58569621c9bc35aaff2fe"),
    ("libswresample", "85ffc0b7e41e424354f7dfd930fa6c808ddf4465367dfaf0c453e689a6620fe4"),
    ("libswscale", "97aec54519fb6bbd76af6684cde65e1586186122f8ed72aff648d32cbcd04404"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new", targets: ["ffmpeg_kit_flutter_new"])
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
            name: "ffmpeg_kit_flutter_new",
            dependencies: ffmpegLibs.map { .target(name: $0.name) },
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new")
            ]
        )
    ]
)
