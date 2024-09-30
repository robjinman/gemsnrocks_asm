%define       CELL_SZ 64
%define       GRID_W 40
%define       GRID_H 20
%define       HUD_H 64
%define       BACKGROUND_COLOUR 0xFF332211
%define       HUD_COLOUR 0xFF111111

              SECTION .data

hide_cursor   db 0x1b, '[?25l', 0
show_cursor   db 0x1b, '[?25h', 0

%define       STR_GOODBYE_LEN 33
str_goodbye   db "Thanks for playing Gems'n'Rocks!", 10
str_you_died  db 'You died!', 0
str_success   db 'Success!', 0
str_victory   db 'You are victorious!', 0
str_ent_to_q  db 'Press enter to quit', 0
str_continue  db 'Press enter to continue', 0
str_num_gems  db 'Gems remaining:', 0

img_font_path db './data/font.bmp', 0
img_plyr_path db './data/player.bmp', 0
img_soil_path db './data/soil.bmp', 0
img_rock_path db './data/rock.bmp', 0
img_gem_path  db './data/gem.bmp', 0
img_wall_path db './data/wall.bmp', 0
img_exit_path db './data/exit.bmp', 0

%define       DIR_RIGHT 0
%define       DIR_LEFT 1
%define       DIR_UP 2
%define       DIR_DOWN 3

%define       PLYR_ANIM_DEATH 4
%define       PLYR_ANIM_WIN 5
%define       EXIT_ANIM_OPEN 1
%define       GEM_ANIM_COLLECT 2

unit_vecs     dd 1, 0                       ; right
              dd -1, 0                      ; left
              dd 0, -1                      ; up
              dd 0, 1                       ; down

next_obj_addr resq 0

; Top-left corner of the screen in world space
camera_x      dd 0
camera_y      dd 0

%define       GAME_ST_ALIVE 0
%define       GAME_ST_DEAD 1
%define       GAME_ST_SUCCESS 2
%define       GAME_ST_VICTORIOUS 3

level         dd 0
num_gems      dd 0
game_state    dd GAME_ST_ALIVE
player_dir    dd -1
pending_move  dd -1

%define       OBJ_TYPE_PLYR 1
%define       OBJ_TYPE_SOIL 0
%define       OBJ_TYPE_ROCK 2
%define       OBJ_TYPE_GEM 3
%define       OBJ_TYPE_WALL 4
%define       OBJ_TYPE_EXIT 5

              SECTION .bss

%define       OBJ_SIZE 104
%define       OBJ_OFFSET_TYPE 0
%define       OBJ_OFFSET_X 8
%define       OBJ_OFFSET_Y 16
%define       OBJ_OFFSET_IMG 24             ; Pointer to sprite sheet
%define       OBJ_OFFSET_IMG_ROW 32         ; Current row (animation)
%define       OBJ_OFFSET_FRAME 40           ; Current column (frame)
%define       OBJ_OFFSET_ANIM_ST 48         ; 1 = playing, 0 = paused
%define       OBJ_OFFSET_DX 56
%define       OBJ_OFFSET_DY 64
%define       OBJ_OFFSET_FLAGS 72
%define       OBJ_OFFSET_GRID_X 80
%define       OBJ_OFFSET_GRID_Y 88
%define       OBJ_OFFSET_QUEUED_ANIM 96

%define       OBJ_FLAG_CAN_FALL 1
%define       OBJ_FLAG_STACKABLE 2
%define       OBJ_FLAG_ANIMATED 4

%define       ANIM_NUM_FRAMES 8

objects       resb OBJ_SIZE * GRID_W * GRID_H
grid          resq GRID_W * GRID_H          ; Pointers to game objects
pending_destr resq GRID_W * GRID_H
player        resq 1
exit          resq 1

termios_old   resb 60                       ; Original terminal settings
termios_new   resb 60                       ; Modified terminal settings
stdin_flags   resq 1                        ; Original stdin flags

; First 8 bytes contains width and height
%define       IMG_FONT_W 2730
%define       IMG_FONT_H 48
img_font      resb 8 + IMG_FONT_W * IMG_FONT_H * 4

%define       IMG_PLYR_W 512
%define       IMG_PLYR_H 384
img_plyr      resb 8 + IMG_PLYR_W * IMG_PLYR_H * 4

%define       IMG_SOIL_W 512
%define       IMG_SOIL_H 64
img_soil      resb 8 + IMG_SOIL_W * IMG_SOIL_H * 4

%define       IMG_ROCK_W 512
%define       IMG_ROCK_H 128
img_rock      resb 8 + IMG_ROCK_W * IMG_ROCK_H * 4

%define       IMG_GEM_W 512
%define       IMG_GEM_H 192
img_gem       resb 8 + IMG_GEM_W * IMG_GEM_H * 4

%define       IMG_WALL_W 64
%define       IMG_WALL_H 64
img_wall      resb 8 + IMG_WALL_W * IMG_WALL_H * 4

%define       IMG_EXIT_W 512
%define       IMG_EXIT_H 128
img_exit      resb 8 + IMG_EXIT_W * IMG_EXIT_H * 4

              SECTION .text

              extern drw_init
              extern drw_draw
              extern drw_fill
              extern drw_darken
              extern drw_draw_text
              extern drw_load_bmp
              extern drw_term
              extern drw_flush
              extern drw_fb_w
              extern drw_fb_h

              extern util_min
              extern util_max
              extern util_int_to_str
              extern util_print
              extern util_assert_fail

              extern levels
              extern num_levels

              global _start

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
load_images:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              lea rdi, [rel img_font_path]
              lea rsi, [rel img_font]
              mov rdx, IMG_FONT_W
              mov rcx, IMG_FONT_H
              call drw_load_bmp

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

              lea rdi, [rel img_gem_path]
              lea rsi, [rel img_gem]
              mov rdx, IMG_GEM_W 
              mov rcx, IMG_GEM_H
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

              lea r10, [rel levels]
              mov r8d, [level]
              imul r8, GRID_W * GRID_H      ; level offset
              add r10, r8

              mov r8, 0
              mov [num_gems], r8d

              lea r8, [rel objects]
              mov [next_obj_addr], r8

              xor r8, r8                    ; row
