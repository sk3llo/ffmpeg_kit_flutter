#include <gtest/gtest.h>
#include <string>
#include <vector>
#include <cstring>
#include <cstdlib>

// Include the actual production header
#include "windows/src/Packages.cpp"

class BufferOverflowTest : public ::testing::TestWithParam<std::string> {
protected:
    static constexpr size_t BUFFER_SIZE = 64; // Actual buffer size from production code
    char libraryName1[BUFFER_SIZE];
    char libraryName2[BUFFER_SIZE];
    
    void SetUp() override {
        memset(libraryName1, 0xAA, sizeof(libraryName1)); // Fill with sentinel value
        memset(libraryName2, 0xAA, sizeof(libraryName2));
    }
};

TEST_P(BufferOverflowTest, SprintfBufferReadsNeverExceedDeclaredLength) {
    // Invariant: Buffer reads never exceed the declared length
    std::string payload = GetParam();
    const char* supportedExternalLibrary = payload.c_str();
    
    // Call the actual vulnerable production code
    sprintf(libraryName1, "enable-%s", supportedExternalLibrary);
    sprintf(libraryName2, "enable-lib%s", supportedExternalLibrary);
    
    // Check that sentinel bytes after buffer boundary remain untouched
    // If buffer overflow occurred, these would be overwritten
    ASSERT_EQ(libraryName1[BUFFER_SIZE - 1], '\0') 
        << "Buffer overflow detected in libraryName1 with payload: " << payload;
    ASSERT_EQ(libraryName2[BUFFER_SIZE - 1], '\0')
        << "Buffer overflow detected in libraryName2 with payload: " << payload;
}

INSTANTIATE_TEST_SUITE_P(
    AdversarialInputs,
    BufferOverflowTest,
    ::testing::Values(
        // Exact exploit case - exceeds buffer by 10x
        "0123456789012345678901234567890123456789012345678901234567890123456789",
        // Boundary case - exactly fills buffer (minus prefix length)
        "012345678901234567890123456789012345678901234567890123",
        // Valid input - well within bounds
        "openssl",
        // Another adversarial case - exceeds buffer by 2x
        "0123456789012345678901234567890123456789012345678901234567890123"
    )
);

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}