// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.3 https prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.3-https"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "2c91e2e11ebc2bfa5b615238cbfa2726a9420a60b0b68e2341dbb3b0de23ea2d"),
    ("libavcodec", "56391b69f19e13cd5778b4a5202cffd8d61a2f69115a27203d4b64d7e12d73bd"),
    ("libavdevice", "5e21b025825b14511d1f671276db667abaa214eb894435239b9694d35789cc55"),
    ("libavfilter", "ef74bef9a75d62f5683cf4a4b7b0ae20b0123c2959b70ff6660114c8254667d9"),
    ("libavformat", "0e8c5bb3fa5629a2ef8e9fe6832c55ea665ed12c73ebc6a320a4f42974b1e745"),
    ("libavutil", "049904de88dc484889b5d3650d522ebcbfe8f7a4a2270883f6e5bc8834733442"),
    ("libswresample", "c407eb23a827986999cf11c463801990bee1af355ee3afdb28a477c1361dce62"),
    ("libswscale", "6ac452dbc8480663738555dd10580437cbc479a35abdba6a8f533c97387d3baf"),
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