.loop_row:
              xor r9, r9                    ; col
.loop_col:
              mov r11, r8
              imul r11, GRID_W
              add r11, r9
              add r11, r10
              movzx rdx, byte [r11]         ; object type

              mov rdi, r9
              mov rsi, r8

              push r8
              push r9
              push r10

              cmp rdx, OBJ_TYPE_PLYR
              je .type_plyr
              cmp rdx, OBJ_TYPE_EXIT
              je .type_exit
              cmp rdx, OBJ_TYPE_GEM
              je .type_gem
              cmp rdx, OBJ_TYPE_ROCK
              je .type_rock
              cmp rdx, OBJ_TYPE_SOIL
              je .type_soil
              cmp rdx, OBJ_TYPE_WALL
              je .type_wall
.type_exit:
              call construct_exit
              jmp .end
.type_gem:
              call construct_gem
              inc dword [num_gems]
              jmp .end
.type_plyr:
              call construct_player
              jmp .end
.type_rock:
              call construct_rock
              jmp .end
.type_soil:
              call construct_soil
              jmp .end
.type_wall:
              call construct_wall
              jmp .end
.end:
              pop r10
              pop r9
              pop r8

              inc r9
              cmp r9, GRID_W
              jl .loop_col

              inc r8
              cmp r8, GRID_H
              jl .loop_row

              mov [game_state], dword GAME_ST_ALIVE
              mov [pending_move], dword -1

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
              mov r8, OBJ_FLAG_STACKABLE | OBJ_FLAG_ANIMATED
              call construct_object
              mov [player], rax

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
construct_exit:
; rdi gridX
; rsi gridY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rdx, rsi
              mov rsi, rdi
              mov rdi, OBJ_TYPE_EXIT
              lea rcx, [rel img_exit]
              mov r8, OBJ_FLAG_STACKABLE | OBJ_FLAG_ANIMATED
              call construct_object
              mov [exit], rax

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
construct_gem:
; rdi gridX
; rsi gridY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rdx, rsi
              mov rsi, rdi
              mov rdi, OBJ_TYPE_GEM
              lea rcx, [rel img_gem]
              mov r8, OBJ_FLAG_CAN_FALL | OBJ_FLAG_ANIMATED
              call construct_object

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
construct_rock:
; rdi gridX
; rsi gridY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rdx, rsi
              mov rsi, rdi
              mov rdi, OBJ_TYPE_ROCK
              lea rcx, [rel img_rock]
              mov r8, OBJ_FLAG_CAN_FALL | OBJ_FLAG_ANIMATED
              call construct_object

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
construct_soil:
; rdi gridX
; rsi gridY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rdx, rsi
              mov rsi, rdi
              mov rdi, OBJ_TYPE_SOIL
              lea rcx, [rel img_soil]
              mov r8, OBJ_FLAG_STACKABLE | OBJ_FLAG_ANIMATED
              call construct_object

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
construct_wall:
; rdi gridX
; rsi gridY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rdx, rsi
              mov rsi, rdi
              mov rdi, OBJ_TYPE_WALL
              lea rcx, [rel img_wall]
              mov r8, OBJ_FLAG_STACKABLE | OBJ_FLAG_ANIMATED
              call construct_object

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
centre_cam:
; Centre the camera around the player
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov r8, [player]
              mov rdi, [r8 + OBJ_OFFSET_X]
              mov rsi, [r8 + OBJ_OFFSET_Y]

              push rsi

              mov r8d, [drw_fb_w]
              shr r8, 1
              sub rdi, r8                   ; playerX - fb_w / 2

              mov rsi, 0
              call util_max

              mov rdi, rax                  ; max(0, playerX - fb_w / 2)
              mov rsi, GRID_W
              imul rsi, CELL_SZ
              sub esi, [drw_fb_w]
              call util_min

              mov [camera_x], eax           ; min(GRID_W * CELL_SZ - fb_w, max(0, playerX - fb_w / 2))

              pop rsi                       ; playerY

              mov r8d, [drw_fb_h]
              sub r8, HUD_H
              shr r8, 1
              sub rsi, r8                   ; playerY - fb_h / 2

              mov rdi, 0
              call util_max

              mov rdi, rax                  ; max(0, playerY - fb_h / 2)
              mov rsi, GRID_H
              imul rsi, CELL_SZ
              sub esi, [drw_fb_h]
              add rsi, HUD_H
              call util_min

              mov [camera_y], eax           ; min(GRID_H * CELL_SZ - fb_h, max(0, playerY - fb_h / 2))

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

              mov rax, 1                  ; sys_write
              mov rdi, 1                  ; stdout
              mov rsi, hide_cursor
              mov rdx, 6
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

              mov rax, 1                  ; sys_write
              mov rdi, 1                  ; stdout
              mov rsi, show_cursor
              mov rdx, 6
              syscall

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
grid_insert:
; rdi gridX
; rsi gridY
; rdx object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov r11, rsi
              imul r11, GRID_W
              add r11, rdi
              shl r11, 3
              lea r8, [rel grid]
              add r8, r11
              mov [r8], rdx

              cmp rdx, 0
              je .end
              mov [rdx + OBJ_OFFSET_GRID_X], rdi
              mov [rdx + OBJ_OFFSET_GRID_Y], rsi
