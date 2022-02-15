; exported event handlers
global update
global handleKeyPress

extern printf

section .data
msg: db '%d', 10, 0

section .text
; event handler for updating the game state every frame
; called every frame by the game loop
; input: none
; return: none
update:
    ; print msg
    ret

; event handler for key presses
; called by the event handler on key events
; input: key code as unsigned integer
; return: none
handleKeyPress:
    ret
