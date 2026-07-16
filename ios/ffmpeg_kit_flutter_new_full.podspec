Pod::Spec.new do |s|
  s.name             = 'ffmpeg_kit_flutter_new_full'
  s.version          = '8.1.2'
  s.summary          = 'FFmpeg Kit for Flutter'
  s.description      = 'A Flutter plugin for running FFmpeg and FFprobe commands.'
  s.homepage         = 'https://github.com/sk3llo/ffmpeg_kit_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Anton Karpenko' => 'kapraton@gmail.com' }

  s.platform            = :ios
  s.requires_arc        = true
  s.static_framework    = true

  s.source              = { :path => '.' }
  s.source_files        = 'ffmpeg_kit_flutter_new_full/Sources/ffmpeg_kit_flutter_new_full/**/*.{h,m}'
  s.public_header_files = 'ffmpeg_kit_flutter_new_full/Sources/ffmpeg_kit_flutter_new_full/include/**/*.h'

  s.default_subspec = 'full'

  s.dependency          'Flutter'
  # The vendored xcframeworks ship a native arm64 iOS-simulator slice, so arm64
  # must NOT be excluded for the simulator (required by Apple Silicon / Xcode 26+).
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }

  s.subspec 'full' do |ss|
    # Guard on the actual xcframework, not just the ./Frameworks directory: a
    # failed/interrupted download used to leave an empty ./Frameworks behind,
    # which made every subsequent `pod install` skip setup and fail the build
    # with "'ffmpegkit/FFmpegKitConfig.h' file not found" (issue #88). setup_ios.sh
    # now installs atomically and re-runs until the frameworks are really there.
    s.prepare_command = <<-CMD
      if [ ! -d "./Frameworks/ffmpegkit.xcframework" ]; then
        chmod +x ../scripts/setup_ios.sh
        ../scripts/setup_ios.sh
      fi
    CMD
    ss.source_files         = 'ffmpeg_kit_flutter_new_full/Sources/ffmpeg_kit_flutter_new_full/**/*.{h,m}'
    ss.public_header_files  = 'ffmpeg_kit_flutter_new_full/Sources/ffmpeg_kit_flutter_new_full/include/**/*.h'
    ss.ios.vendored_frameworks = 'Frameworks/ffmpegkit.xcframework',
                                 'Frameworks/libavcodec.xcframework',
                                 'Frameworks/libavdevice.xcframework',
                                 'Frameworks/libavfilter.xcframework',
                                 'Frameworks/libavformat.xcframework',
                                 'Frameworks/libavutil.xcframework',
                                 'Frameworks/libswresample.xcframework',
                                 'Frameworks/libswscale.xcframework'
    ss.ios.deployment_target = '14.0'
  end
end
