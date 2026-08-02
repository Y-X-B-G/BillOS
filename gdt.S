.code16 //Bootloader needs to have 16 bit code
.globl gdt_set //this must be available to other file

gdt_set:
	movw 2(%bp), %ax	;//Move the argument into the %ax register
	lgdt (%ax)		;
	movw 0x10, %ax		;Set all segment registers to kernel data segment except CS
	movw %ax, %ds		;
	movw %ax, %es		;
	movw %ax, %ss		;
	movw %ax, %fs		;
	movw %ax, %gs		;
	jmp 0x8:setcodeseg	;A far jump is apparently the only way to set this
setcodeseg:
	ret
