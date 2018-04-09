# Godot Chip 8 Emulator
#
# Based on original Java code written by Johan (https://github.com/Johnnei/Youtube-Tutorials/tree/master/emulator_chip8)
# Ported to Godot by Vitor Almeida da Silva on November 2017 (https://github.com/vitoralmeidasilva)
# Uses a SimpleGodotCRTShader: A simple Godot (v2.x) shader that simulates CRT Displays by Henrique Alves (https://github.com/henriquelalves/SimpleGodotCRTShader)


# TODO:
# rewrite interface
# understand what is possible
# force signals to decouple interface
# correct shader color (why color bleeding gives an "error")

#INTERFACE
#OPTIONS
# - shader
# - colors
# - fullscreen
#ROM
# - load
# - random
# - description
#INPUT
# - show/hide keyboard
#ENDINTERFACE

#INFERFACE SCREEN DIVISION
# DISPLAY
#  - fullscreen
#  - shader
#  - show fps
# EMULATION
#  - background color
#  - foreground color
#  - random rom at startup
#  - slow keyboard
#  - show rom description on load
#ENDINFERFACE SCREEN DIVISION

# tests with loading many screens at once (with random roms) and positioning (for screenshot purposes)
# Write "help" and "description" of what is chip-8 (wikipedia)..., full finished polished product, must be something curious, usable, fun
# change ICON
# expose configuration in options menu (rewrite interface)

# keyboard focus on interface
# hide keyboard by default
# button to show keyboard
# OPTIMIZE PERFORMANCE (last issue)


extends TextureRect

# exported configuration
export(int) var pixelScale = 10 # pixel scaling
export(Color, RGB) var fgColor = Color(1.0, 1.0, 1.0) # foreground color (old green = 44c321)
export(Color, RGB) var bgColor = Color(0.0, 0.0, 0.0) # background color (old green = 1f6b21)
export(bool) var showFPS = false # FPS counter
export(bool) var randomRomAtStartup = true # load a random ROM at startup
export(bool) var useShader = true # use post processing effects
export(bool) var showRomDescriptionOnLoad = false # show a dialog containing a description of the selected ROM

# environment
var romsPath = "res://roms/"
var romsDescriptionPath = "res://descriptions/"
var availableROMs = []

var soundsPath = "res://sounds/"


# UI
onready var ROMSelector = $"../ui/VBoxContainer/PanelContainer/HBoxContainer/ROMSelector"
onready var ButtonRandomGame = $"../ui/VBoxContainer/PanelContainer/HBoxContainer/ButtonRandomGame"
onready var ButtonHowToPlay = $"../ui/VBoxContainer/PanelContainer/HBoxContainer/ButtonHowToPlay"
onready var HowToPlayDialog = $"../ui/VBoxContainer/Container/HowToPlayDialog"
onready var HowToPlayDialogText = $"../ui/VBoxContainer/Container/HowToPlayDialog/ScrollContainer/TextEdit"
onready var KeyboardDialog = $"../ui/VBoxContainer/Container/KeyboardDialog"
onready var KeyboardButton1 = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/Button1"
onready var KeyboardButton2 = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/Button2"
onready var KeyboardButton3 = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/Button3"
onready var KeyboardButtonC = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/ButtonC"
onready var KeyboardButton4 = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/Button4"
onready var KeyboardButton5 = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/Button5"
onready var KeyboardButton6 = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/Button6"
onready var KeyboardButtonD = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/ButtonD"
onready var KeyboardButton7 = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/Button7"
onready var KeyboardButton8 = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/Button8"
onready var KeyboardButton9 = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/Button9"
onready var KeyboardButtonE = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/ButtonE"
onready var KeyboardButtonA = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/ButtonA"
onready var KeyboardButton0 = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/Button0"
onready var KeyboardButtonB = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/ButtonB"
onready var KeyboardButtonF = $"../ui/VBoxContainer/Container/KeyboardDialog/GridContainer/ButtonF"
onready var FPSLabel = $"../ui/VBoxContainer/FPSLabel"
onready var CRTShader = $"../Shaders/CRT"


# chip8 console
var memory = [] # 4kb (4096 bytes); each entry here is an integer representation of one byte
var V = [] # 16 registers (called V0-VF)
var I = 0 # address pointer (16 bit) (but only 12 bits are going to be used)
var pc = 0x200 # program counter (starts at memory location 0x200 h or 512 d)

# stack
var stack = [] # stack (current implementation is 16 levels)
var stackPointer = 0 # current stack pointer (index)

