tftp 0x46000000 ct/ml/zImage
tftp 0x49000000 ct/ml/sun7i-a20-cubietruck.dtb
setenv bootargs "root=/dev/nfs init=/sbin/init nfsroot=${serverip}:/srv/nfs/ct/rootfs rw ip=dhcp console=ttyS0,115200 rootwait panic=10 consoleblank=0 debug"
env set fdt_high ffffffff
bootz 0x46000000 - 0x49000000

