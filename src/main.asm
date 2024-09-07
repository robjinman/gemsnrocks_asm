              SECTION .data
hello:        db 'Hello, World!', 10
fb_path:      db '/dev/fb0', 0

drw_fbfd:     dd 0
drw_fb:       dq 0
drw_fb_bytes  dq 0
drw_fb_w      dd 1920
drw_fb_h      dd 1080

              SECTION .bss

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
; Initialise the draw system
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Open /dev/fb0 and get a file descriptor
              mov rax, 2                    ; sys_open
              lea rdi, [rel fb_path]
              mov rsi, 2                    ; O_RDWR
              mov rdx, 0                    ; flags
              syscall
              mov [drw_fbfd], eax

; Compute total frame buffer size
              mov eax, [drw_fb_w]
              mov edi, [drw_fb_h]
              mul edi
              shl rax, 2
              mov [drw_fb_bytes], eax

; mmap the 'file' into the address space
              mov rax, 9                    ; sys_mmap
              mov rdi, 0                    ; addr hint
              mov rsi, [drw_fb_bytes]
              mov rdx, qword 0b11           ; PROT_READ | PROT_WRITE
              mov r10, qword 0b1            ; MAP_SHARED
              mov r8d, [drw_fbfd]
              mov r9, 0
              syscall
              mov [drw_fb], rax

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_term:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rax, 11                   ; sys_munmap
              mov rdi, [drw_fb]
              mov rsi, [drw_fb_bytes]
              syscall

              mov edi, [drw_fbfd]
              mov rax, 3                    ; sys_close

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_copy:
; Copy pixels from src buffer to dest buffer
;
; rdi     src
; rsi     srcX
; rdx     srcY
; rcx     dst
; r8      dstX
; r9      dstY
; stack   w
;         h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TODO
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_draw:
; Copy pixels from src buffer to frame buffer
;
; rdi     src
; rsi     srcX
; rdx     srcY
; rcx     dstX
; r8      dstY
; r9      w
; stack   h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TODO
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_fill:
; Fills the rectangular region with a colour
;
; rdi     dstX
; rsi     dstY
; rdx     w
; rcx     h
; r8      colour
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push r12
              push r13
              xor r10, r10                  ; r10 counts rows
.loop_row:
              xor r11, r11                  ; r11 counts columns
.loop_col:
              mov r12, rdi
              add r12, r11
              shl r12, 2                    ; offset in column
              mov rax, rsi
              add rax, r10
              mov r13d, [drw_fb_w]
              imul rax, r13
              shl rax, 2
              add rax, [drw_fb]             ; pointer to row
              mov [rax + r12], r8

              inc r11
              cmp r11, rdx
              jl .loop_col

              inc r10
              cmp r10, rcx
              jl .loop_row

              pop r13
              pop r12

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

              mov rdi, 300
              mov rsi, 200
              mov rdx, 80
              mov rcx, 50
              mov r8, 0x00FF0000
              call drw_fill

              call drw_term

              mov rax, 60
              xor rdi, rdi
              syscall
