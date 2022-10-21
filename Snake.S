.define VSYNC_COUNTER $0300
.define TIME $0301
.define FRAME #$60

.define HEAD_PAGE_POSITION $0311
.define HEAD_NEXT_POSITION $0312
.define TAIL_POSITION $0313
.define DIRECTION $0320
.define GAME_OVER_TIMER $0321

.define INPUT $4000
.define TOP #$01
.define BOTTOM #$02
.define LEFT #$04
.define RIGHT #$08

.define ZERO #$00
.define MAX #$FF
.define SNAKE_COLOR #$FF
.define APPLE_COLOR #$01

.ORG $8000
; reset Stack
start:
LDX MAX
TXS

game:
; clear Screen Page             TODO
; clear ZeroPage
JSR clear_zero_page
; clear Screen
JSR clear_screen
; set head page position to $00
STA HEAD_PAGE_POSITION
; set head next to $00
STA HEAD_NEXT_POSITION
; set tail position to $00
STA TAIL_POSITION
; set initial direction to $00
STA DIRECTION
; draw snake
LDA SNAKE_COLOR
LDX HEAD_PAGE_POSITION
STA $0200, X

main_loop:
; read input
LDA INPUT
BEQ else_store_input
; store input only if is not queal to 0
STA DIRECTION
else_store_input:
; read time
LDA TIME
; move snake 1 "pixel" at second
BEQ main_loop
LDA ZERO
STA TIME
; check direction
LDA DIRECTION
AND TOP
BEQ else_bottom
;                             TODO -16
JMP end_check_input
else_bottom:
LDA DIRECTION
AND BOTTOM
BEQ else_left
LDA #$10
JMP end_check_input
else_left:
LDA DIRECTION
AND LEFT
BEQ else_right
;                             TODO -01
JMP end_check_input
else_right:
LDA DIRECTION
AND RIGHT
BEQ end_check_input
LDA #$01
JMP end_check_input
end_check_input:
; read current head position
LDX HEAD_PAGE_POSITION
; sum with position
ADC $00, X
STA HEAD_NEXT_POSITION
; check if hit something 
TAX
LDA $0200, X
CMP SNAKE_COLOR
;                              TODO Check if not is tail
BEQ game_over
CMP APPLE_COLOR
;                              TODO Apple
; move snake
; clear tail
LDX TAIL_POSITION
LDA ZERO
STA $0200, X
; save new head position
LDX HEAD_PAGE_POSITION
LDA HEAD_NEXT_POSITION
STA $00, X
; draw head
TAX
LDA SNAKE_COLOR
STA $0200, X


JMP main_loop

game_over:
LDA GAME_OVER_TIMER
BEQ game
JMP game_over


clear_zero_page:
LDX ZERO
LDA ZERO
loop_clear_zero_page:
STA $00, X
INX
BNE loop_clear_zero_page
RTS

clear_screen:
LDX ZERO
LDA ZERO
loop_clear_screen:
STA $0200, X
INX
BNE loop_clear_screen
RTS

clear_screen_page:
LDX ZERO
LDA ZERO
loop_clear_screen_page:
STA $0200, X
INX
BNE loop_clear_screen_page
RTS

nmi:
DEC VSYNC_COUNTER
BEQ reset_vsync
RTI

reset_vsync:
TAY
LDA FRAME
STA VSYNC_COUNTER
LDA DIRECTION
BEQ not_increase_time
LDA #$01
STA TIME
not_increase_time:
LDA GAME_OVER_TIMER
BEQ not_game_over
DEC GAME_OVER_TIMER
not_game_over:
TYA
RTI

.goto $FFFA
.dw nmi ; non maskable
.dw start ; reset
.dw start ; interrupt