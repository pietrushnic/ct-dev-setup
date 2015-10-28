FEL=${HOME}/projects/3mdeb/cubietruck/sunxi-tools
UBOOT=${HOME}/projects/3mdeb/cubietruck/u-boot
CT_DEV_SETUP=${HOME}/projects/3mdeb/cubietruck/ct-dev-setup 
UBOOT_SCRIPT=${CT_DEV_SETUP}/write_uboot.scr

${FEL}/fel spl ${UBOOT}/spl/sunxi-spl.bin
sleep 1
${FEL}/fel write 0x4a000000 ${UBOOT}/u-boot-dtb-pa.bin
${FEL}/fel exe 0x4a000000
