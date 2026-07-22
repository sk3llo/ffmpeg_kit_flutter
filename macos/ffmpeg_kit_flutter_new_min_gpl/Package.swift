// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 min-gpl prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.2-min-gpl"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "75e4466decd57f882a04324a7cd43f8d1e390f614e16c74ece11099391e92c73"),
    ("libavcodec", "4032cc47e2e2a1fba5daa488d67232e7456881c64803a8ae0cbaeaaf05236005"),
    ("libavdevice", "d3938e2ffce751236b4ab1ca9a8970c548084e5c826767b9b71bc8079d165c07"),
    ("libavfilter", "e878c25bd15da2de89a41b1754c2ac7051290f3e4487912a47b0fba904f55398"),
    ("libavformat", "27978413383b1fce815fa8435f47e8a39ddaa8dbb0fb1b337586b7462fbd1466"),
    ("libavutil", "01bd48ea45b72acf0c66a7f4799f75fe635fe4f6e970a36928a1fce9b47e760e"),
    ("libswresample", "c7f41ca10172900f67a88bc6ccebdfb41066ad32d2f365d10ae876cc50c94d86"),
    ("libswscale", "b03eb0bb8f880f733e4b9ccf894cf4cce20b571e7942f851e3e12be0aefb2b95"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_min_gpl",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-min-gpl", targets: ["ffmpeg_kit_flutter_new_min_gpl"])
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
            name: "ffmpeg_kit_flutter_new_min_gpl",
            dependencies: ffmpegLibs.map { .target(name: $0.name) },
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_min_gpl")
            ]
        )
    ]
)
