;Z80 Forth OS for the KH-LF57K microcomputer
;Written by Koppany Horvath (c) y47

;use CuteCom to send the file
;use gtkterm as the serial terminal
;a build file exists in the z80 folder that will build this file
;the linux folder has the z80 highlight file, /usr/share/gtksourceview-3.0/language-specs/
;make sure highlight file has correct permissions
;http://eclass.aspete.gr/modules/document/file.php/EHN155/Z80%20Reference.pdf
;http://clrhome.org/table/

org 0 ;len of prog for rom programmer
	dw endOfProg
	;ds 32 ;skip first 32 bytes for zim
org 0
	nop
	nop
	nop
	jp init

;sends byte in A, then receives byte to A
;requires A register, tested
serial:
	out ($ff),a
	in a,($fe)
	ret

;prints a c string starting at address BC
;requires A, BC registers, tested
print:
	ld a,(bc)
	cp $00
	ret z
	call serial
	inc bc
	jp print

;returns the length of BC address c string to A register
;requires D, A, BC registers, tested
strlen:
	ld d,$00
strlen3:
	ld a,(bc)
	cp $00
	jp z,strlen2
	inc d
	inc bc
	jp strlen3
strlen2:
	ld a,d
	ret

; returns true in A register if c strings at BC and HL are same
; requires BC, HL, A registers, tested
strcmp:
	ld a,(bc)
	cp (hl)
	jp nz,strcmp2
	cp $00
	jp z,strcmp3
	inc bc
	inc hl
	jp strcmp
strcmp3:
	ld a,$01
	ret
strcmp2:
	ld a,$00
	ret

;returns result in HL of BC * DE
;requires A, BC, DE, HL registers, tested
multiply:
	ld hl,$0000
	ld a,b
	ld b,$10
Mult16_Loop:
	add hl,hl
	sla c
	rla
	jr nc,Mult16_NoAdd
	add hl,de
Mult16_NoAdd:
	djnz Mult16_Loop
	ret

;divide HL by BC, HL=HL%BC, DE=HL/BC
;uses A, BC, DE, HL, tested
divide:
	ld de,$0000 ;de = 0
divide1:
	or a ;while(hl >= bc){
	sbc hl,bc ;hl -= bc
	jp m,divide2
	inc de ;de++
	jp divide1 ;}
divide2:
	add hl,bc
	ret

