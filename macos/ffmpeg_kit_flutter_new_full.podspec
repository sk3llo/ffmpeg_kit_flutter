Pod::Spec.new do |s|
  s.name             = 'ffmpeg_kit_flutter_new_full'
  s.version          = '8.1.2'
  s.summary          = 'FFmpeg Kit for Flutter'
  s.description      = 'A Flutter plugin for running FFmpeg and FFprobe commands.'
  s.homepage         = 'https://github.com/sk3llo/ffmpeg_kit_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Anton Karpenko' => 'kapraton@gmail.com' }

  s.platform            = :osx
  s.requires_arc        = true
  s.static_framework    = true

  s.source              = { :path => '.' }
  s.source_files        = 'ffmpeg_kit_flutter_new_full/Sources/ffmpeg_kit_flutter_new_full/**/*.{h,m}'
  s.public_header_files = 'ffmpeg_kit_flutter_new_full/Sources/ffmpeg_kit_flutter_new_full/include/**/*.h'

  s.default_subspec     = 'full'

  s.dependency          'FlutterMacOS'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.subspec 'full' do |ss|
    ss.source_files         = 'ffmpeg_kit_flutter_new_full/Sources/ffmpeg_kit_flutter_new_full/**/*.{h,m}'
    ss.public_header_files  = 'ffmpeg_kit_flutter_new_full/Sources/ffmpeg_kit_flutter_new_full/include/**/*.h'
    ss.osx.vendored_frameworks = 'Frameworks/ffmpegkit.framework',
                                 'Frameworks/libavcodec.framework',
                                 'Frameworks/libavdevice.framework',
                                 'Frameworks/libavfilter.framework',
                                 'Frameworks/libavformat.framework',
                                 'Frameworks/libavutil.framework',
                                 'Frameworks/libswresample.framework',
                                 'Frameworks/libswscale.framework'
    ss.osx.deployment_target = '10.15'

    # Guard on the actual framework, not just the ./Frameworks directory, so a
    # failed download can never leave a broken empty dir that makes future
    # `pod install`s skip setup (see issue #88). setup_macos.sh installs
    # atomically and re-runs until the frameworks are really present.
    s.prepare_command = <<-CMD
      if [ ! -d "./Frameworks/ffmpegkit.framework" ]; then
        chmod +x ../scripts/setup_macos.sh
        ../scripts/setup_macos.sh
      fi
    CMD
  end
end