# flags for running state
var loaded = false # ROM loaded on memory
var running = false # is the game running? (emulation cycles only run when it is true)


# timing
var delayTimer = 0
var soundTimer = 0

# drawing
var display = [] # each entry here represents a pixel on screen (resolution is 640x320 (upscaled 10x from the original 64x32 resolution))
var needRedraw = false # does the game need to be redraw?

# input
var keys = []
# keyboard layout is:
# 1 2 3 C
# 4 5 6 D
# 7 8 9 E
# A 0 B F

var romDescription = "" # current ROM description (if available)

func _ready():
	randomize()
	loadAvailableROMs()
	
	# connect interface signals
	ROMSelector.connect("item_selected", self, "on_item_selected")
	ButtonRandomGame.connect("pressed", self, "loadRandomROM")
	ButtonHowToPlay.connect("pressed", self, "showHowToPlayDialog")

	#KeyboardButton1.connect("pressed", self, "on_buttom_pressed", [KeyboardButton1.text])
	KeyboardButton1.connect("button_down", self, "on_buttom_down", [KeyboardButton1.text])
	KeyboardButton1.connect("button_up", self, "on_buttom_up", [KeyboardButton1.text])

	#KeyboardButton2.connect("pressed", self, "on_buttom_pressed", [KeyboardButton2.text])
	KeyboardButton2.connect("button_down", self, "on_buttom_down", [KeyboardButton2.text])
	KeyboardButton2.connect("button_up", self, "on_buttom_up", [KeyboardButton2.text])

	#KeyboardButton3.connect("pressed", self, "on_buttom_pressed", [KeyboardButton3.text])
	KeyboardButton3.connect("button_down", self, "on_buttom_down", [KeyboardButton3.text])
	KeyboardButton3.connect("button_up", self, "on_buttom_up", [KeyboardButton3.text])

	#KeyboardButtonC.connect("pressed", self, "on_buttom_pressed", [KeyboardButtonC.text])
	KeyboardButtonC.connect("button_down", self, "on_buttom_down", [KeyboardButtonC.text])
	KeyboardButtonC.connect("button_up", self, "on_buttom_up", [KeyboardButtonC.text])

	#KeyboardButton4.connect("pressed", self, "on_buttom_pressed", [KeyboardButton4.text])
	KeyboardButton4.connect("button_down", self, "on_buttom_down", [KeyboardButton4.text])
	KeyboardButton4.connect("button_up", self, "on_buttom_up", [KeyboardButton4.text])

	#KeyboardButton5.connect("pressed", self, "on_buttom_pressed", [KeyboardButton5.text])
	KeyboardButton5.connect("button_down", self, "on_buttom_down", [KeyboardButton5.text])
	KeyboardButton5.connect("button_up", self, "on_buttom_up", [KeyboardButton5.text])

	#KeyboardButton6.connect("pressed", self, "on_buttom_pressed", [KeyboardButton6.text])
	KeyboardButton6.connect("button_down", self, "on_buttom_down", [KeyboardButton6.text])
	KeyboardButton6.connect("button_up", self, "on_buttom_up", [KeyboardButton6.text])

	KeyboardButtonD.connect("pressed", self, "on_buttom_pressed", [KeyboardButtonD.text])
	KeyboardButtonD.connect("button_down", self, "on_buttom_down", [KeyboardButtonD.text])
	KeyboardButtonD.connect("button_up", self, "on_buttom_up", [KeyboardButtonD.text])

	#KeyboardButton7.connect("pressed", self, "on_buttom_pressed", [KeyboardButton7.text])
	KeyboardButton7.connect("button_down", self, "on_buttom_down", [KeyboardButton7.text])
	KeyboardButton7.connect("button_up", self, "on_buttom_up", [KeyboardButton7.text])

	#KeyboardButton8.connect("pressed", self, "on_buttom_pressed", [KeyboardButton8.text])
	KeyboardButton8.connect("button_down", self, "on_buttom_down", [KeyboardButton8.text])
	KeyboardButton8.connect("button_up", self, "on_buttom_up", [KeyboardButton8.text])

	#KeyboardButton9.connect("pressed", self, "on_buttom_pressed", [KeyboardButton9.text])
	KeyboardButton9.connect("button_down", self, "on_buttom_down", [KeyboardButton9.text])
	KeyboardButton9.connect("button_up", self, "on_buttom_up", [KeyboardButton9.text])

	#KeyboardButtonE.connect("pressed", self, "on_buttom_pressed", [KeyboardButtonE.text])
	KeyboardButtonE.connect("button_down", self, "on_buttom_down", [KeyboardButtonE.text])
	KeyboardButtonE.connect("button_up", self, "on_buttom_up", [KeyboardButtonE.text])

	#KeyboardButtonA.connect("pressed", self, "on_buttom_pressed", [KeyboardButtonA.text])
	KeyboardButtonA.connect("button_down", self, "on_buttom_down", [KeyboardButtonA.text])
	KeyboardButtonA.connect("button_up", self, "on_buttom_up", [KeyboardButtonA.text])

	#KeyboardButton0.connect("pressed", self, "on_buttom_pressed", [KeyboardButton0.text])
	KeyboardButton0.connect("button_down", self, "on_buttom_down", [KeyboardButton0.text])
	KeyboardButton0.connect("button_up", self, "on_buttom_up", [KeyboardButton0.text])

	#KeyboardButtonB.connect("pressed", self, "on_buttom_pressed", [KeyboardButtonB.text])
	KeyboardButtonB.connect("button_down", self, "on_buttom_down", [KeyboardButtonB.text])
	KeyboardButtonB.connect("button_up", self, "on_buttom_up", [KeyboardButtonB.text])

	#KeyboardButtonF.connect("pressed", self, "on_buttom_pressed", [KeyboardButtonF.text])
	KeyboardButtonF.connect("button_down", self, "on_buttom_down", [KeyboardButtonF.text])
	KeyboardButtonF.connect("button_up", self, "on_buttom_up", [KeyboardButtonF.text])

	# pick a random ROM at startup
	if (randomRomAtStartup):
		loadRandomROM()
	
	playAppear()
	playBackgroundNoise()