.end:
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
grid_erase:
; rdi gridX
; rsi gridY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rdx, 0
              call grid_insert

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
grid_at:
; rdi gridX
; rsi gridY
;
; Returns
; rax object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov r11, rsi
              imul r11, GRID_W
              add r11, rdi
              shl r11, 3
              lea r8, [rel grid]
              add r8, r11
              mov rax, [r8]

              cmp rax, 0
              je .ok

              ; Check the object really is at its grid coords
              mov r8, [rax + OBJ_OFFSET_GRID_X]
              mov r9, [rax + OBJ_OFFSET_GRID_Y]
              cmp r8, rdi
              jne .error
              cmp r9, rsi
              je .ok
.error:
              call util_assert_fail
.ok:
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
obj_erase:
; rdi object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov r8, [rdi + OBJ_OFFSET_GRID_X]
              mov r9, [rdi + OBJ_OFFSET_GRID_Y]

              imul r9, GRID_W
              add r9, r8
              shl r9, 3                     ; offset

              ; Erase from grid
              lea r8, [rel grid]
              add r8, r9
              mov r10, [r8]
              ; But only if the object is actually in the grid
              cmp rdi, r10
              jne .skip
              xor r11, r11
              mov [r8], r11
.skip:
              ; Add to pending_destr
              lea r8, [rel pending_destr]
              add r8, r9
              mov [r8], rdi

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

              ; The animation has just finished
              ; If there's another one queued, start it right away
              mov rsi, [rdi + OBJ_OFFSET_QUEUED_ANIM]
              cmp rsi, -1
              je .end
              mov rdx, 0
              mov rcx, 0
              call obj_play_anim
              mov r8, -1
              mov [rdi + OBJ_OFFSET_QUEUED_ANIM], r8

.end:
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
update_scene:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              xor rcx, rcx
.loop:
              mov r8, rcx
              shl r8, 3                     ; offset

              lea r9, [rel grid]
              add r9, r8
              mov rdi, [r9]
              cmp rdi, 0
              je .skip1

              push rcx
              push r8
              call obj_update
              pop r8
              pop rcx
.skip1:
              lea r9, [rel pending_destr]
              add r9, r8
              mov rdi, [r9]
              cmp rdi, 0
              je .skip2

              push rcx
              call obj_update
              pop rcx
.skip2:

              inc rcx
              cmp rcx, GRID_H * GRID_W
              jl .loop

              cmp [num_gems], dword 0
              jne .end
              mov rdi, [exit]
              mov rsi, EXIT_ANIM_OPEN
              mov rdx, 0
              mov rcx, 0
              call obj_play_anim
.end:

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
construct_object:
; rdi type
; rsi gridX
; rdx gridY
; rcx image
; r8  flags
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rbp
              mov rbp, rsp
              sub rsp, 56

              mov [rbp - 8], rdi            ; type
              mov [rbp - 16], rsi           ; gridX
              mov [rbp - 24], rdx           ; gridY
              mov [rbp - 32], rcx           ; image
              mov [rbp - 48], r8            ; flags

              mov r11, OBJ_SIZE
              mov rax, [next_obj_addr]
              add [next_obj_addr], r11

              mov r11, rax                  ; pointer

              mov rdi, [rbp - 8]            ; type
              mov [r11 + OBJ_OFFSET_TYPE], rdi

              mov rdi, [rbp - 16]           ; gridX
              imul rdi, CELL_SZ             ; worldX
              mov [r11 + OBJ_OFFSET_X], rdi
              mov rdi, [rbp - 24]           ; gridY
              imul rdi, CELL_SZ             ; worldY
              mov [r11 + OBJ_OFFSET_Y], rdi

              mov rdi, [rbp - 32]           ; image
              mov [r11 + OBJ_OFFSET_IMG], rdi

              mov rdi, 0
              mov [r11 + OBJ_OFFSET_IMG_ROW], rdi
              mov [r11 + OBJ_OFFSET_FRAME], rdi
              mov [r11 + OBJ_OFFSET_ANIM_ST], rdi
              mov rdi, [rbp - 48]           ; flags
              mov [r11 + OBJ_OFFSET_FLAGS], rdi
              mov rdi, -1
              mov [r11 + OBJ_OFFSET_QUEUED_ANIM], rdi

              mov rdi, [rbp - 16]           ; gridX
              mov rsi, [rbp - 24]           ; gridY
              mov rdx, r11                  ; pointer
              call grid_insert

              mov rsp, rbp
              pop rbp

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
obj_is_falling:
; rdi object
;
; Returns
; rax whether the object is falling
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              ; To save having to add some kind of IS_FALLING flag, assume an object is falling if:
              ;   - its animation state is 1
              ;   - its dy is positive
              ;   - OBJ_FLAG_ANIMATED is unset, so it's moving but not animating

              mov r8, [rdi + OBJ_OFFSET_ANIM_ST]
              cmp r8, 0
              je .skip

              mov r8, [rdi + OBJ_OFFSET_DY]
              cmp r8, 0
              jle .skip

              mov r8, [rdi + OBJ_OFFSET_FLAGS]
              and r8, OBJ_FLAG_ANIMATED
              cmp r8, 0
              jne .skip

              mov rax, 1
              ret
.skip:
              mov rax, 0
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
obj_play_anim:
; rdi object
; rsi animation ID (row of sprite sheet)
; rdx dx
; rcx dy
;
; Returns
; rax 1 if playing the animation succeeded, 0 otherwise
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              ; Skip to end if there's already an animation playing
              mov r8, [rdi + OBJ_OFFSET_ANIM_ST]
              cmp r8, 1
              je .failure

              ; Set animated flag
              mov r9, [rdi + OBJ_OFFSET_FLAGS]
              or r9, OBJ_FLAG_ANIMATED
              mov [rdi + OBJ_OFFSET_FLAGS], r9

              mov r9, 1
              mov [rdi + OBJ_OFFSET_ANIM_ST], r9
              mov [rdi + OBJ_OFFSET_IMG_ROW], rsi
              mov [rdi + OBJ_OFFSET_DX], rdx
              mov [rdi + OBJ_OFFSET_DY], rcx
