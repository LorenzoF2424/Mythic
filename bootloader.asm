bits 16
org 0x7c00


lea si,[msg]
call printf

lea si,[msg2]
call printf

lea si,[msg3]
call printf


JMP $

printf:

    

    mov ah,0x0e
    mov al,[si]

    cmp al,0
    je fineprint

    int 10h


    inc si

jmp printf
fineprint:

ret


msg db "bootloader eseguito!", 13, 10, 0
msg2 db "valerio e' un omosessuale bastardo gay", 13, 10, 0
msg3 db "simone ti prego baciami", 0


TIMES 510 - ($ - $$) db 0	;Fill the rest of sector with 0
DW 0xAA55			;Add boot signature at the end of bootloader