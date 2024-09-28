              SECTION .text

              global util_alloc
              global max
              global min

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
max:
; rdi a
; rsi b
;
; Returns
; rax greatest of a and b
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              cmp rdi, rsi
              jg .a_is_larger

              mov rax, rsi
              ret
.a_is_larger:
              mov rax, rdi
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
min:
; rdi a
; rsi b
;
; Returns
; rax lowest of a and b
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              cmp rdi, rsi
              jl .a_is_less

              mov rax, rsi
              ret
.a_is_less:
              mov rax, rdi
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
util_alloc:
; Allocate memory
;
; rdi num bytes
;
; Returns
; rax pointer to memory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov r11, rdi

              mov rax, 9                    ; sys_mmap
              mov rdi, 0                    ; addr
              mov rsi, r11                  ; num bytes
              mov rdx, 0b11                 ; PROT_READ | PROT_WRITE
              mov r10, 0b00100010           ; MAP_PRIVATE | MAP_ANONYMOUS
              mov r8, -1                    ; file descriptor
              mov r9, 0                     ; offset

              push rdi
              syscall
              pop rdi

              ; Zero memory
              xor r9, r9
              xor rcx, rcx
              mov r8, rax
.loop:
              add r8, rcx
              mov [r8], r9

              inc rcx
              cmp rcx, rdi

              ret
