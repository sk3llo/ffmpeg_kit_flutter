// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 video prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64_arm64e,
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.2-video"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "75c358658aed92f71cb214404209cc148ce72ea8a19d35c9d7b09198f54d91a3"),
    ("libavcodec", "8afe508b363667b749d6f2e3af9ff873b9174120d20af988cce7669a908669f7"),
    ("libavdevice", "7eb1707c62c3ca16d870a3af4150f3e5ae5974507eb37f325d31d6c37d95e87e"),
    ("libavfilter", "c886fd0b5615d9bddbc31ab91e36fbba0988f9164b542cd370bc902b02628afd"),
    ("libavformat", "9f097e9eb20d2d45db258ae80216735d9c5420deedfc11f2375547313e94d92d"),
    ("libavutil", "fba49411c375af1ecaa581893ad564483d2bbc8a0523df0596ec581dc568a5ae"),
    ("libswresample", "341a969606afeb2e5e58eb62eaa931c5156116b0e5ad54c51f39246c1a263677"),
    ("libswscale", "ed41cdd6e45c4148ef97e99c7e097a2a85e4794cd025c4c9037dda3720e7ba82"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_video",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-video", targets: ["ffmpeg_kit_flutter_new_video"])
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
            name: "ffmpeg_kit_flutter_new_video",
            dependencies: ffmpegLibs.map { .target(name: $0.name) },
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_video")
            ]
        )
    ]
)
