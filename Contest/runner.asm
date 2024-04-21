INCLUDE Irvine32.inc
INCLUDE Macros.inc

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

outroString db "Congratulations! You have collected all the stars and saved the world from math illiteracy!", 0Dh, 0Ah, 0Dh, 0Ah
			db "You are now the math master of the world! Press any key to exit...", 0Dh, 0Ah, 0

introString db "Welcome to... ", 0Dh, 0Ah, 0Dh, 0Ah

			db "  __  __    _  _____ _   _ _____ __  __  ___  _   _ ___ _   _ __  __ ", 0Dh, 0Ah
			db " |  \/  |  / \|_   _| | | | ____|  \/  |/ _ \| \ | |_ _| | | |  \/  |", 0Dh, 0Ah
			db " | |\/| | / _ \ | | | |_| |  _| | |\/| | | | |  \| || || | | | |\/| |", 0Dh, 0Ah
			db " | |  | |/ ___ \| | |  _  | |___| |  | | |_| | |\  || || |_| | |  | |", 0Dh, 0Ah
			db " |_|  |_/_/   \_\_| |_| |_|_____|_|  |_|\___/|_| \_|___|\___/|_|  |_|", 0Dh, 0Ah, 0Dh, 0Ah


			db "a game of math and adventure!", 0Dh, 0Ah
			db "Travel through the world and challenge all the math masters.... if you dare....", 0Dh, 0Ah, 0Dh, 0ah
			db "TIPS & INFO:", 0Dh, 0Ah
			db " - Asterisks (*) represent a math master, go up and press space to begin battle", 0Dh, 0Ah
			db " - You may want to get some questions wrong here and there, as you win, difficulty and terms per question increase", 0Dh, 0Ah
			db " - PEMDAS will not work here, equations are evaluated left to right", 0Dh, 0Ah
			db "Press any key to continue...", 0Dh, 0Ah, 0
		

correctAnswerString db "Correct! Math masters hear your name world wide and prepare in anticipation of your arrival...", 0
incorrectAnswerString db "Incorrect! The world is doomed to a future of math illiteracy...", 0

filename BYTE "world.txt",0
buffer BYTE 5000 DUP(?)
fileHandle DWORD ?
bytesRead DWORD ?

phrasesfilename BYTE "mathphrases.txt",0
phrasesbuffer BYTE 5000 DUP(?)
phrasesfileHandle DWORD ?
phrasesbytesRead DWORD ?
phraseStart DWORD ?
phraseEnd DWORD ?

starPos DWORD ?
totalStars BYTE 0
oldX BYTE ?
oldY BYTE ?
maxX BYTE 80
maxY BYTE 25
xPos BYTE 1
yPos BYTE 1

difficultyLevel BYTE 2

currentTerm BYTE ?
termArr db 100 DUP(?)
operators db 100 DUP(?)

equationAnswer BYTE ?			; Variable to store the answer to the equation
terms BYTE ?					; Number of terms in the equation
operator BYTE ?					; Equation operator code
term BYTE ?						; Equation term
equationBuffer BYTE 5000 DUP(?) ; Buffer to store the equation



;=========================MACROS==================================================================================================================================

; Macro to put buffer position into edi
GetBufferPos MACRO
	movzx eax, maxX	; move max X into eax
	add eax, 2		; add 2 to account for new line characters
	movzx edi, yPos	; move y into edi
	mov ebx, edx
	mul edi			; multiply y by max x to get right row
	mov edx, ebx
	mov edi, eax	; mov mul result back into edi
	movzx eax, xPos	; zero extend xpos to add to edi
	add edi, eax	; add x to edi to get proper index
	ENDM

; Define a macro named MoveByteToVar
; Arguments:
;   var - The variable to move the byte into
;   src - The source pointer or index

MoveByteToVar MACRO var, src
    LOCAL tmpReg
    movzx eax, BYTE PTR [src]   ; Move byte at src to EAX with zero-extension
    mov [var], al				; Move the content of EAX to var
ENDM