func on_buttom_down(button):
	var pressed = true
	if (button == "1"): keys[1] = pressed
	if (button == "2"): keys[2] = pressed
	if (button == "3"): keys[3] = pressed
	if (button == "4"): keys[4] = pressed
	if (button == "5"): keys[5] = pressed
	if (button == "6"): keys[6] = pressed
	if (button == "7"): keys[7] = pressed
	if (button == "8"): keys[8] = pressed
	if (button == "9"): keys[9] = pressed
	if (button == "0"): keys[0] = pressed
	if (button == "A"): keys[0x0A] = pressed
	if (button == "B"): keys[0x0B] = pressed
	if (button == "C"): keys[0x0C] = pressed
	if (button == "D"): keys[0x0D] = pressed
	if (button == "E"): keys[0x0E] = pressed
	if (button == "F"): keys[0x0F] = pressed
	#print("on_buttom_down: " + button)

func on_buttom_up(button):
	var pressed = false
	if (button == "1"): keys[1] = pressed
	if (button == "2"): keys[2] = pressed
	if (button == "3"): keys[3] = pressed
	if (button == "4"): keys[4] = pressed
	if (button == "5"): keys[5] = pressed
	if (button == "6"): keys[6] = pressed
	if (button == "7"): keys[7] = pressed
	if (button == "8"): keys[8] = pressed
	if (button == "9"): keys[9] = pressed
	if (button == "0"): keys[0] = pressed
	if (button == "A"): keys[0x0A] = pressed
	if (button == "B"): keys[0x0B] = pressed
	if (button == "C"): keys[0x0C] = pressed
	if (button == "D"): keys[0x0D] = pressed
	if (button == "E"): keys[0x0E] = pressed
	if (button == "F"): keys[0x0F] = pressed
	#print("on_buttom_up: " + button)

func loadRandomROM():
	var i = randi() % availableROMs.size()
	ROMSelector.select(i)
	on_item_selected(i)

