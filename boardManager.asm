%define board_width 10
%define board_height 15

; exported functions
global generatePiece

; imported functions
extern rand

section .data
format: db "%d", 0xa, 0

; all possible pieces
; each piece as a 4x4 matrix (bool[4][4])

piece1: db 0, 0, 0, 0
        db 1, 1, 1, 1
        db 0, 0, 0, 0
        db 0, 0, 0, 0

piece2: db 0, 0, 0, 0
        db 0, 1, 1, 0
        db 0, 1, 1, 0
        db 0, 0, 0, 0

piece3: db 0, 0, 0, 0
        db 0, 0, 1, 0
        db 1, 1, 1, 0
        db 0, 0, 0, 0

piece4: db 0, 0, 0, 0
        db 1, 0, 0, 0
        db 1, 1, 1, 0
        db 0, 0, 0, 0

piece5: db 0, 0, 0, 0
        db 1, 1, 0, 0
        db 0, 1, 1, 0
        db 0, 0, 0, 0

piece6: db 0, 0, 0, 0
        db 0, 1, 1, 0
        db 1, 1, 0, 0
        db 0, 0, 0, 0

piece7: db 0, 0, 0, 0
        db 0, 1, 0, 0
        db 1, 1, 1, 0
        db 0, 0, 0, 0

; array of pieces (bool[4][4][7])
pieces: dq piece1, piece2, piece3, piece4, piece5, piece6, piece7
piece_count: equ 7

section .text
; function generates a new piece
; input:   piece (bool[4][4]) pointer to store piece in
;          position (dword[2]) pointer to store position in
; return:  none
generatePiece:
    push rbp
    mov rbp, rsp

    ; generate random number
    call rand
    mov rbx, piece_count
    div rbx

    mov rsp, rbp
    pop rbp
    ret
