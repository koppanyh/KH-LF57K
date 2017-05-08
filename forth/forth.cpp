#include <iostream>
#include <stdint.h>
#include <cstdlib>
using namespace std;

/*  1B flags & size (machine code, immediate, compiler only, 5b size)
	2B next ptr
	nB name
	nB definition/machine code
	2B finish (1B for machine code)
		machine code 0xff is treated as 'rts'
		interpreter code 0xffff is treated as 'rts'
		use little endian encoding */
uint8_t words[65536] = {
	//0x0000 - 0x00ff - data stack
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	//0x0100 - 0x013f - return stack
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	//0x0140 - 0x017f - loop/misc stack
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0, //0x0180 data stack pointer
	0, //0x0181 return stack pointer
	0, //0x0182 loop/misc stack pointer
	0xea,0x05, //0x0183 word latest
	0xfe,0x05, //0x0185 word end
	//0x0187 - 0x0286 - input buffer
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	//0x0287 - 0x02a6 - word buffer
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0, //0x02a7 input index
	0, //0x02a8 input length
	//0x02a9 - 0x02c8 - temporary buffer
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	
	/* redo the addresses for everything */
	// +		100		( n1 n2 -- n3 ) add n2 to n1
	0x81,0xff,0xff,'+',0x00,0xff, //0x02c9
	// -		100		( n1 n2 -- n3 ) subtract n2 from n1
	0x81,0xc9,0x02,'-',0x01,0xff, //0x02cf
	// *		100		( n1 n2 -- n3 ) multiply n2 to n1
	0x81,0xcf,0x02,'*',0x02,0xff, //0x02d5
	// /mod		100		( n1 n2 -- n3 n4 ) divide and mod n2 from n1
	0x84,0xd5,0x02,'/','m','o','d',0x03,0xff, //0x02db
	// =		100		( n1 n2 -- n3 ) true if n1 equals n2, else false
	0x81,0xdb,0x02,'=',0x04,0xff, //0x02e4
	// <>		100		( n1 n2 -- n3 ) true if n1 not equals n2, else false
	0x82,0xe4,0x02,'<','>',0x05,0xff, //0x02ea
	// <		100		( n1 n2 -- n3 ) true if n1 less than n2, else false
	0x81,0xea,0x02,'<',0x06,0xff, //0x02f1
	// >		100		( n1 n2 -- n3 ) true if n1 greater than n2, else false
	0x81,0xf1,0x02,'>',0x07,0xff, //0x02f7
	// <=		100		( n1 n2 -- n3 ) true if n1 less than equal n2, else false
	0x82,0xf7,0x02,'<','=',0x08,0xff, //0x02fd
	// >=		100		( n1 n2 -- n3 ) true if n1 greater than equal n2, else false
	0x82,0xfd,0x02,'>','=',0x09,0xff, //0x0304
	// and		100		( n1 n2 -- n3 ) logic and n1 & n2
	0x83,0x04,0x03,'a','n','d',0x0a,0xff, //0x030b
	// or		100		( n1 n2 -- n3 ) logic or n1 & n2
	0x82,0x0b,0x03,'o','r',0x0b,0xff, //0x0313
	// xor		100		( n1 n2 -- n3 ) logic xor n1 & n2
	0x83,0x13,0x03,'x','o','r',0x0c,0xff, //0x031a
	// .		100		( n1 -- ) display n1 followed by a space
	0x81,0x1a,0x03,'.',0x0d,0xff, //0x0322
	// .s		100		( -- ) display all the numbers in the stack without popping the stack
	0x82,0x22,0x03,'.','s',0x0e,0xff, //0x0328
	// LIT		101		( -- n1 ) get next number from program and push to stack
	0xa3,0x28,0x03,'L','I','T',0x0f,0xff, //0x032f
	// drop		100		( n1 -- ) pop n1 from stack
	0x84,0x2f,0x03,'d','r','o','p',0x10,0xff, //0x0337
	// pick		100		( n1 n2 +n -- n1 n2 n1 ) copy the +nth value from stack (not counting +n, starting at 0) and place on top
	0x84,0x37,0x03,'p','i','c','k',0x11,0xff, //0x0340
	// roll		100		( n1 n2 +n -- n2 n1 ) move the +nth value from stack (not counting +n, starting at 0) to the top of stack
	0x84,0x40,0x03,'r','o','l','l',0x12,0xff, //0x0349
	// words	100		( -- ) display all the words in the forth dictionary
	0x85,0x49,0x03,'w','o','r','d','s',0x13,0xff, //0x0352
	// exit		100		( -- ) returns execution to operating system or shuts down computer
	0x84,0x52,0x03,'e','x','i','t',0x14,0xff, //0x035c
	// !		100		( n1 n2 -- ) save n1 to the address n2
	0x81,0x5c,0x03,'!',0x15,0xff, //0x0365
	// @		100		( n1 -- n2 ) get the value at the address n1
	0x81,0x65,0x03,'@',0x16,0xff, //0x036b
	// c!		100		( n1 n2 -- ) save the low 8 bits of n1 to the address n2
	0x82,0x6b,0x03,'c','!',0x17,0xff, //0x0371
	// c@		100		( n1 -- n2 ) get the byte at the address n1
	0x82,0x71,0x03,'c','@',0x18,0xff, //0x0378
	// >r		100		( n1 -- ) push n1 to the return stack
	0x82,0x78,0x03,'>','r',0x19,0xff, //0x037f
	// r>		100		( -- n1 ) pop n1 from the return stack
	0x82,0x7f,0x03,'r','>',0x1a,0xff, //0x0386
	// r@		100		( -- n1 ) copy the top value from the return stack
	0x82,0x86,0x03,'r','@',0x1b,0xff, //0x038d
	// emit		100		( n1 -- ) output the character of the ascii value of n1
	0x84,0x8d,0x03,'e','m','i','t',0x1c,0xff, //0x0394
	// key		100		( -- n1 ) get the ascii value of the first key pressed
	0x83,0x94,0x03,'k','e','y',0x1d,0xff, //0x039d
	// word		100		( -- n1) gets a string from input and leaves the address of the string
	0x84,0x9d,0x03,'w','o','r','d',0x1e,0xff, //0x03a5
	// number	100		( -- n1 ) gets a number from input
	0x86,0xa5,0x03,'n','u','m','b','e','r',0x1f,0xff, //0x03ae
	// type		100		( n1 -- ) string is displayed starting from the address n1
	0x84,0xae,0x03,'t','y','p','e',0x20,0xff, //0x03b9
	// count	100		( n1 -- n2 ) gets the length of a string at n1 and puts the length n2 on the stack
	0x85,0xb9,0x03,'c','o','u','n','t',0x21,0xff, //0x03c2
	// compare	100		( n1 n2 -- n3 ) compares strings at address n1 and n2 and returns 0 for false or -1 for true
	0x87,0xc2,0x03,'c','o','m','p','a','r','e',0x22,0xff, //0x03cc
	// FIND		100		( n1 -- n2 ) find the address n2 of a word with name starting at n1
	0x84,0xcc,0x03,'F','I','N','D',0x23,0xff, //0x03d8
	// ,		100		( n1 -- ) writes n1 into the memory at WEND and updates WEND position
	0x81,0xd8,0x03,',',0x24,0xff, //0x03e1
	// EXEC		100		( n1 -- ) executes the word with address n1
	0x84,0xe1,0x03,'E','X','E','C',0x25,0xff, //0x03e7
	// CREATE	100		( n1 -- ) create the header for a word/constant/variable from string address n1
	0x86,0xe7,0x03,'C','R','E','A','T','E',0x26,0xff, //0x03f0
	// LATEST	000		( -- n1 ) leave the address of the latest word variable in the stack
	0x06,0xf0,0x03,'L','A','T','E','S','T',0x2f,0x03,0x83,0x01,0xff,0xff, //0x03fb
	// WEND		000		( -- n1 ) leave the address of the end of words variable in the stack
	0x04,0xfb,0x03,'W','E','N','D',0x2f,0x03,0x85,0x01,0xff,0xff, //0x040a
	// swap		000		( n1 n2 -- n2 n1 ) switch the top 2 elements on the stack
	0x04,0x0a,0x04,'s','w','a','p',0x2f,0x03,0x01,0x00,0x49,0x03,0xff,0xff, //0x0417
	// dup		000		( n1 -- n1 n1 ) duplicates top of stack
	0x03,0x17,0x04,'d','u','p',0x2f,0x03,0x00,0x00,0x40,0x03,0xff,0xff, //0x0426
	// /		000		( n1 n2 -- n3 ) leaves division result of n1 and n2
	0x01,0x26,0x04,'/',0xdb,0x02,0x37,0x03,0xff,0xff, //0x0434
	// mod		000		( n1 n2 -- n3 ) leaves modulo result of n1 and n2
	0x03,0x34,0x04,'m','o','d',0xdb,0x02,0x17,0x04,0x37,0x03,0xff,0xff, //0x043e
	// negate	000		( n1 -- n2 ) leaves 2's complement of n1 in stack
	0x06,0x3e,0x04,'n','e','g','a','t','e',0x2f,0x03,0x00,0x00,0x17,0x04,0xcf,0x02,0xff,0xff, //0x044c
	// over		000		( n1 n2 -- n1 n2 n1 ) duplicates second number in stack
	0x04,0x4c,0x04,'o','v','e','r',0x2f,0x03,0x01,0x00,0x40,0x03,0xff,0xff, //0x045f
	// rot		000		( n1 n2 n3 -- n2 n3 n1 ) rotates third number in stack to top
	0x03,0x5f,0x04,'r','o','t',0x2f,0x03,0x02,0x00,0x49,0x03,0xff,0xff, //0x046e
	// -rot		000		( n1 n2 n3 -- n3 n1 n2 ) rotates top number to third place in stack
	0x04,0x6e,0x04,'-','r','o','t',0x6e,0x04,0x6e,0x04,0xff,0xff, //0x047c
	// cells	000		( n1 -- n2 ) multiplies n1 with size of number cell (2 for 16 bit number system)
	0x05,0x7c,0x04,'c','e','l','l','s',0x2f,0x03,0x02,0x00,0xd5,0x02,0xff,0xff, //0x0489
	// cr		000		( -- ) prints a carriage return and new line
	0x02,0x89,0x04,'c','r',0x2f,0x03,0x0a,0x00,0x2f,0x03,0x0d,0x00,0x94,0x03,0x94,0x03,0xff,0xff, //0x0499
	// invert	000		( n1 -- n2 ) logic not n1
	0x06,0x99,0x04,'i','n','v','e','r','t',0x2f,0x03,0xff,0xff,0x1a,0x03,0xff,0xff, //0x04ac
	// STATE	000		( -- n1 ) leave the address of the state variable in the stack, 0 is interpret, -1 is compile
	0x05,0xac,0x04,'S','T','A','T','E',0x2f,0x03,0xcb,0x04,0xff,0xff,0x00,0x00, //0x04bd
	// VERSION	000		( -- ) leave the forth version * 10 on the stack
	0x07,0xbd,0x04,'V','E','R','S','I','O','N',0x2f,0x03,0x09,0x00,0xff,0xff, //0x04cd
	// BWORD	101		( -- n1 ) gets next word in input buffer and leaves address in stack
	0x85,0xcd,0x04,'B','W','O','R','D',0x27,0xff, //0x04dd
	// BKEY		101		( -- n1 ) gets next char from input buffer and leaves in stack
	0x84,0xdd,0x04,'B','K','E','Y',0x28,0xff, //0x04e7
	// allot	000		( n1 -- ) increment program end counter by n1
	0x05,0xe7,0x04,'a','l','l','o','t',0x0a,0x04,0x6b,0x03,0xc9,0x02,0x0a,0x04,0x65,0x03,0xff,0xff, //0x04f0
	// IMMEDIATE000		( -- ) toggle immediate flag on latest word
	0x09,0xf0,0x04,'I','M','M','E','D','I','A','T','E',0xfb,0x03,0x6b,0x03,0x78,0x03,0x2f,0x03,0x40,0x00,0x1a,0x03,0xfb,0x03,0x6b,0x03,0x71,0x03,0xff,0xff, //0x0504
	// constant	010		( n1 -- ) create a word that leaves the value n1 in the stack
	0x48,0x04,0x05,'c','o','n','s','t','a','n','t',0xdd,0x04,0xf0,0x03,0x2f,0x03,0x2f,0x03,0xe1,0x03,0xe1,0x03,0x2f,0x03,0xff,0xff,0xe1,0x03,0xff,0xff, //0x0524
	// variable	010		( -- ) create a word that leaves the address for a variable in the stack
	0x48,0x24,0x05,'v','a','r','i','a','b','l','e',0xdd,0x04,0xf0,0x03,0x2f,0x03,0x2f,0x03,0xe1,0x03,0x0a,0x04,0x6b,0x03,0x2f,0x03,0x04,0x00,0xc9,0x02,0xe1,0x03,0x2f,0x03,0xff,0xff,0xe1,0x03,0x2f,0x03,0x00,0x00,0xe1,0x03,0xff,0xff, //0x0543
	// BRANCH	101		( -- ) replace the top of return stack with next number in program
	0xa6,0x43,0x05,'B','R','A','N','C','H',0x29,0xff, //0x0572
	// 0BRANCH	101		( -- ) replace the top of return stack with next number in program if top of stack is 0
	0xa7,0x72,0x05,'0','B','R','A','N','C','H',0x2a,0xff, //0x057d
	// (		010		( -- ) start of a comment, comment ends at first ) character
	0x41,0x7d,0x05,'(',0xe7,0x04,0x2f,0x03,0x29,0x00,0xe4,0x02,0x7d,0x05,0x8d,0x05,0xe7,0x04,0x37,0x03,0xff,0xff, //0x0589
	// +!		100		( n1 n2 -- ) adds n1 to the value at address n2
	0x82,0x89,0x05,'+','!',0x2b,0xff, //0x059f
	// >l		100		( n1 -- ) push n1 to the loop stack
	0x82,0x9f,0x05,'>','l',0x2c,0xff, //0x05a6
	// l>		100		( -- n1 ) pop n1 from the loop stack
	0x82,0xa6,0x05,'l','>',0x2d,0xff, //0x05ad
	// :		010		( -- ) start compiling sequence
	0x41,0xad,0x05,':',0x2f,0x03,0xff,0xff,0xbd,0x04,0x65,0x03,0xdd,0x04,0xf0,0x03,0xff,0xff, //0x05b4
	// ;		011		( -- ) add 0xffff to the end of program and make state 0
	0x61,0xb4,0x05,';',0x2f,0x03,0xff,0xff,0xe1,0x03,0x2f,0x03,0x00,0x00,0xbd,0x04,0x65,0x03,0xff,0xff, //0x05c6
	// begin	011		( -- ) specified return address for repeat/until
	0x65,0xc6,0x05,'b','e','g','i','n',0x0a,0x04,0x6b,0x03,0xa6,0x05,0xff,0xff, //0x05da
	// until	011		( n1 -- ) branch to begin statement in begin-until loop if n1 is false
	0x65,0xda,0x05,'u','n','t','i','l',0x2f,0x03,0x7d,0x05,0xe1,0x03,0xad,0x05,0xe1,0x03,0xff,0xff, //0x05ea
	 //0x05fe
	// while	111		( n1 -- ) branch past repeat if n1 is false in do-while-repeat loop
	// repeat	111		( -- ) branch to begin statement in begin-while-repeat loop
	// +loop	111		( n1 -- ) increments loop counter by n1
	// loop		011		( -- ) like +loop but increment by 1 automatically
	// I		101		( -- n1 ) leaves a copy of the top of the loop control stack on the stack
	// J		101		( -- n1 ) leaves a copy of the second element of the loop control stack on the stack
	// K		101		( -- n1 ) leaves a copy of the third element of the loop control stack on the stack
	// if		111		( n1 -- ) beginning of if statement, jump to else/then if false
	// else		111		( -- ) an if's else statement, jump to then if if is true
	// then		111		( -- ) set if's false branch to then's location
	// leave	101		( -- ) pop the second element from the return stack to break a loop
	// do		111		( n1 n2 -- ) starts a loop with n1 as a terminator and n2 as a starting index
	// ABORT"	011		( n1 ... -- ) clears the stacks, displays "error", returns to interpreter
	// ."		011		( -- ) displays the characters until the first " character
	// FORTH	000		( -- ) the forth interpreter/compiler
	//http://forth.sourceforge.net/standard/fst83/fst83-12.htm
	//http://www.eecs.wsu.edu/~hauser/teaching/Arch-F07/handouts/jonesforth.s.txt
};

