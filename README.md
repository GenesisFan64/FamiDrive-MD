# FamiDrive-MD
A modification of Nemul (A NES emulator running on the SEGA Genesis/MegaDrive)

originally made by Mairtrus, so credits to him for his effort...

** ROMS ARE NOT INCLUDED IN THE SOURCE ***

Features:
- Original version didn't work on hardware, this one does
- Added support for another mapper other than mapper 0: CNROM
- Working vertical scrolling using both scroll layers (Map height is different than MD's)

Current issues/TODO:
- *SLOW*, at least this system can do something like this.
- Graphic glitches (bad timing, affects sprite 0 hit)
- No sound at all, no plans for it
- Sprite 8x16 mode not done (it's different than MD's sprite size 8x16)
- Control reading is not implemented correctly (not 6pad safe)
- Some games doesn't work
