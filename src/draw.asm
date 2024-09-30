              SECTION .data

%define       FONT_CHAR_W 30
%define       FONT_CHAR_H 48
%define       SPACE_CHAR_CODE_PT 32

drw_fb_path   db '/dev/fb0', 0
drw_fbfd      dd 0
drw_fb_w      dd 0
drw_fb_h      dd 0
drw_buf       dq 0

              SECTION .text

              global drw_fb_w
              global drw_fb_h
              global drw_init
              global drw_term
              global drw_draw
              global drw_load_bmp
              global drw_fill
              global drw_draw_text
              global drw_flush

              extern util_alloc

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

              sub rsp, 160

              ; Get screen resolution
              mov rax, 16                   ; sys_ioctl
              mov rdi, [drw_fbfd]
              mov rsi, 0x4600               ; FBIOGET_VSCREENINFO
              mov rdx, rsp
              syscall

              mov r11d, [rsp]
              mov [drw_fb_w], r11d          ; width
              mov r11d, [rsp + 4]
              mov [drw_fb_h], r11d          ; height

              ; Allocate space for screen buffer
              mov edi, [drw_fb_w]
              mov r11d, [drw_fb_h]
              imul rdi, r11
              shl rdi, 2
              call util_alloc
              mov [drw_buf], rax

              add rsp, 160

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
; rdx w
; rcx h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rsi
              push rdx
              push rcx

              ; Open file
              mov rax, 2                    ; sys_open
              mov rsi, 2                    ; O_RDWR
              mov rdx, 0                    ; flags
              syscall
              mov rdi, rax                  ; file descriptor

              pop rcx
              pop rdx
              pop rsi

              ; Store width and height at beginning of buffer
              mov [rsi], edx
              add rsi, 4
              mov [rsi], ecx
              add rsi, 4

              ; Load data from file
              mov rax, 17                   ; sys_pread64
              imul rdx, rcx
              shl rdx, 2                    ; num bytes
              mov r10, 54                   ; offset

              push r11
              push rcx
              syscall
              pop rcx
              pop r11

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_draw_text:
; rdi text
; rsi font image
; rdx x
; rcx y
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rbp
              push r12
              push r13
              mov rbp, rsp
              sub rsp, 32

              mov r13, rdi                  ; text
              mov [rbp - 8], rsi            ; font image
              mov [rbp - 16], rdx           ; x
              mov [rbp - 24], rcx           ; y

              xor r11, r11                  ; count
.loop:
              movzx r8, byte [r13]
              cmp r8, 0
              je .end

              push r11                      ; count

              mov rdi, [rbp - 8]
              mov r10, r11
              imul r10, FONT_CHAR_W
              mov rsi, r10
              add rsi, [rbp - 16]           ; dstX
              mov rdx, [rbp - 24]           ; dstY
              mov rcx, r8
              sub rcx, SPACE_CHAR_CODE_PT
              imul rcx, FONT_CHAR_W         ; srcX
              mov r8, 0                     ; srcY
              mov r9, FONT_CHAR_W           ; w
              mov r12, FONT_CHAR_H
              sub rsp, 16
              mov [rsp], r12                ; h
              call drw_draw
              add rsp, 16

              pop r11                       ; count

              inc r13                       ; advance text pointer
              inc r11                       ; advance counter
              jmp .loop
.end:
              mov rsp, rbp
              pop r13
              pop r12
              pop rbp

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_draw:
; Copy pixels from src image to frame buffer
;
; rdi image
; rsi dstX (screen space)
; rdx dstY (screen space)
; rcx srcX
; r8  srcY
; r9  w
;     h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rbp
              mov rbp, rsp
              sub rsp, 80

              mov r10d, [rdi]
              mov [rbp - 64], r10           ; srcW
              mov r10d, [rdi + 4]
              mov [rbp - 72], r10           ; srcH

              add rdi, 8                    ; start of pixel data

              mov [rbp - 8], rdi            ; src
              mov [rbp - 16], rsi           ; dstX
              mov [rbp - 24], rdx           ; dstY
              mov [rbp - 32], rcx           ; srcX
              mov [rbp - 40], r8            ; srcY
              mov [rbp - 48], r9            ; w
              mov r10, [rbp + 16]
              mov [rbp - 56], r10           ; h

              push r12
              push r13
              push r14
              push r15

              xor r13, r13                  ; row
.loop_row:
              ; src offset = 4 * (srcW * (row + srcY) + srcX + col)
              ; dst offset = 4 * (drw_fb_w * (row + dstY) + dstx + col)

              mov r8, r13
              add r8, [rbp - 40]            ; row + srcY
              imul r8, [rbp - 64]           ; srcW * (row + srcY)
              add r8, [rbp - 32]            ; srcW * (row + srcY) + srcX

              mov r9, r13
              add r9, [rbp - 24]            ; row + dstY
              cmp r9, 0
              jl .skip_row
              cmp r9d, [drw_fb_h]
              jge .skip_row
              imul r9d, [drw_fb_w]          ; drw_fb_w * (row + dstY)
              add r9, [rbp - 16]            ; drw_fb_w * (row + dstY) + dstX

              xor r14, r14                  ; col
.loop_col:
              mov r15, r14
              add r15, [rbp - 16]
              cmp r15, 0
              jl .skip_col
              cmp r15d, [drw_fb_w]
              jge .skip_col

              mov r10, r8
              add r10, r14                  ; srcW * (row + srcY) + srcX + col
              shl r10, 2                    ; src offset

              mov r11, r9
              add r11, r14                  ; drw_fb_w * (row + dstY) + dstX + col
              shl r11, 2                    ; dst offset

              mov rdi, [rbp - 8]            ; src
              add rdi, r10                  ; src + src offset

              mov rsi, [drw_buf]            ; dst
              add rsi, r11                  ; dst + dst offset

              mov r15d, [rdi]               ; src pixel

              ; Copy pixel if alpha component is non-zero
              mov rax, r15
              mov rdx, 0xFF000000
              and rax, rdx
              jz .skip_col
              mov [rsi], r15d               ; copy pixel
.skip_col:
              inc r14
              cmp r14, [rbp - 48]
              jl .loop_col
.skip_row:
              inc r13
              cmp r13, [rbp - 56]
              jl .loop_row

              pop r15
              pop r14
              pop r13
              pop r12
              mov rsp, rbp
              pop rbp

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drw_flush:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rax, 18                   ; sys_pwrite64
              mov rdi, [drw_fbfd]
              mov rsi, [drw_buf]
              mov edx, [drw_fb_w]
              imul edx, [drw_fb_h]
              shl rdx, 2                    ; num bytes
              mov r10, 0                    ; destination offset
              syscall

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
              mov r10, rsi                  ; dstY
              mov r11, rdx                  ; w
              mov r12, rcx                  ; h

              xor r13, r13                  ; row
.loop_row:
              xor r14, r14                  ; column
.loop_col:
              mov r15, r13
              add r15, r10
              imul r15d, [drw_fb_w]
              add r15, r9
              add r15, r14
              shl r15, 2                    ; dst offset

              mov rdi, [drw_buf]
              add rdi, r15
              mov [rdi], r8d

              inc r14
              cmp r14, r11
              jl .loop_col

              inc r13
              cmp r13, r12
              jl .loop_row

              pop r15
              pop r14
              pop r13
              pop r12

              ret