/* String Functions */
uint8_t strlen(uint16_t dat){ //get string length
	uint8_t l = 0;
	while(words[dat+l]){
		l++; }
	return l; }
bool isNum(uint16_t dat){ //check if can convert to number
	uint8_t l = 0;
	while(words[dat+l]){
		if((words[dat+l] < 48 || words[dat+l] > 57) && words[dat+l] != '-') return false;
		l++; }
	return true; }
uint16_t toNum(uint16_t dat){ //convert to number
	uint8_t l = 0;
	uint16_t n = 0;
	bool isneg = false;
	while(words[dat+l]){
		if(words[dat+l] == '-') isneg = true;
		else{
			n *= 10;
			n += words[dat+l]-48; }
		l++; }
	if(isneg) n *= -1;
	return n; }
bool strcmp(uint16_t dat1, uint16_t dat2){ //compare 2 strings
	uint8_t l = 0;
	while((words[dat1+l] | words[dat2+l]) != 0){
		if(words[dat1+l] != words[dat2+l]) return false;
		l++; }
	return true; }
void printNum(uint16_t n){ //print signed numbers
	if(n&0x8000){
		cout << '-';
		n -= 1;
		n ^= 0xffff; }
	cout << n; }
char getKey(){ //function to get single key
	char c;
	cin.get(c);
	return c; }
