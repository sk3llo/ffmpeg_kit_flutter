// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 https-gpl prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64_arm64e,
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.2-https-gpl"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "9e10a85447aee51475dece42aa5a7697330206503155b745f312af84aa4e5846"),
    ("libavcodec", "4603adeaab038442ac67314b54303b52926fcdcef77cbf07bfa074ca7c4e4778"),
    ("libavdevice", "cde53f58f4fc98a098931049ea9a5bdf9cf55876e39602f7a697e8713db044f0"),
    ("libavfilter", "37748ec1cc86344fc8d62d1bfcbf4cc9d69c50dd9c3fac8a2515f1da9c96e9f3"),
    ("libavformat", "c952ef55a30cab349ab28362d21ae341bcfa62188918eaccfb2b389a987484f6"),
    ("libavutil", "64269da96fbdecd70908814122873ceabd4c340875fb7d8054cc5ba2da7ecfb8"),
    ("libswresample", "ee42188fb62b0e6bdd75d6834a409789edc90cb4725bcffbe3f3cd9259a8649c"),
    ("libswscale", "56f94c6036baccf80583d521a667c3cc14d562e316e3a65e09f28c13cdd73a9b"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_https_gpl",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-https-gpl", targets: ["ffmpeg_kit_flutter_new_https_gpl"])
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
            name: "ffmpeg_kit_flutter_new_https_gpl",
            dependencies: ffmpegLibs.map { .target(name: $0.name) },
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_https_gpl")
            ]
        )
    ]
)
