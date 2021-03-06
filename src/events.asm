%define board_width 10
%define board_height 15

%define piece_size 4

%define lines_per_level 5
%define min_drop_speed 3

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
global getScore

; imported functions
extern generatePiece
extern randomColor
extern drawScore
extern drawLevel

extern tryMove
extern tryRotate
extern freezePiece
extern hardDrop
extern clearLines

extern srand
extern time


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

    score: dd 0
    line_clear_scores: dd 0, 60, 150, 350, 750

    level: dw 0
    line_clear_counter: dw 0

section .text

; event handler for updating the game state every frame
; called every frame by the game loop
; input: none
; return: whether the game should continue
update:
    push rbp
    mov rbp, rsp

    call dropUpdate

    mov rsp, rbp
    pop rbp
    ret

; function updates the drop state
; input: none
; return: whether the game should continue (false if game over)
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
    ; add score
    mov rdi, 4
    call addScore

    ; clear lines
    mov rdi, board
    call clearLines
    add [line_clear_counter], ax
    ; add score
    mov rdi, [line_clear_scores + rax * 4]
    call addScore
    ; check level up
    cmp word [line_clear_counter], lines_per_level
    jb dont_level_up
    ; level up
    sub word [line_clear_counter], lines_per_level
    inc word [level]
    ; draw new level
    mov di, word [level]
    call drawLevel

dont_level_up:
    
    ; generate a new piece
    mov rdi, piece
    mov rsi, piece_position
    call generatePiece
    ; random color
    call randomColor
    mov [piece_color], rax

dont_freeze:
    ; reset timer
    call resetTimer

dont_drop:
    ; return true
    mov rax, 1
    mov rsp, rbp
    pop rbp
    ret

drop_game_over:
    ; return false
    mov rax, 0
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
    ; try to move the piece
    mov rdi, piece
    mov rsi, board
    mov rdx, piece_position
    mov rcx, 0x100
    mov r8, [piece_color]
    call tryMove
    ; if moved, reset timer and add score
    cmp rax, 0
    je key_press_end
    ; reset timer
    call resetTimer
    ; add score
    mov rdi, 1
    call addScore

    jmp key_press_end
up:
    ; roatate 
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

    cmp rax, 0
    je key_press_end
    ; add score
    mov rdi, 3
    mul rdi
    mov rdi, 2
    div rdi     ; cells * 1.5
    mov rdi, rax    ; score
    call addScore
    ; reset timer
    call resetTimer

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

; function adds score
; input: score as unsigned integer   (edi)
; return: none
addScore:
    push rbp
    mov rbp, rsp
    sub rsp, 8

    ; calculate multiplier (1 + level / 2 = (level + 2) * score / 2)
    xor eax, eax
    movsx eax, word [level]
    add eax, 2  ; level + 1
    mul edi ; (level + 1) * score
    ; div by 2
    mov cx, 2
    xor dx, dx
    div cx

    ; add score
    add dword [score], eax

    ; draw score
    mov edi, [score]
    call drawScore

    mov rsp, rbp
    pop rbp
    ret

; function resets the drop timer
; input: none
; return: none
resetTimer:
    ; calculate drop speed = 200 / (level + 8)
    xor rax, rax
    xor rdx, rdx
    mov ax, 200
    mov bx, [level]
    add bx, 8
    div bx
    ; min 3 frames
    cmp ax, min_drop_speed
    jge set_drop_speed
    ; set to min
    mov ax, min_drop_speed
set_drop_speed:
    mov word [frames_to_drop], ax
    ret

; function returns the current score
; input: none
; return: score as unsigned integer   (eax)
getScore:
    mov eax, [score]
    ret