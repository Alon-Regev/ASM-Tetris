%define board_width 10
%define board_height 15

%define piece_size 4

; exported event handlers
global update
global handleKeyPress

; imported functions
extern drawPiece
extern clearScreen

section .data
    ; colors
    color_red: db "#f00", 0

    ; vars
    board_length: equ board_width * board_height
    board: times board_length db 0

    piece_length: equ piece_size * piece_size
    piece: times 16 db 0

    piece_x: dw 0
    piece_y: dw 0
    piece_color: dq 0


section .text
; event handler for updating the game state every frame
; called every frame by the game loop
; input: none
; return: none
update:
    ret

; event handler for key presses
; called by the event handler on key events
; input: key code as unsigned integer
; return: none
handleKeyPress:
    ret
