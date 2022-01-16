echo "Ensure ADB is running with elevated rights"
adb kill-server
sudo adb start-server

BUILD_DATE=$(adb shell getprop ro.build.date)
BUILD_DATE_UTC=$(date +%Y%m%d -d "$BUILD_DATE")
echo "ROM build date: $BUILD_DATE ($BUILD_DATE_UTC)"

$LOCAL_IMG_DIR="images/"
mkdir -p "$LOCAL_IMG_DIR/$BUILD_DATE_UTC"
cd "$LOCAL_IMG_DIR/$BUILD_DATE_UTC"

echo "Reboot to recovery..."
adb reboot recovery

echo ""
read -p "Enable ADB in Recovery, then press key to resume"

# boot image output filename
BOOT_IMG_DIR="/tmp/magisk"
BOOT_IMG_NAME="boot-$BUILD_DATE_UTC.img"
BOOT_IMG="$BOOT_IMG_DIR/$BOOT_IMG_NAME"

echo "Dump boot partition to image"
adb shell mkdir $BOOT_IMG_DIR
adb shell dd if=/dev/block/bootdevice/by-name/boot of=$BOOT_IMG

echo "Pull boot image to for pushing it to user storage later"
adb pull $BOOT_IMG

echo "Reboot to android"
adb reboot

read -p "Wait for reboot, then press key to resume"

echo "Upload boot image to user storage"
adb push $BOOT_IMG_NAME /storage/emulated/0/$BOOT_IMG

echo "Start magisk APP"
adb shell monkey -p com.topjohnwu.magisk 1

ANDROID_BEFORE=$(adb shell date +%s)

clear
echo "*****************************************************"
echo "* Patch image in Magisk APP"
echo "* 1. In \"Magisk\" section, press \"Install\""
echo "* 2. Press \"Next step\""
echo "* 3. Press \"Choose file to patch\""
echo "* 4. Navigate to image file (check below for name)"
echo "* 5. Hit \"Start\""
echo "*"
echo "Image to patch: \"$BOOT_IMG\" "
echo "*****************************************************"
echo ""
echo ""
read -p "After patching process finished, leave installer log open and press any key to proceed."

ANDROID_NOW=$(adb shell date +%s)

PATCHED_FILE=$(adb shell find /storage/emulated/0/Download/magisk_patched* -mmin -$((ANDROID_NOW - ANDROID_BEFORE))s)

echo ""
echo "Check Magisk installer log."
read -p "Is the output file $PATCHED_FILE?"

echo "Pull patched file"
adb pull $PATCHED_FILE 

PATCHED_FILE_NAME="${PATCHED_FILE##*/}"
echo "$PATCHED_FILE_NAME"

echo "Reboot to fastboot..."
adb reboot fastboot

echo ""
read -p "Wait for fastboot, then press key to resume"

fastboot flash boot $PATCHED_FILE_NAME

echo "Reboot to android"
fastboot reboot

read -p "Wait for reboot, then press key to resume"

echo "Check state in Magisk app"
adb shell monkey -p com.topjohnwu.magisk 1
