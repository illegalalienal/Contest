INCLUDE Irvine32.inc

.data
maxX BYTE 80
maxY BYTE 25
xPos BYTE 40          ; Horizontal position of the dot, starting in the middle of the screen
yPos BYTE 12          ; Vertical position of the dot, starting in the middle of the screen

.code
main PROC
    call Clrscr         ; Clear the screen initially

    
    ; Correctly set DL (column) and DH (row) for the initial dot position
    mov ah, yPos
    mov edx, 0          ; Clear EDX to safely set DH and DL
    mov dh, ah          ; yPos -> DH
    mov al, xPos
    mov dl, al          ; xPos -> DL
    call Gotoxy
    mov al, '.'
    call WriteChar

MoveDot:
    mov  eax,10
    call Delay

    call ReadKey        ; Check for keyboard input
    jz   MoveDot        ; No key pressed, loop again

    ; Check direction based on virtual scan code (AH)
    cmp  ah, 48h        ; Up arrow
    je   MoveUp
    cmp  ah, 50h        ; Down arrow
    je   MoveDown
    cmp  ah, 4Bh        ; Left arrow
    je   MoveLeft
    cmp  ah, 4Dh        ; Right arrow
    je   MoveRight

    jmp  MoveDot        ; Continue checking for input

MoveUp:
    mov ah, yPos
    cmp ah, 1
    jle RedrawDot
    dec  yPos           ; Move the dot up
    jmp  RedrawDot

MoveDown:
    mov ah, yPos
    cmp ah, [maxY]
    jge RedrawDot
    inc  yPos           ; Move the dot down
    jmp  RedrawDot

MoveLeft:
    mov al, xPos
    cmp al, 1
    jle RedrawDot
    dec  xPos           ; Move the dot left
    jmp  RedrawDot

MoveRight:
    mov al, xPos
    cmp al, [maxX]
    jge RedrawDot
    inc  xPos           ; Move the dot right
    jmp  RedrawDot

RedrawDot:
    call Clrscr         ; Clear the screen for redrawing
    mov ah, yPos
    mov edx, 0          ; Clear EDX to safely set DH and DL
    mov dh, ah          ; yPos -> DH
    mov al, xPos
    mov dl, al          ; xPos -> DL
    call Gotoxy
    mov al, '.'
    call WriteChar
    jmp MoveDot        ; Loop back to check for more input

    exit
main ENDP
END main
