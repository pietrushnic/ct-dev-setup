tftp 0x43000000 ct-aw/script.bin
tftp 0x48000000 ct-aw/zImage
setenv bootargs "root=/dev/nfs init=/sbin/init nfsroot=192.168.1.8:/srv/nfs/cubietruck rw ip=dhcp console=tty1 rootwait sunxi_ve_mem_reserve=0 sunxi_g2d_mem_reserve=0 sunxi_no_mali_mem_reserve sunxi_fb_mem_reserve=16 hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x720p60 panic=10 consoleblank=0 debug"
printenv bootargs
bootz 0x48000000
