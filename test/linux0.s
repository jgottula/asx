	.intel_syntax noprefix
	.intel_mnemonic
	
	STDIN  = 0
	STDOUT = 1
	STDERR = 2
	
	__NR_write = 1
	__NR_exit  = 60
	
	.data
	
hello:
	.ascii "hello world!\n"
	hello_len = $-hello
	
	.text
	
	.global _start
_start:
	mov rax,__NR_write
	mov rsi,$hello /* gnu as and its horrible syntax can go die in a fire */
	mov rdi,STDOUT
	mov rdx,hello_len
	syscall
	
	mov rax,__NR_exit
	mov rdi,0
	syscall
	
	/*mov rax,__NR_write
	mov rbx,STDOU
	T
	mov rcx,hello
	mov rdx,hello_len
	int 0x80*/
	
	/*mov rax,__NR_exit
	mov rbx,0
	int 0x80*/
