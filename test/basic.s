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
