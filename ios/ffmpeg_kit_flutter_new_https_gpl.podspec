Pod::Spec.new do |s|
  s.name             = 'ffmpeg_kit_flutter_new_https_gpl'
  s.version          = '7.1.1'
  s.summary          = 'FFmpeg Kit for Flutter'
  s.description      = 'A Flutter plugin for running FFmpeg and FFprobe commands.'
  s.homepage         = 'https://github.com/sk3llo/ffmpeg_kit_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Anton Karpenko' => 'kapraton@gmail.com' }

  s.platform            = :ios
  s.requires_arc        = true
  s.static_framework    = true

  s.source              = { :path => '.' }
  s.source_files        = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.default_subspec = 'https_gpl'

  s.dependency          'Flutter'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 arm64' }

  s.subspec 'https_gpl' do |ss|
    s.prepare_command = <<-CMD
      if [ ! -d "./Frameworks" ]; then
        chmod +x ../scripts/setup_ios.sh
        ../scripts/setup_ios.sh
        fi
    CMD
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.ios.vendored_frameworks = 'Frameworks/ffmpegkit.framework',
                                 'Frameworks/libavcodec.framework',
                                 'Frameworks/libavdevice.framework',
                                 'Frameworks/libavfilter.framework',
                                 'Frameworks/libavformat.framework',
                                 'Frameworks/libavutil.framework',
                                 'Frameworks/libswresample.framework',
                                 'Frameworks/libswscale.framework'
    ss.ios.deployment_target = '14.0'
  end
end
