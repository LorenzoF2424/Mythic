bits 16
org 0x7c00
    
    ;variables initialization
    xor ax, ax
    mov ds, ax
    mov es, ax      
    mov ss, ax
    mov sp, 0x7c00
    mov [diskNum],dl

    mov si, msg
    call printf

    ;expanding available memory space on the disk

    mov si, msg2
    call printf




    mov ax, 0
    mov es , ax
    mov ah,2
    mov al,1
    mov ch,0
    mov cl,2
    mov dh,0
    mov dl,[diskNum]
    mov bx, 0x7E00
    int 13h

    mov bl,1
    call check_disk_operation_success

    ;protected mode loader section
    mov si, msg3
    call printf

    ;checking A20
    call enable_A20

    ;loading descriptor
    cli
    lgdt [GDT_Descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ;start 32bit protected mode
    jmp CODE_SEG:protected_mode

; QUA FINISCE IL CODICE DIRETTO DEL PRIMO SETTORE
; ALLA LINEA 181 COTINUA







printf:
   push ax
    push bx
    

    .printLoop:
    
        
        mov ah,14
        mov al,[si]

        cmp al,0
        je .finished

        int 10h


        inc si

    jmp .printLoop
    .finished:
      
    pop bx
    pop ax
ret


check_disk_operation_success:
    jc .disk_error
    jmp .false1
    .disk_error:

        mov si, cfE
        call printf

    jmp .if1end
    .false1:

        mov si, cfC
        call printf
    .if1end:

    cmp al,bl
    je .true2
    jmp .false2
    .true2:
        mov si, alT
        call printf
    jmp .if2end
    .false2:

        mov si, alF
        call printf
    .if2end:

ret



diskNum db 0
msg db "Bootloader trovato!!! Eseguendo il codice.....", 13, 10, 0
msg2 db "Ampliando spazio di memoria dedicato al bootloader....", 13, 10, 0

cfE db "cf = true, Lettura del Disco NON Riuscita Correttamente!!", 13, 10, 0
cfC db "cf = false, Lettura Riuscita Correttamente!!", 13, 10, 0
alT db "al e' corretto, sono stati letti tutti i settori", 13, 10, 0
alF db "al NON e' corretto, uno o piu settori non sono stati letti", 13, 10, 0

TIMES 510 - ($ - $$) db 0	;Fill the rest of sector with 0
DW 0xAA55	


;=========================================================================
;||                           SECTOR 2                                  ||
;=========================================================================

msg3 db "Avviando modalita' protetta a 32 bit......", 13, 10, 0

enable_A20:
    pusha
    in al, 0x92
    or al, 2
    out 0x92, al
    popa
ret

GDT_Start:
    null_descriptor:
        dq 0
        
    code_descriptor:
        dw 0xffff
        dw 0
        db 0
        db 10011010b
        db 11001111b
        db 0
    data_descriptor:
        dw 0xffff
        dw 0
        db 0
        db 10010010b
        db 11001111b
        db 0

        
    
 
GDT_End:
GDT_Descriptor:
    dw GDT_End - GDT_Start - 1 ; size
    dd GDT_Start               ; start

CODE_SEG equ code_descriptor - GDT_Start
DATA_SEG equ data_descriptor - GDT_Start ; equ sets constants




bits 32
protected_mode:


    mov ax, DATA_SEG     ; 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    mov esp, 0x00090000  ; Stack sicuro
    
    ; edi = display cursor
    ;mov byte [edi], 'A'      ; ASCII CHAR
    ;mov byte [edi+1], 0x0F     ; Attributes (white on black)



    mov dl,39
    mov dh,8
    call loadAt
    mov byte [edi], 'C'     
    mov byte [edi+1], 0x0F     
    mov byte [edi+2], 'I'
    mov byte [edi+3], 0x0F
    mov byte [edi+4], 'A'
    mov byte [edi+5], 0x0F
    mov byte [edi+6], 'O'
    mov byte [edi+7], 0x0F


 










    ;call load_Long_Mode
JMP $

loadAt: ;converte dl in colonna e dh in riga(l*h)
    push ebx
    push eax
    push ecx

    mov ebx,0xB8000
    mov eax,80
    mul dh
    add al, dl
    mov cl,2
    mul cx
    add ebx,eax
    mov edi,ebx

    pop ecx
    pop eax
    pop ebx
ret


load_Long_Mode:

    mov eax, cr0
    and eax,0x7FFFFFFF
    mov cr0,eax
    mov eax, cr4
    or eax,0x620
    mov cr4,eax

ret

TIMES 1024 - ($ - $$) db 0