.success:
              mov rax, 1
              ret
.failure:
              mov rax, 0
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
obj_queue_anim:
; Queued animations don't have deltas
; 
; rdi object
; rsi animation ID (row of sprite sheet)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              ; Try to play the animation first
              mov rdx, 0
              mov rcx, 0
              call obj_play_anim

              cmp rax, 1
              je .end

              ; Only queue the animation if it failed to play
              mov [rdi + OBJ_OFFSET_QUEUED_ANIM], rsi
.end:
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
obj_play_transform:
; rdi object
; rsi animation ID (row of sprite sheet)
; rdx dx
; rcx dy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              ; Skip to end if there's already an animation playing
              mov r8, [rdi + OBJ_OFFSET_ANIM_ST]
              cmp r8, 1
              je .end

              ; Unset animated flag
              mov r9, [rdi + OBJ_OFFSET_FLAGS]
              mov r10, OBJ_FLAG_ANIMATED
              not r10
              and r9, r10
              mov [rdi + OBJ_OFFSET_FLAGS], r9

              mov r9, 1
              mov [rdi + OBJ_OFFSET_ANIM_ST], r9
              mov [rdi + OBJ_OFFSET_DX], rdx
              mov [rdi + OBJ_OFFSET_DY], rcx
.end:
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
obj_draw:
; rdi object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rbp
              push r12
              push r13

              mov rbp, rsp
              sub rsp, 16

              mov r13, [rdi + OBJ_OFFSET_FLAGS]
              and r13, OBJ_FLAG_ANIMATED

              mov r11, rdi
              mov rdi, [r11 + OBJ_OFFSET_IMG]
              mov rsi, [r11 + OBJ_OFFSET_X]
              mov r12d, [camera_x]
              sub rsi, r12
              mov rdx, [r11 + OBJ_OFFSET_Y]
              mov r12d, [camera_y]
              sub rdx, r12
              add rdx, HUD_H
              xor rcx, rcx
              cmp r13, 0
              je .not_animated
              mov rcx, [r11 + OBJ_OFFSET_FRAME]
              imul rcx, CELL_SZ             ; srcX
.not_animated:
              mov r8, [r11 + OBJ_OFFSET_IMG_ROW]
              imul r8, CELL_SZ              ; srcY
              mov r9, CELL_SZ               ; w
              mov r10, CELL_SZ              ; h
              mov [rbp - 16], r10
              call drw_draw

              mov rsp, rbp
              pop r13
              pop r12
              pop rbp

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clear_screen:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rdi, 0
              mov rsi, 0
              mov edx, [drw_fb_w]
              mov ecx, [drw_fb_h]
              mov r8, BACKGROUND_COLOUR
              call drw_fill

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
render_hud:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rdi, 0
              mov rsi, 0
              mov edx, [drw_fb_w]
              mov rcx, CELL_SZ
              mov r8, HUD_COLOUR
              call drw_fill

              lea rdi, [rel str_num_gems]
              lea rsi, [rel img_font]
              mov rdx, 10
              mov rcx, 10
              call drw_draw_text

              sub rsp, 16
              mov edi, [num_gems]
              mov rsi, rsp
              call util_int_to_str
              mov rdi, rsp
              lea rsi, [rel img_font]
              mov rdx, 500
              mov rcx, 10
              call drw_draw_text
              add rsp, 16

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
render_box:
; rdi string 1
; rsi string 2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rbp
              push r12
              push r13
              mov rbp, rsp
              sub rsp, 48

              mov r8d, [drw_fb_w]
              mov r9d, [drw_fb_h]

              mov r10, r8                   ; fb_w
              shr r10, 3                    ; x = fb_w / 8
              mov r12, r10                  ; x
              shl r12, 1                    ; 2 * x
              mov r11, r8                   ; fb_w
              sub r11, r12                  ; w = fb_w - 2 * x

              mov r12, r9                   ; fb_h
              shr r12, 2                    ; y = fb_h / 4
              mov rcx, r12                  ; y
              shl rcx, 1                    ; 2 * y
              mov r13, r9                   ; fb_h
              sub r13, rcx                  ; h = fb_h - 2 * y

              mov [rbp - 8], r10            ; x
              mov [rbp - 16], r12           ; y
              mov [rbp - 24], r11           ; w
              mov [rbp - 32], r13           ; h
              mov [rbp - 40], rdi           ; string 1
              mov [rbp - 48], rsi           ; string 2

              mov rdi, r10                  ; x
              mov rsi, r12                  ; y
              mov rdx, r11                  ; w
              mov rcx, r13                  ; h
              call drw_darken

              mov rdi, [rbp - 40]           ; string 1
              lea rsi, [rel img_font]
              mov rdx, [rbp - 8]            ; x
              add rdx, 40
              mov rcx, [rbp - 16]           ; y
              add rcx, 40
              call drw_draw_text

              mov rdi, [rbp - 48]           ; string 2
              lea rsi, [rel img_font]
              mov rdx, [rbp - 8]            ; x
              add rdx, 40
              mov rcx, [rbp - 16]           ; y
              add rcx, 150
              call drw_draw_text

              mov rsp, rbp
              pop r13
              pop r12
              pop rbp

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
render_death_box:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              lea rdi, [rel str_you_died]
              lea rsi, [rel str_continue]
              call render_box

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
render_success_box:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              lea rdi, [rel str_success]
              lea rsi, [rel str_continue]
              call render_box

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
render_victorious_box:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              lea rdi, [rel str_victory]
              lea rsi, [rel str_ent_to_q]
              call render_box

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
render_scene:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rbp
              push r12
              push r13
              push r14
              push r15
              mov rbp, rsp
              sub rsp, 16

              call clear_screen

              mov r14, CELL_SZ

              mov eax, [drw_fb_w]
              add eax, [camera_x]
              xor rdx, rdx
              div r14
              ; Increment xMax if there's a remainder
              cmp rdx, 0
              je .no_inc_x
              inc rax