func _process(delta):
	# FPS counter
	FPSLabel.visible = showFPS
	if (showFPS):
		FPSLabel.set_text("FPS: " + str(Engine.get_frames_per_second()))
	
	# post processing feature
	CRTShader.visible = useShader

	if (!running):
		return
	
	#setKeyBuffer()
	
	# process opcodes
	var opcode = ((memory[pc] << 8) | memory[pc + 1])

	#print(intToHex(opcode), ": ")

	var msn = opcode & 0xF000 # most significant nibble

	if (msn == 0x0000): # multi-case
		var lsb = opcode & 0x00FF # least significant byte
		if (lsb == 0x00E0): # 00E0: Clears the screen
			clearScreen(bgColor)
			pc += 2
			needRedraw = true
		elif (lsb == 0x00EE): # 00EE: Returns from a subroutine
			stackPointer -= 1
			pc = (stack[stackPointer] + 2)
			#print("Returning to ", intToHex(pc))
		else: # 0NNN: Calls RCA 1802 program at address NNN. Not necessary for most ROMs.
			playError()
			print("Unsupported Opcode!")
			return
	elif (msn == 0x1000): # 1NNN: Jumps to address NNN
		var nnn = opcode & 0x0FFF
		pc = nnn
		#print("Jumping to ", intToHex(pc))
	elif (msn == 0x2000): # 2NNN: Calls subroutine at NNN
		stack[stackPointer] = pc
		stackPointer += 1
		pc = opcode & 0x0FFF
		#print("Calling ", intToHex(pc))
	elif (msn == 0x3000): # 3XNN: Skips the next instruction if VX equals NN
		var x = (opcode & 0x0F00) >> 8
		var nn = opcode & 0x00FF
		if (V[x] == nn):
			pc += 4
			#print("Skipping next instruction (V[", x, "] == ", nn, ")")
		else:
			pc += 2
			#print("Not skipping next instruction (V[", x, "] != ", nn, ")")
	elif (msn == 0x4000): # 4XNN: Skips the next instruction if VX doesn't equal NN.
		var x = (opcode & 0x0F00) >> 8
		var nn = opcode & 0x00FF
		if (V[x] != nn):
			pc += 4
			#print("Skipping next instruction (V[", x, "] =/= ", nn, ")")
		else:
			pc += 2
			#print("Not skipping next instruction (V[", x, "] == ", nn, ")")
	elif (msn == 0x5000): # 5XY0: Skips the next instruction if VX equals VY.
		var x = (opcode & 0x0F00) >> 8
		var y = (opcode & 0x00F0) >> 4

		if (V[x] == V[y]):
			pc += 4
			#print("Skipping next instruction (V[", x, "] == V[", y, "])")
		else:
			pc += 2
			#print("Not skipping next instruction (V[", x, "] =/= V[", y, "])")
	elif (msn == 0x6000): # 6XNN: Sets VX to NN
		var x = (opcode & 0x0F00) >> 8
		V[x] = opcode & 0x00FF
		pc += 2
		#print("Setting V[", x, "] to ", V[x])
	elif (msn == 0x7000): # 7XNN: Adds NN to VX
		var x = (opcode & 0x0F00) >> 8
		var nn = opcode & 0x00FF
		V[x] = ((V[x] + nn) & 0xFF)
		pc += 2
		#print("Adding ", nn, " to V[", x, "] = ", V[x])
	elif (msn == 0x8000):
		var lsn = opcode & 0x000F # least significant nibble

		if (lsn == 0x0000): # 8XY0: Sets VX to the value of VY.
			var x = (opcode & 0x0F00) >> 8
			var y = (opcode & 0x00F0) >> 4
			V[x] = V[y]
			#print("Setting V[", x, "] to the value of V[", y, "] = ", V[y])
			pc += 2
		elif (lsn == 0x0001): # 8XY1: Sets VX to VX or VY.
			var x = (opcode & 0x0F00) >> 8
			var y = (opcode & 0x00F0) >> 4
			#print("Set V[", x, "] to ", V[x], " | ", V[y], " = ", (V[x] | V[y]))
			V[x] = ((V[x] | V[y]) & 0xFF)
			pc += 2
		elif (lsn == 0x0002): # 8XY2: Sets VX to VX and VY.
			var x = (opcode & 0x0F00) >> 8
			var y = (opcode & 0x00F0) >> 4
			#print("Set V[", x, "] to ", V[x], " & ", V[y], " = ", (V[x] & V[y]))
			V[x] = (V[x] & V[y])
			pc += 2
		elif (lsn == 0x0003): # 8XY3: Sets VX to VX xor VY.
			var x = (opcode & 0x0F00) >> 8
			var y = (opcode & 0x00F0) >> 4
			#print("Set V[", x, "] to ", V[x], " ^ ", V[y], " = ", (V[x] ^ V[y]))
			V[x] = ((V[x] ^ V[y]) & 0xFF)
			pc += 2
		elif (lsn == 0x0004): # 8XY4: Adds VY to VX. VF is set to 1 when there's a carry, and to 0 when there isn't.
			var x = (opcode & 0x0F00) >> 8
			var y = (opcode & 0x00F0) >> 4
			#print("Adding V[", y, "] to V[", y, "] = ", ((V[x] + V[y]) & 0xFF), ", Apply Carry if needed")
			if (V[y] > 255 - V[x]):
				V[0xF] = 1
			else:
				V[0xF] = 0

			V[x] = ((V[x] + V[y]) & 0xFF)

			pc += 2
		elif (lsn == 0x0005): # 8XY5: VY is subtracted from VX. VF is set to 0 when there's a borrow, and 1 when there isn't.
			var x = (opcode & 0x0F00) >> 8
			var y = (opcode & 0x00F0) >> 4
			#print("Subtracting V[", y, "] from V[", x, "] = ", ((V[x] - V[y]) & 0xFF), ", Apply Borrow if needed, ")
			if (V[x] > V[y]):
				V[0xF] = 1
				#print("No Borrow")
			else:
				V[0xF] = 0
				#print("Borrow")

			V[x] = ((V[x] - V[y]) & 0xFF)
			pc += 2
		elif (lsn == 0x0006): # 8XY6: Shifts VX right by one. VF is set to the value of the least significant bit of VX before the shift.[2]
			var x = (opcode & 0x0F00) >> 8
			V[0xF] = (V[x] & 0x1)
			V[x] = (V[x] >> 1)
			pc += 2
			#print("Shift V[", x, "] >> 1 and VF to LSB of VX")
		elif (lsn == 0x0007): # 8XY7: Sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there isn't.
			var x = (opcode & 0x0F00) >> 8
			var y = (opcode & 0x00F0) >> 4

			if (V[x] > V[y]): # borrow
				V[0xF] = 0
			else:
				V[0xF] = 1

			V[x] = ((V[y] - V[x]) & 0xFF)

			pc += 2
		elif (lsn == 0x000E): # 8XYE: Shifts VX left by one. VF is set to the value of the most significant bit of VX before the shift.[2]
			var x = (opcode & 0x0F00) >> 8
			V[0xF] = (V[x] & 0x80)
			V[x] = (V[x] << 1)
			pc += 2
			#print("Shift V[", x, "] << 1 and VF to MSB of VX")
		else:
			playError()
			print("Unsupported Opcode!")
			return
	elif (msn == 0x9000): # 9XY0: Skips the next instruction if VX doesn't equal VY.
		var x = (opcode & 0x0F00) >> 8
		var y = (opcode & 0x00F0) >> 4
		
		if (V[x] != V[y]):
			pc += 4
			#print("Skipping next instruction (V[", x, "] =/= V[", y, "])")
		else:
			pc += 2
			#print("Not skipping next instruction (V[", x, "] == V[", y, "])")
	elif (msn == 0xA000): # ANNN: Sets I to address NNN
		I = (opcode & 0x0FFF)
		pc += 2
		#print("Setting I to ", intToHex(I))
	elif (msn == 0xB000): # BNNN: Jumps to the address NNN plus V0.
		var nnn = opcode & 0x0FFF
		var extra = V[0] & 0xFF
		pc = (nnn + extra)
	elif (msn == 0xC000): # CXNN: Sets VX to the result of a bitwise operation on a random number and NN
		var x = (opcode & 0x0F00) >> 8
		var nn = opcode & 0x00FF
		var randomNumber = (randi() % 256) &  nn
		#print("V[", x, "] has been set to (randomized) ", randomNumber)
		V[x] = randomNumber
		pc += 2
	elif (msn == 0xD000): # DXYN: Draw a sprite (X, Y) with size (8, N). Sprite is located at I
		# Drawing by XOR-ing to the screen
		# Check collision and set V[0xf
		# Read the image from I
		var x = V[(opcode & 0x0F00) >> 8]
		var y = V[(opcode & 0x00F0) >> 4]
		var height = opcode & 0x000F
		
		V[0xF] = 0
		
		for _y in range(height):
			var line = memory[I + _y]
			for _x in range(8):
				var pixel = line & (0x80 >> _x)
				if (pixel != 0):
					var totalX = x + _x
					var totalY = y + _y

					totalX = totalX % 64
					totalY = totalY % 32

					var index = (totalY * 64) + totalX

					if (display[index] == 1):
						V[0xF] = 1

					display[index] ^= 1
		
		pc += 2
		needRedraw = true
		#print("Drawing at V[", int(V[(opcode & 0x0F00) >> 8]), "] = ", int(x), ", V[", int(V[(opcode & 0x00F0) >> 4]), "] = ", int(y))
	elif (msn == 0xE000):
		var lsb = opcode & 0x00FF # least significant byte
		if (lsb == 0x009E): # EX9E: Skips the next instruction if the key stored in VX is pressed.
			var x = (opcode & 0x0F00) >> 8
			var key = V[x]
			if (keys[key] == true):
				pc += 4
			else:
				pc += 2
		elif (lsb == 0x00A1): # EXA1: Skips the next instruction if the key stored in VX isnt pressed.
			var x = (opcode & 0x0F00) >> 8
			var key = V[x]
			if (keys[key] == false):
				pc += 4
			else:
				pc += 2
			#print("Skipping next instuction if V[", x, "] = ", V[x], " is not pressed")
		else:
			playError()
			print("Unexisting opcode")
			return
	elif (msn == 0xF000): 
		var lsb = opcode & 0x00FF
		if (lsb == 0x0007): # FX07: Sets VX to the value of delay timer
			var x = (opcode & 0x0F00) >> 8
			V[x] = delayTimer
			#print("V[", x, "] has been set to ", delayTimer)
			pc += 2
		elif (lsb == 0x000A): # FX0A: A key press is awaited, and then stored in VX.
			var x = (opcode & 0x0F00) >> 8
			for i in range(keys.size()):
				if (keys[i] == true):
					V[x] = i
					pc += 2
			#print("Awaiting keypress to be stored in V[", x, "]")
		elif (lsb == 0x0015): # FX15: Sets the delay timer to VX
			var x = (opcode & 0x0F00) >> 8
			delayTimer = V[x]
			#print("Set delay timer to V[", x, "] = ", V[x])
			pc += 2
		elif (lsb == 0x0018): # FX18: Sets the sound timer to VX
			var x = (opcode & 0x0F00) >> 8
			soundTimer = V[x]
			#print("Set sound timer to V[", V[x], "] = ", V[x])
			pc += 2
		elif (lsb == 0x0029): # FX29: Sets I to the location of the sprite for the character VX (Fontset)
			var x = (opcode & 0x0F00) >> 8
			var character = V[x]
			I = (0x050 + (character * 5))
			#print("Setting I to character V[", x, "] = ", V[x], " Offset to 0x ", intToHex(I))
			pc += 2
		elif (lsb == 0x0033): # FX33: Store a binary-coded decimal value VX in I, I + 1 and I + 2
			var x = (opcode & 0x0F00) >> 8
			var value = V[x]
			
			var hundreds = (value - (value % 100)) / 100
			value -= hundreds * 100
			var tens = (value - (value % 10)) / 10
			value -= tens * 10
			memory[I] = hundreds
			memory[I + 1] = tens
			memory[I + 2] = value
			#print("Storing Binary-Coded Decimal  V[", x, "] = ", (V[(opcode & 0x0F00) >> 8]), " as {", hundreds, ", ", tens, ", ", value, "}")
			pc += 2
		elif (lsb == 0x0055): # FX55: Stores V0 to VX in memory starting at address I
			var x = (opcode & 0x0F00) >> 8
			for i in range(x):
				memory[I + i] = V[i]
			#print("Setting V[0] to V[", x, "] to the values of memory[0x", intToHex(I & 0xFF), "]")
			pc += 2
		elif (lsb == 0x0065): # FX65: Fills V0 to VX with values from I
			var x = (opcode & 0x0F00) >> 8
			for i in range(x):
				V[i] = memory[I + i]
			#print("Setting V[0] to V[", x, "] to the values of memory[0x", intToHex(I & 0xFF), "]")
			I = (I + x + 1) # as noted by note 4
			pc += 2
		elif (lsb == 0x001E): # FX1E: Adds VX to I
			var x = (opcode & 0x0F00) >> 8
			I = (I + V[x]);
			#print("Adding V[", x, "] = ", int(V[x]), " to I")
			pc += 2
		else:
			playError()
			print("Unsupported Opcode!")
			return
	else:
		playError()
		print("Unsupported Opcode!")
		return

	if (soundTimer > 0):
		soundTimer -= 1
		playBeep()

	if (delayTimer > 0):
		delayTimer -= 1

	if (needRedraw):
		update()

