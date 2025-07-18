package com.antonkarpenko.ffmpegkit;

import android.content.Context;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CameraMetadata;
import android.os.Build;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;

import static android.content.Context.CAMERA_SERVICE;
import static com.antonkarpenko.ffmpegkit.FFmpegKitConfig.TAG;

/**
 * <p>Helper class to detect camera devices that can be used in
 * <code>FFmpeg</code>/<code>FFprobe</code> commands.
 */
class CameraSupport {

    /**
     * <p>Lists camera ids that can be used in <code>FFmpeg</code>/<code>FFprobe</code> commands.
     *
     * @param context application context
     * @return the list of supported camera ids on Android API Level 24+, an empty list on older
     * API levels
     */
    static List<String> extractSupportedCameraIds(final Context context) {
        final List<String> detectedCameraIdList = new ArrayList<>();

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                final CameraManager manager = (CameraManager) context.getSystemService(CAMERA_SERVICE);
                if (manager != null) {
                    final String[] cameraIdList = manager.getCameraIdList();

                    for (String cameraId : cameraIdList) {
                        final CameraCharacteristics chars = manager.getCameraCharacteristics(cameraId);
                        final Integer cameraSupport = chars.get(CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL);

                        if (cameraSupport != null && cameraSupport == CameraMetadata.INFO_SUPPORTED_HARDWARE_LEVEL_LEGACY) {
                            Log.d(TAG, "Detected camera with id " + cameraId + " has LEGACY hardware level which is not supported by Android Camera2 NDK API.");
                        } else if (cameraSupport != null) {
                            detectedCameraIdList.add(cameraId);
                        }
                    }
                }
            } catch (final CameraAccessException e) {
                Log.w(TAG, "Detecting camera ids failed.", e);
            }
        }

        return detectedCameraIdList;
    }

}
