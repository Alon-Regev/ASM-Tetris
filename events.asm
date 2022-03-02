%define board_width 10
%define board_height 15

%define piece_size 4

%define local(x) x * 8

; key codes
%define left_key 113
%define right_key 114
%define down_key 116
%define up_key 111
%define space_key 65

; exported event handlers
global update
global handleKeyPress
global init

; imported functions
extern generatePiece
extern randomColor

extern tryMove
extern tryRotate
extern freezePiece
extern hardDrop
extern clearLines

extern srand
extern time
extern exit

section .data
    ; vars
    board_length: equ board_width * board_height 
    board: times board_length db 0

    piece_length: equ piece_size * piece_size
    piece: times 16 db 0

    piece_position:
    piece_x: db 0
    piece_y: db 0
    piece_color: dq 0

    frames_to_drop: dw 20
    drop_speed: dw 4   ; once per second

section .text

; event handler for updating the game state every frame
; called every frame by the game loop
; input: none
; return: none
update:
    push rbp
    mov rbp, rsp

    call dropUpdate

    mov rsp, rbp
    pop rbp
    ret

; function updates the drop state
; input: none
; return: none
dropUpdate:
    push rbp
    mov rbp, rsp
    sub rsp, 8

    ; drop counter
    dec word [frames_to_drop]
    jnz dont_drop   ; if frames left == 0
    ; drop the piece (using tryMove)
    mov rdi, piece
    mov rsi, board
    mov rdx, piece_position
    mov cx, 0x100      ; direction (0, 1)
    mov r8, [piece_color]
    call tryMove
    ; check freeze (can't drop)
    cmp rax, 1  ; can move
    je dont_freeze  ; if moved, don't freeze

    ; freeze the piece
    mov rdi, piece
    mov rsi, board
    mov dx, [piece_position]
    call freezePiece
    ; check game over
    cmp rax, 0  ; can't freeze, out of bounds
    je drop_game_over

    ; clear lines
    mov rdi, board
    call clearLines
    
    ; generate a new piece
    mov rdi, piece
    mov rsi, piece_position
    call generatePiece
    ; random color
    call randomColor
    mov [piece_color], rax

dont_freeze:
    ; reset timer
    mov ax, [drop_speed]
    mov [frames_to_drop], ax

dont_drop:
    mov rsp, rbp
    pop rbp
    ret

drop_game_over:
    call gameOver
    mov rsp, rbp
    pop rbp
    ret

; event handler for key presses
; called by the event handler on key events
; input: key code as unsigned integer   (rdi)
; return: none
handleKeyPress:
    push rbp
    mov rbp, rsp
    sub rsp, 8

    ; switch key code (rdi)
    cmp rdi, left_key
    je left
    cmp rdi, right_key
    je right
    cmp rdi, down_key
    je down
    cmp rdi, up_key
    je up
    cmp rdi, space_key
    je space
    ; default: do nothing
    jmp switch_end
    
left:
    mov cx, -0x1
    jmp switch_end
right:
    mov cx, 0x1
    jmp switch_end
down:
    mov cx, 0x100
    jmp switch_end
up:
    ; roatate piece
    mov rdi, piece
    mov rsi, board
    mov dx, [piece_position]
    mov rcx, [piece_color]
    call tryRotate
    jmp key_press_end
space:
    ; hard drop
    mov rdi, piece
    mov rsi, board
    mov rdx, piece_position
    mov rcx, [piece_color]
    call hardDrop
    jmp key_press_end

switch_end:
    ; try to move the piece
    mov rdi, piece
    mov rsi, board
    mov rdx, piece_position
    ; direction in cx
    mov r8, [piece_color]
    call tryMove

key_press_end:
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

; function ends the game
; input: none
; return: none
gameOver:
    mov rdi, 0
    call exit