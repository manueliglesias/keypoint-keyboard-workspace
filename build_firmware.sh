#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYPOINT_REPO="$SCRIPT_DIR/ZitaoTech_KEYPOINT"
DONGLE_REPO="$SCRIPT_DIR/zmk_config_keypoint_macintosch_dongle"

echo "=========================================="
echo " KEYPOINT ZMK Unified Docker Builder"
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

        echo "🔨 Building Left Half Firmware (Trackpad Peripheral)..."
        cd app
        west build -p -b keypoint_dongle_left -d build_left -- -DSHIELD="lpm_view;left_bbtrackpad_keypoint" -DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n
        cp build_left/zephyr/zmk.uf2 /workspace/build_output/Keypoint_left_trackpad.uf2
        echo "✅ Built: Keypoint_left_trackpad.uf2"

        echo "🔨 Building Dongle Firmware (Central)..."
        west build -p -b keypoint_dongle -d build_dongle -- -DSHIELD="st7789_display" -DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=y
        cp build_dongle/zephyr/zmk.uf2 /workspace/build_output/Keypoint_dongle.uf2
        echo "✅ Built: Keypoint_dongle.uf2"
    '

cp "$KEYPOINT_REPO/build_output/Keypoint_dongle.uf2" "$SCRIPT_DIR/build_output/"
cp "$KEYPOINT_REPO/build_output/Keypoint_left_trackpad.uf2" "$SCRIPT_DIR/build_output/"

echo ""
echo "🎉 Build complete!"
echo "Output files saved to build_output/:"
echo "  1. $SCRIPT_DIR/build_output/Keypoint_dongle.uf2"
echo "  2. $SCRIPT_DIR/build_output/Keypoint_left_trackpad.uf2"
