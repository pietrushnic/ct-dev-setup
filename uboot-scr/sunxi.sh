mkimage -C none -A arm -T script -d boot.cmd.sunxi boot.scr.sunxi
sudo cp boot.scr.sunxi /srv/tftp/ct/boot.scr