void getWord(){ //function to populate word buff with word from keyboard
	char c;
	uint8_t i = 0xff;
	do{
		c = getKey(); i++;
		words[0x0287+i] = c;
	} while(c!=0 && c!=10 && c!=13 && c!=32 && i!=31);
	words[0x0287+i] = 0; }
char getBuffKey(){ //get individual key from input buff
	char c;
	if(words[0x02a7] < words[0x02a8]){
		c = words[0x0187 + words[0x02a7]];
		words[0x02a7]++;
	} else c = 0;
	return c; }
void getBuffWord(){ //function to populate word buff with word from input buff
	char c;
	uint8_t i = 0xff;
	do{
		c = getBuffKey(); i++;
		words[0x0287+i] = c;
	} while(c!=0 && c!=10 && c!=13 && c!=32 && i!=32);
	words[0x0287+i] = 0; }

/* Stack Functions */
void fstackpush(uint16_t dat){ //data stack
	uint8_t y = words[0x0180];
	if(y == 254) cout << "Err: Stack Overflow" << endl;
	words[0x0000+y] = dat & 0xff; y++;
	words[0x0000+y] = dat >> 8; y++;
	words[0x0180] = y; }
uint16_t fstackpull(){
	uint8_t y = words[0x0180];
	uint16_t t;
	if(y == 0) cout << "Err: Stack Underflow" << endl;
	y--; t = words[0x0000+y] << 8;
	y--; t |= words[0x0000+y];
	words[0x0180] = y;
	return t; }
