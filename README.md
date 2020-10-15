# FamiDrive-MD
A modification of Nemul (A NES emulator running on the SEGA Genesis/MegaDrive)

originally made by Mairtrus, so credits to him for his effort...

** ROMS ARE NOT INCLUDED IN THE SOURCE ***

Features:
- Original version didn't work on hardware, this one does
- Added support for another mapper other than mapper0: CNROM
- Working vertical scrolling using both scroll layers (Map height is different than MD's)

Current issues/TODO:
- SLOW, probably will stay like this.
- Graphic glitches (bad timing)
- Bad sprite 0 timing (too slow)
- No sound at all, no plans for it
- Control reading is not implemented correctly
- Some games doesn't work
- Implement background color mirroring
- Changed the way it draws the screen background, but palette selection isn't done yet
- Emulated stack ($100-$1FF) needs more testing
