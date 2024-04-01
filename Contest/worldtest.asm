INCLUDE Irvine32.inc

.data
world BYTE "##########",\
           "#........#",\
           "#........#",\
           "#........#",\
           "#....###.#",\
           "#....#...#",\
           "#....#...#",\
           "#........#",\
           "#........#",\
           "##########",0
playerChar  BYTE '.'           ; Character representing the player
xPos        DWORD 1            ; Player's starting X position (1-indexed for simplicity)
yPos        DWORD 1            ; Player's starting Y position (1-indexed for simplicity)
worldWidth  DWORD 10           ; Width of the world
worldHeight DWORD 10           ; Height of the world

.code
main PROC
    call Clrscr             ; Clear the console
    call DrawWorld          ; Draw the initial state of the world
    call ProcessInput       ; Start processing player input
    exit                    ; Ensure the program exits properly
main ENDP

DrawWorld PROC
    LOCAL currentPos:DWORD
    mov ecx, 0              ; Counter for looping through the world array
    mov ebx, 1              ; Used to track when to print a new line

    .WHILE ecx < worldWidth * worldHeight
        mov eax, yPos
        dec eax             ; Adjust yPos to 0-based for calculation
        mul worldWidth
        add eax, xPos       ; Adjust xPos to 0-based and add to eax
        dec eax             ; Adjust calculated index to 0-based
        mov currentPos, eax ; Store current position for comparison

        ; Check if we're at the player's position
        .IF ecx == currentPos
            mov al, playerChar
        .ELSE
            mov al, world[ecx] ; Load the current world character
        .ENDIF
        call WriteChar     ; Write the character
        
        ; New line if at the end of the world row
        .IF ebx == worldWidth
            call Crlf       ; Move to a new line
            mov ebx, 0      ; Reset line character counter
        .ENDIF

        inc ebx
        inc ecx
    .ENDW
    ret
DrawWorld ENDP

ProcessInput PROC
    .REPEAT
        call ReadKey            ; Wait for a key press
        movzx eax, ax           ; Ensure we're only working with the lower 16 bits
        cmp ah, 48h             ; Check for up arrow key
        je MoveUp
        cmp ah, 50h             ; Check for down arrow key
        je MoveDown
        cmp ah, 4Bh             ; Check for left arrow key
        je MoveLeft
        cmp ah, 4Dh             ; Check for right arrow key
        je MoveRight
        cmp dx, 1Bh             ; Check if ESC key was pressed for exit
    .UNTIL dx == 1Bh
    ret
ProcessInput ENDP

CanMove PROC USES ecx edx, nextX:DWORD, nextY:DWORD
    ; Ensure next positions are within bounds
    cmp nextX, 1
    jl  MoveNotAllowed       ; Jump if nextX < 1
    cmp nextX, worldWidth
    jg  MoveNotAllowed       ; Jump if nextX > worldWidth
    cmp nextY, 1
    jl  MoveNotAllowed       ; Jump if nextY < 1
    cmp nextY, worldHeight
    jg  MoveNotAllowed       ; Jump if nextY > worldHeight
    
    ; Calculate position in the world array
    mov eax, nextY
    dec eax                  ; Adjust for zero-based indexing
    mul worldWidth
    add eax, nextX
    dec eax                  ; Adjust for zero-based indexing
    
    ; Use ECX as a temporary register for the character at the next position
    mov ecx, eax             ; Copy the calculated index to ECX
    movzx edx, byte ptr world[ecx] ; Load the character at the next position into EDX

    ; Check if the next position is a wall
    cmp dl, '#'
    je   MoveNotAllowed      ; If it's a wall, movement is not allowed
    
MoveAllowed:
    mov eax, 1               ; Movement is allowed
    ret

MoveNotAllowed:
    xor eax, eax             ; Movement is not allowed (clear EAX to 0)
    ret
CanMove ENDP



MoveUp:
    mov eax, yPos
    dec eax
    push eax              ; Next Y position
    push xPos             ; Current X position
    call CanMove
    add esp, 8            ; Clean up the stack
    cmp eax, 1            ; Check if movement is allowed
    jne RedrawAndContinue ; If not, skip the position update
    dec yPos              ; Update position
    jmp RedrawAndContinue

MoveDown:
    mov eax, yPos
    inc eax
    push eax              ; Next Y position
    push xPos             ; Current X position
    call CanMove
    add esp, 8            ; Clean up the stack
    cmp eax, 1            ; Check if movement is allowed
    jne RedrawAndContinue ; If not, skip the position update
    inc yPos              ; Update position
    jmp RedrawAndContinue

MoveLeft:
    mov eax, xPos
    dec eax
    push yPos             ; Current Y position
    push eax              ; Next X position
    call CanMove
    add esp, 8            ; Clean up the stack
    cmp eax, 1            ; Check if movement is allowed
    jne RedrawAndContinue ; If not, skip the position update
    dec xPos              ; Update position
    jmp RedrawAndContinue

MoveRight:
    mov eax, xPos
    inc eax
    push yPos             ; Current Y position
    push eax              ; Next X position
    call CanMove
    add esp, 8            ; Clean up the stack
    cmp eax, 1            ; Check if movement is allowed
    jne RedrawAndContinue ; If not, skip the position update
    inc xPos              ; Update position
    jmp RedrawAndContinue

RedrawAndContinue:
    call Clrscr                   ; Clear the screen for redrawing
    call DrawWorld                ; Redraw the world after movement
    ret

END main
