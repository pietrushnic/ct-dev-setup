mkimage -C none -A arm -T script -d boot.cmd.ml boot.scr.ml
sudo cp boot.scr.ml /srv/tftp/ct/boot.scr

