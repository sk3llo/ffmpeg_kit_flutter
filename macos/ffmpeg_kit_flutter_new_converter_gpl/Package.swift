// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.3 converter-gpl prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.3-converter-gpl"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "009afd507a02502b345030d5d195eb4d3089597783dc195f6a1da55213dbf242"),
    ("libavcodec", "a00ee307df8e01fafcd6ab871d6393c5123fefc8cd21899a35289b0c5428f73c"),
    ("libavdevice", "39dca96c9c8e93a9afa9cf7f134450197dec993fa20f8cce07160cfd2a720bb6"),
    ("libavfilter", "26ee64303aff7fc79496036baab5956ac9ce88efa858507d37dd37df7f88d43f"),
    ("libavformat", "284aa88629be68f9fa3ef96d59cf51657ff0fc4a863bec2d962905b1f46c1322"),
    ("libavutil", "4914f540c6ae42524484a2f62624296ad5c14da5caf3d82b7b2c816c6abc9aed"),
    ("libswresample", "add1ad3979355659ab33c0778cb975b365e9da91aeaa8fc55ff7c86d9de0c931"),
    ("libswscale", "1dd6efc3870d13639c0469c7a0203313ab40014920f609b07677f5a84ecc69b7"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_converter_gpl",
    platforms: [
        .macOS("11.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-converter-gpl", targets: ["ffmpeg_kit_flutter_new_converter_gpl"])
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
            name: "ffmpeg_kit_flutter_new_converter_gpl",
            dependencies: ffmpegLibs.map { .target(name: $0.name) } + [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_converter_gpl")
            ]
        )
    ]
)
