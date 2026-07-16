// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 min-gpl prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64_arm64e,
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.2-min-gpl"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "d912b664e5ac8d23062e41d5356ae428dd581e7dc55069ec5ef71ea39ad9b934"),
    ("libavcodec", "eb17fae9e018157585f908c81ee3545d14ff624a072f5cd12a0f972126449f3c"),
    ("libavdevice", "3bbca3993bfc02e52e912f74c03f9b38cc7173e17ca4581cbd622cd7bd5d2642"),
    ("libavfilter", "ae60dfb3f1a2a4e3b1dcd3b25d23d9596d56ba8bb9b5171efead5b903b11bb53"),
    ("libavformat", "1eecd1ba124a406ec11150fe50b7cb02451a4679ff42e3869cb5f8443249044b"),
    ("libavutil", "7a85ab557e4292c05ae4f5794ba9c8216fee8552306c67b6ff7f01f30bbf0985"),
    ("libswresample", "12ae39b2be7f8becdd5c8f91a1dd28341edfcbcf433eee2610b7abf0eaa2011d"),
    ("libswscale", "0d3b087c20b2da469e6bf179f47304d6437ae918f2d087291de05a02878741e2"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_min_gpl",
    platforms: [
        .iOS("14.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-min-gpl", targets: ["ffmpeg_kit_flutter_new_min_gpl"])
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
            name: "ffmpeg_kit_flutter_new_min_gpl",
            dependencies: ffmpegLibs.map { .target(name: $0.name) },
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_min_gpl")
            ]
        )
    ]
)