.code
;========================================MAIN==========================================================================================================================================
main PROC
	
	call HideCursor
	call PrepareWorld
	call PreparePhrases
	call CountStars

	call IntroScreen

	call DrawWorld
	call InitDotPosition
	
	mov dl, 85
	mov dh, 5
	call Gotoxy

	
	game:
		mov eax, 16
		call Delay
		;call DrawInfo
		call MoveDot
		.IF totalStars == 0
			jmp Outro
		.ENDIF
	jmp game

	Outro:
		call DisplayOutro

	exit
main ENDP

;==========================================HELPER FUNCTIONS===============================================================================================================================

DisplayOutro PROC
	call Clrscr
	mov dl, 0
	mov dh, 0
	mov edx, OFFSET outroString
	call WriteString

	;Wait for key press before exiting outro screen
	WaitLoop:
	call ReadKey
	jz WaitLoop

	ret
DisplayOutro ENDP

SetColor PROC
    LOCAL hConsole:DWORD

	; Get a handle to the console's output buffer
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hConsole, eax

	; Set the text color
	invoke SetConsoleTextAttribute, hConsole, cx
	ret

SetColor ENDP

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

IntroScreen PROC
	; Clear screen and write intro message
	call Clrscr
	mov edx, OFFSET introString
	call WriteString


	;Wait for key press before exiting intro screen
	WaitLoop:
	call ReadKey
	jz WaitLoop

	ret
IntroScreen ENDP

InitDotPosition PROC
	mov edx, 0
	mov dl ,xPos
	mov dh, yPos
	call Gotoxy
	mov al, '.'
	call WriteChar
	ret
InitDotPosition ENDP

