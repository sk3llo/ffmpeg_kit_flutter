// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// FFmpeg 8.1.2 https-gpl prebuilt binaries.
// Each zip contains one combined XCFramework with ios-arm64 (arm64e dropped, #164),
// ios-arm64_x86_64-simulator and macos-arm64_x86_64 slices.
// URLs and checksums are regenerated on every native FFmpeg release
// (see scripts/build_spm_artifacts.sh).
let ffmpegTag = "8.1.2-https-gpl"
let ffmpegBase = "https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/\(ffmpegTag)"
let ffmpegLibs: [(name: String, checksum: String)] = [
    ("ffmpegkit", "075f6a2d102c668311f8a9c58bb351e3f38aa90c7abb4f130fbb8f59a20aa2f7"),
    ("libavcodec", "dc8e7e340ae683cf4215fcc7661bb4314b028b7441b658d1adcfd6ee0f15960e"),
    ("libavdevice", "54e1fd05ab7f2c3bb1523f3b02b650f587091866227be2a537054bebdeb4ed5f"),
    ("libavfilter", "8418b040f2161c8a6d0d54462737370d4ff44cabf161d35fed0c80248c0aa19c"),
    ("libavformat", "daa5a6bf0e4164c517a35598413948282b1e5153600daa5f00b9334ec9674138"),
    ("libavutil", "88bea70eeca849356d74c2744390aaa02ee50bf4924c958e08ac11016d5fb01b"),
    ("libswresample", "7fe7119378ca3ac9c31964aaa00e67ea9d61418cf472814808b99a510ce434ab"),
    ("libswscale", "3ec71939ac96e9717ee66db0dd7478db650238a0c40f42541d247c9099def670"),
]

let package = Package(
    name: "ffmpeg_kit_flutter_new_https_gpl",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "ffmpeg-kit-flutter-new-https-gpl", targets: ["ffmpeg_kit_flutter_new_https_gpl"])
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
            name: "ffmpeg_kit_flutter_new_https_gpl",
            dependencies: ffmpegLibs.map { .target(name: $0.name) },
            cSettings: [
                .headerSearchPath("include/ffmpeg_kit_flutter_new_https_gpl")
            ]
        )
    ]
)