.no_inc_x:
              mov [rbp - 8], rax            ; xMax

              mov eax, [drw_fb_h]
              sub rax, HUD_H
              add eax, [camera_y]
              xor rdx, rdx
              div r14
              ; Increment yMax if there's a remainder
              cmp rdx, 0
              je .no_inc_y
              inc rax
.no_inc_y:
              mov [rbp - 16], rax           ; yMax

              mov eax, [camera_y]
              xor rdx, rdx
              div r14
              mov r8, rax                   ; row

.loop_row:
              mov eax, [camera_x]
              xor rdx, rdx
              div r14
              mov r9, rax                   ; col
.loop_col:
              mov r10, r8
              imul r10, GRID_W
              add r10, r9
              shl r10, 3                    ; offset

              lea r12, [rel grid]
              add r12, r10
              mov rdi, [r12]
              cmp rdi, 0
              je .skip1

              push r8
              push r9
              push r10
              call obj_draw
              pop r10
              pop r9
              pop r8
.skip1:
              lea r11, [rel pending_destr]
              add r11, r10
              mov rdi, [r11]
              cmp rdi, 0
              je .skip2

              push r8
              push r9
              call obj_draw
              pop r9
              pop r8
.skip2:
              inc r9
              cmp r9, [rbp - 8]
              jl .loop_col

              inc r8
              cmp r8, [rbp - 16]
              jl .loop_row

              call render_hud

              cmp [game_state], dword GAME_ST_DEAD
              je .st_dead
              cmp [game_state], dword GAME_ST_SUCCESS
              je .st_success
              cmp [game_state], dword GAME_ST_VICTORIOUS
              je .st_victorious
              cmp [game_state], dword GAME_ST_ALIVE
              je .st_endif
.st_success:
              call render_success_box
              jmp .st_endif
.st_victorious:
              call render_victorious_box
              jmp .st_endif
.st_dead:
              call render_death_box
.st_endif:

              call drw_flush

              mov rsp, rbp
              pop r15
              pop r14
              pop r13
              pop r12
              pop rbp

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push_exit:
; rdi object
; rsi direction
;
; Returns
; rax block player = 1, allow player = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              cmp [num_gems], dword 0
              jne .closed

              mov r8, [level]
              inc r8
              cmp r8d, [num_levels]
              jl .success
              mov [game_state], dword GAME_ST_VICTORIOUS
              jmp .endif
.success:
              mov [game_state], dword GAME_ST_SUCCESS
.endif:
              mov rax, 0
              ret
.closed:
              mov rax, 1
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push_gem:
; rdi object
; rsi direction
;
; Returns
; rax block player = 1, allow player = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov r8, [rdi + OBJ_OFFSET_ANIM_ST]
              cmp r8, 1
              je .block_player

              push rdi

              mov rsi, GEM_ANIM_COLLECT     ; animation ID
              mov rdx, 0                    ; dx
              mov rcx, 0                    ; dy
              call obj_play_anim

              pop rdi                       ; object
              call obj_erase

              dec dword [num_gems]

              mov rax, 0
              jmp .end

.block_player:
              mov rax, 1                    ; block player movement
.end:
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push_rock:
; rdi object
; rsi direction
;
; Returns
; rax block player = 1, allow player = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rbp
              mov rbp, rsp
              sub rsp, 16

              push r12
              push r13
              push r14
              push r15

              mov r8, [rdi + OBJ_OFFSET_ANIM_ST]
              cmp r8, 1
              je .block_player

              mov [rbp - 8], rdi            ; object
              mov [rbp - 16], rsi           ; direction

              mov r8, [rdi + OBJ_OFFSET_GRID_X]
              mov r9, [rdi + OBJ_OFFSET_GRID_Y]

              lea r14, [rel unit_vecs]
              mov r11, [rbp - 16]           ; direction
              shl r11, 3
              add r14, r11
              movsx r12, dword [r14]        ; dx
              movsx r13, dword [r14 + 4]    ; dy

              cmp r13, 0                    ; don't allow pushing vertically
              jne .block_player

              mov rdi, r8
              add rdi, r12                  ; gridX + dx
              mov rsi, r13
              add rsi, r9                   ; gridY + dy
              call grid_at

              cmp rax, 0
              jne .block_player

              mov rdi, [rbp - 8]
              mov rsi, [rbp - 16]
              mov rdx, 1
              call obj_move

              mov rax, 0                    ; allow player movement
              jmp .end

.block_player:
              mov rax, 1                    ; block player movement
.end:

              pop r15
              pop r14
              pop r13
              pop r12

              mov rsp, rbp
              pop rbp

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push_soil:
; rdi object
; rsi direction
;
; Returns
; rax block player = 1, allow player = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rdi

              mov rsi, 0                    ; animation ID
              mov rdx, 0                    ; dx
              mov rcx, 0                    ; dy
              call obj_play_anim

              pop rdi                       ; object
              call obj_erase

              mov rax, 0

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push_wall:
; rdi object
; rsi direction
;
; Returns
; rax block player = 1, allow player = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rax, 1

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
obj_push:
; Push the object from the given direction
;
; rdi object
; rsi direction
;
; Returns
; rax block player = 1, allow player = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov r8, [rdi + OBJ_OFFSET_TYPE]

              cmp r8, OBJ_TYPE_EXIT
              je .type_exit
              cmp r8, OBJ_TYPE_GEM
              je .type_gem
              cmp r8, OBJ_TYPE_ROCK
              je .type_rock
              cmp r8, OBJ_TYPE_SOIL
              je .type_soil
              cmp r8, OBJ_TYPE_WALL
              je .type_wall
