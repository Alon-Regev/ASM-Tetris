%define board_width 10
%define board_height 15
%define piece_size 4
%define window_width 300
%define window_height 450 

%define local1 8
%define local2 16
%define local3 24

; exported functions
global drawPiece

; imported functions
extern drawRect
extern printf

section .data
    ; constants
    cell_size_full: equ window_height / board_height    ; the height constraints the cell size
    border_one_side: equ 2

    border: equ border_one_side * 2
    cell_size: equ cell_size_full - border

section .text
; funciton draws a piece on the screen
; input: piece (bool[][]) - the piece to draw           (rdi)
;        x (int) - the x coordinate of the piece        (rsi)
;        y (int) - the y coordinate of the piece        (rdx)
;        color (const char*) - the color of the piece   (rcx)
; output: none
drawPiece:
    push rbp
    push rsp
    mov rbp, rsp
    ; 3 local variables (offset_x, offset_y, color
    sub rsp, 32
    mov [rbp - local3], rcx

    ; iterate over piece
    ; save x and y offsets
    mov [rbp - local1], rsi    ; x offset
    mov [rbp - local2], rdx    ; y offset
    ; iterate over piece
    mov rbx, rdi    ; piece 
    mov rdi, 0  ; x coordinate
    mov rsi, 0  ; y coordinate
; loop over y coordinate
start_loop_y:
    mov rdi, 0  ; reset x coordinate
    ; loop over x coordinate
    start_loop_x:
        ; check if cell is active
        mov rax, piece_size
        mul rsi
        add rbx, rax    ; piece[y][0]
        mov dl, [rbx + rdi]    ; get piece[y][x]
        sub rbx, rax    ; move rbx back to first row

        ; check if cell is active
        cmp dl, 0
        je dont_draw_cell
        ; draw cell at position (rdi + local1, rsi + local2)
        push rdi
        push rsi

        add rdi, [rbp - local1]
        add rsi, [rbp - local2]
        mov rdx, [rbp - local3]
        call drawCell

        pop rsi
        pop rdi

dont_draw_cell:

        ; increment x and compare
        inc rdi
        cmp rdi, piece_size
        jl start_loop_x ; while x < board_width
    ; end loop x

    ; increment y and compare
    inc rsi
    cmp rsi, piece_size
    jl start_loop_y ; while y < board_height
; end loop y
    ; return
    mov rsp, rbp
    pop rsp
    pop rbp
    ret

; function draws a single cell on the screen
; input: x (int) - x coordinate (rdi)
;        y (int) - y coordinate (rsi)
;        color (const char*) - color of the cell (rdx)
; return: none
drawCell:
    ; draw cell
    ; void drawRect(int x, int y, int w, int h, const char *color)
    ; x, y already in place
    push rbp
    mov rbp, rsp

    ; save color for later
    mov rcx, rdx

    ; calculate x and y in pixels
    mov rax, rdi
    mov rdx, cell_size_full
    mul rdx     ; x * cell_size_full
    add rax, border_one_side ; add space for border
    mov rdi, rax

    mov rax, rsi
    mov rdx, cell_size_full
    mul rdx     ; y * cell_size_full
    add rax, border_one_side ; add space for border
    mov rsi, rax

    ; call drawRect
    mov r8, rcx   ; color
    mov rdx, cell_size
    mov rcx, cell_size
    call drawRect

    ; return
    mov rsp, rbp
    pop rbp
    ret