MoveDot PROC
	call ReadKey
	jz RedrawDot

	; Save old position
	mov dl, xPos
	mov oldX, dl
	mov dh, yPos
	mov oldY, dh

	; Check direction based on virtual scan code (AH)
    cmp  ah, 48h        ; Up arrow
    je   MoveUp
    cmp  ah, 50h        ; Down arrow
    je   MoveDown
    cmp  ah, 4Bh        ; Left arrow
    je   MoveLeft
    cmp  ah, 4Dh        ; Right arrow
    je   MoveRight
	cmp  ah, 39h		; Space
          	je	 CheckStar
	
	jmp RedrawDot			; Check for new input if none matched

	CheckStar:
		; Check if the dot is next to a star
		GetBufferPos

		; Place length of one row into eax
		movzx ebx, maxX	; move max X into eax
		add ebx, 2		; add 2 to account for new line characters

		; Check Above
		sub edi, ebx	; subtract by one row to check above
		mov al, byte ptr [buffer + edi]
		cmp al, '*'
		je checkPass

		add edi, ebx	; add back to edi to return to original position


		; Check Below
		add edi, ebx	; add one row to check below
		mov al, byte ptr [buffer + edi]
		cmp al, '*'
		je checkPass

		sub edi, ebx	; subtract by one row to return to original position


		; Check Left
		dec edi			; move x left one to check left
		mov al, byte ptr [buffer + edi]
		cmp al, '*'
		je checkPass

		inc edi 		; add back to edi to return to original position


		; Check Right
		inc edi			; move x right one to check right
		mov al, byte ptr [buffer + edi]
		cmp al, '*'
		je checkPass

		dec edi			; subtract by one row to return to original position

		
		jmp checkFail

		checkPass:
		    ; Save the position of the star
			mov starPos, edi
			; Clear screen, write battle message, show math problem
			call Clrscr
			; Move cursor to top left corner
			mov dl, 0
			mov dh, 0
			call Gotoxy
			; Write battle message
			call PrintRandomPhrase
			; Show math problem
			mov dl, 0
			mov dh, 5
			call Gotoxy
			call GenerateMathEquation
			; Read answer from user
			mov dl, 0
			mov dh, 10
			call Gotoxy
			call ReadInt
			jno GoodInput

			;Write error message
			call WriteWindowsMsg
			exit

			; If input is good, check against equation answer
			GoodInput:
			cmp al, equationAnswer
			je CorrectAnswer

			jmp IncorrectAnswer

			CorrectAnswer: 
			; Write correct answer message, increase difficulty
			mov edi, starPos
			mov byte ptr [buffer + edi], ' '	; Change the star to a space
			dec totalStars

			mov dl, 0
			mov dh, 15
			call Gotoxy
			mov edx, OFFSET correctAnswerString
			call WriteString
			inc difficultyLevel
			jmp AnswerChecked

			IncorrectAnswer:
			; Write incorrect answer message, decrease difficulty
			mov dl, 0
			mov dh, 15
			call Gotoxy
			mov edx, OFFSET incorrectAnswerString
			call WriteString
			dec difficultyLevel

			AnswerChecked:

			;update terms with difficulty level
			mov ah, difficultyLevel
			mov terms, ah

			;Wait for key press before continuing
			WaitLoop:
			call ReadKey
			jz WaitLoop

			call DrawWorld


		checkFail:
			jmp RedrawDot	



	
	
	MoveUp:
		mov ah, yPos
		cmp ah, 1
		jle RedrawDot	; If dot cannot move, jump without decrementing

		GetBufferPos	; Put dot buffer position into edi

		movzx ebx, maxX	; Move max X into ebx
		add ebx, 2		; Add 2 to account for new line characters
		sub edi, ebx 	; Move edi up one row to check above

		mov al, byte ptr [buffer + edi]	; Move the character at the buffer position into al

		cmp al, ' '
		jne RedrawDot	; If space to be moved into isn't empty, skip

		dec yPos	
		jmp RedrawDot

	MoveDown:
		mov ah, yPos
		cmp ah, [maxY]
		jge RedrawDot

		GetBufferPos	; Put dot buffer position into edi

		movzx ebx, maxX	; Move max X into ebx
		add ebx, 2		; Add 2 to account for new line characters
		add edi, ebx 	; Move edi down one row to check below

		mov al, byte ptr [buffer + edi]	; Move the character at the buffer position into al

		
		cmp al, ' '
		jne RedrawDot

		inc yPos
		jmp RedrawDot

	MoveLeft:
		mov ah, xPos
		cmp ah, 1
		jle RedrawDot

		GetBufferPos	; Put dot buffer position into edi

		dec edi			; move x left one to account for move

		mov al, byte ptr [buffer + edi]	; Move the character at the buffer position into al
		
		cmp al, ' '
		jne RedrawDot

		dec xPos
		jmp RedrawDot

	MoveRight:
		mov ah, xPos
		cmp ah, [maxX]
		jge RedrawDot

		GetBufferPos 	; Put dot buffer position into edi

		inc edi			; move x right one to account for move

		mov al, byte ptr [buffer + edi]	; Move the character at the buffer position into al
		
		cmp al, ' '
		jne RedrawDot

		inc xPos
		jmp RedrawDot

	RedrawDot:
		mov dl, oldX
		mov dh, oldY
		call Gotoxy
		mov al, ' '
		call WriteChar	; Write space over old dot

		; Set text color to red
		mov cx, 4          ; Attribute for red color
		call SetColor

		mov dl, xPos
		mov dh, yPos
		call Gotoxy		; Go to new xy
		mov al, '.'
		call WriteChar	; Write dot in new xy

		; Reset text color to white on black
		mov cx, 15         ; Attribute for bright white on black
		call SetColor
		
	ret
MoveDot ENDP

PrepareWorld PROC
	; Open the file for reading
	mov edx, OFFSET filename      ; Pointer to filename
	call OpenInputFile                 ; OpenFile is used for reading; adjust if needed
	mov fileHandle, eax            ; Save file handle

	; Read from the file
	mov eax, fileHandle            ; File handle
	mov edx, OFFSET buffer         ; Buffer to store file data
	mov ecx, SIZEOF buffer         ; Max bytes to read
	call ReadFromFile              ; Read file content
	mov bytesRead, eax             ; Save the number of bytes read
	jc   readError                 ; Jump if error occurred
	jmp readSuccess

	readError:
		call WriteWindowsMsg
		exit

	readSuccess:

	; Close the file
	mov eax, fileHandle
	call CloseFile

	ret
PrepareWorld ENDP

	CountStars PROC
		xor edi, edi                ; Clear edi for use as index
		mov ecx, bytesRead          ; Length of the buffer to print

		; Clear Screen before drawing
		call Clrscr
	CountLoop:
		cmp edi, ecx                ; Check if we've reached the end of the buffer
		je EndCount                  ; Jump to end if done

		mov al, byte ptr [buffer + edi] ; Move the current character to eax, zero-extend to prevent sign extension
		cmp al, '*'
		je CountStar

		inc edi                     ; Move to the next character
		jmp CountLoop                ; Continue loop

	CountStar:
		inc totalStars
		inc edi
		jmp CountLoop

	EndCount:


	ret
