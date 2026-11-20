// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.3 video prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.3-video"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "e4559f41ed2630be0fe54b36198d46e31e900ff883377df1ccd55b0f5bdc3757"),
    ("libavcodec", "c85689bff534626e2cedf95287e68176cf13223521c138da4b2d3a125f478c65"),
    ("libavdevice", "19f989b915da908f26907135c9896833f39aee4f279c95e31b4189438a2865d8"),
    ("libavfilter", "f1d544489014221518fe2928d98e793404b3b43248943cae9c0edd33b7c7e687"),
    ("libavformat", "e40715eb014d17043c8d7a7c9fd016eb2b243d6f1c46b7a0545b59c0f390ed5e"),
    ("libavutil", "52b763f8735309d7f8f06426aed26b2c345a90b007d3ae22e7421fe832a5dc26"),
    ("libswresample", "379a06308c1dd3cc71d9995f5ca3686954635a3f7dab25bfedb509f595d7f5dd"),
    ("libswscale", "f5da3db9bc23c3a6cfc0c73c1a19af60fc2e1faecce9e19617cc15971bee312a"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_video",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-video", targets: ["ffmpeg_kit_flutter_new_video"])
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
            name: "ffmpeg_kit_flutter_new_video",
            dependencies: ffmpegLibs.map { .target(name: $0.name) } + [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_video")
            ]
        )
    ]
)
