 #
 # Copyright © 2014, Varun Chitre "varun.chitre15" <varun.chitre15@gmail.com>
 #
 # Custom build script
 #
 # This software is licensed under the terms of the GNU General Public
 # License version 2, as published by the Free Software Foundation, and
 # may be copied, distributed, and modified under those terms.
 #
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 #
 # Please maintain this if you use this script or any part of it
 #
KERNEL_DIR=$PWD
KERN_IMG=$KERNEL_DIR/arch/arm64/boot/Image
DTBTOOL=$KERNEL_DIR/tools/dtbToolCM
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
# Modify the following variable if you want to build
export CROSS_COMPILE="/home/jarvis/Toolchain/bin/aarch64-linux-android-"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="pritansh"
export KBUILD_BUILD_HOST="jarvis"
STRIP="/home/jarvis/Toolchain/bin/aarch64-linux-android-strip"
MODULES_DIR=$KERNEL_DIR/../modulesPureX

compile_kernel ()
{
echo -e "$blue***********************************************"
echo "          Compiling PureX kernel          "
echo -e "***********************************************$nocol"
rm -f $KERN_IMG
make purex_defconfig
make Image -j8
make dtbs -j8
make modules -j8
if ! [ -a $KERN_IMG ];
then
echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
exit 1
fi
$DTBTOOL -2 -o $KERNEL_DIR/arch/arm64/boot/dt.img -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm/boot/dts/
make_zip
}

make_zip ()
{
echo "Copying modules"
mkdir -p purex_kernel
make -j4 modules_install INSTALL_MOD_PATH=purex_kernel INSTALL_MOD_STRIP=1
mkdir -p cwm_flash_zip/system/lib/modules/pronto
find purex_kernel/ -name '*.ko' -type f -exec cp '{}' cwm_flash_zip/system/lib/modules/ \;
mv cwm_flash_zip/system/lib/modules/wlan.ko cwm_flash_zip/system/lib/modules/pronto/pronto_wlan.ko
cp arch/arm64/boot/Image cwm_flash_zip/tools/
cp arch/arm64/boot/dt.img cwm_flash_zip/tools/
rm -f arch/arm64/boot/purex_kernel.zip
cd cwm_flash_zip
zip -r ../arch/arm64/boot/purex_kernel.zip ./
cd $KERNEL_DIR
}

case $1 in
clean)
make ARCH=arm64 -j4 clean mrproper
rm -f arch/arm/boot/dts/*.dtb
rm -f arch/arm64/boot/dt.img
rm -rf purex_kernel
rm -f arch/arm64/boot/purex_kernel.zip
rm -f cwm_flash_zip/tools/dt.img
rm -f cwm_flash_zip/tools/Image
;;
dt)
make purex_defconfig
make dtbs -j4
$DTBTOOL -2 -o $KERNEL_DIR/arch/arm64/boot/dt.img -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm/boot/dts/
;;
*)
compile_kernel
;;
esac
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
