// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.3 https-gpl prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.3-https-gpl"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "83cdb48e7fd6cc3a5dca9d752425de4c67c3ff7cabd03dd60fd537fbe49831e5"),
    ("libavcodec", "6679cce2a72ec230d9c11a277df81a7fa75dbdf906afcf4bb37e23dfa4c705d9"),
    ("libavdevice", "d1901b0812ffeb64d9b92d322744731cf9438f4f6a47185a9e0b3c35b6001525"),
    ("libavfilter", "6030f60e95fc11198860d11f9adb860f586aacd48be87778cbd81f4e04a3aeec"),
    ("libavformat", "bce16f836bc8a2a5ec8029fc16c6f3c395c9f0276efec3d87388b4376193d86c"),
    ("libavutil", "9b2d4442e4251d8553e9067a3c8cd8f949ef224df1f2653173e1399050646b93"),
    ("libswresample", "97292173919101503749c8dd7884e94fbac4ead77138915d677156f534859280"),
    ("libswscale", "1b253bc0fcb623838176de3b1929a16745345b11180e0f6b04d8db85422eb9dd"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_https_gpl",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-https-gpl", targets: ["ffmpeg_kit_flutter_new_https_gpl"])
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
            name: "ffmpeg_kit_flutter_new_https_gpl",
            dependencies: ffmpegLibs.map { .target(name: $0.name) } + [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_https_gpl")
            ]
        )
    ]
)