func _draw():
	var color = null
	var size = display.size()

	for i in range(size):
		if (display[i] == 0):
			color = bgColor
		else:
			color = fgColor

		var x = ((i % 64))
		var y = (floor((i / 64)))
		drawPixel(x * pixelScale, y * pixelScale, color)

# clear the screen
func clearScreen(color):
	var size = display.size()
	for i in range(size):
		display[i] = 0

# draw a pixel into coordinates x and y using color x
# pixel size is configured from editor
func drawPixel(x, y, color):
	draw_rect(Rect2(x, y, pixelScale, pixelScale), color)

# convert the integer argument to an hexadecimal string representation (using two chars)
# example: 10 d becomes 0A h
func intToHex(integer):
	return "%02X" % integer

func initChip8():
	I = 0
	pc = 0x200
	stackPointer = 0
	loaded = false
	running = false
	delayTimer = 0
	soundTimer = 0
	needRedraw = false

	# TODO: is there a better way??
	memory.resize(4096 + 1)
	var mSize = memory.size()
	for i in range(mSize):
		memory[i] = 0

	var size = (64 * 32) # Original CHIP-8 display resolution is 64x32
	display.resize(size)
	for i in range(size):
		display[i] = 0 # clear screen ((randi() % 2) generates a random value between 0 and 1)

	var vSize = 16 + 1
	V.resize(vSize)
	for i in range(vSize):
		V[i] = 0
	
	var kSize = 16
	keys.resize(kSize)
	for i in range(kSize):
		keys[i] = false

	stack.resize(16 + 1)
	loadFont()

