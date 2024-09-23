%include      "src/common.mac"

%define       MAP_W FB_W / 64
%define       MAP_H FB_H / 64

              SECTION .data

goodbye:      db 'Good bye!', 10

image_path:   db './data/circles.bmp', 0
image_w:      dd 512
image_h:      dd 512
image_size:   dd 512 * 512 * 4

player_x:     dd 900
player_y:     dd 200
player_dx     dd 0
player_dy     dd 0

              SECTION .bss

%define       NUM_GAME_OBJS MAP_W * MAP_H
%define       GAME_OBJ_SZ 128
game_objs     resb NUM_GAME_OBJS * GAME_OBJ_SZ

termios_old:  resb 60                       ; Original terminal settings
termios_new:  resb 60                       ; Modified terminal settings
stdin_flags:  resq 1                        ; Original stdin flags
image:        resb 512 * 512 * 4

              SECTION .text
              extern drw_init
              extern drw_draw
              extern drw_fill
              extern drw_load_bmp
              extern drw_term

              global _start

; Process memory layout
;----------------------
;
;  Higher Addresses
; |--------------|
; | Stack        |  (Grows Downwards)
; |______________|
; |              |
; |              |  (Unavailable)
; |______________|
; | Heap         |  (Grows Upwards)
; |              |
; |              |
; |              |
; |--------------|  <-- Program Break (Manipulated by sbrk)
; | BSS Segment  |  (Uninitialized Data)
; |--------------|
; | Data Segment |  (Initialized Data)
; |--------------|
; | Text Segment |  (Code)
; |--------------|
;  Lower Addresses
;
;
; Calling convention
; ------------------
;
; To call a function, fill registers in order.
;   For integers and pointers: rdi, rsi, rdx, rcx, r8, r9
;   For floating-point (float, double): xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, xmm7
; For system calls, the order is: rdi, rsi, rdx, r10, r8, r9
; Push remaining args to stack (in order right-to-left for C functions)
; The call instruction will then push the return address
; Functions shouldn't change: rbp, rbx, r12, r13, r14, r15
; Functions return integers in rax and floats in xmm0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
initialise:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rax, 72                   ; sys_fcntl
              mov rdi, 0                    ; stdin
              mov rsi, 3                    ; F_GETFL (get file status flags)
              syscall
              mov [stdin_flags], rax

              mov rdi, 0                    ; stdin
              mov rsi, 4                    ; F_SETFL (set file status flags)
              mov rdx, rax                  ; Copy old flags to rdx
              or rdx, 0x800                 ; O_NONBLOCK = 0x800 (set non-blocking flag)
              mov rax, 72                   ; sys_fcntl
              syscall

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

              mov rdi, 0                    ; stdin
              mov rsi, 4                    ; F_SETFL (set file status flags)
              mov rdx, [stdin_flags]        ; Copy old flags to rdx
              mov rax, 72                   ; sys_fcntl
              syscall

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
keyboard:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              sub rsp, 16
              mov rax, 0                      ; sys_read
              mov rdi, 0                      ; stdin
              mov rsi, rsp
              mov rdx, 3                      ; num bytes
              syscall
              cmp rax, -1
              je .no_input
              cmp byte [rsp], 0x1B            ; esc sequence
              jne .no_input
              cmp byte [rsp + 1], 0x5B        ; [ character
              jne .quit
              cmp byte [rsp + 2], 0x41
              je .key_up
              cmp byte [rsp + 2], 0x42
              je .key_down
              cmp byte [rsp + 2], 0x43
              je .key_right
              cmp byte [rsp + 2], 0x44
              je .key_left
.key_up:
              mov [player_dx], dword 0
              mov [player_dy], dword -8
              jmp .no_input
.key_down:
              mov [player_dx], dword 0
              mov [player_dy], dword 8
              jmp .no_input
.key_right:
              mov [player_dx], dword 8
              mov [player_dy], dword 0
              jmp .no_input
.key_left:
              mov [player_dx], dword -8
              mov [player_dy], dword 0
              jmp .no_input
.quit:
              add rsp, 16
              mov rax, -1
              ret
.no_input:
              add rsp, 16
              mov rax, 0
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
              mov rdi, 0
              mov rsi, 0
              mov rdx, FB_W
              mov rcx, FB_H
              mov r8, 0xFF44220F
              call drw_fill

              sub rsp, 32
              lea rdi, [rel image]
              mov esi, [image_w]
              mov edx, [image_h]
              mov ecx, [player_x]
              mov r8d, [player_y]
              mov r9, 128                     ; srcX
              mov r10, 192                    ; srcY
              mov [rsp], r10
              mov r10, 64                     ; w
              mov [rsp + 8], r10
              mov r10, 64                     ; h
              mov [rsp + 16], r10
              call drw_draw
              add rsp, 32

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

              ; Get keyboard input
              call keyboard
              cmp rax, -1
              je .exit

              ; Move fella
              mov r8d, [player_dx]
              add [player_x], r8d
              mov r8d, [player_dy]
              add [player_y], r8d

              jmp .loop

.exit:
              mov rax, 1                      ; sys_write
              mov rdi, 1                      ; stdout
              lea rsi, [rel goodbye]
              mov rdx, 14
              syscall

              call terminate

              mov rax, 60                     ; sys_exit
              xor rdi, rdi
              syscall
