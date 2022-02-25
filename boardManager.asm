%define board_width 10
%define board_height 15

%define piece_size 4

%define local1 8
%define local2 16

; exported functions
global generatePiece
global move
global checkCollision

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

; function checks if a piece collides with the board or with the borders
; input:   piece (bool[4][4]) pointer to piece to check         (rdi)
;          position (word[2]) pointer to position of piece      (rsi)
;          board (bool[10][15]) pointer to board                (rdx)
; return:  bool (true if there's a collision, false if not)
checkCollision:
    push rbp
    mov rbp, rsp
    ; 2 local variables
    sub rsp, 16
    mov qword [rbp - local1], 0
    mov qword [rbp - local2], 0
    ; store position in local variables
    mov ax, [rsi]
    mov [rbp - local1], ax  ; x position
    mov ax, [rsi + 2]
    mov [rbp - local2], ax  ; y position
    ; save bases of piece and board
    mov rbx, rdi    ; piece
    mov rcx, rdx    ; board

    mov rdi, 0  ; x position
    mov rsi, 0  ; y position
    ; go over all positions in piece
start_loop_y:
    mov rdi, 0
    ; loop over x
    start_loop_x:
        ; check if cell in piece is active
        mov rax, piece_size
        mul rsi    ; piece_size * y
        add rax, rdi ; piece_size * y + x (piece offset)
        mov al, [rbx + rax] 
        cmp al, 0
        je end_loop_x   ; cell is inactive, continue
        ; check if cell is out of bounds
        ; check x
        mov ax, di
        add ax, [rbp - local1]     ; x + x_offset
        ; check that 0 <= x < board_width
        cmp ax, board_width
        jge collision_detected
        cmp ax, 0
        jl collision_detected
        ; check y
        mov ax, si
        add ax, [rbp - local2]    ; y + y_offset
        ; check that y < board_height
        cmp ax, board_height
        jge collision_detected
        ; if y < 0 don't check board overlap
        cmp ax, 0
        jl end_loop_x

        ; check if cell in board is also active (overlapping cells)
        mov rax, board_width
        mov dx, si
        add dx, [rbp - local2]  ; y + y_offset
        mul dx     ; board_width * (y + y_offset)
        add ax, di
        add ax, [rbp - local1]  ; ax = board_width * y + x      (index on board)

        mov al, [rcx + rax]
        cmp al, 1
        je collision_detected

    end_loop_x:
        ; inc x and cmp
        inc rdi
        cmp rdi, piece_size
        jl start_loop_x     ; while x < piece size
    
    ; inc y and cmp
    inc rsi
    cmp rsi, piece_size
    jl start_loop_y     ; while y < piece size

    ; no collision detected, return false
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret

collision_detected:
    ; return true
    mov rax, 1
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
