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
    mov bx, 0x7e00
    int 13h

    mov bl,1
    call check_disk_operation_success

    ;protected mode loader section
load_protected_mode:
    mov si, msg3
    call printf

    ;checking A20
    in al, 0x92
    or al, 2
    out 0x92, al

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





		;Add boot signature at the end of bootloader
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
    
    ; *** CORREZIONE: usa EDI come puntatore ***
    mov edi, 0xB8000     ; Indirizzo base

    mov byte [edi], 'A'      ; Carattere ASCII
    mov byte [edi+1], 0x0F     ; Attributo (bianco su nero)
    
    ; Scrivi anche 'B' per essere sicuro
    mov byte [edi+2], 'B'
    mov byte [edi+3], 0x0F














JMP $
TIMES 1024 - ($ - $$) db 0