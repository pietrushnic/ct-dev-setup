#!/bin/bash

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
UBOOT_AND_ADDR=0x800000

flash_spl() {
  ${FEL}/fel spl ${CHIP_TOOLS}/sunxi-spl.bin
  sleep 1
  ${FEL}/fel write 0x43000000 ${CHIP_TOOLS}/out-sunxi-spl.bin
  ${FEL}/fel write 0x4a000000 ${UBOOT}/u-boot-dtb.bin
  ${FEL}/fel write 0x43100000 ${SPL_SCRIPT}
  ${FEL}/fel exe 0x4a000000
}

flash_uboot() {
  ${FEL}/fel spl ${UBOOT}/spl/sunxi-spl.bin
  sleep 1
  ${FEL}/fel write 0x43000000 ${UBOOT}/spl/sunxi-spl.bin
  ${FEL}/fel write 0x4a000000 ${UBOOT}/u-boot-dtb-pa.bin
  ${FEL}/fel write 0x43100000 ${UBOOT_SCRIPT}
  ${FEL}/fel exe 0x4a000000
}

build_uboot_dis_ecc_rnd() {
  cd $UBOOT
  git co jwrdegoede/sunxi-wip/dis-ecc-rnd
  make CROSS_COMPILE=arm-linux-gnueabihf- Cubietruck_defconfig
  sed -i 's:CONFIG_SYS_NAND_U_BOOT_OFFS=0x8000:CONFIG_SYS_NAND_U_BOOT_OFFS=0x800000:g' .config
  make -j$(nproc) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
}


build_uboot_no_oob_verify() {
  cd $UBOOT
  git co jwrdegoede/sunxi-wip/no-oob-verify
  make CROSS_COMPILE=arm-linux-gnueabihf- Cubietruck_defconfig
  sed -i 's:CONFIG_SYS_NAND_U_BOOT_OFFS=0x8000:CONFIG_SYS_NAND_U_BOOT_OFFS=0x800000:g' .config
  make -j$(nproc) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
  dd if=u-boot-dtb.bin of=u-boot-dtb-pa.bin bs=8k conv=sync
}

spl_img_builder() {
  cd $CHIP_TOOLS
  cp $UBOOT/spl/sunxi-spl.bin .
  ./spl-image-builder -s 40 -c 1024 -p 8192 -o 640 -u 8192 -r 3 -d sunxi-spl.bin out-sunxi-spl.bin
}

flash_spl() {
  cd $CT_DEV_SETUP
  mkimage -A arm -T script -C none -n "flash cubietruck spl" -d $SPL_CMD $SPL_SCRIPT
  read -rsp $'Run Cubietruck in FEL mode and hit key ...\n' -n1 key
  flash_spl
}


flash_uboot() {
  cd $CT_DEV_SETUP
  mkimage -A arm -T script -C none -n "flash cubietruck uboot" -d $UBOOT_CMD $UBOOT_SCRIPT
  read -rsp $'Disconect power and run Cubietruck in FEL mode again, then hit key ...\n' -n1 key
  flash_uboot
}

build_uboot_dis_ecc_rnd
spl_img_builder
flash_spl

build_uboot_no_oob_verify
flash_uboot
