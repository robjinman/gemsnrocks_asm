%define       CELL_SZ 64
%define       GRID_W 50
%define       GRID_H 50
%define       BACKGROUND_COLOUR 0xFF112233

              SECTION .data

goodbye       db 'Good bye!', 10

img_plyr_path db './data/player.bmp', 0
img_soil_path db './data/soil.bmp', 0
img_rock_path db './data/rock.bmp', 0
img_gem_path  db './data/gem.bmp', 0
img_wall_path db './data/wall.bmp', 0
img_exit_path db './data/exit.bmp', 0

%define       DIR_UP 0
%define       DIR_DOWN 1
%define       DIR_RIGHT 2
%define       DIR_LEFT 3

unit_vecs     dd 0, -1                      ; up
              dd 0, 1                       ; down
              dd 1, 0                       ; right
              dd -1, 0                      ; left

%define       OBJ_TYPE_PLYR 0
%define       OBJ_TYPE_SOIL 1
%define       OBJ_TYPE_ROCK 2
%define       OBJ_TYPE_GEM 3
%define       OBJ_TYPE_WALL 4
%define       OBJ_TYPE_EXIT 5

levels        db 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 0, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4
              db 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5
              db 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4

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

%define       ANIM_NUM_FRAMES 8

grid          resq GRID_W * GRID_H          ; Pointers to game objects
player        resq 1

termios_old   resb 60                       ; Original terminal settings
termios_new   resb 60                       ; Modified terminal settings
stdin_flags   resq 1                        ; Original stdin flags

; First 8 bytes contains width and height
%define       IMG_PLYR_W 512
%define       IMG_PLYR_H 512
img_plyr      resb 8 + IMG_PLYR_W * IMG_PLYR_H * 4

%define       IMG_SOIL_W 512
%define       IMG_SOIL_H 64
img_soil      resb 8 + IMG_SOIL_W * IMG_SOIL_H * 4

%define       IMG_ROCK_W 512
%define       IMG_ROCK_H 256
img_rock      resb 8 + IMG_ROCK_W * IMG_ROCK_H * 4

%define       IMG_GEM_W 512
%define       IMG_GEM_H 256
img_gem       resb 8 + IMG_GEM_W * IMG_GEM_H * 4

%define       IMG_WALL_W 512
%define       IMG_WALL_H 64
img_wall      resb 8 + IMG_WALL_W * IMG_WALL_H * 4

%define       IMG_EXIT_W 512
%define       IMG_EXIT_H 128
img_exit      resb 8 + IMG_EXIT_W * IMG_EXIT_H * 4

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
construct_exit:
; rdi gridX
; rsi gridY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov rdx, rsi
              mov rsi, rdi
              mov rdi, OBJ_TYPE_EXIT
              lea rcx, [rel img_exit]
              call construct_object

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
grid_at:
; rdi gridX
; rsi gridY
;
; Returns
; rax object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              imul rsi, GRID_W
              add rsi, rdi
              shl rsi, 3
              lea r8, [rel grid]
              add r8, rsi
              mov rax, [r8]

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
grid_insert_world:
; rdi worldX
; rsi worldY
; rdx object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rdx

              mov rax, rdi
              mov r8, CELL_SZ
              xor rdx, rdx
              div r8
              mov r9, rax                   ; gridX

              mov rax, rsi
              mov r8, CELL_SZ
              xor rdx, rdx
              div r8
              mov r10, rax                  ; gridY

              pop rdx

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
obj_draw:
; rdi object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              sub rsp, 32
              mov r11, rdi
              mov rdi, [r11 + OBJ_OFFSET_IMG]
              mov rsi, [r11 + OBJ_OFFSET_X]
              mov rdx, [r11 + OBJ_OFFSET_Y]
              mov rcx, [r11 + OBJ_OFFSET_FRAME]
              imul rcx, CELL_SZ             ; srcX
              mov r8, [r11 + OBJ_OFFSET_IMG_ROW]
              imul r8, CELL_SZ              ; srcY
              mov r9, CELL_SZ               ; w
              mov r10, CELL_SZ              ; h
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

              push r12
              push r13
              push r14

              mov r14, CELL_SZ

              mov eax, [drw_fb_w]
              xor rdx, rdx
              div r14
              mov r12, rax                  ; x max

              mov eax, [drw_fb_h]
              xor rdx, rdx
              div r14
              mov r13, rax                  ; y max

              lea r11, [rel grid]

              mov r8, 0                     ; row
.loop_row:
              mov r9, 0                     ; col
