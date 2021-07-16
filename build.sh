#!/bin/bash

BOLD='\033[1m'
GRN='\033[01;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[01;31m'
RST='\033[0m'
echo "Cloning dependencies if they don't exist...."

if [ ! -d clang ]
then
git clone --depth=1 https://github.com/kardebayan/android_prebuilts_clang_host_linux-x86_clang-5696680.git clang
fi

if [ ! -d gcc32 ]
then
git clone --depth=1 https://github.com/KudProject/arm-linux-androideabi-4.9 gcc32
fi

if [ ! -d gcc ]
then
git clone --depth=1 https://github.com/KudProject/aarch64-linux-android-4.9 gcc
fi

if [ ! -d AnyKernel ]
then
git clone --depth=1 https://github.com/stormbreaker-project/AnyKernel3.git -b CPH1859 AnyKernel
fi

echo "Done"


KERNEL_DIR=$(pwd)
IMAGE="${KERNEL_DIR}/out/arch/arm64/boot/Image.gz-dtb"
TANGGAL=$(date +"%Y%m%d-%H")
TIME=0
VER=$(make kernelversion)  
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PATH="${KERNEL_DIR}/clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export ARCH=arm64
export KBUILD_BUILD_USER=kardebayan
export KBUILD_BUILD_HOST=buildbot

# Compile plox
function compile() {

    echo -e "${CYAN}"
    make -j$(nproc) O=out ARCH=arm64 realme-mt6771_defconfig
    make -j$(nproc) O=out \
                    ARCH=arm64 \
                    CC=clang \
                    CLANG_TRIPLE=aarch64-linux-gnu- \
                    CROSS_COMPILE=aarch64-linux-android- \
                    CROSS_COMPILE_ARM32=arm-linux-androideabi-
SUCCESS=$?
	if [ $SUCCESS -eq 0 ]
		END=$(date +%s)
		TIME=$(echo $((${END}-${START})) | awk '{print int($1/60)" Minutes and "int($1%60)" Seconds"}')
        	then
		echo -e "${GRN}"
		echo "------------------------------------------------------------"
		echo "Compilation successful..."
		echo "Compilation Time: ${TIME}"
        	echo "Image.gz-dtb can be found at out/arch/arm64/boot/Image.gz-dtb"
    		cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
		echo  "------------------------------------------------------------"
		echo -e "${RST}"
	else
		END=$(date +%s)
		TIME=$(echo $((${END}-${START})) | awk '{print int($1/60)" Minutes and "int($1%60)" Seconds"}')
		echo -e "${RED}"
                echo "------------------------------------------------------------"
		echo "Compilation failed.. check build logs for errors"
                echo "Compilation Time: $1"
                echo "------------------------------------------------------------"
		echo -e "${RST}"
	fi
   echo -e "${RST}"
}
# Zipping
function zipping() {
    echo -e "${YELLOW}"
    echo "Creating a flashable zip....."
    cd AnyKernel || exit 1
    zip -r9 Stormbreaker-CPH1859-${TANGGAL}-${VER}.zip * > /dev/null 2>&1
    cd ..
    echo "Zip stored at AnyKernel/Stormbreaker-CPH1859-${TANGGAL}-${VER}.zip"
    echo -e "${RST}"
}


#Start Counting build time after build started we don't want wait time included
START=$(date +%s)

# Compile
compile

if [ $SUCCESS -eq 0 ]
then
	mkdir -p AnyKernel/modules/vendor/lib/modules
	cp -r out/drivers/misc/mediatek/connectivity/bt/mt66xx/legacy/bt_drv.ko AnyKernel/modules/vendor/lib/modules
        cp -r out/drivers/misc/mediatek/connectivity/common/wmt_drv.ko AnyKernel/modules/vendor/lib/modules
        cp -r out/drivers/misc/mediatek/connectivity/fmradio/fmradio_drv.ko AnyKernel/modules/vendor/lib/modules
        cp -r out/drivers/misc/mediatek/connectivity/gps/gps_drv.ko AnyKernel/modules/vendor/lib/modules
        cp -r out/drivers/misc/mediatek/connectivity/wlan/adaptor/wmt_chrdev_wifi.ko AnyKernel/modules/vendor/lib/modules
        cp -r out/drivers/misc/mediatek/connectivity/wlan/core/gen3/wlan_drv_gen3.ko AnyKernel/modules/vendor/lib/modules
        cp -r out/drivers/misc/mediatek/met/met.ko AnyKernel/modules/vendor/lib/modules
        cp -r out/drivers/misc/mediatek/performance/fpsgo_cus/fpsgo.ko AnyKernel/modules/vendor/lib/modules
	zipping $TIME
fi
