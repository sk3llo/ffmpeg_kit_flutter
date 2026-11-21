// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 9.1-beta.1 https-gpl prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "9.1-beta.1-https-gpl"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "6d380ff802e177910e80eec11d916d093c5ea89f0226a9b3ed2045557ac09a8e"),
    ("libavcodec", "ef224ba849786491ebcd5a5afea2f298e32f96ce557ee1e780a52bd6f0418b1e"),
    ("libavdevice", "0b6898b997f8e9774674d0a6088a75884c152f46fa37f1b929f13dff72867786"),
    ("libavfilter", "21f2a0e193e39fdd6467b94ef4ff587640967f63f153bc79362217406bbdd8b7"),
    ("libavformat", "766dd2ed8c7876275c92fe378fd28e32a663e8ab9cf61582d8ec3cd671d0e9a7"),
    ("libavutil", "b864cc10926f8992b6f690a796d0d134f73227389ae404024e9c7c099480b678"),
    ("libswresample", "9144a61b8ea18f1f26258994fa2ad38728c8a29ace47c9ebfca9afc53800bf06"),
    ("libswscale", "8320c0c722b61f825eb11dcdeac1501366e37a4212e8edc58081603371e61548"),
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
