%define board_width 10
%define board_height 15

%define piece_size 4

; exported event handlers
global update
global handleKeyPress
global init

; imported functions
extern generatePiece
extern drawPiece
extern clearScreen
extern randomColor
extern getBackgroundColor

extern srand
extern time

section .data
    ; vars
    board_length: equ board_width * board_height
    board: times board_length db 0

    piece_length: equ piece_size * piece_size
    piece: times 16 db 0

    piece_position:
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

; event handler for initializing the game
; called by the game loop on game start
; input: none
; return: none
init:
    ; get time(NULL)
    mov rdi, 0
    call time

    ; call srand(time(NULL))
    mov rdi, rax
    call srand

    ; generate first piece
    mov rdi, piece
    mov rsi, piece_position
    call generatePiece
    ; pick color
    call randomColor
    mov [piece_color], rax

    ret