func loadFont():
	# values are in hexadecimal
	var fontset = [
		0xF0, 0x90, 0x90, 0x90, 0xF0, # 0
		0x20, 0x60, 0x20, 0x20, 0x70, # 1
		0xF0, 0x10, 0xF0, 0x80, 0xF0, # 2
		0xF0, 0x10, 0xF0, 0x10, 0xF0, # 3
		0x90, 0x90, 0xF0, 0x10, 0x10, # 4
		0xF0, 0x80, 0xF0, 0x10, 0xF0, # 5
		0xF0, 0x80, 0xF0, 0x90, 0xF0, # 6
		0xF0, 0x10, 0x20, 0x40, 0x40, # 7
		0xF0, 0x90, 0xF0, 0x90, 0xF0, # 8
		0xF0, 0x90, 0xF0, 0x10, 0xF0, # 9
		0xF0, 0x90, 0xF0, 0x90, 0x90, # A
		0xE0, 0x90, 0xE0, 0x90, 0xE0, # B
		0xF0, 0x80, 0x80, 0x80, 0xF0, # C
		0xE0, 0x90, 0x90, 0x90, 0xE0, # D
		0xF0, 0x80, 0xF0, 0x80, 0xF0, # E
		0xF0, 0x80, 0xF0, 0x80, 0x80  # F
	]
	var start = 0x50 # starting position is 0x50 h or 80 d
	var offset = 0
	var size = fontset.size()
	for i in range(size):
			memory[start + offset] = fontset[i]
			offset += 1

