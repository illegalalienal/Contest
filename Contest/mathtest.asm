include Irvine32.inc

.data
promptMsg db "What is ",0
equalsMsg db " + ",0
answerPrompt db "? ",0
correctMsg db "Correct!",0
incorrectMsg db "Incorrect. Try again!",0
number1 dd ?
number2 dd ?
userAnswer dd ?

.code
main PROC
    ; Generate two random numbers
    call Randomize
    mov eax, 100                ; Limit the numbers to 0-99
    call RandomRange
    mov number1, eax            ; Store the first number
    call RandomRange
    mov number2, eax            ; Store the second number
    
    ; Prompt the user with the question
    mov edx, OFFSET promptMsg
    call WriteString
    mov eax, number1
    call WriteDec
    mov edx, OFFSET equalsMsg
    call WriteString
    mov eax, number2
    call WriteDec
    mov edx, OFFSET answerPrompt
    call WriteString
    
    ; Read the user's answer
    call ReadInt
    mov userAnswer, eax         ; Store the user's answer
    
    ; Check if the answer is correct
    mov eax, number1
    add eax, number2            ; Calculate the correct answer
    cmp eax, userAnswer         ; Compare with the user's answer
    je correctAnswer            ; Jump if equal (answer is correct)
    
    ; Incorrect answer
    mov edx, OFFSET incorrectMsg
    call WriteString
    jmp endProgram
    
correctAnswer:
    ; Correct answer
    mov edx, OFFSET correctMsg
    call WriteString

endProgram:
    exit
main ENDP

END main
