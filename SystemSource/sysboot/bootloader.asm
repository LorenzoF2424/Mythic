org 0x7c00
bits 16

jmp	0x0000:start

    diskNum db 0
    kernel_entry equ 0x1000
    times 8-($-$$) db 0

    ;	Boot Information Table
    bi_PrimaryVolumeDescriptor  resd  1    ; LBA of the Primary Volume Descriptor
    bi_BootFileLocation         resd  1    ; LBA of the Boot File
    bi_BootFileLength           resd  1    ; Length of the boot file in bytes
    bi_Checksum                 resd  1    ; 32 bit checksum
    bi_Reserved                 resb  40   ; Reserved 'for future standardization'

    


start:
    
    ;variables initialization
    xor bx, bx
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
    
    mov al,3
    mov bh,0
    mov bl,al
    push bx
    mov ch,0
    mov cl,2
    mov dh,0
    mov dl,[diskNum]
    mov bx, 0x7E00
  
  

    int 13h
    pop bx
    
    
    call check_disk_operation_success


    mov ax, 0
    mov es , ax
    mov ah,2
    
    mov al,14
    mov bh,0
    mov bl,al
    push bx
    mov ch,0
    mov cl,5
    mov dh,0
    mov dl,[diskNum]
    mov bx, 0x1000
  
  

    int 13h
    pop bx
    
    
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

; END FIRST SECTOR REAL CODE
; CONTINUE ON LINE ∼200








printf:
    push ax
    push bx
    

    .printLoop:
        
        lodsb

        or al,al
        jz .finished
        mov bh,0
        mov ah,14
        int 10h


       

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


msg db "Bootloader found!!! Executing the code.....", 13, 10, 0
msg2 db "Loading other sectors for more memory....", 13, 10, 0
cfE db "cf = true, Disk Read FAILURE!!", 13, 10, 0
alF db "al INCORRECT, one or more sectors didn't get read!!", 13, 10, 0


TIMES 510 - ($ - $$) db 0	;Fill the rest of sector with 0
DW 0xAA55	


;=========================================================================
;||                           SECTOR 2-4                                ||
;=========================================================================
cfC db "cf = false, Disk Read Success!!", 13, 10, 0
alT db "al Correct, every sector got read into memory....", 13, 10, 0
msg3 db "Loading Protected x32 Mode......", 13, 10, 0

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



;=========================================================================
;||                             32 BIT                                  ||
;=========================================================================
bits 32
string: db "string where i want", 0


protected_mode:


    mov ax, DATA_SEG     ; 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x90000
    mov esp, ebp  ; Stack safe
    
    ; edi = display cursor
    ;mov byte [edi], 'A'      ; ASCII CHAR
    ;mov byte [edi+1], 0x0F     ; Attributes (white on black)



    mov dl,75
    mov dh,8
    mov cl,0x0F
    mov esi,string
    call printf32

    mov dl,40
    mov dh,20
    call loadAt

    
 
    .delay:
    ;jmp .delay
    jmp kernel_entry ; Salta al kernel
  
  ;call load_Long_Mode
JMP $














loadAt: ;convert dl in column and dh in row(l*h)
    push ebx
    push eax
    push ecx

    mov ebx,0xB8000
    mov eax,80
    mul dh
    add al, dl
    SHL eax,1
    add ebx,eax
    mov edi,ebx

    pop ecx
    pop eax
    pop ebx
ret


printf32:
   push eax
    push ebx
    
    call loadAt
    .printLoop:
    
        lodsb
        or al,al
        jz .finished

        
        mov byte [edi], al 
        mov byte [edi+1], cl

        add edi,2

    jmp .printLoop
    .finished:
    
   
    pop ebx
    pop eax
ret


switch_long_mode:

    mov eax, cr0
    and eax,0x7FFFFFFF
    mov cr0,eax
    mov eax, cr4
    or eax,0x620
    mov cr4,eax
    mov eax, dword[ebp+0x4]
    mov cr3, eax
    mov ecx, 0xC0000080
    rdmsr
    or eax,0x101
    wrmsr
    mov eax,cr0
    or eax,0xE00000E
    mov cr0,eax
    ;jmp 0x08:long_mode
ret



TIMES 2048 - ($ - $$) db 0


