%define board_width 10
%define board_height 15

%define piece_size 4

%define local(x) 8 * x

; exported functions
global generatePiece
global tryMove
global freezePiece

; imported functions
extern rand
extern memcpy
extern drawPiece
extern getBackgroundColor


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
start_position_x: db 0
start_position_y: db 0

section .text
; function generates a new piece
; input:   piece (bool[4][4]) pointer to store piece in         (rdi)
;          position (byte[2]) pointer to store position in      (rsi)
; return:  none
generatePiece:
    push rbp
    mov rbp, rsp
    ; 1 local variable
    sub rsp, 16
    ; store position in local variable
    mov [rbp - local(1)], rsi
    mov [rbp - local(2)], rdi

    ; generate random number
    call rand
    ; take modulo 7 to get piece index
    mov rbx, piece_count
    div rbx

    ; copy pieces[rax] into piece
    mov rdi, [rbp - local(2)]
    mov rsi, [pieces + rdx * 8] ; src
    mov rdx, 16         ; size
    call memcpy

    ; set position to 0, 0
    mov rbx, [rbp - local(1)]     ; position
    mov cx, [start_position]
    mov word [rbx], cx        ; position = start_position

    mov rsp, rbp
    pop rbp
    ret

; function checks if a piece collides with the board or with the borders
; input:   piece (bool[4][4]) pointer to piece to check         (rdi)
;          board (bool[10][15]) pointer to board                (rsi)
;          position (byte[2]) check collision in (x, y)         (dl, dh)
; return:  bool (true if there's a collision, false if not)
checkCollision:
    push rbp
    mov rbp, rsp
    ; 2 local variables
    sub rsp, 16
    mov qword [rbp - local(1)], 0
    mov qword [rbp - local(2)], 0
    ; store position in local variables
    mov [rbp - local(1)], dl  ; x position
    mov [rbp - local(2)], dh  ; y position
    ; save bases of piece and board
    mov rbx, rdi    ; piece
    mov rcx, rsi    ; board

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
        add ax, [rbp - local(1)]     ; x + x_offset
        ; check that 0 <= x < board_width
        cmp ax, board_width
        jge collision_detected
        cmp ax, 0
        jl collision_detected
        ; check y
        mov ax, si
        add al, [rbp - local(2)]    ; y + y_offset
        ; check that y < board_height
        cmp al, board_height
        jge collision_detected
        ; if y < 0 don't check board overlap
        cmp ax, 0
        jl end_loop_x

        ; check if cell in board is also active (overlapping cells)
        mov rax, board_width
        mov dx, si
        add dx, [rbp - local(2)]  ; y + y_offset
        mul dx     ; board_width * (y + y_offset)
        add ax, di
        add ax, [rbp - local(1)]  ; ax = board_width * y + x      (index on board)

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

; function tries to move a piece. doensn't do anything if movement isn't possible. redraws the piece.
; input:   piece (bool[4][4]) pointer to piece to move         (rdi)
;          board (bool[10][15]) pointer to board               (rsi)
;          position (byte[2]) pointer to position (x, y)       (rdx)
;          direction (word) direction to move piece (value)    (cl, ch)
;          color (const char*) color to draw the piece         (r8)
; return:  whether the piece was moved or not
tryMove:
    push rbp
    mov rbp, rsp
    ; 4 local variables
    sub rsp, 48
    mov [rbp - local(1)], rdi   ; piece
    mov [rbp - local(2)], rsi   ; board
    mov [rbp - local(3)], rdx   ; position
    mov [rbp - local(4)], rcx   ; direction
    mov [rbp - local(5)], r8    ; color
    ; change position in direction and check collision
    mov dx, [rdx]   ; dl, dh = x, y
    add dx, cx
    call checkCollision
    ; if collision detected, return false and don't change position
    cmp rax, 1
    je try_move_return
    ; if no collision detected, move piece
    ; delete piece from screen
    ; get color in rcx
    call getBackgroundColor
    mov rcx, rax
    ; piece in rdi
    mov rdi, [rbp - local(1)]
    ; (x, y) from (dl, dh) in (rsi, rdx)
    mov rdx, [rbp - local(3)]
    mov rdx, [rdx]
    movsx rsi, dl
    mov al, dh
    movsx rdx, al
    call drawPiece

    ; move piece in board and redraw
    mov rdx, [rbp - local(3)] ; position ptr
    mov cx, [rbp - local(4)]  ; direction
    add word [rdx], cx      ; move in direction
    mov dx, [rdx]           ; dl, dh = x, y
    ; redraw piece
    mov rdi, [rbp - local(1)] ; piece
    movsx rsi, dl   ; x
    mov al, dh
    movsx rdx, al   ; y
    mov rcx, [rbp - local(5)]     ; color
    call drawPiece

    ; return no collision
    mov rax, 0

try_move_return:
    ; negate return (no collision -> true, collision -> false)
    neg rax
    inc rax

    mov rsp, rbp
    pop rbp
    ret

; function freezes the piece in place on the board
; input:   piece (bool[4][4]) pointer to piece to freeze         (rdi)
;          board (bool[10][15]) pointer to board                 (rsi)
;          position (byte[2]) piece position in (dl, dh)         (dx)
; return:  none
freezePiece:
    push rbp
    mov rbp, rsp
    ; 1 local
    sub rsp, 8
    mov [rbp - local(1)], dx    ; position

    ; set bases of piece and board
    mov rbx, rdi
    mov rcx, rsi

    ; fill board with piece
    mov rdi, 0  ; x index
    mov rsi, 0  ; y index

    ; loop over piece
freeze_start_loop_y:
    mov rdi, 0

    freeze_start_loop_x:
        mov rax, piece_size
        mul rsi    ; piece_size * y
        add rax, rdi ; piece_size * y + x   (piece index)
        ; check if cell is active in piece
        mov al, [rbx + rax] 
        cmp al, 0
        je freeze_end_loop_x   ; cell is inactive, continue

        ; set cell active on board
        mov rax, board_width
        mov dx, si  ; y
        add dl, byte [rbp - local(1) + 1]  ; y + y_offset
        mul dx      ; board_width * (y + y_offset)
        
        add ax, di
        add al, byte [rbp - local(1)]  ; ax = board_width * y + x      (index on board)
breakpoint:
        ; TODO: check if cell is out of bounds (can't freeze, game over)
        ; set cell
        mov byte [rcx + rax], 1

    freeze_end_loop_x:
        ; inc x and cmp
        inc rdi
        cmp rdi, piece_size
        jl freeze_start_loop_x     ; while x < piece size
    
    ; inc y and cmp
    inc rsi
    cmp rsi, piece_size
    jl freeze_start_loop_y     ; while y < piece size


    mov rsp, rbp
    pop rbp
    ret
