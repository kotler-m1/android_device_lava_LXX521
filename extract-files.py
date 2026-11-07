#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixup_remove_proto_version_suffix,
    lib_fixups as default_lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

namespace_imports = [
    'device/lava/LXX521',
]

blob_fixups: blob_fixups_user_type = {
    'vendor/lib64/libmtkcam_hal_aidl_common.so': blob_fixup()
        .replace_needed(
            'android.hardware.camera.common-V2-ndk.so',
            'android.hardware.camera.common-V1-ndk.so',
        ),
    'vendor/lib64/mt6878/libmtkcam_hal_aidl_common.so': blob_fixup()
        .replace_needed(
            'android.hardware.camera.common-V2-ndk.so',
            'android.hardware.camera.common-V1-ndk.so',
        ),
}

def lib_fixup_legacy_vendor_library(lib: str, partition: str):
    if partition in ("vendor", "odm"):
        return lib + "_legacy"
    return None

lib_fixups: lib_fixups_user_type = {
    **default_lib_fixups,

    # Keep legacy vendor audio clients linked to the stock V2 implementation.
    "av-types-aidl-cpp": lib_fixup_legacy_vendor_library,
    "audioclient-types-aidl-cpp": lib_fixup_legacy_vendor_library,
    "lib_android_keymaster_keymint_utils": lib_fixup_legacy_vendor_library,
    "libkeymint": lib_fixup_legacy_vendor_library,
    "libaudioclient_aidl_conversion": lib_fixup_legacy_vendor_library,

    # Android 15 Protobuf compatibility.
    'libprotobuf-cpp-lite-21.7':
        lib_fixup_remove_proto_version_suffix,
    'libprotobuf-cpp-full-21.7':
        lib_fixup_remove_proto_version_suffix,

}

module = ExtractUtilsModule(
    'LXX521',
    'lava',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
