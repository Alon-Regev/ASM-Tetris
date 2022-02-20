%define board_width 10
%define board_height 15

; exported event handlers
global update
global handleKeyPress

; imported functions
extern drawBoard
extern clearScreen

section .data
    board_length: equ board_width * board_height
    board:  times board_length db 1


section .text
; event handler for updating the game state every frame
; called every frame by the game loop
; input: none
; return: none
update:
    call redraw
    ret

; function for redrawing the screen GUI
; input: none
; return: none
redraw:
    push rbp
    mov rbp, rsp

    ; clean screen
    call clearScreen

    ; draw board
    mov rdi, board
    call drawBoard

    ; return
    mov rsp, rbp
    pop rbp
    ret

; event handler for key presses
; called by the event handler on key events
; input: key code as unsigned integer
; return: none
handleKeyPress:
    ret
