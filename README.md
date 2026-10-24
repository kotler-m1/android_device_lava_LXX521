# Android device tree for LAVA LAVA LXX521 (LXX521) & Guide below.

```
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
<<<<<<< HEAD

=======
```

# Device & Vendor Tree Generation Guide (dumpyara + aospdtgen + extract-utils)

A step-by-step guide to extracting Android firmware with **dumpyara**, generating a starter device tree with **aospdtgen**, and then generating the matching vendor tree with LineageOS **extract-utils** on Debian Linux.

## Overview

| Tool | Purpose |
|------|---------|
| [dumpyara](https://github.com/AndroidDumps/dumpyara) | Extracts a firmware package (OTA zip, `payload.bin`, images) into a dump folder |
| [aospdtgen](https://github.com/SebaUbuntu/aospdtgen) | Reads that dump and generates an AOSP-style device tree |
| [extract-utils](https://github.com/LineageOS/android_tools_extract-utils) | Pulls proprietary blobs from the dump and generates the vendor tree |

**Workflow:** `firmware.zip` → `dumpyara` → `dump/` → `aospdtgen` → `device tree` → `extract-utils` → `vendor tree`

## Requirements

- Debian (or a Debian-based distro such as Ubuntu)
- Python 3.8+
- Git
- Roughly 20-30 GB of free disk space (firmware dumps are large)
- Stock firmware or a **full** OTA package for your device (not an incremental update)

## 1. Install dependencies

```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv git p7zip-full lz4 brotli \
    android-sdk-libsparse-utils erofs-utils protobuf-compiler
```

## 2. Set up a virtual environment

Recent Debian releases block system-wide `pip install` (PEP 668), so use a venv:

```bash
python3 -m venv ~/dtgen-env
source ~/dtgen-env/bin/activate
pip install --upgrade pip
pip install dumpyara aospdtgen
```

If the PyPI packages fail to install or are outdated, install from source:

```bash
pip install git+https://github.com/AndroidDumps/dumpyara.git
pip install git+https://github.com/SebaUbuntu/aospdtgen.git
```

## 3. Extract the firmware with dumpyara

```bash
dumpyara /path/to/firmware.zip -o ~/dump
```

If the `dumpyara` command is not found:

```bash
python3 -m dumpyara /path/to/firmware.zip -o ~/dump
```

After it finishes, `~/dump` should contain extracted partitions such as `system/`, `vendor/`, `product/`, `boot.img`, and the raw `.img` files.

## 4. Generate the device tree with aospdtgen

```bash
python3 -m aospdtgen ~/dump -o ~/dt_output
```

The output is written to `~/dt_output/<manufacturer>/<codename>/` and typically contains:

```
Android.bp
AndroidProducts.mk
BoardConfig.mk
device.mk
proprietary-files.txt
prebuilt/            # kernel / dtb
...
```

# Vendor Tree Generation (Using a Fresh dumpyara Dump)
  
> **Do not use the folder generated during device tree creation as the extraction target.**
> Run **dumpyara one more time** to unpack the firmware into a new, separate folder, and use that fresh dump to generate the vendor tree.


## 5. Generate the vendor tree

The vendor tree holds the proprietary blobs your device needs. It is generated from the device tree's `extract-files.py` script, using the LineageOS extract-utils tool.

> The examples below use `device/lava/LXX521` as the device tree path and `/media/kotler/linux/lxx521/` as the dump path. Replace them with your own manufacturer, codename, and paths.

1. Go to your working directory, the one that contains your `device/<manufacturer>/<codename>` folder (for example `/media/kotler/linux/output`):

   ```bash
   cd /media/kotler/linux/output
   ```

2. Clone only the extract-utils tool from LineageOS:

   ```bash
   git clone https://github.com/LineageOS/android_tools_extract-utils -b lineage-22.1 tools/extract-utils
   ```

3. Run the extraction script, pointing `PYTHONPATH` at the folder you just cloned and passing the path to your dump:

   ```bash
   PYTHONPATH=tools/extract-utils python3 device/lava/LXX521/extract-files.py /media/kotler/linux/lxx521/
   ```

   If your device tree is in a different location, change `device/lava/LXX521` to match.

4. When it finishes, the `vendor/lava/LXX521` folder is created in your working directory.

5. Push the vendor tree to GitHub so you can use it in your build (for example, in your Crave build command):

   ```bash
   cd vendor/lava/LXX521
   git init
   git add .
   git commit -m "LXX521: initial vendor tree"
   git remote add origin https://github.com/<your-username>/<your-vendor-repo>.git
   git push -u origin main
   ```

Pick the extract-utils branch that matches the LineageOS version you are building (here `lineage-22.1`).

### Fix: `proprietary-files.txt` not found

`extract-files.py` expects to find `device/<manufacturer>/<codename>/proprietary-files.txt` **relative to your current directory**. If your working directory is itself the device tree (for example, you are inside `/media/kotler/linux/output` and the tree files sit directly in it), the script looks for `/media/kotler/linux/output/device/lava/LXX521/proprietary-files.txt`, which does not exist, and fails.

To fix this, create the expected directory structure with a symlink that points back to your device tree. Run these commands while inside your output folder (here `/media/kotler/linux/output`):

```bash
mkdir -p device/lava
ln -s /media/kotler/linux/output device/lava/LXX521
```

When the script looks for `device/lava/LXX521`, it now lands back in your output folder, where the files really are. Then run the extraction command from step 3 again.

Use your own manufacturer, codename, and absolute path in place of `lava`, `LXX521`, and `/media/kotler/linux/output`.

## 6. Clean up the generated trees

The output is a **starting point**, not a finished tree. You will usually need to:

- Verify partition sizes, kernel command line, and board platform in `BoardConfig.mk`
- Add a `lineage_<codename>.mk` (or `omni_<codename>.mk`, etc.) for your target ROM or recovery
- Swap the prebuilt kernel for a self-built one if you have the kernel source
- Test-build (for example, as TWRP or LineageOS) and fix errors one at a time

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `ModuleNotFoundError` | Activate the venv: `source ~/dtgen-env/bin/activate` |
| `dumpyara: command not found` | Use `python3 -m dumpyara ...` or check that the venv is active |
| Dump is empty or incomplete | Confirm `erofs-utils`, `lz4`, and `p7zip-full` are installed and read the dumpyara error output |
| Dynamic partitions / `vendor_boot` not detected | Newer devices may need manual extraction and manual edits to the generated files |
| `extract-files.py` fails or blobs are missing | Check that `PYTHONPATH` points to `tools/extract-utils`, that the dump path is correct, and that `proprietary-files.txt` lists the files you need |
| `proprietary-files.txt` not found when running `extract-files.py` | The script resolves `device/<manufacturer>/<codename>/` from your current directory. Create a symlink as described in [Fix: `proprietary-files.txt` not found](#fix-proprietary-filestxt-not-found) |
| Extract-utils branch mismatch | Clone the branch that matches your target LineageOS version (for example `lineage-22.1`) |
| Wrong firmware type | Use full stock firmware or a full OTA, not an incremental update |

## Notes

- Always keep your original firmware zip as a backup.
- Proprietary blobs extracted from a dump belong to the device manufacturer. Check the licensing before redistributing them.
- Generated trees often need device-specific tweaks. Compare against a similar device from the same SoC family when possible.

## Credits

- [dumpyara](https://github.com/AndroidDumps/dumpyara) by AndroidDumps
- [aospdtgen](https://github.com/SebaUbuntu/aospdtgen) by SebaUbuntu
- [extract-utils](https://github.com/LineageOS/android_tools_extract-utils) by the LineageOS project
>>>>>>> 5622f22dbf1dc657a5756c343f2d7dee552c5396
