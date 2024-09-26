              SECTION .text

              global util_alloc

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
