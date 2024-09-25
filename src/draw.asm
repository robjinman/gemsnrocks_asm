%include      "src/common.mac"

              SECTION .data

drw_fb_path:  db '/dev/fb0', 0
drw_fbfd:     dd 0
drw_fb_bytes: dq 0
drw_fb_w:     dd FB_W
drw_fb_h:     dd FB_H

              SECTION .bss

drw_buf:      resb FB_W * 4                 ; General purpose buffer

              SECTION .text

              global drw_init
              global drw_term
              global drw_draw
              global drw_load_bmp
              global drw_fill

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
              mov [drw_fb_bytes], rax

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_term:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov edi, [drw_fbfd]
              mov rax, 3                    ; sys_close

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_load_bmp:
; Load a .bmp file into the given buffer
;
; rdi path
; rsi buffer
; rdx bytes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              ; Open file
              push rsi
              push rdx

              mov rax, 2                    ; sys_open
              mov rsi, 2                    ; O_RDWR
              mov rdx, 0                    ; flags
              syscall
              mov rdi, rax

              pop rdx
              pop rsi

              ; Load data from file
              mov rax, 17                   ; sys_pread64
              mov r10, 54
              push r11
              push rcx
              syscall
              pop rcx
              pop r11

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_blit:
; Copy pixels from src to dst buffers, with alpha masking
;
; rdi src
; rsi dst
; rdx count (in pixels)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push r11

              xor rcx, rcx
.loop:
              mov r8, rcx
              shl r8, 2                     ; offset in bytes

              mov r9, r8
              add r9, rdi                   ; src address
              add r8, rsi                   ; dst address

              mov r10d, [r9]
              mov rax, r10
              mov r11, 0xFF000000
              and rax, r11
              jz .skip
              mov [r8], r10d
.skip:
              inc rcx
              cmp rcx, rdx
              jl .loop

              pop r11

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_draw:
; Copy pixels from src buffer to frame buffer
;
; rdi src
; rsi srcW
; rdx srcH
; rcx dstX
; r8  dstY
; r9  srcX
;     srcY
;     w
;     h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rbp
              mov rbp, rsp
              sub rsp, 80

              mov [rbp - 8], rdi            ; src
              mov [rbp - 16], rsi           ; srcW
              mov [rbp - 24], rdx           ; srcH
              mov [rbp - 32], rcx           ; dstX
              mov [rbp - 40], r8            ; dstY
              mov [rbp - 48], r9            ; srcX
              mov r10, [rbp + 16]
              mov [rbp - 56], r10           ; srcY
              mov r10, [rbp + 24]
              mov [rbp - 64], r10           ; w
              mov r10, [rbp + 32]
              mov [rbp - 72], r10           ; h

              push r12
              push r13
              push r14
              push r15

              xor r13, r13                  ; row
.loop_row:
              ; src offset = 4 * (srcW * (row + srcY) + srcX)
              ; dst offset = 4 * (drw_fb_w * (row + dstY) + dstx)
              mov r14, r13
              add r14, [rbp - 56]           ; row + srcY
              imul r14, [rbp - 16]          ; srcW * (row + srcY)
              add r14, [rbp - 48]           ; srcW * (row + srcY) + srcX
              shl r14, 2                    ; src offset

              mov r15, r13
              add r15, [rbp - 40]           ; row + dstY
              imul r15d, [drw_fb_w]         ; drw_fb_w * (row + dstY)
              add r15, [rbp - 32]           ; drw_fb_w * (row + dstY) + dstX
              shl r15, 2                    ; dst offset

              ; Read bytes from frame buffer into buffer
              mov rax, 17                   ; sys_pread64
              mov rdi, [drw_fbfd]
              lea rsi, [rel drw_buf]
              mov rdx, [rbp - 64]           ; w
              shl rdx, 2                    ; num bytes
              mov r10, r15                  ; frame buffer offset
              syscall

              ; Blit pixels from src image to buffer
              mov rdi, [rbp - 8]            ; src
              add rdi, r14
              lea rsi, [rel drw_buf]
              mov rdx, [rbp - 64]           ; w
              call drw_blit

              ; Write buffer to screen
              mov rax, 18                   ; sys_pwrite64
              mov rdi, [drw_fbfd]
              lea rsi, [rel drw_buf]
              mov rdx, [rbp - 64]           ; w
              shl rdx, 2                    ; num bytes
              mov r10, r15                  ; frame buffer offset
              syscall

              inc r13
              cmp r13, [rbp - 72]           ; h
              jl .loop_row

              pop r15
              pop r14
              pop r13
              pop r12
              mov rsp, rbp
              pop rbp

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_fill_buf:
; Fills the buffer with a 64-bit value
;
; rdi value
; rsi count
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              lea rdx, [rel drw_buf]
              xor rcx, rcx
.loop:
              mov r8, rcx
              shl r8, 2
              add r8, rdx
              mov [r8], rdi

              inc rcx
              cmp rcx, rsi
              jl .loop

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_fill:
; Fills the rectangular region with a colour
;
; rdi dstX
; rsi dstY
; rdx w
; rcx h
; r8  colour
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push r12
              push r13
              push r14
              push r15

              mov r9, rdi                   ; dstX
              mov r14, rsi                  ; dstY
              mov r11, rdx                  ; w
              mov r12, rcx                  ; h

              mov rdi, r8
              mov rsi, r11
              call drw_fill_buf

              xor r13, r13                  ; row
.loop_row:
              mov r15, r14
              add r15, r13
              imul r15d, [drw_fb_w]
              add r15, r9
              shl r15, 2                    ; offset into frame buffer

              mov rax, 18                   ; sys_pwrite64
              mov rdi, [drw_fbfd]
              lea rsi, [drw_buf]
              mov rdx, r11                  ; num bytes
              shl rdx, 2
              mov r10, r15                  ; destination offset
              push r11
              syscall
              pop r11

              inc r13
              cmp r13, r12
              jl .loop_row

              pop r15
              pop r14
              pop r13
              pop r12

              ret
