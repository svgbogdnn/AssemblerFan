;--------------------------------------
; //Printf function 	
; TIMETRACKING:
;	10.03 	1 hour - makefile + nasm
;		2 hours - translating to decimal 
;		2 hours - converting to binary, octal
;		1 hour - converting to hexadecimal
;		1 hour - solving interrupt/syscall problems
;		2 hours - format string handling
;		2 hours - stack frame

;--------------------------------------
; //Bogdan 23.10.2022
;--------------------------------------

section .code

;--------------------------------------
%macro 	exit 0
	mov eax, 1
	xor ebx, ebx
	int 0x80
%endmacro
 
;--------------------------------------
; WRITES CHAR IN STDOUT
; Entry: rcx = &char
; Destroy List : rax rcx rdx rdi rsi
;--------------------------------------
putchar_mem:
	mov rax, 1
	mov rdx, 1
	mov rdi, 1
	syscall	
	ret

;--------------------------------------
; WRITES CHAR IN STDOUT
; Entry: sp + 32 = char to write
; Destroy List: rax rcx rdx rsi rdi 
;--------------------------------------
putchar_nomem: ; prints char from stack
	mov rax, 1
	mov rdx, 1
	mov rdi, 1
	mov rsi, rsp
	add rsi, 32 ; rdi and rsi are also pushed in stack
	syscall
	ret

;--------------------------------------
; WRITES STRING IN STDOUT
; Entry: rsi = &string
; Destroy List: rax rcx rdx rsi rdi
;--------------------------------------
putstring: 
.for:
	call putchar_mem
	inc rsi ; ++rsi
	cmp [rsi], byte '$'
	jne .for
	ret
;--------------------------------------
; CONVERT NUMBER INTO DECIMAL
; Entry: rax = number to convert
; Destroy List: rax rbx rdx rdi
;--------------------------------------
decimal:
	xor rdi, rdi ; rdi = 0
.for:	
	xor rdx, rdx ; rdx = 0
	mov rbx, 10 ; rbx = rax
	div rbx ; rax = rax / 10, rdx = rax % 10
	add rdx, '0' ; rdx -> ascii code of digit
	push rdx ; push digit ascii code in stack
	inc rdi ; ++rdi
	cmp rax, 0
	jne .for
;print 
.for_print:
	push rsi ; save rsi
	push rdi ; save rdi
	push rcx ; save rcx
	call putchar_nomem
	pop rcx ; return rcx
	pop rdi ; return rdi
	pop rsi ; return rsi
	pop rdx ; rdx = written symb (trash)
	dec rdi ; --rdi
	jnz .for_print
;print
	ret

;--------------------------------------
; CONVERT NUMBER INTO BINARY
; Entry: rax = number to convert
; Destroy List: rax rbx rdx rdi
;--------------------------------------
binary:
	xor rdi, rdi ; rdi = 0
.for:	
	mov rbx, rax ; rbx = rax
	shr rbx, 1 ; rbx /= 2
	shl rbx, 1 ; rbx *= 2
	xchg rax, rbx ; swap (rax, rbx)
	xor rbx, rax ; rbx = digit
	add rbx, '0' ; digit -> digit ascii code
	push rbx ; push digit ascii code in stack
	inc rdi ; ++rdi
	shr rax, 1 ; rax /= 2 - rax is ready for the next walkthrough
	cmp rax, 0
	jne .for
;print 
.for_print:
	push rsi ; save rsi
	push rdi ; save rdi
	push rcx ; save rcx
	call putchar_nomem
	pop rcx ; return rcx
	pop rdi ; return rdi
	pop rsi ; return rsi
	pop rdx ; rdx = written symb (trash)
	dec rdi ; --rdi
	jnz .for_print
;print
	ret
;--------------------------------------
; CONVERT NUMBER INTO OCTAL
; Entry: rax = number to convert
; Destroy List: rax rbx rdx rdi
;--------------------------------------
octal:
	xor rdi, rdi ; rdi = 0
