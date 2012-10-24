.include "include.s"

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
	
	call ambiguous
	
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

/* demonstrates size-ambiguous behavior */
ambiguous:
	movl 1,[eax]
	movw 1,[eax]
	movb 1,[eax]
	mov  1,eax   // invalid, ambiguous
	
	ret

/*
 * multi
 * line
 * comment
 */
/+ nest comment +/
/+/+ double nest comment +/+/
/+/+/+/++/+/+/+/
/+ /* layered */ +/
