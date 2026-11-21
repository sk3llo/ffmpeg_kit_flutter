// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 9.1-beta.1 converter-gpl prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices, each with its dSYM.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "9.1-beta.1-converter-gpl"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "9c8722cf72fdf40d657698c12981ef112eb59dd0a2912813569bd6f59d989dd1"),
    ("libavcodec", "92dca6f215db99be72c4d812748a7ffe39c95d887035c16d687f4eea8c555b60"),
    ("libavdevice", "41e344a064508602160a0c644434e663bf524c7835ad5fcd84335f15817800ca"),
    ("libavfilter", "6cada6c2bd8cc0b9535bd2fad502962ec01513d1b8f609f2faff33282c87e594"),
    ("libavformat", "a28be83c54b1dce66887d1e550a8ec8ba3d861398252700b5515b2884a737b57"),
    ("libavutil", "c3e0336f5f72bdba7577e264a278eb1d39710485e37fb443977b652f785866a1"),
    ("libswresample", "0406fba0ac788cf7fa2f1815a7b04f8a9b226052152cd6c7978cca5245da6304"),
    ("libswscale", "9d00755d23df7ed8fe6583c6331f156fa68fef645ab1f41d0e781e3e9cba50f1"),
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
