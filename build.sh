#!/bin/bash
set -e

# Set Git identity for repo init
git config --global user.name "kotler-m1"
git config --global user.email "kotler.b3@gmail.com"

# Setup build workspace directory
cd /crave-devspaces/lxx521-16

# =========================================================
# Initialize LineageOS 23.2 (Android 16)
# =========================================================
cd /crave-devspaces/lxx521-16
echo "Initializing repo..."
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs --depth=1

# resync tool
echo "Syncing source..."
/opt/crave/resync.sh

# =========================================================
# Setup Device & Vendor Trees
# =========================================================
echo "Setting up device trees..."
rm -rf device/lava/LXX521
rm -rf vendor/lava/LXX521

# Clone device tree
git clone https://github.com/kotler-m1/android_device_lava_LXX521.git device/lava/LXX521

# Download and extract the fixed vendor tree from GitHub Releases
echo "Downloading and extracting vendor tree..."
wget -q -O /tmp/vendor.zip https://github.com/kotler-m1/android_device_lava_LXX521/releases/download/v1.0.0-android16_lxx521/vendor.zip
mkdir -p vendor/lava/LXX521
unzip -q /tmp/vendor.zip -d /tmp/vendor_extract

# Move contents into the correct directory
mv /tmp/vendor_extract/* vendor/lava/LXX521/ 2>/dev/null || true

# Automatically fix the nested folder issue if it exists inside the zip
if [ -d "vendor/lava/LXX521/vendor" ]; then
    echo "Fixing nested vendor directory structure..."
    mv vendor/lava/LXX521/vendor/lava/LXX521/* vendor/lava/LXX521/
    rm -rf vendor/lava/LXX521/vendor
fi


# =========================================================
# Setup Build Environment
# =========================================================
echo "Setting up build environment..."
source build/envsetup.sh

# --- Set Build Identity (Customize with your info) ---
export BUILD_USERNAME="Kotler"
export BUILD_HOSTNAME="lava-lxx521"
export KBUILD_BUILD_USER="kotler"
export KBUILD_BUILD_HOST="lxx521-builder"
# -----------------------------------------------------

# lunch target for Android 16
lunch lineage_LXX521-bp4a-userdebug

# =========================================================
# Build the ROM
# =========================================================
echo "Starting compilation..."
mka bacon

# =========================================================
# Automated Upload to GoFile
# =========================================================
echo "Build complete. Starting upload to GoFile..."

# Find the generated zip file
ZIP_FILE=$(find out/target/product/LXX521 -name "*.zip" | head -n 1)

if [ -z "$ZIP_FILE" ]; then
    echo "ERROR: No ZIP file found. Build may have failed."
    exit 1
fi

# Check if jq is installed (required for the GoFile script)
if ! command -v jq &> /dev/null; then
    echo "jq not found. Installing..."
    sudo apt update -y && sudo apt install jq -y
fi

# Run the GoFile upload logic directly
echo "Uploading $ZIP_FILE ..."
SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers[0].name')
LINK=$(curl -# -F "file=@$ZIP_FILE" "https://${SERVER}.gofile.io/uploadFile" | jq -r '.data|.downloadPage') 2>&1

echo "========================================="
echo "Upload Done! Your download link is:"
echo "$LINK"
echo "========================================="
