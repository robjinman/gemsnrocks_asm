              SECTION .data
drw_fb_path:  db '/dev/fb0', 0

drw_fbfd:     dd 0
drw_fb:       dq 0
drw_fb_bytes: dq 0
drw_fb_w:     dd 1920
drw_fb_h:     dd 1080

hello:        db 'Hello, World!', 10

image_path:   db './data/image.bmp', 0
image_w:      dd 64
image_h:      dd 64
image_size:   dd 64 * 64 * 4

player_x:     dd 300
player_y:     dd 200

              SECTION .bss
image:        resb 64 * 64 * 4

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
              lea rdi, [rel drw_fb_path]
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
drw_load_bmp:
; Load a .bmp file into the given buffer
;
; rdi     path
; rsi     buffer
; rdx     bytes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              ; Open file
              push rsi
              push rdx

              mov rax, 2                    ; sys_open
              mov rsi, 2                    ; O_RDWR
              mov rdx, 0                    ; flags
              syscall
              mov rdi, rax

              push rdi

              ; Skip header
              mov rax, 8                    ; sys_lseek
              mov rsi, 54
              mov rdx, 0                    ; SEEK_SET
              syscall

              pop rdi
              pop rdx
              pop rsi

              ; Load data from file
              mov rax, 0                    ; sys_read
              syscall

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_copy:
; Copy pixels from src buffer to dest buffer
;
; rdi     src
; rsi     srcX
; rdx     srcY
; rcx     dstX
; r8      dstY
; r9      w
; stack   h
;         dst
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rbp
              mov rbp, rsp

              push r12
              push r13
              push r14

              xor r11, r11                  ; r11 counts rows
.loop_row:
              xor r12, r12                  ; r12 counts columns
.loop_col:
              ; src offset = 4 * (r9 * (r11 + rdx) + (r12 + rsi))
              ; dst offset = 4 * (drw_fb_w * (r11 + r8) + (r12 + rcx))
              mov rax, r11
              add rax, rdx
              imul rax, r9
              add rax, r12
              add rax, rsi
              shl rax, 2
              mov r15, rax                  ; src offset

              mov rax, r11
              add rax, r8
              imul eax, [drw_fb_w]
              add rax, r12
              add rax, rcx
              shl rax, 2                    ; dst offset

              add r15, rdi                  ; src pixel address
              add rax, [rbp + 24]           ; dst pixel address

              mov r10d, [r15]
              mov [rax], r10d

              inc r12
              cmp r12, r9
              jl .loop_col

              inc r11
              cmp r11, [rbp + 16]
              jl .loop_row

              pop r14
              pop r13
              pop r12

              pop rbp
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
              push rbp
              mov rbp, rsp

              mov r10, [rbp + 16]           ; h

              sub rsp, 16
              mov r11, [drw_fb]
              mov [rsp + 8], r11
              mov [rsp], r10

              call drw_copy

              add rsp, 16
              pop rbp
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
              add rax, r12
              mov [rax], r8d

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
              call drw_init

              ; Game loop
.loop:

              mov rdi, 0
              mov rsi, 0
              mov edx, [drw_fb_w]
              mov ecx, [drw_fb_h]
              mov r8, 0xFF332209
              call drw_fill

              lea rdi, [rel image_path]
              lea rsi, [rel image]
              mov rdx, [image_size]
              call drw_load_bmp

              sub rsp, 16
              lea rdi, [rel image]
              mov rsi, 0
              mov rdx, 0
              mov ecx, [player_x]
              mov r8d, [player_y]
              mov r9d, [image_w]
              mov r10d, [image_h]
              mov [rsp], r10d
              call drw_draw
              add rsp, 16

              ; Sleep
              sub rsp, 16
              mov rdi, rsp
              mov r8, 0                       ; seconds
              mov [rsp], r8
              mov r8, 1000000000/30           ; nanoseconds
              mov [rsp + 8], r8
              mov rsi, 0
              mov rax, 35                     ; sys_nanosleep
              syscall
              add rsp, 16

              ; Move fella
              add [player_x], dword 1

              jmp .loop

              mov rax, 1                      ; sys_write
              mov rdi, 1                      ; stdout
              lea rsi, [rel hello]
              mov rdx, 14
              syscall

              call drw_term

              mov rax, 60                     ; sys_exit
              xor rdi, rdi
              syscall