void rtnpush(uint16_t d){ //return stack
	uint8_t y = words[0x0181];
	words[0x0100+y] = d & 0xff; y++;
	words[0x0100+y] = d >> 8; y++;
	if(y == 64) y = 0;
	words[0x0181] = y; }
uint16_t rtnpull(){
	uint8_t y = words[0x0181];
	uint16_t t;
	if(y == 0) y = 64;
	y--; t = words[0x0100+y] << 8;
	y--; t |= words[0x0100+y];
	words[0x0181] = y;
	return t; }
void lppush(uint16_t d){ //misc/loop stack
	uint8_t y = words[0x0182];
	words[0x0140+y] = d & 0xff; y++;
	words[0x0140+y] = d >> 8; y++;
	if(y == 64) y = 0;
	words[0x0182] = y; }
uint16_t lppull(){
	uint8_t y = words[0x0182];
	uint16_t t;
	if(y == 0) y = 64;
	y--; t = words[0x0140+y] << 8;
	y--; t |= words[0x0140+y];
	words[0x0182] = y;
	return t; }

/* Word Functions */
bool dispWords = false;
uint16_t findWord(uint16_t dat){ //finds address of word
	int y;
	uint16_t p = words[0x0183] | words[0x0184]<<8; //latest word
	uint16_t t;
	uint8_t wlen;
	uint8_t dlen = strlen(dat); //get len of target word
	do{
		wlen = words[p] & 0x1f; //get len of word
		t = p + 3; //start of word name
		for(y=0; y!=wlen; y++) words[0x02a9+y] = words[t+y]; //use temporary buffer
		words[0x02a9+y] = 0; //terminate tmp buff
		if(dispWords) cout << words+0x02a9 << " "; //display words
		if(wlen == dlen && strcmp(dat,0x02a9)) break; //break if found word
		t = words[++p]; //get next word address
		t |= words[++p] << 8;
		p = t;
	} while(p != 0xffff);
	return p;
}
void machineWord(uint16_t); //just a function prototype
void execWord(uint16_t waddr){                      //executes word from address
	uint16_t wdef = waddr + (words[waddr] & 0x1f) + 3;
	if(words[waddr] & 0x80) machineWord(wdef);      //machine code
	else while(true){                               //run threaded code
		waddr = words[wdef];                        //get address of word def
		waddr |= words[++wdef] << 8;
		if(waddr == 0xffff) return;                 //return if addr = 0xffff
		rtnpush(++wdef);                            //push data to return stack
		execWord(waddr);                            //run it through execWord
		wdef = rtnpull();                           //come back and pull from return stack
	}                                               //jump to top of threaded code execution
}
void machineWord(uint16_t d){
	uint16_t tmp = 0, tmp2 = 0;
	while(words[d] != 0xff){
		switch(words[d]){ //insert machine routines here
			case 0x00: // +
				fstackpush(fstackpull() + fstackpull()); break;
			case 0x01: // -
				tmp = fstackpull();
				fstackpush(fstackpull() - tmp); break;
			case 0x02: // *
				fstackpush(fstackpull() * fstackpull()); break;
			case 0x03: // /mod
				tmp2 = fstackpull();
				tmp = fstackpull();
				fstackpush(tmp / tmp2);
				fstackpush(tmp % tmp2); break;
			case 0x04: // =
				tmp2 = fstackpull();
				tmp = fstackpull();
				if(tmp == tmp2) fstackpush(0xffff);
				else fstackpush(0); break;
			case 0x05: // <>
				tmp2 = fstackpull();
				tmp = fstackpull();
				if(tmp == tmp2) fstackpush(0);
				else fstackpush(0xffff); break;
			case 0x06: // <
				tmp2 = fstackpull();
				tmp = fstackpull();
				if(tmp < tmp2) fstackpush(0xffff);
				else fstackpush(0); break;
			case 0x07: // >
				tmp2 = fstackpull();
				tmp = fstackpull();
				if(tmp > tmp2) fstackpush(0xffff);
				else fstackpush(0); break;
			case 0x08: // <=
				tmp2 = fstackpull();
				tmp = fstackpull();
				if(tmp <= tmp2) fstackpush(0xffff);
				else fstackpush(0); break;
			case 0x09: // >=
				tmp2 = fstackpull();
				tmp = fstackpull();
				if(tmp >= tmp2) fstackpush(0xffff);
				else fstackpush(0); break;
			case 0x0a: // and
				fstackpush(fstackpull() & fstackpull()); break;
			case 0x0b: // or
				fstackpush(fstackpull() | fstackpull()); break;
			case 0x0c: // xor
				fstackpush(fstackpull() ^ fstackpull()); break;
			case 0x0d: // .
				printNum(fstackpull());
				cout << ' '; break;
			case 0x0e: // .s
				cout << "=> ";
				for(tmp=0; tmp<words[0x0180]; tmp+=2){
					printNum(words[0x0000+tmp] | words[0x0000+tmp+1]<<8);
					cout << ' '; }
				cout << endl; break;
			case 0x0f: // LIT
				tmp2 = rtnpull();
				tmp = words[tmp2+1]<<8 | words[tmp2];
				rtnpush(tmp2+2);
				fstackpush(tmp); break;
			case 0x10: // drop
				fstackpull(); break;
			case 0x11: // pick
				tmp = fstackpull();
				tmp2 = words[0x0180] - 2;
				tmp2 -= tmp * 2;
				fstackpush(words[0x0000+tmp2+1]<<8 | words[0x0000+tmp2]); break;
			case 0x12: // roll
				tmp = fstackpull();
				tmp2 = words[0x0180] - 2 - tmp*2;
				tmp2 = words[0x0000 + tmp2 + 1]<<8 | words[0x0000 + tmp2];
				words[0x0000 + words[0x0180]] = tmp2 & 0xff;
				words[0x0000 + words[0x0180] + 1] = tmp2 >> 8;
				tmp = words[0x0180] - 2 - tmp*2;
				while(tmp < words[0x0180]){
					words[0x0000+tmp] = words[0x0000+tmp+2];
					tmp++;
					words[0x0000+tmp] = words[0x0000+tmp+2];
					tmp++; } break;
			case 0x13: // words
				dispWords = true;
				findWord(0x0286);
				dispWords = false;
				cout << endl; break;
			case 0x14: // exit
				exit(0); break;
			case 0x15: // !
				tmp = fstackpull();
				tmp2 = fstackpull();
				words[tmp] = tmp2 & 0xff;
				words[++tmp] = tmp2 >> 8; break;
			case 0x16: // @
				tmp = fstackpull();
				tmp2 = words[tmp++];
				tmp2 |= words[tmp] << 8;
				fstackpush(tmp2); break;
			case 0x17: // c!
				words[fstackpull()] = fstackpull() & 0xff; break;
			case 0x18: // c@
				fstackpush(words[fstackpull()]); break;
			case 0x19: // >r
				rtnpush(fstackpull()); break;
			case 0x1a: // r>
				fstackpush(rtnpull()); break;
			case 0x1b: // r@
				tmp = rtnpull();
				rtnpush(tmp);
				fstackpush(tmp); break;
			case 0x1c: // emit
				cout << (char)fstackpull(); break;
			case 0x1d: // key
				fstackpush(getKey()); break;
			case 0x1e: // word
				getWord();
				fstackpush(0x0287); break;
			case 0x1f: // number
				getWord();
				fstackpush(toNum(0x0287)); break;
			case 0x20: // type
				cout << words + fstackpull(); break;
			case 0x21: // count
				fstackpush(strlen(fstackpull())); break;
			case 0x22: // compare
				if(strcmp(fstackpull(), fstackpull())) fstackpush(0xffff);
				else fstackpush(0); break;
			case 0x23: // FIND
				fstackpush(findWord(fstackpull())); break;
			case 0x24: // ,
				tmp = fstackpull();
				words[*(uint16_t*)(words+0x0185)] = tmp & 0xff; words[0x0185]++;
				words[*(uint16_t*)(words+0x0185)] = tmp >> 8; words[0x0185]++; break;
			case 0x25: // EXEC
				execWord(fstackpull()); break;
			case 0x26: // CREATE
				tmp = fstackpull();
				tmp2 = *(uint16_t*)(words+0x0185); //start of this word
				words[tmp2] = strlen(tmp); tmp2++; //lenflag byte
				words[tmp2] = words[0x0183]; tmp2++; //next ptr
				words[tmp2] = words[0x0184]; tmp2++;
				*(uint16_t*)(words+0x0185) = tmp2; //set wend
				*(uint16_t*)(words+0x0183) = tmp2-3; //set latest to this word
				tmp2 = 0;
				while(words[tmp+tmp2]){ //insert word
					words[*(uint16_t*)(words+0x0185)] = words[tmp+tmp2];
					(*(uint16_t*)(words+0x0185))++; tmp2++; } break;
			case 0x27: // BWORD
				getBuffWord();
				fstackpush(0x0287); break;
			case 0x28: // BKEY
				fstackpush(getBuffKey()); break;
			case 0x29: // BRANCH
				tmp2 = rtnpull();
				tmp = words[tmp2++];
				tmp |= words[tmp2] << 8;
				rtnpush(tmp); break;
			case 0x2a: // 0BRANCH
				tmp2 = rtnpull();
				if(fstackpull()){ //branch past
					rtnpush(tmp2+2);
				} else{ //branch to addr
					tmp = words[tmp2++];
					tmp |= words[tmp2] << 8;
					rtnpush(tmp); } break;
			case 0x2b: // +!
				tmp = fstackpull();
				tmp2 = fstackpull();
				tmp2 += words[tmp+1]<<8 | words[tmp];
				words[tmp] = tmp2 & 0xff;
				words[++tmp] = tmp2 >> 8; break;
			case 0x2c: // >l
				lppush(fstackpull()); break;
			case 0x2d: // l>
				fstackpush(lppull()); break;
		}
		d++;
	}
}

