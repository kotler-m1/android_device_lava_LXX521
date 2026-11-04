#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import (
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

blob_fixups: blob_fixups_user_type = {}

lib_fixups: lib_fixups_user_type = {
    **default_lib_fixups,

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
