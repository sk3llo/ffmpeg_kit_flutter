// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 full prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.2-full"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "a565f36d1d6769523fe78aee3c015212ea7f9b1fc1007bea21e46c1d6df06bde"),
    ("libavcodec", "eb56ac124c03ebd4c91584b86fe3c6d758ed1cff1cf475cc6bca319f0f7c8106"),
    ("libavdevice", "0f1f06f636beb75936e5f840f81ec15966fb1dfaff14f78cb83bdbcc3422bb89"),
    ("libavfilter", "50eb73ebe41724444b8256c2c61541ced3fda7b2e1b20aac2f928fb2bf2d0ac6"),
    ("libavformat", "e9f08440c7e0aa3fba67e1f9f1f4c06a6fb2b9da557953fd086b2343dda6b31a"),
    ("libavutil", "70d35584a0ee9282bdbb6b02f3ce806f6ceb27b81cf148905642b468a40bfec6"),
    ("libswresample", "df15ca091b005cc984f644c68d6617ac6b9588992fa8387bb068c4f1c8a6d0be"),
    ("libswscale", "2570aab53ad07282e3539dff906d73a9c801589b1d3b33870df0ccbe892c4b07"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_full",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-full", targets: ["ffmpeg_kit_flutter_new_full"])
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
            name: "ffmpeg_kit_flutter_new_full",
            dependencies: ffmpegLibs.map { .target(name: $0.name) },
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_full")
            ]
        )
    ]
)