# load ROM of name "name" into memory
func loadROM(ROM):
	initChip8()

	loaded = false
	running = false

	var start = 0x200 # starting position is 0x200 h or 512 d (511 d because of arrays are zero indexed)
	var offset = 0

	var file = File.new()
	file.open(romsPath + ROM, File.READ)

	var bytes = file.get_buffer(file.get_len()) # RawArray

	for byte in bytes:
		memory[start + offset] = byte # integer
		offset += 1

	loaded = true
	running = true

# _input callback will be called when a keyboard button is pressed or released.
func _input(event):
	# the event of interest is keyaboard event, which is of class 'InputEventKey'
	if event is InputEventKey:
		var is_echo = "Echo" if event.echo else ""

		if event.pressed:
			var pressed = true
			if (event.scancode == KEY_KP_0 || event.scancode == KEY_0): keys[0] = pressed
			if (event.scancode == KEY_KP_1 || event.scancode == KEY_1): keys[1] = pressed
			if (event.scancode == KEY_KP_2 || event.scancode == KEY_2 || event.scancode == KEY_UP): keys[2] = pressed
			if (event.scancode == KEY_KP_3 || event.scancode == KEY_3): keys[3] = pressed
			if (event.scancode == KEY_KP_4 || event.scancode == KEY_4 || event.scancode == KEY_LEFT): keys[4] = pressed
			if (event.scancode == KEY_KP_5 || event.scancode == KEY_5 || event.scancode == KEY_ENTER): keys[5] = pressed
			if (event.scancode == KEY_KP_6 || event.scancode == KEY_6 || event.scancode == KEY_RIGHT): keys[6] = pressed
			if (event.scancode == KEY_KP_7 || event.scancode == KEY_7): keys[7] = pressed
			if (event.scancode == KEY_KP_8 || event.scancode == KEY_8 || event.scancode == KEY_DOWN): keys[8] = pressed
			if (event.scancode == KEY_KP_9 || event.scancode == KEY_9): keys[9] = pressed
			if (event.scancode == KEY_KP_7 || event.scancode == KEY_7): keys[7] = pressed
			if (event.scancode == KEY_A): keys[0x0A] = pressed
			if (event.scancode == KEY_B): keys[0x0B] = pressed
			if (event.scancode == KEY_C): keys[0x0C] = pressed
			if (event.scancode == KEY_D): keys[0x0D] = pressed
			if (event.scancode == KEY_E): keys[0x0E] = pressed
			if (event.scancode == KEY_F): keys[0x0F] = pressed
			#prints("Key pressed ", event.scancode, " ",  OS.get_scancode_string(event.scancode), is_echo)
		else:
			var pressed = false
			if (event.scancode == KEY_KP_0 || event.scancode == KEY_0): keys[0] = pressed
			if (event.scancode == KEY_KP_1 || event.scancode == KEY_1): keys[1] = pressed
			if (event.scancode == KEY_KP_2 || event.scancode == KEY_2 || event.scancode == KEY_UP): keys[2] = pressed
			if (event.scancode == KEY_KP_3 || event.scancode == KEY_3): keys[3] = pressed
			if (event.scancode == KEY_KP_4 || event.scancode == KEY_4 || event.scancode == KEY_LEFT): keys[4] = pressed
			if (event.scancode == KEY_KP_5 || event.scancode == KEY_5 || event.scancode == KEY_ENTER): keys[5] = pressed
			if (event.scancode == KEY_KP_6 || event.scancode == KEY_6 || event.scancode == KEY_RIGHT): keys[6] = pressed
			if (event.scancode == KEY_KP_7 || event.scancode == KEY_7): keys[7] = pressed
			if (event.scancode == KEY_KP_8 || event.scancode == KEY_8 || event.scancode == KEY_DOWN): keys[8] = pressed
			if (event.scancode == KEY_KP_9 || event.scancode == KEY_9): keys[9] = pressed
			if (event.scancode == KEY_KP_7 || event.scancode == KEY_7): keys[7] = pressed
			if (event.scancode == KEY_A): keys[0x0A] = pressed
			if (event.scancode == KEY_B): keys[0x0B] = pressed
			if (event.scancode == KEY_C): keys[0x0C] = pressed
			if (event.scancode == KEY_D): keys[0x0D] = pressed
			if (event.scancode == KEY_E): keys[0x0E] = pressed
			#prints("Key released ", event.scancode, " ", OS.get_scancode_string(event.scancode), is_echo)

