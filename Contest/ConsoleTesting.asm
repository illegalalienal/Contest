INCLUDE Irvine32.inc
INCLUDE Macros.inc
INCLUDELIB kernel32.lib

SetConsoleTextAttribute PROTO,
    hConsoleOutput: DWORD,
    wAttributes: WORD

SetConsoleCursorInfo PROTO,
    hConsoleOutput:DWORD,
    lpConsoleCursorInfo:PTR CONSOLE_CURSOR_INFO

CONSOLE_CURSOR_INFO STRUCT
    dwSize DWORD ?
    bVisible DWORD ?
CONSOLE_CURSOR_INFO ENDS

.data
cursorInfo CONSOLE_CURSOR_INFO <1, FALSE>  ; Set cursor size to 1 and visibility to FALSE
unusualColorMessage db "This is a string in an unusual color!", 0


.code
HideCursor PROC
    LOCAL hConsole:DWORD
    ; Get a handle to the console's output buffer
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov hConsole, eax
    ; Set the cursor info to hide the cursor
    lea eax, cursorInfo
    invoke SetConsoleCursorInfo, hConsole, eax
    ret
HideCursor ENDP

SetColor PROC color:WORD
    LOCAL hConsole:DWORD

	; Get a handle to the console's output buffer
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hConsole, eax

	; Set the text color
	invoke SetConsoleTextAttribute, hConsole, color
	ret

SetColor ENDP

main PROC
	push 0B1h ; Light blue text color
    call SetColor ; Set the text color to a light blue


    call HideCursor
    ; The rest of your program goes here
    exit
main ENDP

END main