int main(){
	uint16_t waddr;
	char c;
	int y, x;
	
	cout << "  uForth v0.9" << endl;
	cout << "(c) y47 KH-Labs";
	
	while(true){
		cout << endl << ">> ";
		cin.getline((char*)(words+0x0187),256); //store to memory
		words[0x02a8] = strlen(0x0187); //inplen
		words[0x02a7] = 0; //inpind
		
		while(true){ //while words in buffer
			getBuffWord();
			if(!words[0x0287]) break;
			
			waddr = findWord(0x0287);
			if(waddr != 0xffff){ //check if in dict
				if(words[waddr] & 0x20 && !words[0x04cb]){
					cout << "Err: '" << words+0x0287 << "' is a compile only word" << endl;
					words[0x0180] = 0; break;
				} else if(words[0x04cb] && !(words[waddr] & 0x40)){
					fstackpush(waddr);
					execWord(0x03e1); // ,
				} else execWord(waddr);
			} else if(isNum(0x0287)){ //check if number
				fstackpush(toNum(0x0287));
				if(words[0x04cb]){
					fstackpush(0x032f);
					execWord(0x03e1);
					execWord(0x03e1);
				}
			} else{ //throw an error
				cout << "Err: '" << words+0x0287 << "' is not a word" << endl;
				words[0x0180] = 0; break;
			}
		}
	}
}

