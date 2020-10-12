#======================================================================
# .raw.pal to VDP
# 
# STABLE
#======================================================================

import sys
import os.path

#======================================================================
# -------------------------------------------------
# Settings
# -------------------------------------------------

DO_PADDING = True

#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

if os.path.exists(sys.argv[1]) == False:
	print("P2BIN: File not found")
	exit()
	
input_file = open(sys.argv[1],"rb")
output_file = open(sys.argv[2],"wb")

a = ord( input_file.read(1) )
b = ord( input_file.read(1) )
#print ( hex(a),hex(b) )
working=True

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

while working:
	a = int( ord(input_file.read(1)) )
	#print hex(a)
	if a == 0:
		working = False

	elif a == 0x81:
		input_file.seek(3,1)
		#print "ESTOY EN",hex(input_file.tell())
		startfrom  = int(ord(input_file.read(1)))
		startfrom |= int(ord(input_file.read(1))) << 8
		startfrom |= int(ord(input_file.read(1))) << 16
		startfrom |= int(ord(input_file.read(1))) << 24
		length = int(ord(input_file.read(1)))
		length |= int(ord(input_file.read(1))) << 8
		
		#print hex(startfrom),hex(length)
		output_file.seek(startfrom)
		result = input_file.read(length)
		output_file.write(result)
		#working = False
		#break
	
	else:
		print("PONME ALGO WEY")
		working = False

# ----------------------------
# Padding
# ----------------------------

#if DO_PADDING == True:
	#print
	
# ----------------------------
# End
# ----------------------------

input_file.close()
output_file.close()    
