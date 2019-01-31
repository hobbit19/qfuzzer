; =========================================================================== ;
; /src/boot_early/boot.s                                                      ;
; Copyright (C) 2018, k4m1 <k4m1@protonmail.com>                              ;
; All rights reserved.                                                        ;
; See /LICENSE for whole license text.                                        ;
;                                                                             ;
; This code acts as the initial entry point for the bootloader.               ;
; First we'll setup unreal mode, then load rest of the loader and jump to     ;
; second stage of the bootloader.                                             ;
; =========================================================================== ;

org	0x7c00
bits	16
align	4

%define SECTOR_COUNT 15

; clearing out CS
jmp	0x0000:start

BOOT_DEVICE db 0
BL_SECTORS db 0

start:
	xor	ax, ax
	mov	ds, ax
	mov	ss, ax
	mov	sp, 0x9c00
	
	; swapping to unreal mode
	cli
	push	ds
	lgdt	[dummy_gdt]
	mov	eax, cr0
	or	al, 1
	mov	cr0, eax
	jmp	.pmode
.pmode:
	mov	bx, 0x08
	mov	ds, bx
	and	al, 0xFE
	mov	cr0, eax
	pop	ds
	sti

	; now we're in unreal mode, we have access to 32-bit registers
	; and to BIOS interrupts.

	mov	[BOOT_DEVICE], dl

	; clearing the screen
	xor	eax, eax
	mov	al, 0x03
	int	0x10


; ============================================================================ ;
; Function to load 2nd stage bootloader from disk.                             ;
; ============================================================================ ;

load_second_stage:
	mov	bx,  _start
	mov	dh, SECTOR_COUNT
	mov	dl, [BOOT_DEVICE]
	mov	byte [BL_SECTORS], dh
	xor	ch, ch
	xor	dh, dh
	mov	cl, 0x02
	.read_start:
		mov	di, 5
	.read:
		mov	ah, 0x02
		mov	al, [BL_SECTORS]
		int	0x13
		jc	.retry
		sub	[BL_SECTORS], al
		jz	.read_done
		mov	cl, 0x01
		xor	dh, 1
		jnz	.read_start
		inc	ch
		jmp	.read_start
	.retry:
		; disk read failed, reseting disk & retrying
		xor	ah, ah
		int	0x13
		dec	di
		jnz	.read
		mov	si, msg_disk_read_failed
		call	panic_early
	.read_done:
		jmp	_start

msg_disk_read_failed db "Failed to read boot disk.", 0x0A, 0

hang:
	cli
	hlt
	jmp	hang

panic_early:
	lodsb
	or	al, al
	mov	ah, 0x0E
	int	0x10
	cmp	al, 0
	jne	panic_early
.hang:
	cli
	hlt
	jmp	.hang


dummy_gdt:
	dw	gdt_end - gdt - 1
	dd	gdt
gdt:
	dq	0
	dw	0xffff
	dw	0
	db	0
	db	10010010b
	db	11001111b
	db	0
gdt_end:

times	510-($-$$) db 0
dw	0xAA55

%include "src/boot_early/second_stage.s"

