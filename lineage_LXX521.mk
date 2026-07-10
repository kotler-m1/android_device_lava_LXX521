#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from LXX521 device
$(call inherit-product, device/lava/LXX521/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_DEVICE := LXX521
PRODUCT_NAME := lineage_LXX521
PRODUCT_BRAND := LAVA
PRODUCT_MODEL := LAVA LXX521
PRODUCT_MANUFACTURER := lava

PRODUCT_GMS_CLIENTID_BASE := android-lava

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="LAVA_LXX521_SW_V12_HW_V1.0_20260519" \
    BuildFingerprint=LAVA/LXX521/LXX521:15/AP3A.240905.015.A2/260518:user/release-keys
