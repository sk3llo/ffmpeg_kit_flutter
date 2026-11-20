// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.3 full-gpl prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release.
let ffmpegTag = "8.1.3-full-gpl"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "cf7d9f1da5380d9c0e7da5e5c3bd7e3ca8b2764bb9555e427f3cd3235b1b8de0"),
    ("libavcodec", "99aeb1ee00c98ed196752adca3cbbd5f0f40cffb0ae5555ec3e018970a3f2c52"),
    ("libavdevice", "f0d5fc347331d770721b3d7630913f9e2b8ce6a34018cae2e3d5cc3af4349e03"),
    ("libavfilter", "5e8560530e478e030d7126e25b3cd8685ff04de88ccf8d05588ab1593d3d6f88"),
    ("libavformat", "815fa6fa69d7732ec1227aca544217b648e5be5f9486152f18c36c528510d16a"),
    ("libavutil", "2d4672d2be6052f4415bb953fdc8dabe515b795f6fbe00dce10df9ac85d7d189"),
    ("libswresample", "d1da48f1c2e8a9894997384fe4076ca04bb52e2298734ba54cafbf4c15fef357"),
    ("libswscale", "5aa9b7b3194a4982a778a672c5b7b986c3e54c9dbc004cf87f7d321ec40f6e19"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new", targets: ["ffmpeg_kit_flutter_new"])
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
            name: "ffmpeg_kit_flutter_new",
            dependencies: ffmpegLibs.map { .target(name: $0.name) } + [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new")
            ]
        )
    ]
)