.type_exit:
              call push_exit
              jmp .end
.type_gem:
              call push_gem
              jmp .end
.type_rock:
              call push_rock
              jmp .end
.type_soil:
              call push_soil
              jmp .end
.type_wall:
              call push_wall
              jmp .end
.end:
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
grid_push_obj:
; Push the object from the given direction
;
; rdi direction
;
; Returns
; rax block player = 1, allow player = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push r12
              push r13
              push r14

              mov rax, [player]
              mov r8, [rax + OBJ_OFFSET_GRID_X]
              mov r9, [rax + OBJ_OFFSET_GRID_Y]

              mov r11, rdi                  ; direction
              push r11

              lea r14, [rel unit_vecs]
              shl r11, 3
              add r14, r11
              movsx r12, dword [r14]        ; dx
              movsx r13, dword [r14 + 4]    ; dy

              ; player grid coords + delta
              add r8, r12
              add r9, r13

              mov rdi, r8
              mov rsi, r9
              call grid_at

              pop r11                       ; direction

              cmp rax, 0
              je .skip

              mov rdi, rax
              mov rsi, r11
              call obj_push
.skip:

              pop r14
              pop r13
              pop r12

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
grid_move_obj:
; rdi object
; rsi direction
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rbp
              mov rbp, rsp
              sub rsp, 32

              mov r8, [rdi + OBJ_OFFSET_GRID_X]
              mov r9, [rdi + OBJ_OFFSET_GRID_Y]

              mov [rbp - 8], rdi            ; object
              mov [rbp - 16], rsi           ; direction
              mov [rbp - 24], r8            ; gridX
              mov [rbp - 32], r9            ; gridY

              mov rdi, r8
              mov rsi, r9
              call grid_at

              ; Check the object really is at its grid coords
              cmp rax, [rbp - 8]
              je .ok
              call util_assert_fail
.ok:
              mov rdi, [rbp - 24]
              mov rsi, [rbp - 32]
              call grid_erase

              lea r8, [rel unit_vecs]
              mov r11, [rbp - 16]           ; direction
              shl r11, 3                    ; size of vector is 8 bytes
              add r8, r11
              movsx rdi, dword [r8]         ; dx
              movsx rsi, dword [r8 + 4]     ; dy

              add rdi, [rbp - 24]
              add rsi, [rbp - 32]
              mov rdx, [rbp - 8]
              call grid_insert

              mov rsp, rbp
              pop rbp

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
obj_move:
; rdi object
; rsi direction
; rdx animate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              ; Check if object is currently moving
              mov r8, [rdi + OBJ_OFFSET_ANIM_ST]
              cmp r8, 1
              je .end                       ; exit function if object is moving

              push rdi                      ; object
              push rsi                      ; direction
              push rdx                      ; animate

              call grid_move_obj

              pop rdx                       ; animate
              pop rsi                       ; direction
              pop rdi                       ; object

              lea r8, [rel unit_vecs]
              mov r11, rsi                  ; direction
              shl r11, 3                    ; size of vector is 8 bytes
              add r8, r11
              movsx r9, dword [r8]          ; dx
              movsx r10, dword [r8 + 4]     ; dy

              cmp rdx, 0
              je .no_animate
              ; Play animation
              mov rdx, r9                   ; dx
              imul rdx, CELL_SZ / ANIM_NUM_FRAMES
              mov rcx, r10                  ; dy
              imul rcx, CELL_SZ / ANIM_NUM_FRAMES
              call obj_play_anim
              jmp .end
.no_animate:
              ; Play transformation
              mov rdx, r9                   ; dx
              imul rdx, CELL_SZ / ANIM_NUM_FRAMES
              mov rcx, r10                  ; dy
              imul rcx, CELL_SZ / ANIM_NUM_FRAMES
              call obj_play_transform
.end:
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
plyr_move:
; rdi direction
;
; Returns
; rax 1 if player is already moving, 0 otherwise
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov r8, rdi

              ; Check if player is currently moving
              mov r9, [player]
              mov r10, [r9 + OBJ_OFFSET_ANIM_ST]
              cmp r10, 1
              je .already_moving            ; exit function if already moving

              push r8
              call grid_push_obj
              pop r8
              cmp rax, 1
              je .blocked                   ; exit function if blocked by object

              mov rdi, [player]
              mov rsi, r8
              mov rdx, 1
              call obj_move

              ; If the game state is SUCCESS or VICTORIOUS, we must have just pushed into the exit
              cmp [game_state], dword GAME_ST_SUCCESS
              je .level_complete
              cmp [game_state], dword GAME_ST_VICTORIOUS
              je .level_complete
              jmp .success
.level_complete:
              mov rdi, [player]
              mov rsi, PLYR_ANIM_WIN
              call obj_queue_anim

              mov rdi, [player]
              call obj_erase

              mov r8, [player]
              mov rdi, [r8 + OBJ_OFFSET_GRID_X]
              mov rsi, [r8 + OBJ_OFFSET_GRID_Y]
              mov rdx, [exit]
              call grid_insert

              jmp .success
.already_moving:
              mov rax, 1
              ret
