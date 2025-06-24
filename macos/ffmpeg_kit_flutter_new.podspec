Pod::Spec.new do |s|
  s.name             = 'ffmpeg_kit_flutter_new'
  s.version          = '1.0.0'
  s.summary          = 'FFmpeg Kit for Flutter with Hardware Acceleration'
  s.description      = 'A Flutter plugin for running FFmpeg and FFprobe commands with VideoToolbox support.'
  s.homepage         = 'https://github.com/sk3llo/ffmpeg_kit_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ARTHENICA' => 'open-source@arthenica.com' }

  s.platform            = :osx
  s.requires_arc        = true
  s.static_framework    = true

  s.source              = { :path => '.' }
  s.source_files        = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.default_subspec     = 'full-gpl'

  s.dependency          'FlutterMacOS'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.subspec 'min' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-min', "6.0"
    ss.osx.deployment_target = '10.15'
  end

  s.subspec 'min-lts' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-min', "6.0.LTS"
    ss.osx.deployment_target = '10.12'
  end

  s.subspec 'min-gpl' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-min-gpl', "6.0"
    ss.osx.deployment_target = '10.15'
  end

  s.subspec 'min-gpl-lts' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-min-gpl', "6.0.LTS"
    ss.osx.deployment_target = '10.12'
  end

  s.subspec 'https' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-https', "6.0"
    ss.osx.deployment_target = '10.15'
  end

  s.subspec 'https-lts' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-https', "6.0.LTS"
    ss.osx.deployment_target = '10.12'
  end

  s.subspec 'https-gpl' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-https-gpl', "6.0"
    ss.osx.deployment_target = '10.15'
  end

  s.subspec 'https-gpl-lts' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-https-gpl', "6.0.LTS"
    ss.osx.deployment_target = '10.12'
  end

  s.subspec 'audio' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-audio', "6.0"
    ss.osx.deployment_target = '10.15'
  end

  s.subspec 'audio-lts' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-audio', "6.0.LTS"
    ss.osx.deployment_target = '10.12'
  end

  s.subspec 'video' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-video', "6.0"
    ss.osx.deployment_target = '10.15'
  end

  s.subspec 'video-lts' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-video', "6.0.LTS"
    ss.osx.deployment_target = '10.12'
  end

  s.subspec 'full' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-full', "6.0"
    ss.osx.deployment_target = '10.15'
  end

  s.subspec 'full-lts' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-full', "6.0.LTS"
    ss.osx.deployment_target = '10.12'
  end

  s.subspec 'full-gpl' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.osx.vendored_frameworks = 'Frameworks/ffmpeg-kit-macos-full-gpl/ffmpegkit.framework',
                                 'Frameworks/ffmpeg-kit-macos-full-gpl/libavcodec.framework',
                                 'Frameworks/ffmpeg-kit-macos-full-gpl/libavdevice.framework',
                                 'Frameworks/ffmpeg-kit-macos-full-gpl/libavfilter.framework',
                                 'Frameworks/ffmpeg-kit-macos-full-gpl/libavformat.framework',
                                 'Frameworks/ffmpeg-kit-macos-full-gpl/libavutil.framework',
                                 'Frameworks/ffmpeg-kit-macos-full-gpl/libswresample.framework',
                                 'Frameworks/ffmpeg-kit-macos-full-gpl/libswscale.framework'

    # VideoToolbox support
    ss.osx.frameworks = 'AudioToolbox', 'CoreMedia', 'VideoToolbox', 'CoreVideo'
    ss.libraries = 'z', 'bz2', 'c++', 'iconv'
    ss.osx.deployment_target = '10.15' # Adjust as needed for macOS

    # Enable VideoToolbox features
    ss.pod_target_xcconfig = {
      'OTHER_CFLAGS' => '-DHAVE_VIDEOTOOLBOX=1',
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) HAVE_VIDEOTOOLBOX=1'
    }

    # Adding pre-install hook for macOS
    s.prepare_command = <<-CMD
      if [ ! -d "./Frameworks" ]; then
        chmod +x ../scripts/setup_macos.sh
        ../scripts/setup_macos.sh
      fi
    CMD
  end

  s.subspec 'full-gpl-lts' do |ss|
    ss.source_files         = 'Classes/**/*'
    ss.public_header_files  = 'Classes/**/*.h'
    ss.dependency 'ffmpeg-kit-macos-full-gpl', "6.0.LTS"
    ss.osx.deployment_target = '10.12'
  end

end
