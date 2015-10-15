#!/bin/bash

# https://releases.linaro.org/15.05/components/toolchain/binaries/arm-linux-gnueabihf/
export PATH=${PATH}:${HOME}/projects/3mdeb/cubietruck/toolchains/gcc-linaro-4.9-2015.05-x86_64_arm-linux-gnueabihf/bin

# git://github.com/linux-sunxi/sunxi-tools.git
FEL=${HOME}/projects/3mdeb/cubietruck/sunxi-tools

# https://github.com/pietrushnic/u-boot-sunxi.git
UBOOT=${HOME}/projects/3mdeb/cubietruck/u-boot

# https://github.com/pietrushnic/CHIP-tools.git -b spl-image-builder
CHIP_TOOLS=${HOME}/projects/3mdeb/cubietruck/CHIP-tools

# https://github.com/pietrushnic/ct-dev-setup.git
CT_DEV_SETUP=${HOME}/projects/3mdeb/cubietruck/ct-dev-setup 

SPL_CMD=${CT_DEV_SETUP}/write_spl.cmd
SPL_SCRIPT=${CT_DEV_SETUP}/write_spl.scr
UBOOT_CMD=${CT_DEV_SETUP}/write_uboot.cmd
UBOOT_SCRIPT=${CT_DEV_SETUP}/write_uboot.scr
ALL_CMD=${CT_DEV_SETUP}/write_all.cmd
ALL_SCRIPT=${CT_DEV_SETUP}/write_all.scr
UBOOT_AND_ADDR=0x800000

#UBOOT_IMG=u-boot.img
#UBOOT_IMG_ALIGNED=u-boot-pa.img
UBOOT_IMG=u-boot-dtb.bin
UBOOT_IMG_ALIGNED=u-boot-dtb-pa.bin

flash_spl() {
  ${FEL}/fel spl ${CHIP_TOOLS}/sunxi-spl.bin
  sleep 1
  ${FEL}/fel write 0x43000000 ${CHIP_TOOLS}/out-sunxi-spl.bin
  ${FEL}/fel write 0x4a000000 ${UBOOT}/${UBOOT_IMG_ALIGNED}
  ${FEL}/fel write 0x43100000 ${SPL_SCRIPT}
  ${FEL}/fel exe 0x4a000000
}

flash_uboot() {
  ${FEL}/fel spl ${UBOOT}/spl/sunxi-spl.bin
  sleep 1
  ${FEL}/fel write 0x43000000 ${UBOOT}/spl/sunxi-spl.bin
  ${FEL}/fel write 0x4a000000 ${UBOOT}/${UBOOT_IMG_ALIGNED}
  ${FEL}/fel write 0x43100000 ${UBOOT_SCRIPT}
  ${FEL}/fel exe 0x4a000000
}


flash() {
  ${FEL}/fel spl ${CHIP_TOOLS}/sunxi-spl.bin
  sleep 1
  ${FEL}/fel write 0x43000000 ${CHIP_TOOLS}/out-sunxi-spl.bin
  ${FEL}/fel write 0x4a000000 ${UBOOT}/${UBOOT_IMG_ALIGNED}
  ${FEL}/fel write 0x43100000 ${ALL_SCRIPT}
  ${FEL}/fel exe 0x4a000000
}

build_uboot() {
  cd $UBOOT
  git co u-boot-sunxi/nand-wip
  make CROSS_COMPILE=arm-linux-gnueabihf- Cubietruck_defconfig
  sed -i 's:CONFIG_SYS_NAND_U_BOOT_OFFS=0x8000:CONFIG_SYS_NAND_U_BOOT_OFFS=0x400000:g' .config
  sed -i 's:CONFIG_SUNXI_NAND_UBI_START=0x400000:CONFIG_SUNXI_NAND_UBI_START=0x600000:g' .config
  make -j$(nproc) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
  UBOOT_IMG_SIZE=`stat ${UBOOT_IMG} --printf="%s"|xargs`
  dd if=${UBOOT_IMG} of=${UBOOT_IMG_ALIGNED}
  dd if=/dev/zero of=${UBOOT_IMG_ALIGNED} bs=1 count=`expr 786432 - ${UBOOT_IMG_SIZE}` seek=${UBOOT_IMG_SIZE}
}

build_uboot_dis_ecc_rnd() {
  cd $UBOOT
  git co jwrdegoede/sunxi-wip/dis-ecc-rnd
  make CROSS_COMPILE=arm-linux-gnueabihf- Cubietruck_defconfig
  sed -i 's:CONFIG_SYS_NAND_U_BOOT_OFFS=0x8000:CONFIG_SYS_NAND_U_BOOT_OFFS=0x400000:g' .config
  sed -i 's:CONFIG_SUNXI_NAND_UBI_START=0x400000:CONFIG_SUNXI_NAND_UBI_START=0x600000:g' .config
  make -j$(nproc) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
  dd if=${UBOOT_IMG} of=${UBOOT_IMG_ALIGNED} bs=8k conv=sync
}


build_uboot_no_oob_verify() {
  cd $UBOOT
  git co jwrdegoede/sunxi-wip/no-oob-verify
  make CROSS_COMPILE=arm-linux-gnueabihf- Cubietruck_defconfig
  sed -i 's:CONFIG_SYS_NAND_U_BOOT_OFFS=0x8000:CONFIG_SYS_NAND_U_BOOT_OFFS=0x400000:g' .config
  sed -i 's:CONFIG_SUNXI_NAND_UBI_START=0x400000:CONFIG_SUNXI_NAND_UBI_START=0x600000:g' .config
  make -j$(nproc) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
  dd if=${UBOOT_IMG} of=${UBOOT_IMG_ALIGNED} bs=8k conv=sync
}

spl_img_builder() {
  cd $CHIP_TOOLS
  cp $UBOOT/spl/sunxi-spl.bin .
  ./spl-image-builder -s 40 -c 1024 -p 8192 -o 640 -u 8192 -r 3 -d sunxi-spl.bin out-sunxi-spl.bin
}

spl_stage() {
  cd $CT_DEV_SETUP
  mkimage -A arm -T script -C none -n "flash cubietruck spl" -d $SPL_CMD $SPL_SCRIPT
  read -rsp $'Run Cubietruck in FEL mode and hit key ...\n' -n1 key
  flash_spl
}


uboot_stage() {
  cd $CT_DEV_SETUP
  mkimage -A arm -T script -C none -n "flash cubietruck uboot" -d $UBOOT_CMD $UBOOT_SCRIPT
  read -rsp $'Disconect power and run Cubietruck in FEL mode again, then hit key ...\n' -n1 key
  flash_uboot
}

all_stage() {
  cd $CT_DEV_SETUP
  mkimage -A arm -T script -C none -n "flash cubietruck uboot" -d $ALL_CMD $ALL_SCRIPT
  read -rsp $'Disconect power and run Cubietruck in FEL mode again, then hit key ...\n' -n1 key
  flash
}

#build_uboot_dis_ecc_rnd
#spl_img_builder
#spl_stage
#
#build_uboot_no_oob_verify
#uboot_stage

build_uboot
spl_img_builder
all_stage


