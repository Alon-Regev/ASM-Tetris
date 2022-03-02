%define board_width 10
%define board_height 15
%define piece_size 4
%define window_width 300
%define window_height 480
%define board_offset 30     ; offset from top of window

%define local(x) x * 8

; exported functions
global drawPiece
global randomColor
global getBackgroundColor
global lineClearRedraw
global drawScore

; imported functions
extern drawRect
extern printf
extern rand
extern copyArea
extern drawText
extern sprintf


section .data
    ; constants
    cell_size_full: equ (window_height - board_offset) / board_height    ; the height constraints the cell size
    border_one_side: equ 2

    border: equ border_one_side * 2
    cell_size: equ cell_size_full - border

    ; colors
    color_red: db "#f00", 0
    color_yellow: db "#ff0", 0
    color_green: db "#0f0", 0
    color_blue: db "#00f", 0
    color_pink: db "#f0f", 0
    color_cyan: db "#0ff", 0

    background_color: db "#000", 0

    colors: dq color_red, color_yellow, color_green, color_blue, color_pink, color_cyan
    color_count: equ ($-colors)/8

    score_format: db "Score: %d", 0
    score_text: times 20 db 0
    score_color: db "white", 0
    score_offset_x: dw 10
    score_offset_y: dw 20

section .text
; funciton draws a piece on the screen
; input: piece (bool[][]) - the piece to draw           (rdi)
;        x (byte) - the x coordinate of the piece       (rsi)
;        y (byte) - the y coordinate of the piece       (rdx)
;        color (const char*) - the color of the piece   (rcx)
; output: none
drawPiece:
    push rbp
    push rsp
    mov rbp, rsp
    ; 3 local variables (offset_x, offset_y, color)
    sub rsp, 32
    mov [rbp - local(3)], rcx

    ; iterate over piece
    ; save x and y offsets
    mov [rbp - local(1)], rsi    ; x offset
    mov [rbp - local(2)], rdx    ; y offset
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
        ; draw cell at position (rdi + local(1), rsi + local(2))
        push rdi
        push rsi

        add rdi, [rbp - local(1)]
        add rsi, [rbp - local(2)]
        mov rdx, [rbp - local(3)]
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
    add rax, board_offset
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

; function returns a random color
; input: none
; return: color (const char*) (rax)
randomColor:
    ; get random number
    call rand
    ; get color index (modulo color_count)
    mov rbx, color_count
    div rbx

    ; get color
    mov rax, [colors + rdx * 8]
    ret

; function returns the background color
; input: none
; return: color (const char*) (rax)
getBackgroundColor:
    mov rax, background_color
    ret

; function redraws the board after a line clear
; input: y (int) - the y coordinate of the cleared line (rdi)
; return: none
lineClearRedraw:
    push rbp
    mov rbp, rsp
    ; 1 local
    sub rsp, 8
    mov [rbp - local(1)], rdi   ; y to clear

    ; move lines down using copyArea
    ; copy from (0, 0) to (0, cellSize) chunk size (window_width, y * cellSize)
    mov rdi, 0
    mov rsi, 0

    mov rdx, 0
    mov rcx, cell_size_full
    
    mov r8, window_width
    mov rax, [rbp - local(1)]
    mov rbx, cell_size_full
    mul rbx
    mov rbx, rax    ; y * cellSize
    add rbx, board_offset
    mov r9, rbx

    call copyArea

    ; clear top line using drawRect
    mov rdi, 0  ; x
    mov rsi, board_offset  ; y
    mov rdx, window_width   ; w
    mov rcx, cell_size_full ; h
    mov r8, background_color
    call drawRect

    ; return
    mov rsp, rbp
    pop rbp
    ret

; function draws score on the screen
; input: score (int) - the score to draw (edi)
; return: none
drawScore:
    push rbp
    mov rbp, rsp
    ; 1 local
    sub rsp, 16
    mov [rbp - local(1)], edi   ; score

    ; fill score in score text using sprintf
    mov rdi, score_text     ; result
    mov rsi, score_format   ; format
    mov rdx, [rbp - local(1)]   ; score
    call sprintf
    
    ; draw score
    ; void drawText(int x, int y, const char *text, const char *color)
    mov rdi, [score_offset_x]
    mov rsi, [score_offset_y]
    mov rdx, score_text
    mov rcx, score_color
    call drawText

    ; return
    mov rsp, rbp
    pop rbp
    ret
