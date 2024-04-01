INCLUDE Irvine32.inc
INCLUDE Macros.inc

.data

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

oldX BYTE ?
oldY BYTE ?
maxX BYTE 80
maxY BYTE 25
xPos BYTE 1
yPos BYTE 1

difficultyLevel BYTE 2

equationAnswer DWORD ?			; Variable to store the answer to the equation
terms BYTE ?					; Number of terms in the equation
operator BYTE ?					; Equation operator code
term BYTE ?						; Equation term
equationBuffer BYTE 5000 DUP(?) ; Buffer to store the equation

.code
main PROC
	
	
	call PreparePhrases

	call IntroScreen

	call DrawWorld
	call InitDotPosition
	
	mov dl, 85
	mov dh, 5
	call Gotoxy

	
	game:
		mov eax, 16
		call Delay
		call DrawInfo
		call MoveDot
	jmp game

	exit
main ENDP

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

	mov dl, xPos
	mov dh, yPos

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
		movzx eax, maxX
		add eax, 2
		movzx edi, yPos
		mov ebx, edx
		mul edi
		mov edx, ebx
		mov edi, eax
		movzx eax, xPos
		add edi, eax

		; Check Above
		movzx eax, maxX	; move max X into eax
		add eax, 2		; add 2 to account for new line characters
		sub edi, eax	; subtract by one row to check above
		mov al, byte ptr [buffer + edi]
		cmp al, '*'
		je checkPass

		; Check Below
		movzx eax, maxX
		add eax, 2
		add edi, eax	; add one row to check below
		mov al, byte ptr [buffer + edi]
		cmp al, '*'
		je checkPass

		; Check Left
		dec edi			; move x left one to check left
		mov al, byte ptr [buffer + edi]
		cmp al, '*'
		je checkPass

		; Check Right
		inc edi			; move x right one to check right
		mov al, byte ptr [buffer + edi]
		cmp al, '*'
		je checkPass
		
		jmp checkFail

		checkPass:
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
			cmp eax, equationAnswer
			je CorrectAnswer

			jmp IncorrectAnswer

			CorrectAnswer: 
			; Write correct answer message, increase difficulty
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

		movzx eax, maxX	; move max X into eax
		add eax, 2		; add 2 to account for new line characters
		movzx edi, yPos	; move y into edi
		dec edi			; move y up one to account for move
		mov ebx, edx
		mul edi			; multiply y by max x to get right row
		mov edx, ebx
		mov edi, eax	; mov mul result back into edi
		movzx eax, xPos	; zero extend xpos to add to edi
		add edi, eax	; add x to edi to get proper index
		mov al, byte ptr [buffer + edi]

		cmp al, ' '
		jne RedrawDot	; If space to be moved into isn't empty, skip

		dec yPos	
		jmp RedrawDot

	MoveDown:
		mov ah, yPos
		cmp ah, [maxY]
		jge RedrawDot

		movzx eax, maxX
		add eax, 2
		movzx edi, yPos
		inc edi			; move y down one to account for move
		mov ebx, edx
		mul edi
		mov edx, ebx
		mov edi, eax
		movzx eax, xPos
		add edi, eax
		mov al, byte ptr [buffer + edi]
		
		cmp al, ' '
		jne RedrawDot

		inc yPos
		jmp RedrawDot

	MoveLeft:
		mov ah, xPos
		cmp ah, 1
		jle RedrawDot

		movzx eax, maxX
		add eax, 2
		movzx edi, yPos
		mov ebx, edx
		mul edi
		mov edx, ebx
		mov edi, eax
		movzx eax, xPos
		add edi, eax
		dec edi			; move x left one to account for move
		mov al, byte ptr [buffer + edi]
		
		cmp al, ' '
		jne RedrawDot

		dec xPos
		jmp RedrawDot

	MoveRight:
		mov ah, xPos
		cmp ah, [maxX]
		jge RedrawDot

		movzx eax, maxX
		add eax, 2
		movzx edi, yPos
		mov ebx, edx
		mul edi
		mov edx, ebx
		mov edi, eax
		movzx eax, xPos
		add edi, eax
		inc edi			; move x right one to account for move
		mov al, byte ptr [buffer + edi]
		
		cmp al, ' '
		jne RedrawDot

		inc xPos
		jmp RedrawDot

	RedrawDot:
		;call Clrscr
		;call DrawWorld
		call Gotoxy
		mov al, ' '
		call WriteChar	; Write space over old dot

		mov dl, xPos
		mov dh, yPos
		call Gotoxy		; Go to new xy
		mov al, '.'
		call WriteChar	; Write dot in new xy
		
	ret
MoveDot ENDP

DrawWorld PROC

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

	;Buffer contains the worlds information
	xor edi, edi                ; Clear edi for use as index
    mov ecx, bytesRead          ; Length of the buffer to print

	; Clear Screen before drawing
	call Clrscr
DrawLoop:
    cmp edi, ecx                ; Check if we've reached the end of the buffer
    je EndDraw                  ; Jump to end if done

    mov al, byte ptr [buffer + edi] ; Move the current character to eax, zero-extend to prevent sign extension

	cmp al, '*'
	je ChangeColorYellow

	ChangeColorDefault:
	;ChangeTextColor white + (black * 16)
	jmp Write

	ChangeColorYellow:
	;ChangeTextColor yellow + (black * 16)
	jmp Write


	Write:
    call WriteChar					; Write the character to the 


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

	movzx eax, maxX	; move max X into eax
	add eax, 2
	movzx edi, yPos	; move y into edi
	mov ebx, edx
	mul edi			; multiply y by max x to get right row
	mov edx, ebx
	mov edi, eax	; mov mul result back into edi
	movzx eax, xPos	; zero extend xpos to add to edi
	add edi, eax	; add x to edi to get proper index

	dec edi
	mov al, byte ptr [buffer + edi]
	
	call WriteChar

	mov dl, 85
	mov dh, 3
	call Gotoxy

	inc edi
	inc edi
	mov al, byte ptr [buffer + edi]

	call WriteChar


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

	; Clear the equation answer
	mov equationAnswer, 0

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

	; Store term into Equation Answer
	movzx eax, term				; Move the term into eax
	mov equationAnswer, eax	; Move the first term into the answer
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
			movzx eax, term				; Move the term into eax
			add equationAnswer, eax		; Add the term to the answer
		.ELSEIF operator == 2
			mov BYTE PTR [edi], ' '
			mov BYTE PTR [edi+1], '-'
			mov BYTE PTR [edi+2], ' '
			mov term, al				; Move the term into al
			movzx eax, term				; Move the term into eax
			sub equationAnswer, eax		; Subtract the term from the answer
		.ELSEIF operator == 3
			mov BYTE PTR [edi], ' '
			mov BYTE PTR [edi+1], '*'
			mov BYTE PTR [edi+2], ' '
			movzx ebx, term				; Move the term into ebx
			mov eax, equationAnswer		; Move the answer into eax
			mul ebx						; Multiply the term by the answer
			mov equationAnswer, eax		; Move the result into the equation answer
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
	ret

GenerateMathEquation ENDP

END main
