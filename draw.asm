%define board_width 10
%define board_height 15
%define window_width 300
%define window_height 450 

; exported functions
global drawBoard

; imported functions
extern drawRect
extern printf

section .data
    cell_color: db "#888", 0    ; gray cells

    ; constants
    cell_size_full: equ 30    ; the height constraints the cell size
    border_one_side: equ 2

    border: equ border_one_side * 2
    cell_size: equ cell_size_full - border

section .text
; funciton draws the board on the screen
; input: board (bool[][]) - the board to draw
; output: none
drawBoard:
    ; iterate over board
    mov rbx, rdi    ; board 
    mov rsi, 0  ; y coordinate
    mov rdi, 0  ; x coordinate
; loop over y coordinate
start_loop_y:
    mov rdi, 0  ; x coordinate
    ; loop over x coordinate
    start_loop_x:
        ; check if cell is active
        mov rax, board_width
        mul rsi
        add rbx, rax    ; board[y][0]
        mov dl, byte [rbx + rdi]
        sub rbx, rax    ; back to board

        ; check if cell is active
        cmp dl, 0
        je dont_draw_cell
        ; draw cell at position (rdi, rsi)
        push rdi
        push rsi
        call drawCell
        pop rsi
        pop rdi
dont_draw_cell:

        ; increment x and compare
        inc rdi
        cmp rdi, board_width
        jl start_loop_x ; while x < board_width
    ; end loop x

    ; increment y and compare
    inc rsi
    cmp rsi, board_height
    jl start_loop_y ; while y < board_height
; end loop y

    ret


; function draws a single cell on the screen
; input: x (int) - x coordinate (rdi)
;        y (int) - y coordinate (rsi)
; return: none
drawCell:
    ; draw cell
    ; void drawRect(int x, int y, int w, int h, const char *color)
    ; x, y already in place
    push rbp
    mov rbp, rsp

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
    mov rdx, cell_size
    mov rcx, cell_size
    mov r8, cell_color
    call drawRect

    ; return
    mov rsp, rbp
    pop rbp
    ret