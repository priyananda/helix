[BITS 16]

; Calling convention: the C code is built with gcc -m16, which emits
; 32-bit calls (4-byte return addresses, 4-byte stack arguments). Any
; routine called from C must therefore return with "retd", and calls
; into C (or into a routine shared with C) must use "call dword".

extern main
; ****************************CODE-Segment*********************************
section	.text

[GLOBAL start]
[GLOBAL	put_string]
start:	;Actual Entry Point
pmain:
	mov ax, cs
	mov ds, ax
	mov es, ax

	;temp start
	mov  si, tempmsg
	call dword put_string
	; temp end

	cli
	xor ax,ax
	mov ss, ax		; Stack segment  0x0000
	mov esp, 0xA000	    ; Stack start is 0xA000 (gcc -m16 code addresses via esp/ebp)
	xor ebp, ebp
	sti

	call dword main		; C code main
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Prints a null terminated string in DS:SI
;
[GLOBAL	put_string]
put_string:		; called from C: clobbers eax, ebx, esi
	mov	bx, 7
	mov	ah,0eh
.do:
	mov	al,[si]
	inc	si
	or al,al
	jz .done
	int	10h
	jmp	.do
.done:
	retd
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Control never comes here
	int 19h
	tempmsg db 10, "Nimmajji", 10, 0


%include "gdt.asm"	; The Tables and other stuff related to GDT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Data-Segment;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section	.data

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Bss-Segment;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section	.bss
