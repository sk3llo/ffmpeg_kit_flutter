## 2.0.0-beta.1

* **FFmpeg 9.1, a new major version.** Every platform now ships FFmpeg n9.1 (was n8.1.3), with FFmpeg 9's multi-threaded `ffmpeg`. The Dart API is unchanged, but some commands behave differently: read [Migrating from 8.1](README.md#migrating-from-81) before upgrading. Android uses `com.antonkarpenko:ffmpeg-kit-converter-gpl:3.0.0-beta01`; the iOS, macOS, Linux and Windows binaries come from the `9.1-beta.1-converter-gpl` release.
* **HTTPS certificates are checked by default.** FFmpeg 9 verifies the server's certificate on every `https://` input and output. On iOS and macOS, FFmpegKit checks it against the system's trust store, including user- and MDM-installed certificates. Expired, self-signed and wrong-host certificates now fail; `-tls_verify 0` before an input's `-i` turns the check off for it.
* **Removed `ffmpeg` options:** `-vsync` (use `-fps_mode`), `-map_channel`, `-psnr`, `-top`, `-absf`, `-vbsf`, `-filter_script`, `-filter_complex_script`, `-qphist` and `-adrift_threshold`. `-copytb` is accepted but has no effect. The README lists their replacements.
* **Newer libraries:** GnuTLS 3.8.14, FreeType 2.15.0, HarfBuzz 15.2.0, OpenH264 2.7.0, snappy 1.3.1 and giflib 6.1.3, in the variants that include them.

## 1.0.0

* First release (#166). FFmpeg 8.1.3 with the encoders that converting between common audio and video formats needs: H.264 (x264), HEVC (x265), MP3 (LAME), Opus, Vorbis (libvorbis), VP8 and VP9 (libvpx) and WebP (libwebp), plus the dav1d AV1 decoder. Licensed GPL-3.0-or-later, like the other `-gpl` packages.
* The same Dart API as the other `ffmpeg_kit_flutter_new` packages, from the same source as `ffmpeg_kit_flutter_new` 5.0.0. Android API 24 and later (`com.antonkarpenko:ffmpeg-kit-converter-gpl:2.3.0`), iOS 15.0, macOS 11.0, Windows 10 (x86_64) and Linux (x86_64).
* Every download carries a `LICENSES/` folder whose `NOTICE.txt` lists FFmpeg, FFmpegKit and each library inside, with its version, licence and source. The iOS and macOS frameworks come with their dSYMs.