func playAppear():
	var sound = load(soundsPath + "Appear-KP-1137861048.wav")
	$SoundEffects.stream = sound
	$SoundEffects.play()

func playBeep():
	var sound = load(soundsPath + "Robot_blip-Marianne_Gagnon-120342607.wav")
	$SoundEffects.stream = sound
	if (not $SoundEffects.playing):
		$SoundEffects.play()

func playError():
	var sound = load(soundsPath + "Computer Error-SoundBible.com-1655839472.wav")
	$SoundEffects.stream = sound
	if (not $SoundEffects.playing):
		$SoundEffects.play()

func playBackgroundNoise():
	$AmbientSounds.play()

func loadAvailableROMs():
	var dir = Directory.new()

	# load data
	if (dir.open(romsPath) == OK):
		dir.list_dir_begin(true)
		var fileName = dir.get_next()
		while (fileName != ""):
			availableROMs.append(fileName)
			fileName = dir.get_next()
	else:
		playError()
		print("An error occurred when trying to access the path.")
	
	# fill and connect UI
	for i in range(availableROMs.size()):
		ROMSelector.add_item(availableROMs[i])

func on_item_selected(id):
	loadROM(availableROMs[id])
	romDescription = loadROMDescription(id)
	#KeyboardDialog.show()
	if (showRomDescriptionOnLoad):
		HowToPlayDialog.show()

func loadROMDescription(id):
	# first changes the .c8 extension to .txt
	var path = romsDescriptionPath + availableROMs[id].replace(".c8", ".txt")
	var description = ""

	# now finds the right description
	var file = File.new()
	var err = file.open(path, File.READ)
	if (err == OK):
		description = file.get_as_text()
	else:
		description = "No description."
		#HowToPlayDialog.show()

	HowToPlayDialogText.text = description


	return description

func showHowToPlayDialog():
	HowToPlayDialog.visible = not HowToPlayDialog.visible