CountStars ENDP

DrawWorld PROC	
	;Buffer contains the worlds information
	xor edi, edi                ; Clear edi for use as index
    mov ebx, bytesRead          ; Length of the buffer to print

	; Clear Screen before drawing
	call Clrscr
DrawLoop:
    cmp edi, ebx                ; Check if we've reached the end of the buffer
    je EndDraw                  ; Jump to end if done

    mov al, byte ptr [buffer + edi] ; Move the current character to eax, zero-extend to prevent sign extension

	cmp al, '*'
	je WriteYellow

	jmp NormalWrite

	WriteYellow:
	 ; Set text color to yellow
    mov cx, 14                 ; Attribute for yellow color
    call SetColor
	mov al, '*'
    call WriteChar             ; Write the asterisk in yellow

	; Reset text color to white on black
    mov cx, 15                 ; Attribute for bright white on black
    call SetColor

	jmp PostWrite



	NormalWrite:
    call WriteChar					; Write the character to the 

	PostWrite:


    inc edi                     ; Move to the next character
    jmp DrawLoop                ; Continue loop

EndDraw:
    ret

DrawWorld ENDP

DrawInfo PROC
	mov dl, 85
	mov dh, 0
	call Gotoxy
	movzx eax, xPos
	call WriteInt

	mov dl, 85
	mov dh, 1
	call Gotoxy
	movzx eax, yPos
	call WriteInt

	mov dl, 85
	mov dh, 2
	call Gotoxy

	GetBufferPos

	dec edi
	mov al, byte ptr [buffer + edi]
	
	;mWrite "Left: ", 0
	;call WriteChar

	mov dl, 85
	mov dh, 3
	call Gotoxy

	inc edi
	inc edi
	mov al, byte ptr [buffer + edi]

	;mWrite "Right: ", 0
	;call WriteChar


	ret
DrawInfo ENDP

PreparePhrases PROC
	; Open the file for reading
	mov edx, OFFSET phrasesfilename      ; Pointer to filename
	call OpenInputFile
	mov phrasesfileHandle, eax

	; Read from the file
	mov eax, phrasesfileHandle
	mov edx, OFFSET phrasesbuffer
	mov ecx, SIZEOF phrasesbuffer
	call ReadFromFile
	mov phrasesbytesRead, eax

	; Close the file
	mov eax, phrasesfileHandle
	call CloseFile

	ret

	; phrasesbuffer contains the phrases information
PreparePhrases ENDP

GetRandomPhrase PROC
	; Get a random phrase
	call Randomize
	mov eax, 79
	call RandomRange
	mov ebx, eax
	inc ebx

	; ebx contains the randomly generated index

	; Find the phrase
	xor edi, edi
	xor ecx, ecx
	; ecx will contain the current phrase index

	FindLoop:
		; Find the end of the buffer
		cmp edi, phrasesbytesRead
		je EndFind

		; If randomly generated index matches the current phrase index, we found the phrase
		cmp ebx, ecx
		je FoundPhrase

		; Check for new line, if not skip to NotNewlineFind
		mov al, byte ptr [phrasesbuffer + edi]
		cmp al, 0ah ; New line
		jne NotNewLineFind

		; Increment the phrase index
		inc ecx

	NotNewlineFind:
		inc edi			; Increment edi to show a character was read
		jmp FindLoop

	FoundPhrase:
		; Save the start of the phrase
		mov phraseStart, edi

		; Find the end of the phrase
		FindEnd:
			cmp edi, phrasesbytesRead	; Check if we've reached the end of the buffer
			je FinishFind ; Jump to finish if done

			mov al, byte ptr [phrasesbuffer + edi] ; Move the current character to al
			inc edi ; Move to the next character
			cmp al, 0ah ; New line
			je FinishFind

			jmp FindEnd

			FinishFind:
			; Save the end of the phrase
			dec edi ; Move back one to get the last character of the phrase
			mov phraseEnd, edi ; Save the end

	EndFind:
	ret

GetRandomPhrase ENDP

