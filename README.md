# KH-LF57K
Code and design files for a custom Z80 computer with Forth operating system.

The KH-LF75K computer is a Z80 based single-board computer that was designed, built, and programmed by Koppany Horvath as a project for the University of La Verne's 2nd Mini Makers fair.

This is a collection of the software files for the operating system itself as well as any firmware for the Arduino microcontrollers used. Schematics and documentation of the hardware will also be stored here.

All of this content here is free to use for whatever you want. It is under the MIT License but I also require that you mention my name or GitHub account if you use any of my resources for anything.

Read the "/Users Manual.pdf" file (not written yet) for more information on the computer.

The "/arduino/eepromprog" folder has the sketch for an Arduino Mega 2560 based EEPROM programmer and the schematic to hook it up.
The "/arduino/z80controller" folder contains the sketch for the Arduino Nano based serial communication module used on the KH-LF57K computer.

The "/forth" folder contains the source code for the Forth operating system. This is a custom Forth implementation that is not ANSI compliant and works a little differently than most traditional Forth implementations.
The "/forth/forth.cpp" file is the C++ file that contains a Forth interpreter/compiler prototype that was used for porting the interpreter to Z80 assembly.
The "/forth/z80os.asm" file is the assembly file that contains the ported version of the Forth interpreter from the C++ file; it is specifically written for the KH-LF57K computer but should be easy to port to another Z80 based system by modifying the addresses and input/output subroutines; it also contains a 2 byte header that holds the size of the code to be uploaded to the Arduino for EEPROM programming.
The "/forth/buildscript.sh" file is a script that re-compiles the assembly file every time there is a change to it.

The "/hardware/computer_layout.{png,svg}" files are rought schematics of the laout of the actuall KH-LF57K board. The address (yellow) and data (green) lines aren't shown, but to complete the circuit, just connect all the data lines for all the chips to the right ones on the Z80, same for the address lines. The Arduino Nano uses pins D2-D9 as the data lines for D0-D7.
The "/hardware/computer_layout.fzz" file is the Fritzing file for the computer_layout files.
The "/hardware/eeprom_programmer_schem.{png,svg}" files are a rough schematic of how to hook up the Arduino Mega 2560 to the EEPROM chip.
Schematics use red for positive 5 volts, black for ground, white for signal lines, yellow for address lines, and green for data lines.
The capacitor on the computer is rated at 0.47 uf.

The "/computer_real.jpg" and "/programmer_real.jpg" files are pictures of the actual computer and the actual programmer circuit. You'll might notice a few differences, like the chips being wider or the power supply being different, but those small details won't affect the computer.

The "/z80os-0.9.4.bin" file is the compiled version of the "/forth/z80os.asm" file; the first 2 bytes are the size of the program, the rest is the program starting from address $0000.
