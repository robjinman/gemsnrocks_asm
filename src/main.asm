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
termios_old:  resb 60                       ; Original terminal settings
termios_new:  resb 60                       ; Modified terminal settings
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
drw_draw:
; Copy pixels from src buffer to frame buffer
;
; TODO: Add srcX, srcY, w, and h params to enable copying a subregion of src
;
; rdi     src
; rsi     srcW
; rdx     srcH
; rcx     dstX
; r8      dstY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push r12
              push r13
              push r14
              push r15

              mov r9, rdi                   ; src
              mov r11, rsi                  ; srcW
              mov r12, rdx                  ; srcH

              xor r13, r13                  ; row
.loop_row:
              ; src offset = 4 * (srcW * row)
              ; dst offset = 4 * (drw_fb_w * (row + dstY) + dstx)
              mov r14, r13
              imul r14, r11                 ; srcW * row
              shl r14, 2                    ; src offset

              mov r15, r13
              add r15, r8                   ; row + dstY
              imul r15d, [drw_fb_w]         ; drw_fb_w * (row + dstY)
              add r15, rcx
              shl r15, 2                    ; dst offset

              mov rax, 18                   ; sys_pwrite64
              mov rdi, [drw_fbfd]
              mov rsi, r9
              add rsi, r14
              mov rdx, r11
              shl rdx, 2
              mov r10, r15
              push r11
              push rcx
              syscall
              pop rcx
              pop r11

              inc r13
              cmp r13, r12
              jl .loop_row

              pop r15
              pop r14
              pop r13
              pop r12

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
initialise:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              ; Get current terminal settings
              mov rax, 16                   ; sys_ioctl
              mov rdi, 0                    ; stdin
              mov rsi, 0x5401               ; TCGETS
              mov rdx, termios_old
              syscall

              ; Make a copy
              mov rax, 16                   ; sys_ioctl
              mov rdi, 0                    ; stdin
              mov rsi, 0x5401               ; TCGETS
              mov rdx, termios_new
              syscall

              ; Disable ICANON and ECHO
              and byte [termios_new + 12], 0xF5

              ; Set modified terminal settings
              mov rax, 16                   ; sys_ioctl
              mov rdi, 0                    ; stdin
              mov rsi, 0x5402               ; TCSETS
              mov rdx, termios_new
              syscall

              call drw_init

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
terminate:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              call drw_term

              ; Restore old terminal settings
              mov rax, 16                   ; sys_ioctl
              mov rdi, 0                    ; stdin
              mov rsi, 0x5402               ; TCSETS
              mov rdx, termios_old
              syscall

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_start:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              call initialise

              lea rdi, [rel image_path]
              lea rsi, [rel image]
              mov rdx, [image_size]
              call drw_load_bmp

              ; Game loop
.loop:
              lea rdi, [rel image]
              mov esi, [image_w]
              mov edx, [image_h]
              mov ecx, [player_x]
              mov r8d, [player_y]
              call drw_draw

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
              add [player_x], dword 8

              jmp .loop

              mov rax, 1                      ; sys_write
              mov rdi, 1                      ; stdout
              lea rsi, [rel hello]
              mov rdx, 14
              syscall

              call terminate

              mov rax, 60                     ; sys_exit
              xor rdi, rdi
              syscall