PrintRandomPhrase PROC
	call GetRandomPhrase

	mov edi, phraseStart
	mov ecx, phraseEnd

	PrintLoop:
	    cmp edi, ecx	; Check if we've reached the end of the phrase
		je EndPrint		; Jump to end if done

		mov al, byte ptr [phrasesbuffer + edi]	; Move the current character to al
		call WriteChar							; Write the character to the screen

		inc edi			; Move to the next character
		jmp PrintLoop	; Continue loop

	EndPrint:
	ret

PrintRandomPhrase ENDP

GenerateMathEquation PROC
	; Clear the equation buffer
	mov edi, OFFSET equationBuffer	; Move the offset of the equation buffer into edi
	mov ecx, SIZEOF equationBuffer	; Move the size of the equation buffer into ecx
	mov al, 0	; Move 0 into al
	rep stosb	; Fill the buffer with 0

	; Generate first term
	call Randomize
	mov eax, 9					; 9 is the maximum value for a term
	call RandomRange
	inc eax						; Increment eax to get a number between 1 and 9

	; Store term into buffer
	mov term, al				; Store the random number into term
	mov al, term				; Move the term number into al
	add al, 48					; Convert the number to ASCII
	mov [edi], al				; Move the first term into buffer
	inc edi						; Move to the next position in the equation buffer

	inc cl						; Increment the counter

	; Prepare counter
	mov cl, 1

	; Generate the terms
	GenerateTerms:
		; Call small delay for time slicing
		mov eax, 10
		call Delay
		; Generate a term
		call Randomize
		mov eax, 9		; 9 is the maximum value for a term
		call RandomRange
		inc eax			; Increment eax to get a number between 1 and 9
		mov term, al	; Move the term number into term


		call Randomize
		mov eax, 3			; 3 is the maximum number of operators
		call RandomRange	; Generate a random operator number between 1 and 3 in eax
		inc eax				; Increment eax to get a number between 1 and 3
		mov operator, al	; Move the operator number into variable
	

		; Add the operator to the equation buffer
		.IF operator == 1
			mov BYTE PTR [edi], ' '
			mov BYTE PTR [edi+1], '+'
			mov BYTE PTR [edi+2], ' '
		.ELSEIF operator == 2
			mov BYTE PTR [edi], ' '
			mov BYTE PTR [edi+1], '-'
			mov BYTE PTR [edi+2], ' '
		.ELSEIF operator == 3
			mov BYTE PTR [edi], ' '
			mov BYTE PTR [edi+1], '*'
			mov BYTE PTR [edi+2], ' '
		.ENDIF

		; Add the term to the equation buffer
		add edi, 3					; Move to the end of the equation buffer
		mov al, term 				; Move the term into al
		add al, 48 					; Convert the number to ASCII
		mov [edi], al				; Move the term into the equation buffer
		inc edi						; Move to the next position in the equation buffer

		; Increment the counter and check if we've reached the number of terms
		inc cl
		cmp cl, terms
		jl GenerateTerms

		; Add the equals sign to the equation buffer
		mov BYTE PTR [edi], ' '
		mov BYTE PTR [edi+1], '='
		mov BYTE PTR [edi+2], ' '
        mov BYTE PTR [edi+3], '?'
		add edi, 4

		; Print the equation
		mov ecx, OFFSET equationBuffer
		
		PrintLoop:
		cmp edi, ecx	; Check if we've reached the end of the equation
		je EndPrint		; Jump to end if done

		mov al, byte ptr [ecx]	; Move the current character to al
		call WriteChar							; Write the character to the screen
		
		inc ecx
		jmp PrintLoop

		EndPrint:
		call EvaluateExpression
	ret

GenerateMathEquation ENDP

EvaluateExpression PROC
push eax

;move edi to the start of the equation buffer
imul ecx, difficultyLevel, 4
inc ecx
sub edi, ecx

mov ebx, OFFSET termArr
mov ecx, OFFSET operators

