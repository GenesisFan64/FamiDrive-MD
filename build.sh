clear

# MD ROM
echo "** MEGA DRIVE **"
tools/AS/linux/asl md.asm -q -xx -c -A -olist out/rom_md.lst -A -L -D MCD=0,MARS=0,MARSCD=0
python tools/p2bin.py md.p out/rom_md.bin
rm md.p
rm md.h

# # MEGACD
# echo "** MEGA CD **"
# asl mcd.asm -q -xx -c -A -olist out/rom_mcd.lst -A -L -D MCD=1,MARS=0,MARSCD=0
# python tools/p2bin.py mcd.p out/rom_mcd.iso
# rm mcd.p
# rm mcd.h


