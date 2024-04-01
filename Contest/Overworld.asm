INCLUDE Irvine32.inc

;.MODEL flat, stdcall

.data
maxX BYTE 80
maxY BYTE 25
xPos BYTE 40
yPos BYTE 12

.code

InitDotPosition PROC
	call Clrscr
	mov edx, 0
	mov dl ,xPos
	mov dh, yPos
	call Gotoxy
	mov al, '.'
	call WriteChar
	ret
InitDotPosition ENDP

END