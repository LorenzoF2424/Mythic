bits 32
[org 0x1000]
  
  mov edi, 0xB8000
    
    mov byte [edi+0], 'K'
    mov byte [edi+1], 0x0E
    mov byte [edi+2], 'E'
    mov byte [edi+3], 0x0E
    mov byte [edi+4], 'R'
    mov byte [edi+5], 0x0E
    mov byte [edi+6], 'N'
    mov byte [edi+7], 0x0E
    mov byte [edi+8], 'E'
    mov byte [edi+9], 0x0E
    mov byte [edi+10], 'L'
    mov byte [edi+11], 0x0E
    mov byte [edi+12], '!'
    mov byte [edi+13], 0x0E
    .delay2:
        jmp .delay2


    ; Riempie la seconda riga di '='
    mov edi, 0xB8000 + 160
    mov ecx, 80
    mov ax, 0x0F3D  ; '=' bianco
.fill:
    stosw
    loop .fill
    
    ; Scrivi messaggio sulla terza riga
    mov edi, 0xB8000 + 320
    mov esi, message
    mov ah, 0x0A  ; Verde
.print:
    lodsb
    test al, al
    jz .done
    stosw
    jmp .print

.done:
    ; Loop infinito
    cli
    hlt
    jmp .done

message: db "Kernel loaded successfully at 0x1000!", 0

; Padding
times 4096-($-$$) db 0