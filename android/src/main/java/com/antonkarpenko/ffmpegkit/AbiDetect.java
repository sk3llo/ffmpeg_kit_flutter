package com.antonkarpenko.ffmpegkit;

/**
 * <p>Detects the running ABI name natively using Google <code>cpu-features</code> library.
 */
public class AbiDetect {

    static {
        armV7aNeonLoaded = false;

        com.antonkarpenko.ffmpegkit.NativeLoader.loadFFmpegKitAbiDetect();

        /* ALL LIBRARIES LOADED AT STARTUP */
        com.antonkarpenko.ffmpegkit.FFmpegKit.class.getName();
        com.antonkarpenko.ffmpegkit.FFmpegKitConfig.class.getName();
        com.antonkarpenko.ffmpegkit.FFprobeKit.class.getName();
    }

    static final String ARM_V7A = "arm-v7a";

    static final String ARM_V7A_NEON = "arm-v7a-neon";

    private static boolean armV7aNeonLoaded;

    /**
     * Default constructor hidden.
     */
    private AbiDetect() {
    }

    static void setArmV7aNeonLoaded() {
        armV7aNeonLoaded = true;
    }

    /**
     * <p>Returns the ABI name loaded.
     *
     * @return ABI name loaded
     */
    public static String getAbi() {
        if (armV7aNeonLoaded) {
            return ARM_V7A_NEON;
        } else {
            return getNativeAbi();
        }
    }

    /**
     * <p>Returns the ABI name of the cpu running.
     *
     * @return ABI name of the cpu running
     */
    public static String getCpuAbi() {
        return getNativeCpuAbi();
    }

    /**
     * <p>Returns the ABI name loaded natively.
     *
     * @return ABI name loaded
     */
    native static String getNativeAbi();

    /**
     * <p>Returns the ABI name of the cpu running natively.
     *
     * @return ABI name of the cpu running
     */
    native static String getNativeCpuAbi();

    /**
     * <p>Returns whether FFmpegKit release is a long term release or not natively.
     *
     * @return yes or no
     */
    native static boolean isNativeLTSBuild();

    /**
     * <p>Returns the build configuration for <code>FFmpeg</code> natively.
     *
     * @return build configuration string
     */
    native static String getNativeBuildConf();

}
