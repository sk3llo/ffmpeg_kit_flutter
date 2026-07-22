// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 audio prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.2-audio"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "122f9165b9c4dafdf64d4167d754b803c90ada4b17a285d4e17493b9c5618780"),
    ("libavcodec", "17af32fb8b4a476262c4d2174adbe75abce11e6a4a09cfc288de7e9ccde15d3c"),
    ("libavdevice", "c1ef46493cc78b348e00ba334e6b57a66f0e5d09e5743611ce1baf4ae06a76bb"),
    ("libavfilter", "91ac817bc2e411cc53199ca75e829aa674ccf1d61a38d6b9a44edac408b73f9d"),
    ("libavformat", "3f538c4351584d511efa295e2ce697af1cdf9fafd44cf9bdba0fd818fdea09d4"),
    ("libavutil", "e5dfcdbd0b718aa8ae392a07762bca6fe381de9c4c5cdf95c3d7bf6eff10e628"),
    ("libswresample", "08518579265217dc93e7c369fe7542cc6f5b1ca9a709f1b86aa8f3ed1cfee288"),
    ("libswscale", "8c5ca6c09efd2829aa3d6ad0d654ecdc2922f52ff4c51ef658f712d70022611d"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_audio",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-audio", targets: ["ffmpeg_kit_flutter_new_audio"])
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
            name: "ffmpeg_kit_flutter_new_audio",
            dependencies: ffmpegLibs.map { .target(name: $0.name) },
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_audio")
            ]
        )
    ]
)
