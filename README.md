# ⌨️ KEYPOINT Keyboard Workspace

This is the top-level parent workspace containing both Git repositories and build automation for the ZitaoTech KEYPOINT split keyboard with BlackBerry optical trackpad & Macintosh USB dongle.

---

## 📂 Workspace Structure

```
keypoint-keyboard-workspace/
├── build_firmware.sh                          # Top-level Docker build script
├── build_output/                              # Output compiled .uf2 binaries
│   ├── Keypoint_dongle.uf2                    # Central Dongle firmware
│   └── Keypoint_left_trackpad.uf2             # Left Half Peripheral firmware (Trackpad)
├── ZitaoTech_KEYPOINT/                        # Main KEYPOINT repository (Shields & Drivers)
└── zmk_config_keypoint_macintosch_dongle/     # Macintosh Dongle ZMK configuration repository
```

---

## 🛠️ Repositories Included

1. **`ZitaoTech_KEYPOINT/`**:  
   - GitHub: `https://github.com/manueliglesias/KEYPOINT`
   - Contains driver source code (`source_code/left_bbtrackpad_keypoint/custom_driver_left/a320.c`), shield overlays, and devicetree configurations.

2. **`zmk_config_keypoint_macintosch_dongle/`**:  
   - GitHub: `https://github.com/manueliglesias/zmk_config_keypoint_macintosch_dongle`
   - Contains official board targets (`keypoint_dongle`, `keypoint_dongle_left`), keymaps (with `&BOT` reset key at matrix index 0), and display shields.

---

## ⚡ Quick Start: Building Firmware

From this directory (`keypoint-keyboard-workspace/`), run:

```bash
./build_firmware.sh
```

The script will automatically launch a Docker ZMK container, compile both firmwares using relative paths, and output `.uf2` binaries into `build_output/`.

---

## 🚀 Flashing Instructions

1. **Dongle**: Connect Dongle via USB, double-tap reset button (`NICENANO` drive appears), and drop `build_output/Keypoint_dongle.uf2`.
2. **Left Half**: Connect Left Half via USB, double-tap reset button (`NICENANO` drive appears), and drop `build_output/Keypoint_left_trackpad.uf2`.
