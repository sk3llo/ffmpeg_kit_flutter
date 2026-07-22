// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 https prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.2-https"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "96b8e0fdb9904e1433e436393318d490a28bdf0d37e4f2679e4d022772584f76"),
    ("libavcodec", "8e121c6cba47851baa7d4dc047c763c2d2e9dc51caa76d6b109fa8cc2369d7b6"),
    ("libavdevice", "91a14a0ccd305221788723bfb6d2f441972f0f4b672a80a2efb495286e080704"),
    ("libavfilter", "a2a48ed6d5aa1c1cf996bd4b838a4d62b18c5cc87b1b312ce22d5fcd828a00f5"),
    ("libavformat", "23b4128c7bdde73c66cd5d5d211b563e6a228414c8edff4cfd04444535f36597"),
    ("libavutil", "6ffda916f89135a77a84cf34766a6e598c7e681bfb63e1788218842a61a7b980"),
    ("libswresample", "52d6c3de7a4f1f05198d19ed887febcab9bdbd352dae019bb00b498ae06eb2ae"),
    ("libswscale", "b6ee65b6d7df12325ee62bb7b2ebd2f62097817aac8c13fffb10b3159b8d4227"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_https",
    platforms: [
        .iOS("14.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-https", targets: ["ffmpeg_kit_flutter_new_https"])
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
            name: "ffmpeg_kit_flutter_new_https",
            dependencies: ffmpegLibs.map { .target(name: $0.name) },
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_https")
            ]
        )
    ]
)
