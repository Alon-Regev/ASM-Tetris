%define board_width 10
%define board_height 15

%define local1 8
%define local2 16

; exported functions
global generatePiece
global move

; imported functions
extern rand
extern memcpy


section .data

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
piece_count: equ ($-pieces)/8

start_position: 
start_position_x: dw 0
start_position_y: dw 0

section .text
; function generates a new piece
; input:   piece (bool[4][4]) pointer to store piece in         (rdi)
;          position (word[2]) pointer to store position in     (rsi)
; return:  none
generatePiece:
    push rbp
    mov rbp, rsp
    ; 1 local variable
    sub rsp, 16
    ; store position in local variable
    mov [rbp - local1], rsi
    mov [rbp - local2], rdi

    ; generate random number
    call rand
    ; take modulo 7 to get piece index
    mov rbx, piece_count
    div rbx

    ; copy pieces[rax] into piece
    mov rdi, [rbp - local2]
    mov rsi, [pieces + rdx * 8] ; src
    mov rdx, 16         ; size
    call memcpy

    ; set position to 0, 0
    mov rbx, [rbp - local1]     ; position
    mov ecx, [start_position]
    mov dword [rbx], ecx        ; position = start_position

    mov rsp, rbp
    pop rbp
    ret

; function moves a piece
; input:   position (word*) pointer to store position in      (rdi)
;          direction (dword) direction to move piece (value)  (rsi)
;               16 lsb - horizontal, 16 msb - vertical
; return:  none
move:
    add dword [rdi], esi
    ret
