%define board_width 10
%define board_height 15

%define piece_size 4

%define local(x) 8 * x

; exported functions
global generatePiece
global tryMove
global freezePiece
global tryRotate
global hardDrop
global clearLines

; imported functions
extern rand
extern memcpy
extern memmove
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
start_position_x: db 3
start_position_y: db -3

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
        add al, [rbp - local(1)]     ; x + x_offset
        ; check that 0 <= x < board_width
        cmp al, board_width
        jge collision_detected
        cmp al, 0
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
        add dl, [rbp - local(2)]  ; y + y_offset
        mul dx     ; board_width * (y + y_offset)
        add ax, di
        add al, [rbp - local(1)]  ; ax = board_width * y + x      (index on board)

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
; return:  whether or not the piece can be frozen (true unless out of bounds, meaning game is over)
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
        ; set cell
        mov byte [rcx + rax], 1

        ; if cell out of bounds (above screen), game over (return false)
        mov ax, si  ; piece y
        add al, byte [rbp - local(1) + 1]  ; y + y_offset
        cmp al, 0
        jl cant_freeze

    freeze_end_loop_x:
        ; inc x and cmp
        inc rdi
        cmp rdi, piece_size
        jl freeze_start_loop_x     ; while x < piece size
    
    ; inc y and cmp
    inc rsi
    cmp rsi, piece_size
    jl freeze_start_loop_y     ; while y < piece size

    ; return true
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret
cant_freeze:
    ; return false
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret

; function rotates a piece.
; input:   piece (bool[4][4]) pointer to piece to rotate         (rdi)
;          direction (bool) direction to rotate piece            (si)
; return:  none
rotatePiece:
    push rbp
    mov rbp, rsp
    ; 2 local variable
    sub rsp, 24
    ; 16 bit local for temp piece buffer
    mov qword [rbp - local(2)], 0
    mov qword [rbp - local(2) + 8], 0

    mov [rbp - local(3)], si

    ; set base of piece
    mov rbx, rdi
    ; store direction
    mov cx, si
    
    ; loop over piece  
    mov rdi, 0  ; x index
    mov rsi, 0  ; y index
rotate_start_loop_y:
    mov rdi, 0

    rotate_start_loop_x:
        mov rax, piece_size
        mul rsi    ; piece_size * y
        add rax, rdi ; piece_size * y + x   (piece index)
        ; check if cell is active in piece
        mov al, [rbx + rax] 
        cmp al, 0
        je rotate_end_loop_x   ; cell is inactive, continue

        ; set cell active on temp piece
        ; calculate new position (3 - y, x)
        mov rax, piece_size
        mov rcx, rdi    ; x
        mul rcx         ; (0, x)
        add rax, 3      ; (3, x)
        sub rax, rsi    ; (3 - y, x)

        ; check direction
        cmp word [rbp - local(3)], 0 
        je dont_flip
        ; flip piece - index -> (15 - index)
        neg rax
        add rax, 15
    dont_flip:
        ; set cell
        mov byte [rbp - local(2) + rax], 1

    rotate_end_loop_x:
        ; inc x and cmp
        inc rdi
        cmp rdi, piece_size
        jl rotate_start_loop_x     ; while x < piece size
    
    ; inc y and cmp
    inc rsi
    cmp rsi, piece_size
    jl rotate_start_loop_y     ; while y < piece size

    ; copy temp to piece
    mov rdi, rbx
    lea rsi, [rbp - local(2)]
    mov rdx, 16
    call memcpy

    ; return
    mov rsp, rbp
    pop rbp
    ret