.loop_col:
              mov r10, r8
              imul r10, GRID_W
              add r10, r9
              shl r10, 3
              add r10, r11

              mov rdi, [r10]
              cmp rdi, 0
              je .skip

              push r8
              push r9
              push r10
              push r11
              call obj_draw
              pop r11
              pop r10
              pop r9
              pop r8
.skip:

              inc r9
              cmp r9, r12
              jl .loop_col

              inc r8
              cmp r8, r13
              jl .loop_row

              call drw_flush

              pop r14
              pop r13
              pop r12

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push_exit:
; rdi direction
;
; Returns
; rax block player = 1, allow player = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              ; TODO
              mov rax, 1

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push_gem:
; rdi direction
;
; Returns
; rax block player = 1, allow player = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              ; TODO
              mov rax, 1

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push_rock:
; rdi direction
;
; Returns
; rax block player = 1, allow player = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              ; TODO
              mov rax, 1

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push_soil:
; rdi direction
;
; Returns
; rax block player = 1, allow player = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              ; TODO
              mov rax, 0

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push_wall:
; rdi direction
;
; Returns
; rax block player = 1, allow player = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              ; TODO
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
              mov rdi, rsi

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
grid_player_x:
; Returns
; rax gridX
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov r10, [player]
              mov r8, [r10 + OBJ_OFFSET_X]
              add r8, CELL_SZ / 2

              mov rax, r8
              mov r8, CELL_SZ
              xor rdx, rdx
              div r8                        ; gridX

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
grid_player_y:
; Returns
; rax gridY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              mov r10, [player]
              mov r8, [r10 + OBJ_OFFSET_Y]
              add r8, CELL_SZ / 2

              mov rax, r8
              mov r8, CELL_SZ
              xor rdx, rdx
              div r8                        ; gridY

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
              push rdi

              call grid_player_x
              mov r8, rax

              push r8
              call grid_player_y
              mov r9, rax
              pop r8

              pop rdi
              mov r11, rdi                  ; direction

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

              cmp rax, 0
              je .skip

              mov rdi, rax
              call obj_push
.skip:

              pop r14
              pop r13
              pop r12

              ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
plyr_move:
; rdi direction
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              push rbp
              mov rbp, rsp
              sub rsp, 16

              mov [rbp - 8], rdi            ; direction

              ; Check if player is currently moving
              mov r11, [player]
              mov r8, [r11 + OBJ_OFFSET_ANIM_ST]
              cmp r8, 1
              je .skip                      ; Exit function if player is moving

              call grid_push_obj
              cmp rax, 1
              je .skip                      ; Exit function if blocked by object

              lea r8, [rel unit_vecs]
              mov r11, [rbp - 8]            ; direction
              shl r11, 3                    ; size of vector is 8 bytes
              add r8, r11
              movsx r9, dword [r8]          ; dx
              movsx r10, dword [r8 + 4]     ; dy

              push r9
              push r10

              ; Play animation
              mov rdi, [player]
              mov rsi, [rbp - 8]            ; Animation ID
              mov rdx, r9                   ; dx
              imul rdx, CELL_SZ / ANIM_NUM_FRAMES
              mov rcx, r10                  ; dy
              imul rcx, CELL_SZ / ANIM_NUM_FRAMES
              call obj_play_anim

              ; Erase player from grid
              mov r8, [player]
              mov rdi, [r8 + OBJ_OFFSET_X]
              add rdi, CELL_SZ / 2
              mov rsi, [r8 + OBJ_OFFSET_Y]
              add rsi, CELL_SZ / 2
              mov rdx, 0
              call grid_insert_world

              pop r10                       ; dy
              pop r9                        ; dx

              imul r9, CELL_SZ
              imul r10, CELL_SZ

              ; Re-insert player into grid
              mov r8, [player]
              mov rdi, [r8 + OBJ_OFFSET_X]
              add rdi, CELL_SZ / 2
              add rdi, r9
              mov rsi, [r8 + OBJ_OFFSET_Y]
              add rsi, CELL_SZ / 2
              add rsi, r10
              mov rdx, [player]
              call grid_insert_world
.skip:

              mov rsp, rbp
              pop rbp

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
              mov rdi, DIR_UP
              call plyr_move
              jmp .no_input
.key_down:
              mov rdi, DIR_DOWN
              call plyr_move
              jmp .no_input
.key_right:
              mov rdi, DIR_RIGHT
              call plyr_move
              jmp .no_input
.key_left:
              mov rdi, DIR_LEFT
              call plyr_move
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