.for:	
	mov rbx, rax ; rbx = rax
	shr rbx, 3 ; rbx /= 8
	shl rbx, 3 ; rbx *= 8
	xchg rax, rbx ; swap (rax, rbx)
	xor rbx, rax ; rbx = digit
	add rbx, '0' ; digit -> digit ascii code
	push rbx ; push digit ascii code in stack
	inc rdi ; ++rdi
	shr rax, 3 ; rax /= 8 - rax is ready for the next walkthrough
	cmp rax, 0
	jne .for
;print 
.for_print:
	push rsi ; save rsi
	push rdi ; save rdi
	push rcx ; save rcx
	call putchar_nomem
	pop rcx ; return rcx
	pop rdi ; return rdi
	pop rsi ; return rsi
	pop rdx ; rdx = written symb (trash)
	dec rdi ; --rdi
	jnz .for_print
;print
	ret

;--------------------------------------
; CONVERT NUMBER INTO HEXADECIMAL
; Entry: rax = number to convert
; Destroy List: rax rbx rdx rdi
;--------------------------------------
hexadecimal:
	xor rdi, rdi ; rdi = 0
.for:	
	mov rbx, rax ; rbx = rax
	shr rbx, 4 ; rbx /= 16
	shl rbx, 4 ; rbx *= 16
	xchg rax, rbx ; swap (rax, rbx)
	xor rbx, rax ; rbx = digit
	cmp rbx, 9
	ja .if
	add rbx, '0' ; digit -> digit ascii code
	jmp .next
.if:
	add rbx, 'A' - 10
.next:	
	push rbx ; push digit ascii code in stack
	inc rdi ; ++rdi
	shr rax, 4 ; rax /= 16 - rax is ready for the next walkthrough
	cmp rax, 0
	jne .for
;print 
.for_print:
	push rsi ; save rsi
	push rdi ; save rdi
	push rcx ; save rcx
	call putchar_nomem
	pop rcx ; return rcx
	pop rdi ; return rdi
	pop rsi ; return rsi
	pop rdx ; rdx = written symb (trash)
	dec rdi ; --rdi
	jnz .for_print
;print
	ret

;--------------------------------------
; HANDLE FORMAT STRING
; Entry: BP + 8 = format string
; Destroy List: rax rcx rdx
;--------------------------------------
format_handle: 
	mov rax, [rbp + 8] ; pop format string to rax
	xor rcx, rcx ; rcx = 0 (format string iter)
	xor rdi, rdi ; rdi = 0 (argument counter)
	inc rdi

format_for:
	cmp [rax + rcx], byte '%'
	je switcher
	cmp [rax + rcx], byte '$'
	je return
	push rax ; save rax
	push rcx ; save rcx
	push rdx ; save rdx
	push rdi ; save rdi
	push rsi ; save rsi
	mov rsi, rax
	add rsi, rcx ; rsi (&char to print) = rax + rcx
	call putchar_mem
	pop rsi ; return rsi
	pop rdi ; return rdi
	pop rdx ; return rdx
	pop rcx ; return rcx
	pop rax ; return rax
	inc rcx ; ++rcx
	jmp format_for ; continue format string walkthrough
	ret

switcher:
	inc rdi ; ++argument counter
	inc rcx ; ++format string iter
	cmp [rax + rcx], byte '%'
	je case_percent
	cmp [rax + rcx], byte 'c'
	je case_char
	cmp [rax + rcx], byte 's'
	je case_string
	cmp [rax + rcx], byte 'd'
	je case_decimal
	cmp [rax + rcx], byte 'b'
	je case_binary
	cmp [rax + rcx], byte 'o'
	je case_octal
	cmp [rax + rcx], byte 'x'
	je case_hexadecimal
	jmp format_for
 
