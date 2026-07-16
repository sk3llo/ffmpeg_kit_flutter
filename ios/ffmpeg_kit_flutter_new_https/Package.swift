// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 https prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64_arm64e,
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.2-https"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "1cfea5c8682c875640ef855f2537883fc041dcdf043a130b2c0cc8e805fcead5"),
    ("libavcodec", "af7b23e0aa7a4b9ad224fae4e2530575bcabec71618adc286188670c8b8574a5"),
    ("libavdevice", "3490e4814c4ef73a2125d3eadf2869d46aab7a5ee6d606f1f913309f83869650"),
    ("libavfilter", "093e81d0a345bb5eeeb04e789dd4e07134493c53f6c097b157aba7d5339f6083"),
    ("libavformat", "3e748205606a2bad0f84134bd2706621b447d61f33d445bf8182c15caa2bc127"),
    ("libavutil", "f6aee08a372a75f38497f2760e828c22cbe33c1e1cc78a0acf771c2da95250b1"),
    ("libswresample", "d87515c8501d6b605eb49a60452f59f2dd11787a51ccdf3fd9d883be366dcb19"),
    ("libswscale", "a25db360720a88fbf4cb1dc7caf28d2998db7c81ecc238414f9267d356abcb82"),
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
