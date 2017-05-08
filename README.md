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

The "/buildscript.sh" file is a script that re-compiles the assembly file every time there is a change to it.

The "/z80os-0.8.bin" file is the compiled version of the "/forth/z80os.asm" file; the first 2 bytes are the size of the program, the rest is the program starting from address $0000.
