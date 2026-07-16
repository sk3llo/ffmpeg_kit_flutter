Pod::Spec.new do |s|
  s.name             = 'ffmpeg_kit_flutter_new_video'
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
  s.source_files        = 'ffmpeg_kit_flutter_new_video/Sources/ffmpeg_kit_flutter_new_video/**/*.{h,m}'
  s.public_header_files = 'ffmpeg_kit_flutter_new_video/Sources/ffmpeg_kit_flutter_new_video/include/**/*.h'

  s.default_subspec     = 'video'

  s.dependency          'FlutterMacOS'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.subspec 'video' do |ss|
    ss.source_files         = 'ffmpeg_kit_flutter_new_video/Sources/ffmpeg_kit_flutter_new_video/**/*.{h,m}'
    ss.public_header_files  = 'ffmpeg_kit_flutter_new_video/Sources/ffmpeg_kit_flutter_new_video/include/**/*.h'
    ss.osx.vendored_frameworks = 'Frameworks/ffmpegkit.framework',
                                 'Frameworks/libavcodec.framework',
                                 'Frameworks/libavdevice.framework',
                                 'Frameworks/libavfilter.framework',
                                 'Frameworks/libavformat.framework',
                                 'Frameworks/libavutil.framework',
                                 'Frameworks/libswresample.framework',
                                 'Frameworks/libswscale.framework'
    ss.osx.deployment_target = '10.15'

    # Adding pre-install hook for macOS
    s.prepare_command = <<-CMD
      if [ ! -d "./Frameworks/ffmpegkit.framework" ]; then
        chmod +x ../scripts/setup_macos.sh
        ../scripts/setup_macos.sh
      fi
    CMD
  end
end