;returns true in A register if c string at BC address is number
;requires A, BC registers, tested
isNum:
	ld a,(bc) ;while(words[bc]){ a = words[bc++]
	inc bc
	cp $00
	jp z,isNum2
	cp $2d ;if((words[bc] <= 47 || words[bc] >= 58) && words[bc] != '-')
	jp z,isNum
	cp $3a
	jp nc,isNum1
	cp $30
	jp nc,isNum
isNum1:
	ld a,$00 ;return false
	ret
isNum2:
	ld a,$01 ;return true
	ret

;returns number in HL from converted c string at addr BC
;requires A, BC, D, HL registers, tested
toNum:
	ld hl,$0000 ;hl = 0
	ld d,$00 ;neg = false
toNum1:
	ld a,(bc) ;while(words[bc]){
	cp $00
	jp z,toNum2
	cp $2d ;if(words[bc] == '-')
	jp nz,toNum3
	ld d,$01 ;neg = true
	jp toNum4
toNum3:
	push af ;else{ hl *= 10
	push bc
	push de
	ld b,h
	ld c,l
	ld de,$000a
	call multiply
	pop de
	pop bc
	pop af
	sub $30 ;hl += words[bc] - 48 }
	push bc
	ld b,$00
	ld c,a
	add hl,bc
	pop bc
toNum4:
	inc bc ;bc++
	jp toNum1 ;}
toNum2:
	ld a,d ;if(neg)
	cp $00
	jp z,toNum5
	dec hl ;hl *= -1
	ld a,h
	xor $ff
	ld h,a
	ld a,l
	xor $ff
	ld l,a
toNum5:
	ret

;prints number HL to serial
; requires A, BC, DE, HL registers, tested
printNum:
	bit 7,h ;if(hl & 0x8000){
	jp z,printNum2
	ld a,$2d ;cout << '-'
	call serial
	dec hl ;hl -= 1
	ld a,h ;hl ^= 0xffff }
	xor $ff
	ld h,a
	ld a,l
	xor $ff
	ld l,a
printNum2:
	ld a,$00 ;tmp[7] = 0;
	ld (tmpbuff+7),a
	ld bc,tmpbuff+7
printNum3:
	dec bc ;do{ bc--
	push bc ;tmp[bc] = hl % 10 + 48
	ld bc,$000a
	call divide
	ld a,l
	add a,$30
	pop bc
	ld (bc),a
	ld h,d ;hl /= 10
	ld l,e
	ld a,h ;} while(hl != 0)
	or l
	cp $00
	jp nz,printNum3
	call print ;cout << tmp+bc
	ret

;waits until keypress, then returns ascii char in A register
;requires A register, tested
getKey:
	ld a,$00
getKey2:
	call serial
	cp $00
	jp z,getKey2
	ret

;populates word buff with word from serial
;requires A, BC, D registers, tested
getWord:
	ld d,$00 ;d = 0;
	ld bc,wordbuff-1 ;bc = wordbuff-1;
getWord2:
	call getKey ;do{ a = getKey();
	push af ;cout << a
	call serial
	pop af
	cp $0d ;if(a == 0x0d) cout << 0x0a
	jp nz,getWord4
	push af
	ld a,$0a
	call serial
	pop af
	jp getWord5
getWord4:
	cp $08 ;else if(a == 0x08){
	jp nz,getWord5
	push af ;cout << ' ' << 0x08
	ld a,$20
	call serial
	ld a,$08
	call serial
	pop af
	dec bc ;bc--
	dec d ;d-- }
	jp getWord2
getWord5:
	inc bc ;bc++;
	inc d ;d++;
	ld (bc),a ;words[bc] = a;
	cp $0a ;} while(a!=0 && a!=10 && a!=13 && a!=32 && d!=32);
	jp z,getWord3
	cp $0d
	jp z,getWord3
	cp $20
	jp z,getWord3
	cp $00
	jp z,getWord3
	ld a,d
	cp $20
	jp z,getWord3
	jp getWord2
getWord3:
	ld a,$00 ;words[bc] = 0;
	ld (bc),a
	ret

;populates input buff with data from serial
;requires A, BC, D registers, tested
getInput:
	ld d,$00 ;d = 0
	ld bc,inpbuff-1 ;bc = inpbuff-1
getInput2:
	call getKey ;do{ a = getKey()
	push af ;cout << a
	call serial
	pop af
	cp $0d ;if(a == 0x0d) cout << 0x0a
	jp nz,getInput4
	push af
	ld a,$0a
	call serial
	pop af
	jp getInput5
getInput4:
	cp $08 ;else if(a == 0x08){
	jp nz,getInput5
	push af ;cout << ' ' << 0x08
	ld a,$20
	call serial
	ld a,$08
	call serial
	pop af
	dec bc ;bc--
	dec d ;d-- }
	jp getInput2
getInput5:
	inc bc ;bc++
	inc d ;d++
	ld (bc),a ;words[bc] = a
	cp $0a ;} while(a!=0 && a!=10 && a!= 13 && d!=255)
	jp z,getInput3
	cp $0d
	jp z,getInput3
	cp $00
	jp z,getInput3
	ld a,d
	cp $ff
	jp z,getInput3
	jp getInput2
getInput3:
	ld a,$00 ;words[bc] = 0
	ld (bc),a
	ld (inpind),a ;words[inpind] = 0
	dec d ;words[inplen] = d-1
	ld a,d
	ld (inplen),a
	ret

;returns char from input buff in A register
;requires A, BC, HL registers, tested
getBuffKey:
	ld a,(inplen) ;if(words[inpind] != words[inplen]){
	ld hl,inpind
	cp (hl)
	jp z,getBuffKey2
	ld b,$00 ;a = words[inpbuff + words[inpind]];
	ld c,(hl)
	ld hl,inpbuff
	add hl,bc
	ld a,(hl)
	ld hl,inpind ;words[inpind]++;
	inc (hl)
	jp getBuffKey3
getBuffKey2:
	ld a,$00 ;} else a = 0;
getBuffKey3:
	ret ;return a;

;populates word buff with word from input buff
;requires A, BC, D registers, tested
getBuffWord:
	ld d,$ff ;d = 0xff;
	ld bc,wordbuff-1 ;bc = wordbuff-1
getBuffWord2:
	push bc ;do{ a = getBuffKey()
	call getBuffKey
	pop bc
	inc bc ;bc++
	inc d ;d++
	ld (bc),a ;words[bc] = a;
	cp $0a ;} while(a!=0 && a!=10 && a!=13 && a!=32 && d!=32);
	jp z,getBuffWord3
	cp $0d
	jp z,getBuffWord3
	cp $20
	jp z,getBuffWord3
	cp $00
	jp z,getBuffWord3
	ld a,d
	cp $20
	jp z,getBuffWord3
	jp getBuffWord2
getBuffWord3:
	ld a,$00 ;words[bc] = 0;
	ld (bc),a
	ret

;push HL value onto data stack
;requires A, BC, DE, HL registers, tested
fstackpush:
	ld bc,(dstackptr) ;bc = words[dstackptr];
	ld b,$00
	ld a,c ;if(c == 254)
	cp $fe
	jp nz,fstackpush2
	ld bc,stackoverflowtext ;cout << "Err: Stack Overflow" << endl;
	call print
	ld bc,$00fe
fstackpush2:
	ex de,hl ;de = hl
	ld hl,datastack ;hl = datastack
	add hl,bc ;hl += bc
	ld (hl),e ;words[hl] = e
	inc hl ;hl++
	inc c ;bc++
	ld (hl),d ;words[hl] = d
	inc c ;bc++
	ld a,c ;words[dstackptr] = c
	ld (dstackptr),a
	ret

;pull data stack value into HL
;requires A, BC, DE, HL registers, tested
fstackpull:
	ld bc,(dstackptr) ;bc = words[dstackptr]
	ld b,$00
	ld a,c ;if(c == 0)
	cp $00
	jp nz,fstackpull2
	ld bc,stackunderflowtext ;cout << "Err: Stack Underflow" << endl
	call print
	ld bc,$0000
fstackpull2:
	ld hl,datastack ;hl = datastack
	dec c ;bc--
	add hl,bc ;hl += bc
	ld d,(hl) ;d = words[hl]
	dec c ;bc--
	dec hl ;hl--
	ld e,(hl) ;e = words[hl]
	ld a,c ;words[dstackptr] = c;
	ld (dstackptr),a
	ex de,hl ;return hl
	ret

;push HL value onto return stack
;requires A, BC, DE, HL registers, tested
rtnpush:
	ld bc,(rstackptr) ;bc = words[rstackptr];
	ld b,$00
	ex de,hl ;de = hl
	ld hl,rtnstack ;hl = rtnstack
	add hl,bc ;hl += bc
	ld (hl),e ;words[hl] = e
	inc hl ;hl++
	inc c ;bc++
	ld (hl),d ;words[hl] = d
	inc c ;bc++
	ld a,c ;if(c == 64) c = 0
	and $3f
	ld (rstackptr),a ;words[rstackptr] = c
	ret

;pull return stack value into HL
;requires A, BC, DE, HL registers, tested
rtnpull:
	ld bc,(rstackptr) ;bc = words[rstackptr]
	ld b,$00
	ld a,c ;if(c == 0)
	cp $00
	jp nz,rtnpull2
	ld c,$40
rtnpull2:
	ld hl,rtnstack ;hl = rtnstack
	dec c ;bc--
	add hl,bc ;hl += bc
	ld d,(hl) ;d = words[hl]
	dec c ;bc--
	dec hl ;hl--
	ld e,(hl) ;e = words[hl]
	ld a,c ;words[rstackptr] = c;
	ld (rstackptr),a
	ex de,hl ;return hl
	ret

;push HL value onto loop stack
;requires A, BC, DE, HL registers, tested
lppush:
	ld bc,(lstackptr) ;bc = words[lstackptr];
	ld b,$00
	ex de,hl ;de = hl
	ld hl,lpmstack ;hl = lpmstack
	add hl,bc ;hl += bc
	ld (hl),e ;words[hl] = e
	inc hl ;hl++
	inc c ;bc++
	ld (hl),d ;words[hl] = d
	inc c ;bc++
	ld a,c ;if(c == 64) c = 0
	and $3f
	ld (lstackptr),a ;words[lstackptr] = c
	ret

;pull return stack value into HL
;requires A, BC, DE, HL registers, tested
lppull:
	ld bc,(lstackptr) ;bc = words[lstackptr]
	ld b,$00
	ld a,c ;if(c == 0)
	cp $00
	jp nz,lppull2
	ld c,$40
lppull2:
	ld hl,lpmstack ;hl = lpmstack
	dec c ;bc--
	add hl,bc ;hl += bc
	ld d,(hl) ;d = words[hl]
	dec c ;bc--
	dec hl ;hl--
	ld e,(hl) ;e = words[hl]
	ld a,c ;words[lstackptr] = c;
	ld (lstackptr),a
	ex de,hl ;return hl
	ret

;allows for dynamic calls to address HL
;requires HL register, tested
callHL:
	jp (hl)

;executes Forth word at address BC
;requires A, BC, HL registers, tested
execWord:
	ld a,(bc) ;hl = bc + (words[bc] & 0x1f) + 3
	and $1f
	add a,$03
	ld h,$00
	ld l,a
	add hl,bc
	ld a,(bc) ;if(words[bc] & 0x80)
	bit 7,a
	jp z,execWord2
	call callHL ;machineWord(hl)
	ret
execWord2:
	ld c,(hl) ;else while(true){ bc = words[hl]
	inc hl ;bc |= words[++hl] << 8
	ld b,(hl)
	ld a,b ;if(bc == 0xffff)
	and c
	cp $ff
	ret z ;return
	inc hl ;rtnpush(++hl)
	push bc
	call rtnpush
	pop bc
	call execWord ;execWord(bc)
	call rtnpull ;hl = rtnpull()
	jp execWord2 ;}

;finds address of word with name matching c string at wordbuff, return addr at BC
;requires A, BC, D, E, HL, IX, IY, tested
findWord:
	ld hl,(wordlatest)	;uint16_t hl = words[0x0183] | words[0x0184]<<8; //latest word
	ld bc,wordbuff		;uint8_t tmpvar1 = strlen(wordbuff); //get len of target word
	call strlen
	ld (tmpvar1),a
findWord2:
	ld a,(hl)			;do{ d = words[hl] & 0x1f; //get len of word
	and $1f
	ld d,a
	ld ix,$0000				;ix = hl; //start of word name
	ex de,hl
	add ix,de
	ex de,hl
	ld iy,tmpbuff			;iy = tmpbuff
	ld e,$00
findWord3:
	ld a,d					;for(e=0; d!=e; e++){
	cp e
	jp z,findWord4
	inc e
	ld a,(ix+3)					;words[iy] = words[ix+3]; //use temporary buffer
	ld (iy+0),a
	inc ix						;ix++
	inc iy						;iy++
	jp findWord3			;}
findWord4:
	ld a,$00				;words[iy] = 0; //terminate tmp buff
	ld (iy+0),a
	ld a,(dispwords)		;if(dispWords) cout << words+tmpbuff << " "; //display words
	cp $00
	jp z,findWord5
	ld bc,tmpbuff
	call print
	ld a,$20
	call serial
findWord5:
	ld a,(tmpvar1)			;if(d == tmpvar1 && strcmp(bc,tmpbuff)) break; //break if found word
	cp d
	jp nz,findWords6
	push hl
	ld bc,wordbuff
	ld hl,tmpbuff
	call strcmp
	pop hl
	cp $00
	jp z,findWords6
	jp findWords7
findWords6:
	inc hl					;ix = words[++hl] | words[++hl] << 8; //get next word address
	ld a,(hl)
	ld (tmpvar2),a
	inc hl
	ld a,(hl)
	ld (tmpvar2+1),a
	ld ix,(tmpvar2)
	ld hl,(tmpvar2)			;hl = ix;
	ld a,h				;} while(hl != 0xffff);
	and l
	cp $ff
	jp nz,findWord2
findWords7:
	ld b,h				;bc = hl
	ld c,l
	ret					;return bc

;initializes system variables and stuff
init: ;tested
	di
	ld sp,$0000
	ld hl,latestWord ;wordlatest =
	ld (wordlatest),hl
	ld hl,freeSpace ;wordend =
	ld (wordend),hl
	ld a,$00 ;...stackptr = 0
	ld (dstackptr),a
	ld (rstackptr),a
	ld (lstackptr),a
	ld (state),a
	ld (dispwords),a ;dispwords = false
	ld bc,headertext ;print header
	call print

;the shell part of the forth interpreter
main: ;tested
	ld bc,cursortext	;while(true){ cout << ">> ";
	call print
	call getInput			;cin.getline(inpbuff,256); //store to memory
							;words[inplen] = strlen(inpbuff); //inplen
							;words[inpind] = 0; //inpind
main2:						;while(true){ //while words in buffer
	call getBuffWord			;getBuffWord();
	ld a,(wordbuff) 			;if(!words[wordbuff]) break;
	cp $00
	jp z,main
	call findWord				;waddr = findWord(wordbuff);
	ld a,b						;if(waddr != 0xffff){ //check if in dict
	and c
	cp $ff
	jp z,main4
	ld a,(bc)						;if(words[waddr] & 0x20 && !words[state]){
	bit 5,a
	jp z,main5
	ld a,(state)
	cp $00
	jp nz,main5
	push bc								;cout << "Err: '" << wordbuff << "' is a compile only word" << endl;
	ld bc,comperrtext1
	call print
	ld bc,wordbuff
	call print
	ld bc,comperrtext2
	call print
	pop bc
	ld a,$00							;words[dstackptr] = 0
	ld (dstackptr),a
	jp main								;break
main5:
	ld a,(state)					;} else if(words[state] && !(words[waddr] & 0x40)){
	cp $00
	jp z,main3
	ld a,(bc)
	bit 6,a
	jp nz,main3
	ld h,b								;fstackpush(waddr);
	ld l,c
	call fstackpush
	ld bc,comma							;execWord(0x03e1); // comma
	call execWord
	jp main2
main3:
	call execWord					;} else execWord(waddr);
	jp main2
main4:
	push bc						;} else if(isNum(wordbuff)){ //check if number
	ld bc,wordbuff
	call isNum
	pop bc
	cp $00
	jp z,main6
	push bc							;fstackpush(toNum(wordbuff));
	ld bc,wordbuff
	call toNum
	call fstackpush
	pop bc
	ld a,(state)					;if(words[state]){
	cp $00
	jp z,main2
	ld hl,LIT							;fstackpush(0x032f) //LIT
	call fstackpush
	ld bc,comma							;execWord(0x03e1); //comma
	call execWord
	ld bc,comma							;execWord(0x03e1); //comma
	call execWord
	jp main2						;}
main6:							;} else{ //throw an error
	ld bc,comperrtext1				;cout << "Err: '" << wordbuff << "' is not a word" << endl;
	call print
	ld bc,wordbuff
	call print
	ld bc,worderrtext
	call print
	ld a,$00						;words[dstackptr] = 0;
	ld (dstackptr),a
	jp main							;break; } } }

headertext:
db " uForth v0.9.5",$0d,$0a
db "(c) y47 KH-Labs",$00
cursortext:
db $0d,$0a,">> ",$00
stackoverflowtext:
db $0d,$0a,"Err: Stack Overflow",$0d,$0a,$00
stackunderflowtext:
db $0d,$0a,"Err: Stack Underflow",$0d,$0a,$00
comperrtext1:
db $0d,$0a,"Err: '",$00
comperrtext2:
db "' is a compile only word",$00
worderrtext:
db "' is not a word",$00

;			machine,immediate,compiler
; LIT		101		( -- n1 ) get next number from program and push to stack
LIT: ;tested
	db $a3,$ff,$ff,"LIT"
	call rtnpull ;hl = rtnpull();
	ld c,(hl) ;bc = words[hl+1]<<8 | words[hl];
	inc hl
	ld b,(hl)
	inc hl ;rtnpush(hl+2);
	push bc
	call rtnpush
	pop bc ;fstackpush(bc);
	ld h,b
	ld l,c
	call fstackpush
	ret
; ,			100		( n1 -- ) writes n1 into the memory at WEND and updates WEND position
comma: ;tested
	db $81,LIT&$ff,LIT>>8,","
	call fstackpull ;tmp = fstackpull();
	ld bc,(wordend) ;words[*(uint16_t*)(wordend)] = tmp & 0xff
	ld a,l
	ld (bc),a
	inc bc ;words[wordend]++;
	ld a,h ;words[*(uint16_t*)(wordend)] = tmp >> 8
	ld (bc),a
	inc bc ;words[wordend]++;
	ld (wordend),bc
	ret
; +			100		( n1 n2 -- n3 ) add n2 to n1
plus: ;tested
	db $81,comma&$ff,comma>>8,"+"
	call fstackpull ;bc = fstackpull()
	push hl
	call fstackpull ;hl = fstackpull()
	pop bc
	add hl,bc ;hl += bc
	call fstackpush ;fstackpush(hl)
	ret
; -			100		( n1 n2 -- n3 ) subtract n2 from n1
minus: ;tested
	db $81,plus&$ff,plus>>8,"-"
	call fstackpull ;bc = fstackpull()
	push hl
	call fstackpull ;hl = fstackpull()
	pop bc
	or a ;hl -= bc
	sbc hl,bc
	call fstackpush ;fstackpush(hl)
	ret
; *			100		( n1 n2 -- n3 ) multiply n2 to n1
times: ;tested
	db $81,minus&$ff,minus>>8,"*"
	call fstackpull ;bc = fstackpull()
	push hl
	call fstackpull ;de = fstackpull()
	ld d,h
	ld e,l
	pop bc
	call multiply ;hl = bc*de
	call fstackpush ;fstackpush(hl)
	ret
; /mod		100		( n1 n2 -- n3 n4 ) divide and mod n2 from n1
divmod: ;WIP, doesn't support negative
	db $84,times&$ff,times>>8,"/mod"
	call fstackpull ;bc = fstackpull()
	push hl
	call fstackpull ;hl = fstackpull()
	pop bc
	call divide ;fstackpush(hl / bc) ;divide HL by BC, HL=HL%BC, DE=HL/BC
	push hl
	ex de,hl
	call fstackpush
	pop hl ;fstackpush(hl % bc)
	call fstackpush
	ret
; emit		100		( n1 -- ) output the character of the ascii value of n1
emit: ;tested
	db $84,divmod&$ff,divmod>>8,"emit"
	call fstackpull ;hl = fstackpull()
	ld a,l ;cout << l
	call serial
	ret
; .			100		( n1 -- ) display n1 followed by a space
period: ;tested
	db $81,emit&$ff,emit>>8,"."
	call fstackpull ;hl = fstackpull()
	call printNum ;cout << hl
	ld a,$20 ;cout << ' '
	call serial
	ret
; CREATE	100		( n1 -- ) create the header for a word/constant/variable from string address n1
create: ;tested
	db $86,period&$ff,period>>8,"CREATE"
	call fstackpull ;hl = fstackpull();
	ld bc,(wordend) ;bc = *(uint16_t*)(wordend); //start of this word
	push bc ;words[bc] = strlen(hl); bc++; //lenflag byte
	ld b,h
	ld c,l
	call strlen
	pop bc
	ld (bc),a
	inc bc
	ld a,(wordlatest) ;words[bc] = words[wordlatest]; bc++; //next ptr
	ld (bc),a
	inc bc
	ld a,(wordlatest+1) ;words[bc] = words[wordlatest+1]; bc++;
	ld (bc),a
	inc bc
	ld (wordend),bc ;*(uint16_t*)(wordend) = bc; //set wend
	dec bc ;*(uint16_t*)(wordlatest) = bc-3; //set latest to this word
	dec bc
	dec bc
	ld (wordlatest),bc
	ld bc,(wordend) ;bc = *(uint16_t*)(wordend);
create2:
	ld a,(hl) ;while(words[hl]){ //insert word
	cp $00
	jp z,create3
	ld (bc),a ;words[bc] = words[hl];
	inc bc ;bc++; hl++
	inc hl
	jp create2 ;}
create3:
	ld (wordend),bc ;*(uint16_t*)(wordend) = bc;
	ret
; c!		100		( n1 n2 -- ) save the low 8 bits of n1 to the address n2
cex: ;tested
	db $82,create&$ff,create>>8,"c!"
	call fstackpull
	push hl
	call fstackpull
	ld a,l
	pop hl
	ld (hl),a
	ret
; c@		100		( n1 -- n2 ) get the byte at the address n1
cat: ;tested
	db $82,cex&$ff,cex>>8,"c@"
	call fstackpull
	ld a,(hl)
	ld h,$00
	ld l,a
	call fstackpush
	ret
; !			100		( n1 n2 -- ) save n1 to the address n2
exp: ;tested
	db $81,cat&$ff,cat>>8,"!"
	call fstackpull
	push hl
	call fstackpull
	ld b,h
	ld c,l
	pop hl
	ld (hl),c
	inc hl
	ld (hl),b
	ret
; @			100		( n1 -- n2 ) get the value at the address n1
ats: ;tested
	db $81,exp&$ff,exp>>8,"@"
	call fstackpull
	ld c,(hl)
	inc hl
	ld b,(hl)
	ld h,b
	ld l,c
	call fstackpush
	ret
; STATE		000		( -- n1 ) leave the address of the state variable in the stack, 0 is interpret, -1 is compile
statevar: ;tested
	db $05,ats&$ff,ats>>8,"STATE"
	dw LIT,state,$ffff
; LATEST	000		( -- n1 ) leave the address of the latest word variable in the stack
latest: ;tested
	db $06,statevar&$ff,statevar>>8,"LATEST"
	dw LIT,wordlatest,$ffff
; WEND		000		( -- n1 ) leave the address of the end of words variable in the stack
wend: ;tested
	db $04,latest&$ff,latest>>8,"WEND"
	dw LIT,wordend,$ffff
; BKEY		101		( -- n1 ) gets next char from input buffer and leaves in stack
bkey: ;tested
	db $a4,wend&$ff,wend>>8,"BKEY"
	call getBuffKey
	ld h,$00
	ld l,a
	call fstackpush
	ret
; BWORD		101		( -- n1 ) gets next word in input buffer and leaves address in stack
bword: ;tested
	db $a5,bkey&$ff,bkey>>8,"BWORD"
	call getBuffWord
	ld hl,wordbuff
	call fstackpush
	ret
; :			010		( -- ) start compiling sequence, create and state to -1
colon: ;tested
	db $41,bword&$ff,bword>>8,":"
	dw LIT,$ffff,statevar,cex,bword,create,$ffff
; ;			011		( -- ) add 0xffff to the end of program and make state 0
semicolon: ;tested
	db $61,colon&$ff,colon>>8,";"
	dw LIT,$ffff,comma,LIT,$0000,statevar,cex
	dw LIT,$004f,emit,LIT,$004b,emit,$ffff
; key		100		( -- n1 ) get the ascii value of the first key pressed
key: ;tested
	db $83,semicolon&$ff,semicolon>>8,"key"
	call getKey
	ld h,$00
	ld l,a
	call fstackpush
	ret
; word		100		( -- n1) gets a string from input and leaves the address of the string
gword: ;tested
	db $84,key&$ff,key>>8,"word"
	call getWord
	ld hl,wordbuff
	call fstackpush
	ret
; number	100		( -- n1 ) gets a number from input
number: ;tested
	db $86,gword&$ff,gword>>8,"number"
	call getWord
	ld bc,wordbuff
	call toNum
	call fstackpush
	ret
; words		100		( -- ) display all the words in the forth dictionary
words: ;tested
	db $85,number&$ff,number>>8,"words"
	ld a,$ff
	ld (dispwords),a
	ld a,$00
	ld (wordbuff),a
	call findWord
	ld a,$00
	ld (dispwords),a
	ret
; swap		100		( n1 n2 -- n2 n1 ) switch the top 2 elements on the stack
swap: ;tested
	db $84,words&$ff,words>>8,"swap"
	call fstackpull
	push hl
	call fstackpull
	pop de
	ex de,hl
	push de
	call fstackpush
	pop hl
	call fstackpush
	ret
; dup		100		( n1 -- n1 n1 ) duplicates top of stack
dupl: ;tested
	db $83,swap&$ff,swap>>8,"dup"
	call fstackpull
	push hl
	call fstackpush
	pop hl
	call fstackpush
	ret
; drop		100		( n1 -- ) pop n1 from stack
drop: ;tested
	db $84,dupl&$ff,dupl>>8,"drop"
	call fstackpull
	ret
; =			100		( n1 n2 -- n3 ) true if n1 equals n2, else false
equal: ;tested
	db $81,drop&$ff,drop>>8,"="
	call fstackpull
	push hl
	call fstackpull
	pop bc
	or a
	sbc hl,bc
	ld a,h
	or l
	cp $00
	jp z,equal2
	ld hl,$0000
	call fstackpush
	ret
equal2:
	ld hl,$ffff
	call fstackpush
	ret
; <>		100		( n1 n2 -- n3 ) true if n1 not equals n2, else false
nequ: ;tested
	db $82,equal&$ff,equal>>8,"<>"
	call equal+4
	call fstackpull
	ld a,h
	xor $ff
	ld h,a
	ld a,l
	xor $ff
	ld l,a
	call fstackpush
	ret
; <			100		( n1 n2 -- n3 ) true if n1 less than n2, else false
lesst: ;tested
	db $81,nequ&$ff,nequ>>8,"<"
	call fstackpull
	push hl
	call fstackpull
	pop bc
	or a
	sbc hl,bc
	bit 7,h
	jp z,lesst2
	ld hl,$ffff
	call fstackpush
	ret
lesst2:
	ld hl,$0000
	call fstackpush
	ret
; >			100		( n1 n2 -- n3 ) true if n1 greater than n2, else false
gtrt: ;tested
	db $81,lesst&$ff,lesst>>8,">"
	call fstackpull
	push hl
	call fstackpull
	pop bc
	or a
	sbc hl,bc
	bit 7,h
	jp nz,gtrt2
	ld a,h
	or l
	cp $00
	jp z,gtrt2
	ld hl,$ffff
	call fstackpush
	ret
gtrt2:
	ld hl,$0000
	call fstackpush
	ret
; <=		100		( n1 n2 -- n3 ) true if n1 less than equal n2, else false
lesseq: ;tested
	db $82,gtrt&$ff,gtrt>>8,"<="
	call gtrt+4
	call fstackpull
	ld a,h
	xor $ff
	ld h,a
	ld a,l
	xor $ff
	ld l,a
	call fstackpush
	ret
; >=		100		( n1 n2 -- n3 ) true if n1 greater than equal n2, else false
gtrequ: ;tested
	db $82,lesseq&$ff,lesseq>>8,">="
	call lesst+4
	call fstackpull
	ld a,h
	xor $ff
	ld h,a
	ld a,l
	xor $ff
	ld l,a
	call fstackpush
	ret
; and		100		( n1 n2 -- n3 ) logic and n1 & n2
andd: ;tested
	db $83,gtrequ&$ff,gtrequ>>8,"and"
	call fstackpull
	push hl
	call fstackpull
	pop bc
	ld a,h
	and b
	ld h,a
	ld a,l
	and c
	ld l,a
	call fstackpush
	ret
; or		100		( n1 n2 -- n3 ) logic or n1 & n2
orr: ;tested
	db $82,andd&$ff,andd>>8,"or"
	call fstackpull
	push hl
	call fstackpull
	pop bc
	ld a,h
	or b
	ld h,a
	ld a,l
	or c
	ld l,a
	call fstackpush
	ret
; xor		100		( n1 n2 -- n3 ) logic xor n1 & n2orr:
xxor: ;tested
	db $83,orr&$ff,orr>>8,"xor"
	call fstackpull
	push hl
	call fstackpull
	pop bc
	ld a,h
	xor b
	ld h,a
	ld a,l
	xor c
	ld l,a
	call fstackpush
	ret
; .s		100		( -- ) display all the numbers in the stack without popping the stack
dots: ;tested
	db $82,xxor&$ff,xxor>>8,".s"
	ld a,$3d ;cout << "=>"
	call serial
	ld a,$3e
	call serial
	ld bc,datastack ;bc = datastack
	ld d,$00 ;d = 0
dots2:
	ld a,(dstackptr) ;while(d != words[dstackptr]){
	cp d
	ret z
	ld a,$20 ;cout << ' '
	call serial
	ld a,(bc) ;l = words[bc++]
	ld l,a
	inc bc
	ld a,(bc) ;h = words[bc++]
	ld h,a
	inc bc
	inc d ;d += 2
	inc d
	push bc ;cout << hl
	push de
	call printNum
	pop de
	pop bc
	jp dots2 ;}
; reboot	100		( -- ) restarts the computer
exit: ;tested
	db $86,dots&$ff,dots>>8,"reboot"
	rst 0
	ret
; >r		100		( n1 -- ) push n1 to the return stack
pushr: ;tested
	db $82,exit&$ff,exit>>8,">r"
	call fstackpull
	call rtnpush
	ret
; r>		100		( -- n1 ) pop n1 from the return stack
pullr: ;tested
	db $82,pushr&$ff,pushr>>8,"r>"
	call rtnpull
	call fstackpush
	ret
; r@		100		( -- n1 ) copy the top value from the return stack
rat: ;tested
	db $82,pullr&$ff,pullr>>8,"r@"
	call rtnpull
	push hl
	call rtnpush
	pop hl
	call fstackpush
	ret
; >l		100		( n1 -- ) push n1 to the loop stack
pushl: ;tested
	db $82,rat&$ff,rat>>8,">l"
	call fstackpull
	call lppush
	ret
; l>		100		( -- n1 ) pop n1 from the loop stack
pulll: ;tested
	db $82,pushl&$ff,pushl>>8,"l>"
	call lppull
	call fstackpush
	ret
; type		100		( n1 -- ) string is displayed starting from the address n1
typee: ;tested
	db $84,pulll&$ff,pulll>>8,"type"
	call fstackpull
	ld b,h
	ld c,l
	call print
	ret
; FIND		100		( -- n1 ) find the address n1 of a word with name in wordbuff
find: ;tested
	db $84,typee&$ff,typee>>8,"FIND"
	call findWord
	ld h,b
	ld l,c
	call fstackpush
	ret
; WBUFF		000		( -- n1 ) leaves the address of the start of the word buffer in the stack
wbuff: ;tested
	db $05,find&$ff,find>>8,"WBUFF"
	dw LIT,wordbuff,$ffff
; EXEC		100		( n1 -- ) executes the word with address n1
exec: ;tested
	db $84,wbuff&$ff,wbuff>>8,"EXEC"
	call fstackpull
	ld b,h
	ld c,l
	call execWord
	ret
; BRANCH	101		( -- ) replace the top of return stack with next number in program
branch: ;tested
	db $a6,exec&$ff,exec>>8,"BRANCH"
	call rtnpull ;bc = rtnpull();
	ld b,h
	ld c,l
	ld a,(bc) ;l = words[bc++];
	ld l,a
	inc bc
	ld a,(bc) ;h = words[bc] << 8;
	ld h,a
	call rtnpush ;rtnpush(hl);
	ret
; 0BRANCH	101		( -- ) replace the top of return stack with next number in program if top of stack is 0
branch0: ;tested
	db $a7,branch&$ff,branch>>8,"0BRANCH"
	call fstackpull ;if(fstackpull()){ //branch past
	ld a,h
	or l
	cp $00
	jp z,branch02
	call rtnpull ;	tmp2 = rtnpull();
	inc hl ;	rtnpush(tmp2+2);
	inc hl
	call rtnpush
	ret
branch02:
	call branch ;} else branch() //branch to addr
	ret
; VERSION	000		( -- n1 ) leave the forth version * 100 on the stack
version: ;tested
	db $07,branch0&$ff,branch0>>8,"VERSION"
	dw LIT,$005f,$ffff
; constant	010		( n1 -- ) create a word that leaves the value n1 in the stack
constant: ;tested
	db $48,version&$ff,version>>8,"constant"
	dw bword,create,LIT,LIT,comma,comma,LIT,$ffff,comma,$ffff
; variable	010		( -- ) create a word that leaves the address for a variable in the stack
latestWord:
variable: ;tested
	db $48,constant&$ff,constant>>8,"variable"
	dw bword,create,LIT,LIT,comma,wend,ats,LIT,$0004,plus,comma,LIT,$ffff,comma,LIT,$0000,comma,$ffff
; cr		000		( -- ) prints a carriage return and new line
; +!		100		( n1 n2 -- ) adds n1 to the value at address n2
; pick		100		( n1 n2 +n -- n1 n2 n1 ) copy the +nth value from stack (not counting +n, starting at 0) and place on top
; roll		100		( n1 n2 +n -- n2 n1 ) move the +nth value from stack (not counting +n, starting at 0) to the top of stack
; count		100		( n1 -- n2 ) gets the length of a string at n1 and puts the length n2 on the stack
; compare	100		( n1 n2 -- n3 ) compares strings at address n1 and n2 and returns 0 for false or -1 for true
; /			000		( n1 n2 -- n3 ) leaves division result of n1 and n2
; mod		000		( n1 n2 -- n3 ) leaves modulo result of n1 and n2
; negate	000		( n1 -- n2 ) leaves 2's complement of n1 in stack
; over		000		( n1 n2 -- n1 n2 n1 ) duplicates second number in stack
; rot		000		( n1 n2 n3 -- n2 n3 n1 ) rotates third number in stack to top
; -rot		000		( n1 n2 n3 -- n3 n1 n2 ) rotates top number to third place in stack
; cells		000		( n1 -- n2 ) multiplies n1 with size of number cell (2 for 16 bit number system)
; invert	000		( n1 -- n2 ) logic not n1
; allot		000		( n1 -- ) increment program end counter by n1
; IMMEDIATE	000		( -- ) toggle immediate flag on latest word
; (			010		( -- ) start of a comment, comment ends at first ) character
; begin		011		( -- ) specified return address for repeat/until
; until		011		( n1 -- ) branch to begin statement in begin-until loop if n1 is false
; while		111		( n1 -- ) branch past repeat if n1 is false in do-while-repeat loop
; repeat	111		( -- ) branch to begin statement in begin-while-repeat loop
; +loop		111		( n1 -- ) increments loop counter by n1
; loop		011		( -- ) like +loop but increment by 1 automatically
; I			101		( -- n1 ) leaves a copy of the top of the loop control stack on the stack
; J			101		( -- n1 ) leaves a copy of the second element of the loop control stack on the stack
; K			101		( -- n1 ) leaves a copy of the third element of the loop control stack on the stack
; if		111		( n1 -- ) beginning of if statement, jump to else/then if false
; else		111		( -- ) an if's else statement, jump to then if if is true
; then		111		( -- ) set if's false branch to then's location
; leave		101		( -- ) pop the second element from the return stack to break a loop
; do		111		( n1 n2 -- ) starts a loop with n1 as a terminator and n2 as a starting index
; ABORT"	011		( n1 ... -- ) clears the stacks, displays "error", returns to interpreter
; ."		011		( -- ) displays the characters until the first " character
; FORTH		000		( -- ) the forth interpreter/compiler

endOfProg:
nop

org $2000 ;tmp buff, 32B $2000
tmpbuff: nop
org tmpbuff+32 ;inp buff, 256B $2020
inpbuff: nop
org inpbuff+256 ;word buff, 32B $2120
wordbuff: nop
org wordbuff+32
inpind: nop ;input index, 1B $2140
inplen: nop ;input length, 1B $2141
wordlatest: dw $0000 ;word latest, 2B $2142
wordend: dw $0000 ;word end, 2B $2144
datastack: nop ;data stack, 256B $2146
org datastack+256
rtnstack: nop ;return stack, 64B $2246
org rtnstack+64
lpmstack: nop ;loop/misc stack, 64B
org lpmstack+64
dstackptr: nop ;data stack pointer, 1B
rstackptr: nop ;return stack pointer, 1B
lstackptr: nop ;loop/misc stack pointer, 1B
state: nop ;shell state, 1B
dispwords: nop ;display words boolean, 1B
tmpvar1: dw $0000 ;temp variable 1, 2B
tmpvar2: dw $0000 ;temp variable 2, 2B
tmpvar3: dw $0000 ;temp variable 3, 2B
tmpvar4: dw $0000 ;temp variable 4, 2B
freeSpace: nop
