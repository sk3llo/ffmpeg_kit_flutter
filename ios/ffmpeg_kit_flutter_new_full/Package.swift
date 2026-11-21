// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 9.1-beta.1 full prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "9.1-beta.1-full"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "92cd2e6d44487bfd6eaf02a9ff076975e67970e1377968f5ac247b36482c8ffb"),
    ("libavcodec", "92aa5e9ff62e376642b740b02f593e673594d3ae461cf0d9222a8f7729d7b424"),
    ("libavdevice", "7ecc92dc8f5a09da1838db3b043a418bda09cdb287b29e9824a1c772aeff85cd"),
    ("libavfilter", "3f053750859a48d88e11350557efdff9d73a06a6b2ec50115a2adabda67274da"),
    ("libavformat", "84faa92ebd9e156bfa02f38a318f43db73fc01ccec70586e661d3923edb9994a"),
    ("libavutil", "f59242c197cb0b98a21541b6beced3a49d4683dc33f237b40ec36fab9585401e"),
    ("libswresample", "6672bc3213e99c9fc399439a1c82c110339b63ddb4bd864dd77e1becd48713eb"),
    ("libswscale", "43512f2fe3094e768b57719b5a2e4863840277b0ecdbd5bff0f633fc273f9ead"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_full",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-full", targets: ["ffmpeg_kit_flutter_new_full"])
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
            name: "ffmpeg_kit_flutter_new_full",
            dependencies: ffmpegLibs.map { .target(name: $0.name) } + [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_full")
            ]
        )
    ]
)
