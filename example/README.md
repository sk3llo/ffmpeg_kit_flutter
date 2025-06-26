# example

FFMPEG example

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## How to run on iOS

If you see an error like `'ffmpegkit/FFmpegKitConfig.h' file not found` when building for iOS, it means the required FFmpegKit frameworks have not been downloaded yet. This is expected, as the frameworks are not included in the repository and are downloaded automatically by a setup script.

### Steps to fix:

1. **Install CocoaPods dependencies:**

   ```sh
   cd ios
   pod install
   ```

2. **If you still get the `'ffmpegkit/FFmpegKitConfig.h' file not found` error, run the setup script manually:**

   ```sh
   cd ../../ios
   chmod +x ../scripts/setup_ios.sh
   ../scripts/setup_ios.sh
   ```

3. **Reinstall CocoaPods dependencies:**

   ```sh
   cd ../example/ios
   pod install
   ```

4. **Now you can run the example app on the iOS simulator:**

   ```sh
   cd ..
   flutter run -d <your_simulator_id>
   ```

---

**Note:**  
- The `Frameworks` folder is intentionally not included in the repository. It is generated automatically by the setup script.  
- Make sure you have CocoaPods installed and up to date.  
- If you have any issues, make sure you are running these commands from the correct directories.
