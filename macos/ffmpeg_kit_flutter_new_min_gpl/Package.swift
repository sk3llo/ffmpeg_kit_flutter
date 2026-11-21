// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 9.1-beta.1 min-gpl prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "9.1-beta.1-min-gpl"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "6407fee3e1386a06e504406184f36a48d7e26f5625013c1acdc6b73ab846cd06"),
    ("libavcodec", "0ad05f4326668d7241b38b7b08a1cfaec4dfad48b92ce87cf9e01b6f7d29391e"),
    ("libavdevice", "99b611a4e017e8e7479c6620b2b552f5f40d3dd173af8a83222a5c22ae428c45"),
    ("libavfilter", "8b0871af7a91dd780edf394e1c273b7a334730ff330bc6fbed1e4e46a571b691"),
    ("libavformat", "37d405ff7560fed14044e1e83186718a45aedd3603fba29b98f9b5bd4ecf3136"),
    ("libavutil", "700fd120adfbeb2847eaf20e7e8da14d55b0d56c2454590e0dc62d06c18767f1"),
    ("libswresample", "93c1745f3e559b8e3a27420df3a997dd5c6ac8b442e3cd3f3d34cd476c450ebe"),
    ("libswscale", "be0f315f16d99231e4d4358429fe804f342acdefad779af167495841f3f4072b"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_min_gpl",
    platforms: [
        .macOS("11.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-min-gpl", targets: ["ffmpeg_kit_flutter_new_min_gpl"])
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
            name: "ffmpeg_kit_flutter_new_min_gpl",
            dependencies: ffmpegLibs.map { .target(name: $0.name) } + [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_min_gpl")
            ]
        )
    ]
)