case_percent:
	inc rcx ; ++rcx
	dec rdi ;--argument counter (because % is not an argument)
	push rax ; save rax
	push rcx ; save rcx
	mov rsi, percent
	push rdx ; save rdx
	push rdi ; save rdi
	push rsi ; save rsi
	call putchar_mem
	pop rsi ; return rsi
	pop rdi ; return rdi
	pop rdx ; return rdx
	pop rcx ; return rcx
	pop rax ; return rax
	jmp format_for

case_char:
	inc rcx ; ++rcx
	push rax ; save rax
	push rcx ; save rcx
	mov rsi, [rbp + rdi * 8] ; rsi = &char to print
	push rdx ; save rdx
	push rdi ; save rdi
	push rsi ; save rsi
	call putchar_mem
	pop rsi ; return rsi
	pop rdi ; return rdi
	pop rdx ; return rdx
	pop rcx ; return rcx
	pop rax ; return rax
	jmp format_for

case_string:
	inc rcx; ++rcx
	push rax ; save rax
	push rcx ; save rcx
	push rdx ; save rdx
	push rsi ; save rsi
	mov rsi, [rbp + rdi * 8] ; rsi = &string to print
	push rdi ; save rdi
	call putstring
	pop rdi ; return rdi
	pop rsi ; return rsi
	pop rdx ; return rdx
	pop rcx; return rcx
	pop rax ; return rax
	jmp format_for

case_decimal:
	inc rcx ; ++rcx
	push rax ; save rax
	mov rax, [rbp + rdi * 8] ; rax = number to convert
	push rbx ; save rbx
	push rdx ; save rdx
	push rdi ; save rdi
	call decimal
	pop rdi ; return rdi
	pop rdx ; return rdx
	pop rbx ; return rbx
	pop rax ; return rax
	jmp format_for

case_binary:
	inc rcx ; ++rcx
	push rax ; save rax
	mov rax, [rbp + rdi * 8] ; rax = number to convert
	push rbx ; save rbx
	push rdx ; save rdx
	push rdi ; save rdi
	call binary
	pop rdi ; return rdi
	pop rdx ; return rdx
	pop rbx ; return rbx
	pop rax ; return rax
	jmp format_for

case_octal:
	inc rcx ; ++rcx
	push rax ; save rax
	mov rax, [rbp + rdi * 8] ; rax = number to convert
	push rbx ; save rbx
	push rdx ; save rdx
	push rdi ; save rdi
	call octal
	pop rdi ; return rdi
	pop rdx ; return rdx
	pop rbx ; return rbx
	pop rax ; return rax
	jmp format_for

case_hexadecimal:
	inc rcx ; ++rcx
	push rax ; save rax
	mov rax, [rbp + rdi * 8] ; rax = number to convert
	push rbx ; save rbx
	push rdx ; save rdx
	push rdi ; save rdi
	call hexadecimal
	pop rdi ; return rdi
	pop rdx ; return rdx
	pop rbx ; return rbx
	pop rax ; return rax
	jmp format_for

return:	
	ret
;--------------------------------------
;global _start

;_start:	push string ; string
;	push char ; A ascii
;	push 10
;	push 10
;	push 10
;	push 10
;	push Format 
;	push rbp ; func preparation
;	mov rbp, rsp ; func preparation
;	call format_handle
;	mov rsp, rbp ; func return
;	pop rbp ; func return
;	exit

global my_printf
my_printf:

    	pop r10 ; r10 = return code (special)

; arguments before return code 

	push r9
    	push r8
    	push rcx
    	push rdx
    	push rsi
    	push rdi

; argumnets before return code

        push rbp ; func preparation
        mov rbp, rsp ; func preparation
        call format_handle
        mov rsp, rbp ; func return
        pop rbp ; func return

; arguments before return code

        pop rdi
	pop rsi
	pop rdx
	pop rcx
	pop r8
	pop r9

; arguments before return code

	push r10 ; r10 = return code (special)

	ret
;--------------------------------------
section .data

percent db '%'

;Format db "%d %b %o %x LOL %c %s", 10, '$'
;char db "A"
;string db "Test", '$'
