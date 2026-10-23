#!/bin/bash
set -e

# Set Git Identity (required for repo init)
git config --global user.name "kotler-m1"
git config --global user.email "kotler.b3@gmail.com"

# Setup build workspace directory
cd /crave-devspaces/lxx521-16

# Initialize LineageOS 23.2 (Android 16)
echo "Initializing repo..."
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs --depth=1

# Use standard repo sync
echo "Syncing source..."
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags

# Fix: Ensure Rust Prebuilts are Synced
echo "Force re-syncing Rust prebuilts..."
rm -rf prebuilts/rust
repo sync --force-sync --no-clone-bundle prebuilts/rust

# Clean old directories if they exist
rm -rf device/lava/LXX521
rm -rf vendor/lava/LXX521

# Clone your custom device tree
echo "Cloning device tree..."
git clone https://github.com/kotler-m1/android_device_lava_LXX521.git device/lava/LXX521

# Exclude Cronet to prevent Rust variant errors
echo "Excluding Cronet..."
MAKEFILE="device/lava/LXX521/lineage_LXX521.mk"
echo "PRODUCT_SOONG_NAMESPACES += external/cronet" >> "$MAKEFILE"
echo "SOONG_CONFIG_NAMESPACES += external_cronet" >> "$MAKEFILE"
echo "SOONG_CONFIG_external_cronet := \\" >> "$MAKEFILE"
echo "    enabled false" >> "$MAKEFILE"

# Download and Extract Vendor Zip Release
echo "Setting up vendor tree..."
mkdir -p temp_vendor_extract
wget -q -O vendor_release.zip https://github.com/kotler-m1/android_device_lava_LXX521/releases/download/v1.0.0-android16_lxx521/vendor.zip
unzip -q vendor_release.zip -d temp_vendor_extract/

mkdir -p vendor/lava/LXX521
mv temp_vendor_extract/* vendor/lava/LXX521/ 2>/dev/null || true

# Fix nested vendor directory
if [ -d "vendor/lava/LXX521/vendor" ]; then
  echo "Fixing nested vendor directory..."
  mv vendor/lava/LXX521/vendor/lava/LXX521/* vendor/lava/LXX521/
  rm -rf vendor/lava/LXX521/vendor
fi
rm -rf temp_vendor_extract vendor_release.zip

# Setup build environment
echo "Setting up build environment..."
source build/envsetup.sh

# Select your correct lunch target
lunch lineage_LXX521-bp4a-userdebug

# Clean out directory to prevent stale cache errors
rm -rf out/

# Start build
echo "Starting compilation..."
mka bacon
