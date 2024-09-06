              SECTION .data
hello:        db 'Hello, World!', 10
fb_path:      db '/dev/fb0', 0

drw_fbfd:     dq 0
drw_x:        dq 0
drw_y:        dq 0

              SECTION .bss
drw_buf:      resb 7680

              SECTION .text
              global _start

; Calling convention
; ------------------
; To call a function, fill registers in order.
;   For integers and pointers: rdi, rsi, rdx, rcx, r8, r9
;   For floating-point (float, double): xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, xmm7
; Push args to stack right-to-left (for C function)
; The call instruction will then push the return address
; Functions shouldn't change: rbp, rbx, r12, r13, r14, r15
; Functions return integers in rax and floats in xmm0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_init:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rax, 2                    ; sysopen
              lea rdi, [rel fb_path]
              mov rsi, 2                    ; O_RDWR
              mov rdx, 0                    ; flags
              syscall
              mov [drw_fbfd], rax

; Fill the buffer with the colour
              xor rcx, rcx
              mov rdi, 1920
              mov rdx, 0xCDCDCDCD
.loop:
              mov [drw_buf + 4 * rcx], rdx
              inc rcx
              cmp rcx, rdi
              jl .loop

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_term:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rdi, [drw_fbfd]
              mov rax, 3                    ; sys_close
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_goto:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov [drw_x], rdi
              mov [drw_y], rsi
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_blit:
; Blit pixels from buffer to frame buffer
;
; rdi - num pixels
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rcx, rdi
              ; Seek to position
              mov rdi, [drw_fbfd]
              mov rax, [drw_y]              ; offset
              mov rsi, 1920
              mul rsi
              mov r8, [drw_x]
              add rax, r8
              shl rax, 2
              mov rsi, rax
              xor rdx, rdx                  ; SEEK_SET
              mov rax, 8                    ; sys_lseek
              push rcx
              syscall
              pop rcx
              ; Write pixel data
              lea rsi, [rel drw_buf]
              mov rdx, rcx
              shl rdx, 2                    ; num bytes
              mov rax, 1                    ; sys_write
              syscall
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_fill:
; Fills the rectangular region with a colour
;
; rdi - width
; rsi - height
; rdx - colour
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              xor rcx, rcx
; Fill the buffer with the colour
;.loop:
;              mov [drw_buf + 4 * rcx], rdx
;              inc rcx
;              cmp rcx, rdi
;              jl .loop

              xor rcx, rcx
; Iterate over rows, blitting pixels from buffer to frame buffer
.next_row:
              push rsi
              push rcx
              push rdi
              call drw_blit
              pop rdi
              pop rcx
              pop rsi
              inc dword [drw_y]
              inc rcx
              cmp rcx, rsi
              jl .next_row
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_start:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rax, 1                    ; sys_write
              mov rdi, 1                    ; stdout
              mov rsi, hello                ; TODO: lea rel?
              mov rdx, 14
              syscall

              call drw_init

              mov rdi, 200
              mov rsi, 100
              call drw_goto

              mov rdi, 150
              mov rsi, 80
              mov rdx, 0x00FF0000
              call drw_fill

              call drw_term

              mov rax, 60
              xor rdi, rdi
              syscall
