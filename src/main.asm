%include      "src/common.mac"

%define       CELL_W 64
%define       CELL_H 64
%define       GRID_W FB_W / CELL_W
%define       GRID_H FB_H / CELL_H
%define       BACKGROUND_COLOUR 0xFF44220F

              SECTION .data

goodbye:      db 'Good bye!', 10

image_path:   db './data/circles.bmp', 0
image_w:      dd 512
image_h:      dd 512
image_size:   dd 512 * 512 * 4

              SECTION .bss

%define       OBJ_SIZE 64
%define       OBJ_OFFSET_X 0
%define       OBJ_OFFSET_Y 8
%define       OBJ_OFFSET_IMG 16             ; Pointer to sprite sheet
%define       OBJ_OFFSET_IMG_ROW 24         ; Current row (animation)
%define       OBJ_OFFSET_FRAME 32           ; Current column (frame)
%define       OBJ_OFFSET_ANIM_ST 40         ; 1 = playing, 0 = paused
%define       OBJ_OFFSET_DX 48
%define       OBJ_OFFSET_DY 56

%define       ANIM_NUM_FRAMES 8

grid:         resq GRID_W * GRID_H          ; Pointers to game objects
player:       resq 1

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
              extern drw_flush

              global _start

; Process memory layout
;----------------------
;
;  Higher Addresses
; |--------------|
; | Stack        |  (Grows Downwards)
; |--------------|
; |              |  (Unavailable)
; |              |
; |--------------| <-- Program Break (Manipulated by sbrk)
; | Heap         |  (Grows Upwards)
; |              |
; |              |
; |              |
; |--------------|
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
; For integers and pointers: rdi, rsi, rdx, rcx, r8, r9
; For floating-point (float, double): xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, xmm7
; For system calls, the order is: rdi, rsi, rdx, r10, r8, r9
; Push remaining args to stack (in order right-to-left for C functions)
; The call instruction will then push the return address
; Functions shouldn't change: rbp, rbx, r12, r13, r14, r15
; Functions return integers in rax and floats in xmm0

; Stack should be 16-byte aligned before calling a function.
; TODO: Always push at least 8 bytes before every call?

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
construct_scene:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rdi, 10
              mov rsi, 5
              call construct_player

              ret

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
grid_insert:
; rdi gridX
; rsi gridY
; rdx object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              imul rsi, GRID_W
              add rsi, rdi
              lea r8, [rel grid]
              add r8, rsi
              mov [r8], rdx

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
grid_insert_world:
; rdi worldX
; rsi worldY
; rdx object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rax, rdi
              mov r8, CELL_W
              div r8
              mov r9, rax                   ; gridX

              mov rax, rsi
              mov r8, CELL_H
              div r8
              mov r10, rax                  ; gridY

              mov rdi, r9
              mov rsi, r10
              call grid_insert

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
obj_update:
; rdi object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rdx, [rdi + OBJ_OFFSET_ANIM_ST]
              cmp rdx, 0
              je .end

              ; Move to next frame
              mov rax, [rdi + OBJ_OFFSET_FRAME]
              mov r8, ANIM_NUM_FRAMES
              inc rax
              div r8
              mov [rdi + OBJ_OFFSET_FRAME], rdx

              ; Move the object
              mov r8, [rdi + OBJ_OFFSET_DX]
              add [rdi + OBJ_OFFSET_X], r8
              mov r8, [rdi + OBJ_OFFSET_DY]
              add [rdi + OBJ_OFFSET_Y], r8

              ; Stop the animation if it's reached the end
              cmp rdx, 0
              jne .end
              mov rcx, 0
              mov [rdi + OBJ_OFFSET_ANIM_ST], rcx
.end:
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
update_scene:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              xor rcx, rcx
.loop:
              lea r9, [rel grid]
              mov r8, rcx
              shl r8, 3
              add r9, r8
              mov rdi, [r9]
              cmp rdi, 0
              je .skip

              push rcx
              call obj_update
              pop rcx
