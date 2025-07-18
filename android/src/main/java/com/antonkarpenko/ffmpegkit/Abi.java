package com.antonkarpenko.ffmpegkit;


/**
 * <p>Enumeration for Android ABIs.
 */
public enum Abi {

    /**
     * Represents armeabi-v7a ABI with NEON support
     */
    ABI_ARMV7A_NEON("armeabi-v7a-neon"),

    /**
     * Represents armeabi-v7a ABI
     */
    ABI_ARMV7A("armeabi-v7a"),

    /**
     * Represents armeabi ABI
     */
    ABI_ARM("armeabi"),

    /**
     * Represents x86 ABI
     */
    ABI_X86("x86"),

    /**
     * Represents x86_64 ABI
     */
    ABI_X86_64("x86_64"),

    /**
     * Represents arm64-v8a ABI
     */
    ABI_ARM64_V8A("arm64-v8a"),

    /**
     * Represents not supported ABIs
     */
    ABI_UNKNOWN("unknown");

    private final String name;

    /**
     * <p>Returns the enumeration defined for the given ABI name.
     *
     * @param abiName ABI name
     * @return enumeration defined for the ABI name
     */
    public static Abi from(final String abiName) {
        if (abiName == null) {
            return ABI_UNKNOWN;
        } else if (abiName.equals(ABI_ARM.getName())) {
            return ABI_ARM;
        } else if (abiName.equals(ABI_ARMV7A.getName())) {
            return ABI_ARMV7A;
        } else if (abiName.equals(ABI_ARMV7A_NEON.getName())) {
            return ABI_ARMV7A_NEON;
        } else if (abiName.equals(ABI_ARM64_V8A.getName())) {
            return ABI_ARM64_V8A;
        } else if (abiName.equals(ABI_X86.getName())) {
            return ABI_X86;
        } else if (abiName.equals(ABI_X86_64.getName())) {
            return ABI_X86_64;
        } else {
            return ABI_UNKNOWN;
        }
    }

    /**
     * Returns the ABI name.
     *
     * @return ABI name as defined in Android NDK documentation
     */
    public String getName() {
        return name;
    }

    /**
     * Creates a new enum.
     *
     * @param abiName ABI name
     */
    Abi(final String abiName) {
        this.name = abiName;
    }

}
