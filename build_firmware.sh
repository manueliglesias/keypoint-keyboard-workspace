#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYPOINT_REPO="$SCRIPT_DIR/ZitaoTech_KEYPOINT"
DONGLE_REPO="$SCRIPT_DIR/zmk_config_keypoint_macintosch_dongle"
TARGET="${1:-dongle}"

echo "=========================================="
echo " KEYPOINT ZMK Unified Docker Builder"
echo " Target: $TARGET (options: dongle, left, right, all, reset)"
echo "=========================================="

if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker daemon is not running. Please start Docker Desktop and run this script again."
    exit 1
fi

mkdir -p "$KEYPOINT_REPO/build_env"
mkdir -p "$KEYPOINT_REPO/build_output"
mkdir -p "$SCRIPT_DIR/build_output"

echo "🐳 Running ZMK Docker build container..."

docker run --rm \
    -v "$KEYPOINT_REPO":/workspace \
    -v "$DONGLE_REPO":/dongle_repo \
    -w /workspace/build_env \
    zmkfirmware/zmk-dev-arm:3.5 \
    bash -c '
        set -e
        if [ ! -d "zmk" ]; then
            echo "📥 Cloning ZMK repository (v0.3)..."
            git clone -b v0.3 https://github.com/zmkfirmware/zmk.git
            cd zmk
            west init -l app/
            west update
        else
            cd zmk
        fi

        echo "📦 Installing official dongle boards and shields..."
        cp -r /dongle_repo/config/boards/arm/keypoint_dongle app/boards/arm/
        cp -r /dongle_repo/config/boards/shields/left_bbtrackpad_keypoint app/boards/shields/
        cp -r /dongle_repo/config/boards/shields/right_trackpoint_keypoint app/boards/shields/
        cp -r /dongle_repo/config/boards/shields/lpm_view app/boards/shields/
        cp -r /dongle_repo/config/boards/shields/st7789_display app/boards/shields/

        cd app
        TARGET="'"$TARGET"'"

        if [ "$TARGET" = "dongle" ] || [ "$TARGET" = "all" ]; then
            echo "🔨 Building Dongle Firmware (Central)..."
            west build -p -b keypoint_dongle -d build_dongle -- -DSHIELD="st7789_display" -DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=y -DZMK_CONFIG=/dongle_repo/config
            cp build_dongle/zephyr/zmk.uf2 /workspace/build_output/dongle.uf2
            cp build_dongle/zephyr/zmk.uf2 /workspace/build_output/Keypoint_dongle.uf2
            echo "✅ Built: dongle.uf2 (and Keypoint_dongle.uf2)"
        fi

        if [ "$TARGET" = "left" ] || [ "$TARGET" = "all" ]; then
            echo "🔨 Building Left Half Firmware (Trackpad Peripheral)..."
            west build -p -b keypoint_dongle_left -d build_left -- -DSHIELD="lpm_view;left_bbtrackpad_keypoint" -DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n -DZMK_CONFIG=/dongle_repo/config
            cp build_left/zephyr/zmk.uf2 /workspace/build_output/left_half.uf2
            cp build_left/zephyr/zmk.uf2 /workspace/build_output/Keypoint_left_trackpad.uf2
            echo "✅ Built: left_half.uf2"
        fi

        if [ "$TARGET" = "right" ] || [ "$TARGET" = "all" ]; then
            echo "🔨 Building Right Half Firmware (Trackpoint Peripheral)..."
            west build -p -b keypoint_dongle_right -d build_right -- -DSHIELD="lpm_view;right_trackpoint_keypoint" -DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n -DZMK_CONFIG=/dongle_repo/config
            cp build_right/zephyr/zmk.uf2 /workspace/build_output/right_half.uf2
            cp build_right/zephyr/zmk.uf2 /workspace/build_output/Keypoint_right_trackpoint.uf2
            echo "✅ Built: right_half.uf2"
        fi

        if [ "$TARGET" = "reset" ]; then
            echo "🔨 Building Settings Reset for Dongle..."
            west build -p -b keypoint_dongle -d build_dongle_reset -- -DSHIELD="st7789_display;settings_reset" -DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=y -DZMK_CONFIG=/dongle_repo/config
            cp build_dongle_reset/zephyr/zmk.uf2 /workspace/build_output/dongle_reset.uf2

            echo "🔨 Building Settings Reset for Left..."
            west build -p -b keypoint_dongle_left -d build_left_reset -- -DSHIELD="lpm_view;left_bbtrackpad_keypoint;settings_reset" -DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n -DZMK_CONFIG=/dongle_repo/config
            cp build_left_reset/zephyr/zmk.uf2 /workspace/build_output/left_half_reset.uf2

            echo "🔨 Building Settings Reset for Right..."
            west build -p -b keypoint_dongle_right -d build_right_reset -- -DSHIELD="lpm_view;right_trackpoint_keypoint;settings_reset" -DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n -DZMK_CONFIG=/dongle_repo/config
            cp build_right_reset/zephyr/zmk.uf2 /workspace/build_output/right_half_reset.uf2
            echo "✅ Built: reset firmwares"
        fi
    '

cp -f "$KEYPOINT_REPO"/build_output/*.uf2 "$SCRIPT_DIR/build_output/" 2>/dev/null || true

echo ""
echo "🎉 Build complete!"
echo "Firmwares ready in $SCRIPT_DIR/build_output/:"
ls -lh "$SCRIPT_DIR/build_output/"*.uf2