.blocked:
.success:
              mov rax, 0
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
obj_fall:
; rdi object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rsi, DIR_DOWN
              mov rdx, 0
              call obj_move

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
obj_try_fall:
; rdi object
; rsi gridX
; rdx gridY
;
; Returns
; rax 0 = didn't fall, 1 = did fall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rcx, [rdi + OBJ_OFFSET_FLAGS]
              and rcx, OBJ_FLAG_CAN_FALL
              cmp rcx, 0
              je .end                       ; skip non-fallable objects

              mov r8, rsi                   ; gridX
              mov r9, rdx                   ; gridY

              push rdi                      ; object

              ; Get the object below this one
              mov rdi, r8
              mov rsi, r9
              inc rsi
              call grid_at

              pop rdi                       ; object

              cmp rax, 0
              jne .end                      ; if there's an object below this one

              call obj_fall
              mov rax, 1
              ret
.end:
              mov rax, 0
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
grid_space_to_fall_sideways:
; rdi gridX
; rsi gridY
; rdx direction
;
; Returns
; rax 0 = false, 1 = true
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              lea r8, [rel unit_vecs]
              mov r11, rdx                  ; direction
              shl r11, 3
              add r8, r11
              movsx r10, dword [r8]         ; dx

              mov r8, rdi                   ; gridX
              mov r9, rsi                   ; gridY
              push r8
              push r9
              push r10

              add rdi, r10
              call grid_at
              mov rdx, rax                  ; adjacent cell object

              pop r10                       ; dx
              pop r9                        ; gridY
              pop r8                        ; gridX

              push rdx                      ; adjacent cell object

              mov rdi, r8
              add rdi, r10
              mov rsi, r9
              inc rsi
              call grid_at

              pop rdx                       ; adjacent cell object
              or rax, rdx
              cmp rax, 0                    ; if both down-adjacent and adjacent cells are empty
              je .true

              mov rax, 0
              ret
.true:
              mov rax, 1
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
obj_try_fall_sideways:
; rdi object
; rsi gridX
; rdx gridY
;
; Returns
; rax 0 = didn't fall, 1 = did fall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rbp
              mov rbp, rsp
              sub rsp, 32

              mov [rbp - 8], rdi            ; object
              mov [rbp - 16], rsi           ; gridX
              mov [rbp - 24], rdx           ; gridY

              mov rcx, [rdi + OBJ_OFFSET_FLAGS]
              and rcx, OBJ_FLAG_CAN_FALL
              cmp rcx, 0
              je .no_move                   ; skip non-fallable objects

              ; Get the object below this one
              mov rdi, [rbp - 16]
              mov rsi, [rbp - 24]
              inc rsi
              call grid_at

              cmp rax, 0
              je .no_move                   ; if there's no object below this one

              mov r10, [rax + OBJ_OFFSET_FLAGS]
              and r10, OBJ_FLAG_STACKABLE
              cmp r10, 0
              jne .no_move                  ; don't fall if the object below is stackable

              mov rdi, [rbp - 16]           ; gridX
              mov rsi, [rbp - 24]           ; gridY
              mov rdx, DIR_LEFT
              call grid_space_to_fall_sideways
              cmp rax, 0
              je .try_fall_right

              mov rdi, [rbp - 8]            ; object
              mov rsi, DIR_LEFT
              mov rdx, 1
              call obj_move
              jmp .moved
.try_fall_right:
              mov rdi, [rbp - 16]           ; gridX
              mov rsi, [rbp - 24]           ; gridY
              mov rdx, DIR_RIGHT
              call grid_space_to_fall_sideways
              cmp rax, 0
              je .no_move

              mov rdi, [rbp - 8]
              mov rsi, DIR_RIGHT
              mov rdx, 1
              call obj_move
.moved:
              mov rax, 1
              jmp .end
.no_move:
              mov rax, 0
.end:
              mov rsp, rbp
              pop rbp

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
physics:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              lea r11, [rel grid]

              mov r8, 0                     ; row
.loop_row:
              mov r9, 0                     ; col
.loop_col:
              mov r10, r8
              imul r10, GRID_W
              add r10, r9
              shl r10, 3
              add r10, r11                  ; pointer to object pointer

              mov rdi, [r10]                ; object
              cmp rdi, 0
              je .skip                      ; skip if null

              push r8
              push r9
              push r11
              mov rsi, r9
              mov rdx, r8
              call obj_try_fall
              pop r11
              pop r9
              pop r8
              cmp rax, 1
              je .skip

              push r8
              push r9
              push r11
              mov rsi, r9
              mov rdx, r8
              call obj_try_fall_sideways
              pop r11
              pop r9
              pop r8
.skip:
              inc r9
              cmp r9, GRID_W
              jl .loop_col

              inc r8
              cmp r8, GRID_H - 1
              jl .loop_row

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
death_condition:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov r8, [player]
              mov rdi, [r8 + OBJ_OFFSET_GRID_X]
              mov rsi, [r8 + OBJ_OFFSET_GRID_Y]
              dec rsi
              call grid_at
              cmp rax, 0
              je .still_alive

              mov rdi, rax
              call obj_is_falling
              cmp rax, 0
              je .still_alive

              mov rdi, [player]
              mov rsi, PLYR_ANIM_DEATH
              mov rdx, 0
              mov rcx, 0
              call obj_queue_anim
              mov [game_state], dword GAME_ST_DEAD
              ret
.still_alive:
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
keyboard:
; Returns
; rax change of game state:
;     0 no change
;     1 quit
;     2 restart level
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              sub rsp, 32

              cmp [game_state], dword GAME_ST_ALIVE
              jne .skip_pending_move
              cmp [pending_move], dword DIR_RIGHT
              je .key_right
              cmp [pending_move], dword DIR_LEFT
              je .key_left
              cmp [pending_move], dword DIR_UP
              je .key_up
              cmp [pending_move], dword DIR_DOWN
              je .key_down
.skip_pending_move:

              xor r8, r8                    ; bytes read
