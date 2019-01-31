; =========================================================================== ;
; src/boot_early/second_stage.s                                               ;
; Copyright (C) 2018, k4m1 <k4m1@protonmail.com>                              ;
; See /LICENSE for full license text.                                         ;
;                                                                             ;
; This is the beginning of the second stage of bootloader.                    ;
; Main purpose of the following code is to enable a20 gate, and then find     ;
; kernel from the boot disk.                                                  ;
; =========================================================================== ;

[ BITS 16 ]
_start:
	jmp 	main

; =========================================================================== ;
; defines, macros, etc ...                                                    ;
; =========================================================================== ;
%define kernel_found 1
%define sector_size 0x1000

; =========================================================================== ;
; boot device backup                                                          ;
; =========================================================================== ;
boot_device_db db 0, 0

; =========================================================================== ;
; Main function of second stage entry.                                        ;
; =========================================================================== ;
main:
	xor	ebp, ebp
	mov	esp, 0x9c00

	mov 	al, [BOOT_DEVICE]
	mov 	[boot_device_db], al

	