.skip:
              inc rcx
              cmp rcx, GRID_H * GRID_W
              jl .loop

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
construct_object:
; rdi gridX
; rsi gridY
; rdx image
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rbp
              mov rbp, rsp
              sub rsp, 32

              mov [rbp - 8], rdi            ; gridX
              mov [rbp - 16], rsi           ; gridY
              mov [rbp - 24], rdx           ; image

              mov rdi, OBJ_SIZE
              call util_alloc

              mov r11, rax                  ; pointer

              mov rdi, [rbp - 8]            ; gridX
              imul rdi, CELL_W              ; worldX
              mov [r11 + OBJ_OFFSET_X], rdi
              mov rdi, [rbp - 16]           ; gridY
              imul rdi, CELL_H              ; worldY
              mov [r11 + OBJ_OFFSET_Y], rdi

              mov rdi, [rbp - 24]           ; image
              mov [r11 + OBJ_OFFSET_IMG], rdi

              mov rdi, 0
              mov [r11 + OBJ_OFFSET_IMG_ROW], rdi
              mov [r11 + OBJ_OFFSET_FRAME], rdi
              mov [r11 + OBJ_OFFSET_ANIM_ST], rdi

              mov rdi, [rbp - 8]            ; gridX
              mov rsi, [rbp - 16]           ; gridY
              mov rdx, r11                  ; pointer
              call grid_insert

              mov rsp, rbp
              pop rbp

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
obj_play_anim:
; rdi object
; rsi animation ID (row of sprite sheet)
; rdx dx
; rcx dy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov r8, [rdi + OBJ_OFFSET_ANIM_ST]
              cmp r8, 1
              je .end
              mov r9, 1
              mov [rdi + OBJ_OFFSET_ANIM_ST], r9
              mov [rdi + OBJ_OFFSET_IMG_ROW], rsi
              mov [rdi + OBJ_OFFSET_DX], rdx
              mov [rdi + OBJ_OFFSET_DY], rcx
.end:
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
construct_player:
; rdi gridX
; rsi gridY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              lea rdx, [rel image]
              call construct_object
              mov [player], rax

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
obj_draw:
; rdi object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              sub rsp, 32
              mov r11, rdi
              mov rdi, [r11 + OBJ_OFFSET_IMG]
              mov esi, [image_w]            ; TODO
              mov edx, [image_h]
              mov rcx, [r11 + OBJ_OFFSET_X]
              mov r8, [r11 + OBJ_OFFSET_Y]
              mov r9, [r11 + OBJ_OFFSET_FRAME]
              imul r9, CELL_W               ; srcX
              mov r10, [r11 + OBJ_OFFSET_IMG_ROW]
              imul r10, CELL_H              ; srcY
              mov [rsp], r10
              mov r10, CELL_W               ; w
              mov [rsp + 8], r10
              mov r10, CELL_H               ; h
              mov [rsp + 16], r10
              call drw_draw
              add rsp, 32

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
render_scene:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rdi, 0
              mov rsi, 0
              mov rdx, FB_W
              mov rcx, FB_H
              mov r8, BACKGROUND_COLOUR
              call drw_fill

              xor rcx, rcx
.loop:
              lea r9, [rel grid]
              mov r8, rcx
              shl r8, 3
              add r9, r8
              mov rdi, [r9]
              cmp rdi, 0
              je .skip

              push rcx
              call obj_draw
              pop rcx
.skip:
              inc rcx
              cmp rcx, GRID_H * GRID_W
              jl .loop

              call drw_flush

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
keyboard:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              sub rsp, 16
              mov rax, 0                    ; sys_read
              mov rdi, 0                    ; stdin
              mov rsi, rsp
              mov rdx, 3                    ; num bytes
              syscall
              cmp rax, -1
              je .no_input
              cmp byte [rsp], 0x1B          ; esc sequence
              jne .no_input
              cmp byte [rsp + 1], 0x5B      ; [ character
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
              mov rdi, [player]
              mov rsi, 0                    ; Animation ID
              mov rdx, 0                        ; dx
              mov rcx, 0-CELL_H/ANIM_NUM_FRAMES ; dy
              call obj_play_anim
              jmp .no_input
.key_down:
              mov rdi, [player]
              mov rsi, 1                    ; Animation ID
              mov rdx, 0                        ; dx
              mov rcx, CELL_H/ANIM_NUM_FRAMES   ; dy
              call obj_play_anim
              jmp .no_input
.key_right:
              mov rdi, [player]
              mov rsi, 2                    ; Animation ID
              mov rdx, CELL_W/ANIM_NUM_FRAMES   ; dx
              mov rcx, 0                        ; dy
              call obj_play_anim
              jmp .no_input
.key_left:
              mov rdi, [player]
              mov rsi, 3                    ; Animation ID
              mov rdx, 0-CELL_W/ANIM_NUM_FRAMES ; dx
              mov rcx, 0                        ; dy
              call obj_play_anim
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

              call construct_scene

              ; Game loop
.loop:
              call render_scene

              ; Sleep
              sub rsp, 16
              mov rdi, rsp
              mov r8, 0                     ; seconds
              mov [rsp], r8
              mov r8, 1000000000/30         ; nanoseconds
              mov [rsp + 8], r8
              mov rsi, 0
              mov rax, 35                   ; sys_nanosleep
              syscall
              add rsp, 16

              ; Get keyboard input
              call keyboard
              cmp rax, -1
              je .exit

              call update_scene

              jmp .loop

.exit:
              mov rax, 1                    ; sys_write
              mov rdi, 1                    ; stdout
              lea rsi, [rel goodbye]
              mov rdx, 14
              syscall

              call terminate

              mov rax, 60                   ; sys_exit
              xor rdi, rdi
              syscall