.loop:
              mov rax, 0                    ; sys_read
              mov rdi, 0                    ; stdin
              mov rsi, rsp
              add rsi, r8
              mov rdx, 1                    ; num bytes to read
              syscall
              cmp rax, 0
              jle .done
              add r8, rax                   ; we got data
              cmp r8, 32
              je .done
              jmp .loop
.done:
              cmp r8, 0
              je .end

              mov r9, rsp
              add r9, r8
              mov rdi, r8
              mov rsi, 3
              call util_min
              sub r9, rax                  ; pointer to (no more than) last 3 bytes

              cmp [game_state], dword GAME_ST_ALIVE
              je .st_alive
              cmp [game_state], dword GAME_ST_DEAD
              je .st_dead
              cmp [game_state], dword GAME_ST_SUCCESS
              je .st_success
              cmp [game_state], dword GAME_ST_VICTORIOUS
              je .st_victorious
.st_alive:
              cmp byte [r9], 0x0A          ; new line
              je .restart
              cmp byte [r9], 0x1B          ; esc sequence
              jne .end
              cmp byte [r9 + 1], 0x5B      ; [ character
              jne .quit
              cmp byte [r9 + 2], 0x41
              je .key_up
              cmp byte [r9 + 2], 0x42
              je .key_down
              cmp byte [r9 + 2], 0x43
              je .key_right
              cmp byte [r9 + 2], 0x44
              je .key_left
              jmp .end
.st_dead:
.st_success:
.st_victorious:
              cmp byte [r9], 0x0A          ; new line
              je .restart
              cmp byte [r9], 0x1B          ; esc sequence
              jne .end
              cmp byte [r9 + 1], 0x5B      ; [ character
              jne .quit
              jmp .end
.key_up:
              mov rdi, DIR_UP
              jmp .arrow_key
.key_down:
              mov rdi, DIR_DOWN
              jmp .arrow_key
.key_right:
              mov rdi, DIR_RIGHT
              jmp .arrow_key
.key_left:
              mov rdi, DIR_LEFT
.arrow_key:
              push rdi
              call plyr_move
              pop rdi
              cmp rax, 1                    ; if player was already moving
              jne .plyr_moved_or_blocked
              cmp [player_dir], edi
              je .end
              mov [pending_move], edi
              jmp .end
.quit:
              add rsp, 32
              mov rax, 1
              ret
.restart:
              add rsp, 32
              mov rax, 2
              ret
.plyr_moved_or_blocked:
              mov [pending_move], dword -1  ; clear pending movement
              mov [player_dir], edi
              add rsp, 32
              mov rax, 0
              ret
.end:
              add rsp, 32
              mov rax, 0
              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
delete_pending:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              xor rcx, rcx
.loop:
              lea r9, [rel pending_destr]
              mov r8, rcx
              shl r8, 3                     ; offset
              mov r10, r9
              add r10, r8
              mov rdi, [r10]
              cmp rdi, 0
              je .skip

              mov r11, [rdi + OBJ_OFFSET_ANIM_ST]
              cmp r11, 1
              je .skip                      ; skip if animation is still playing
              ; Erase from pending_destr
              add r8, r9
              xor r11, r11
              mov [r8], r11
.skip:
              inc rcx
              cmp rcx, GRID_H * GRID_W
              jl .loop

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sleep:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              sub rsp, 16
              mov rdi, rsp
              mov r8, 0                     ; seconds
              mov [rsp], r8
              mov r8, 1000000000/60         ; nanoseconds
              mov [rsp + 8], r8
              mov rsi, 0
              mov rax, 35                   ; sys_nanosleep
              syscall
              add rsp, 16

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_start:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              call initialise

              jmp .restart
.next_level:
              inc dword [level]
.restart:
              call construct_scene

              ; Game loop
.loop:
              cmp [game_state], dword GAME_ST_ALIVE
              je .st_alive
              cmp [game_state], dword GAME_ST_SUCCESS
              je .st_success
              cmp [game_state], dword GAME_ST_VICTORIOUS
              je .st_victorious
              cmp [game_state], dword GAME_ST_DEAD
              je .st_dead
.st_alive:
              call centre_cam
              call render_scene
              call sleep
              call death_condition
              call physics
              call keyboard
              cmp rax, 1
              je .exit
              cmp rax, 2
              je .restart
              call update_scene
              call delete_pending
              jmp .loop
.st_dead:
              call centre_cam
              call render_scene
              call sleep
              call physics
              call keyboard
              cmp rax, 1
              je .exit
              cmp rax, 2
              je .restart
              call update_scene

              ; Bit hacky, but force the death animation to stay on the last frame
              mov r8, [player]
              mov r9, [r8 + OBJ_OFFSET_ANIM_ST]
              cmp r9, 0
              jne .skip
              mov r9, ANIM_NUM_FRAMES - 1
              mov [r8 + OBJ_OFFSET_FRAME], r9
.skip:

              call delete_pending
              jmp .loop
.st_success:
              call centre_cam
              call render_scene
              call sleep
              call physics
              call keyboard
              cmp rax, 1
              je .exit
              cmp rax, 2
              je .next_level
              call update_scene
              call delete_pending
              jmp .loop
.st_victorious:
              call centre_cam
              call render_scene
              call sleep
              call physics
              call keyboard
              cmp rax, 1
              je .exit
              cmp rax, 2
              je .exit
              call update_scene
              call delete_pending
              jmp .loop
.exit:

              ; Clear the screen
              mov rdi, 0
              mov rsi, 0
              mov edx, [drw_fb_w]
              mov ecx, [drw_fb_h]
              mov r8, 0
              call drw_fill
              call drw_flush

              lea rdi, [rel str_goodbye]
              mov rsi, STR_GOODBYE_LEN
              call util_print

              call terminate

              mov rax, 60                   ; sys_exit
              xor rdi, rdi
              syscall