; function tries to rotate a piece. if it can't, it changes nothing. redraws if needed.
; input:   piece (bool[4][4]) pointer to piece to rotate         (rdi)
;          board (bool[10][15]) pointer to board                 (rsi)
;          position (byte[2]) piece position in (dl, dh)         (dx)
;          color (const char*) color of piece                    (rcx)
; return:  whether or not the piece can be rotated
tryRotate:
    push rbp
    mov rbp, rsp
    ; 4 locals
    sub rsp, 32
    mov [rbp - local(1)], rdi   ; piece
    mov [rbp - local(2)], rsi   ; board
    mov [rbp - local(3)], dx    ; position
    mov [rbp - local(4)], rcx   ; color

    mov rdi, [rbp - local(1)]   ; piece
    mov si, 0
    call rotatePiece
    
    ; check collision
    mov rdi, [rbp - local(1)]   ; piece
    mov rsi, [rbp - local(2)]   ; board
    mov dx, [rbp - local(3)]    ; position
    call checkCollision
    ; if collision, return to original position and return false
    cmp rax, 1
    je rotate_collision

    ; back to original position
    mov rdi, [rbp - local(1)]   ; piece
    mov si, 1
    call rotatePiece

    ; delete piece with drawPiece
    call getBackgroundColor
    mov rcx, rax
    mov rdi, [rbp - local(1)]   ; piece
    mov dx, [rbp - local(3)]    ; position
    movsx rsi, dl
    mov al, dh
    movsx rdx, al
    call drawPiece

    ; rotate again and redraw
    mov rdi, [rbp - local(1)]   ; piece
    mov si, 0
    call rotatePiece

    ; redraw
    mov rdi, [rbp - local(1)]   ; piece
    mov dx, [rbp - local(3)]   ; position
    movsx rsi, dl
    mov al, dh
    movsx rdx, al
    mov rcx, [rbp - local(4)]   ; color
    call drawPiece

    ; return
    mov rsp, rbp
    pop rbp
    ret

rotate_collision:
    ; rotate back
    mov rdi, [rbp - local(1)]   ; piece
    mov si, 1
    call rotatePiece

    ; return false
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret

; function hard drops piece (without freezing)
; input:   piece (bool[4][4]) pointer to piece to rotate         (rdi)
;          board (bool[10][15]) pointer to board                 (rsi)
;          position (byte[2]) pointer to piece position          (rdx)
;          color (const char*) color of piece                    (rcx)
; return:  none
hardDrop:
    push rbp
    mov rbp, rsp
    ; 4 local variables
    sub rsp, 32
    mov [rbp - local(1)], rdi   ; piece
    mov [rbp - local(2)], rsi   ; board
    mov [rbp - local(3)], rdx   ; position
    mov [rbp - local(4)], rcx   ; color

    ; try move down until not possible
hard_drop_loop:
    ; try move
    mov rdi, [rbp - local(1)]   ; piece
    mov rsi, [rbp - local(2)]   ; board
    mov rdx, [rbp - local(3)]   ; 
    mov cx, 0x100               ; direction
    mov r8, [rbp - local(4)]    ; color
    call tryMove
    ; check if move succeeded
    cmp rax, 1
    je hard_drop_loop   ; while drop succeeded

    mov rsp, rbp
    pop rbp
    ret

; function clears lines if needed
; input:   board (bool[10][15]) pointer to board    (rdi)
; return:  number of lines cleared
clearLines:
    push rbp
    mov rbp, rsp
    
    ; save current line in rbx
    mov rbx, rdi
    ; board in rcx
    mov rcx, rdi

    ; go over all lines in board
    mov rdi, 0  ; x index
    mov rsi, 0  ; y index
    mov rax, 0  ; number of lines cleared

clear_loop_y:
    ; go over all cells in line
    mov rdi, 0
    clear_loop_x:
        ; check if cell is inactive
        mov al, [rbx + rdi]
        cmp al, 0
        je clear_loop_y_end   ; cell is inactive, jump to next line

        ; if active, continue to next cell
        inc rdi
        cmp rdi, board_width
        jl clear_loop_x
    ; if line is full, clear it
    inc rax
    ; shift lines (using memmove)
    ; memmove(board + width, board, rbx - board)
    push rsi
    push rax

    mov rdx, rbx
    sub rdx, rcx    ; rbx - board (copy size)
    mov rdi, rcx
    add rdi, board_width
    mov rsi, rcx
    call memmove

    pop rax
    pop rsi

clear_loop_y_end:
    ; move to next line
    inc rsi
    add rbx, board_width
    cmp rsi, board_height
    jl clear_loop_y
        
    mov rsp, rbp
    pop rbp
    ret
