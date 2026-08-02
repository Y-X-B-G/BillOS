.code16
//If functions need to return a value just write it to one of the D registers  
.global _start
_start:	
	cli;//Disables interrupts because we don't want the bootloader to be interrupted
	xorw %ax, %ax		;
	movw %ax, %ds		;//Set all segment registers to 0
	movw %ax, %es		;
	movw %ax, %ss		;
	movw %ax, %fs		;
	movw %ax, %gs		;movw %ax, %ss		;//Set the stack segment register to 0
	movw $0x7BFF, %sp	;//Sets the stack and base pointers remember that it grows downwards from 0x7Bff to 0x500
	movw $0x7BFF, %bp	;
				//We need to check and see if the A20 line is enabled
				//We can do this by  writing to memory we don't have access to if it was enabled and seeing if it looped back around
				//0x500 - 0x7bff are the first bytes of convential memory we have access to so we can write to 0x100500 - 0x107bff and see if it gets looped back around
				//Write 0 to 0x500 then write 1 to 0x100500 then check 0x500 to see if it got overwritten
				// to address 0x100500 its seg*16+offset so 0x1000
	movw $0x0500, %bx	;
	movw $0x0, %es:(%bx)	;
	
	movw $0xFFFF, %ax	;
	movw %ax, %ex		;
	movw $0x510, %bx	;
	movw $0x01, %es:(%bx)	;
	
	cmp $0x01,  %es:(%bx)	;
	JNE A20alreadyenabled	;
waitforstatus:	
	call checkstatus	;//The second bit of the status register must be clear before we can write to the IO port
	and $0x2, %dl		;//Isolate the 2nd bit
	cmp $0x2, %dl		;//If the 2nd bit is not clear we loop until its clear
	JE waitforstatus	;//OK THIS MIGHT CAUSE AN INFINITE LOOP NOW THAT I THINK ABOUT IT ASK SOMEONE HOW TO FIX THIS
	call setA20		;//Since the 2nd bit is clear we are free to set A20	
A20alreadyenabled:	
	call gdt_init		;This should set up the gdt and segment registers again check gdt.h, gdt.c, and gdt.S for implementation

	mov %cr0, %eax 		;//Get the Cr0 register bits
	or 0x1, %eax		;//Set bit 0 to 1 to enabled protected mode
	mov %eax, %cr0		;//Write back to Cr0

	call bootmain		;
	
checkstatus:
	in  0x64, %dl		;//read the status register from the control port int %dl
	ret			;
setA20:
	call checkstatus	;//We need to copy the current byte in the output port and just flip the A20 bit this way we wont mess anything up
	and $0x1, %dl		;//Isolate the 1st bit 
	cmp $0x1, %dl		;//If 1st bit is set we are ready to read
	JNE setA20 		;//AGAIN INFINITE LOOP MAYBE 
	movw $0xD0, %al		;//Command to read the output port
	in 0x60, %bl		;//get response byte from the output port and put into %bl
	or $0x2, %bl		;//Flip bit 1 to enable A20
waitforwrite1:	
	call checkstatus	;//We should check that the input buffer is free to be written to 
	and $0x2, %dl		;//Isolate the 1st bit
	cmp $0x2, %dl		;//Check the second bit to see if its clear
	JE waitforwrite1	;//Loop if bit is not clear
	movw $0xD1, %al		;//0xD1 is the command to write the next byte to the output register
	out %al, 0x64		;//Write 0xD1 to 0x64 which means the next out should be written to the output i hope
waitforwrite2:
	call checkstatus	;
	and $0x2, %dl		;//Isolate the 1st bit
	cmp $0x2, %dl		;//Check the second bit to see if its clear
	JE waitforwrite2	;//loop if bit isn't clear
	out %bl, 0x60		;//THIS ENABLES A20
	ret			;
filler:	
	times 510-($$-$) db 0	; //Fills any unused bits with 0
	db 0x55 		; //0x55AA is the end of sector marker and marks the end of the bootloader
	db 0xAA			;
	
