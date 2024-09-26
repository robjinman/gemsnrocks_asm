%define       CELL_W 64
%define       CELL_H 64
%define       GRID_W 100
%define       GRID_H 80
%define       BACKGROUND_COLOUR 0xFF112233

              SECTION .data

goodbye       db 'Good bye!', 10

img_plyr_path db './data/player.bmp', 0
img_soil_path db './data/soil.bmp', 0
img_rock_path db './data/rock.bmp', 0
img_wall_path db './data/wall.bmp', 0
img_exit_path db './data/exit.bmp', 0

              SECTION .bss

%define       OBJ_SIZE 72
%define       OBJ_OFFSET_TYPE 0
%define       OBJ_OFFSET_X 8
%define       OBJ_OFFSET_Y 16
%define       OBJ_OFFSET_IMG 24             ; Pointer to sprite sheet
%define       OBJ_OFFSET_IMG_ROW 32         ; Current row (animation)
%define       OBJ_OFFSET_FRAME 40           ; Current column (frame)
%define       OBJ_OFFSET_ANIM_ST 48         ; 1 = playing, 0 = paused
%define       OBJ_OFFSET_DX 56
%define       OBJ_OFFSET_DY 64

%define       OBJ_TYPE_PLYR 100
%define       OBJ_TYPE_SOIL 101
%define       OBJ_TYPE_ROCK 102
%define       OBJ_TYPE_WALL 103
%define       OBJ_TYPE_EXIT 104

%define       ANIM_NUM_FRAMES 8

grid:         resq GRID_W * GRID_H          ; Pointers to game objects
player:       resq 1

termios_old   resb 60                       ; Original terminal settings
termios_new   resb 60                       ; Modified terminal settings
stdin_flags   resq 1                        ; Original stdin flags

; First 8 bytes contains width and height
%define       IMG_PLYR_W 512
%define       IMG_PLYR_H 512
img_plyr      resb 8 + IMG_PLYR_W * IMG_PLYR_W * 4

%define       IMG_SOIL_W 512
%define       IMG_SOIL_H 64
img_soil      resb 8 + IMG_SOIL_W * IMG_SOIL_W * 4

%define       IMG_ROCK_W 512
%define       IMG_ROCK_H 256
img_rock      resb 8 + IMG_ROCK_W * IMG_ROCK_W * 4

%define       IMG_WALL_W 512
%define       IMG_WALL_H 64
img_wall      resb 8 + IMG_WALL_W * IMG_WALL_W * 4

%define       IMG_EXIT_W 512
%define       IMG_EXIT_H 128
img_exit      resb 8 + IMG_EXIT_W * IMG_EXIT_W * 4

              SECTION .text

              extern drw_init
              extern drw_draw
              extern drw_fill
              extern drw_load_bmp
              extern drw_term
              extern drw_flush
              extern drw_fb_w
              extern drw_fb_h

              extern util_alloc

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
load_images:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              lea rdi, [rel img_plyr_path]
              lea rsi, [rel img_plyr]
              mov rdx, IMG_PLYR_W
              mov rcx, IMG_PLYR_H
              call drw_load_bmp

              lea rdi, [rel img_soil_path]
              lea rsi, [rel img_soil]
              mov rdx, IMG_SOIL_W
              mov rcx, IMG_SOIL_H
              call drw_load_bmp

              lea rdi, [rel img_rock_path]
              lea rsi, [rel img_rock]
              mov rdx, IMG_ROCK_W 
              mov rcx, IMG_ROCK_H
              call drw_load_bmp

              lea rdi, [rel img_wall_path]
              lea rsi, [rel img_wall]
              mov rdx, IMG_WALL_W
              mov rcx, IMG_WALL_H
              call drw_load_bmp

              lea rdi, [rel img_exit_path]
              lea rsi, [rel img_exit]
              mov rdx, IMG_EXIT_W
              mov rcx, IMG_EXIT_H
              call drw_load_bmp

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
construct_scene:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              call load_images

              mov rdi, 1
              mov rsi, 1
              call construct_player

              mov rdi, OBJ_TYPE_SOIL
              mov rsi, 8
              mov rdx, 5
              lea rcx, [rel img_soil]
              call construct_object

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
grid_insert:
; rdi gridX
; rsi gridY
; rdx object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              imul rsi, GRID_W
              add rsi, rdi
              shl rsi, 3
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
; rdi type
; rsi gridX
; rdx gridY
; rcx image
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rbp
              mov rbp, rsp
              sub rsp, 48

              mov [rbp - 8], rdi            ; type
              mov [rbp - 16], rsi           ; gridX
              mov [rbp - 24], rdx           ; gridY
              mov [rbp - 32], rcx           ; image

              mov rdi, OBJ_SIZE
              call util_alloc

              mov r11, rax                  ; pointer

              mov rdi, [rbp - 16]           ; gridX
              imul rdi, CELL_W              ; worldX
              mov [r11 + OBJ_OFFSET_X], rdi
              mov rdi, [rbp - 24]           ; gridY
              imul rdi, CELL_H              ; worldY
              mov [r11 + OBJ_OFFSET_Y], rdi

              mov rdi, [rbp - 32]           ; image
              mov [r11 + OBJ_OFFSET_IMG], rdi

              mov rdi, 0
              mov [r11 + OBJ_OFFSET_IMG_ROW], rdi
              mov [r11 + OBJ_OFFSET_FRAME], rdi
              mov [r11 + OBJ_OFFSET_ANIM_ST], rdi

              mov rdi, [rbp - 16]           ; gridX
              mov rsi, [rbp - 24]           ; gridY
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
              mov rdx, rsi
              mov rsi, rdi
              mov rdi, OBJ_TYPE_PLYR
              lea rcx, [rel img_plyr]
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
              mov rsi, [r11 + OBJ_OFFSET_X]
              mov rdx, [r11 + OBJ_OFFSET_Y]
              mov rcx, [r11 + OBJ_OFFSET_FRAME]
              imul rcx, CELL_W              ; srcX
              mov r8, [r11 + OBJ_OFFSET_IMG_ROW]
              imul r8, CELL_H               ; srcY
              mov r9, CELL_W                ; w
              mov r10, CELL_H               ; h
              mov [rsp], r10
              call drw_draw
              add rsp, 32

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
render_scene:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rdi, 0
              mov rsi, 0
              mov edx, [drw_fb_w]
              mov ecx, [drw_fb_h]
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
