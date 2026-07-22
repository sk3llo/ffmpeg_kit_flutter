// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 full-gpl prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release.
let ffmpegTag = "8.1.2-full-gpl"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "60e210bd61861b67c089d6713b3534cc3cddba2d4f30992e16681dbc93cea49f"),
    ("libavcodec", "36dfe499c61a0b63147a1d7cf92a5cec9959e6bbc1d8dc15fa2e79b1f9877bfb"),
    ("libavdevice", "2e23968b444072da40c90d5126e9567cb8504906a8bae014c0de6e795295b7bc"),
    ("libavfilter", "c1af1c1e1bf154550af7a00ef41b6e7de840890319ca2d1997b9f25de01d7b8c"),
    ("libavformat", "5efbdf6ba4dafc61745ca0903a027dea7c34e798f30f70c6700dd7012ab0b8fe"),
    ("libavutil", "6c2f2b343197628ecc0342b096b8b5ae1a81f93e30103fc941ce0647c87d688d"),
    ("libswresample", "839073c6fc2b168dbb57528c451036096ca66e11f52d35ab663266d5b64abe46"),
    ("libswscale", "4e99f0a3332c452402ce93e4fd6bd7b34727d229c37f71f2ddb33e10dbfa760b"),
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
