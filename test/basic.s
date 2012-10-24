#include "include.s"

formatStr:
	.strz "%d\n" // null-terminated ascii string

/* program entry point */
main:
	mov 7,eax
	push eax
	call square
	add 4,esp
	
	push eax
	mov eax,formatStr
	push eax
	call printf
	add 8,esp
	
	xor eax,eax
	ret

/* squares a 32-bit integer */
square:
	push ebp
	mov esp,ebp
	
	mov [ebp+4],eax
	mov eax,edx
	
	mul edx
	
	mov ebp,esp
	pop ebp
	ret


/+ nest comment +/
/+/+ double nest comment +/+/
/+/+/+/++/+/+/+/
/+ /* layered */ +/
