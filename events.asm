%define board_width 10
%define board_height 15

%define piece_size 4

%define local1 8

; key codes
%define left_key 113
%define right_key 114
%define down_key 116
%define up_key 111

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
extern move

extern srand
extern time

section .data
    ; vars
    board_length: equ board_width * board_height
    board: times board_length db 0

    piece_length: equ piece_size * piece_size
    piece: times 16 db 1

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
; input: key code as unsigned integer   (rdi)
; return: none
handleKeyPress:
    push rbp
    mov rbp, rsp
    sub rsp, 8

    ; save direction in bx (ah, al) = (x, y)
    xor rax, rax

    ; switch key code (rdi)
    cmp rdi, left_key
    je left
    cmp rdi, right_key
    je right
    cmp rdi, down_key
    je down
    cmp rdi, up_key
    je up
    ; default: do nothing
    jmp switch_end
    
left:
    mov eax, -0x1
    jmp switch_end
right:
    mov eax, 0x1
    jmp switch_end
down:
    mov eax, 0x10000
    jmp switch_end
up:
    mov eax, -0x10000
    jmp switch_end

switch_end:
    mov [rbp - local1], rax    ; save direction
    ; delete piece with drawPiece
    call getBackgroundColor
    mov rsi, 0
    mov rdx, 0
    mov rdi, piece
    mov si, [piece_x]
    mov dx, [piece_y]
    mov rcx, rax
    call drawPiece

    ; move in direction
    mov rdi, piece_position
    mov rsi, [rbp - local1]     ; direction
    call move

    ; redraw piece
    mov rdi, piece
    mov si, [piece_x]
    mov dx, [piece_y]
    mov rcx, [piece_color]
    call drawPiece

    mov rsp, rbp
    pop rbp
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