; Turn equation buffer into two arrays
TransformLoop:

	mov al, BYTE PTR [edi]		; Load current term into al
	mov currentTerm, al			; Move al into currentTerm

	.IF currentTerm > '0' && currentTerm <= '9'	; currentToken is a number
		mov al, currentTerm
		mov BYTE PTR [ebx], al		; save currentToken to terms
		sub BYTE PTR [ebx], '0'				; convert to raw value
		inc ebx						; increment ebx for next term
		inc edi						; increment edi to point at next buffer pos
		jmp TransformLoop
	.ELSEIF currentTerm == '+' || currentTerm == '-' || currentTerm == '*'	; currentToken is a valid operator
		mov al, currentTerm
		mov BYTE PTR [ecx], al				; save currentToken to operators
		inc ecx								; increment ecx for next operator
		inc edi								; increment edi for next buffer pos
		jmp TransformLoop
	.ELSEIF currentTerm == ' '						; currentToken is a filler space
		inc edi				; Move to next position in buffer
		jmp TransformLoop	; Start next loop
	.ELSE											; currentToken is anything else (i.e. '=')
	mov BYTE PTR [ebx], 0FFh		; Values to signal when end of useful data has been reached
	mov BYTE PTR [ecx], 0FFh
	.ENDIF


mov equationAnswer, 0		; Clear equation answer


; First loop to evaluate the answer, performs all multiplication
EvalLoop1:
	mov ebx, OFFSET termArr
	mov ecx, OFFSET operators		; reset ebx and ecx to point to the arrays

	;mov currentTerm, BYTE PTR [ecx]		; Load operator array into currentTerm, we will be searching mainly for operators
	MoveByteToVar currentTerm, ecx


	; When multiplication is found at index n, it's corresponding numbers are located at 2n and 2n-1 in the terms array.

	.IF currentTerm == '*'
		mov edx, ecx					; save ecx (current term) into edx
		sub edx, OFFSET operators		; sub original ecx from current to get distance from start
		add edx, edx					; double distance to get proper offset for terms
		movzx eax, BYTE PTR [ebx+edx]
		imul BYTE PTR [ebx+edx-1]		; multiply terms corresponding to operator and save in first operator position
		mov BYTE PTR [ebx+edx], 0			; clear the term where the multiplier used to be
		inc ecx							; increment ecx for next operator
	.ELSEIF currentTerm == 0FFh	; if current term is data-end signal, finish loop
		jmp EvalLoop2
	.ELSE	; if not multiplication, continue loop
		inc ecx
		jmp EvalLoop1
	.ENDIF

jmp EvalLoop1

; Second loop to do all addition and subtraction
EvalLoop2:
	mov ebx, OFFSET termArr
	mov ecx, OFFSET operators
	MoveByteToVar currentTerm, ecx

	MoveByteToVar equationAnswer, ebx	; Move first term into equation answer
	inc ebx								; Increment ebx to consider next operator

	.WHILE currentTerm != 0FFh
		LoopStart:
		; Loop through terms to find next non-zero number
		mov al, BYTE PTR [ebx]	; Load current term into al

		.IF al != 0						; If term isn't zero, go ahead and check for next term
		OpCheck:
			.IF BYTE PTR [ecx] == '+' ; If next operator is addition
				add equationAnswer, al	; Add next term, move to next one
				inc ecx					; Increment ecx to consider next operator
			.ELSEIF BYTE PTR [ecx] == '-' ; If next operator is substraction
				sub equationAnswer, al	; Subtract next term, move to next one
				inc ecx					; Increment ecx to consider next operator
			.ELSE						; In case of any other character, increment to next operator and check again
				inc ecx					; Increment ecx to consider next operator
				jmp OpCheck				; Jump back to check next operator
			
			.ENDIF
		.ENDIF							; If term is zero, it was erased, increment to next term but not operator
			inc ebx						; Increment ebx to consider next term
			jmp LoopStart
		
	.ENDW

	.IF currentTerm == '+'		; If operator is addition
		mov al, BYTE PTR [ebx]
		add equationAnswer, al	; Add next term, move to next one
		inc ebx
		inc ecx
	.ELSEIF currentTerm == '-'	; If operator is substraction
		mov al, BYTE PTR [ebx]
		sub equationAnswer, al	; Subtract next term, move to next one
		inc ebx
		inc ecx
	.ELSEIF currentTerm == 0FFh	; If end of data has been reached, end loop
		jmp EvalLoopFinish
	.ELSE						; In case of any other character, ignore and move forward
		inc ecx
	.ENDIF

	jmp EvalLoop2

	EvalLoopFinish:
	
	pop eax
	ret
EvaluateExpression ENDP

END main