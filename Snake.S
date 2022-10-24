.define VSYNC_COUNTER $0300
.define TIME $0301
.define FRAME #$60

.define HEAD_PAGE_POSITION $0311
.define TAIL_PAGE_POSITION $0312
.define HEAD_NEXT_POSITION $0313
.define TAIL_POSITION $0314
.define DIRECTION $0320
.define ADDED_LAST_DIRECTION_FLAG $0321
.define GAME_OVER_TIMER $0322

.define TAIL_TMP_A_POSITION  $0330
.define TAIL_TMP_X_POSITION  $0331

.define INPUT $4000
.define TOP #$01
.define BOTTOM #$02
.define LEFT #$04
.define RIGHT #$08

.define ZERO #$00
.define MAX #$FF
.define BITMASK_VALUES #$0F
.define BITMASK_DIRECTION #$F0
.define SNAKE_COLOR #$FF
.define APPLE_COLOR #$01

.ORG $8000
; reset Stack
start:
LDX MAX
TXS

game_over:
LDA GAME_OVER_TIMER
BEQ game
JMP game_over

game:
; clear Screen Page             TODO
; clear ZeroPage
JSR clear_zero_page
; clear Screen
JSR clear_screen
; set head and tail page position to $00
STA HEAD_PAGE_POSITION
STA TAIL_PAGE_POSITION
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
; update distances
JSR update_distances
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

update_distances:
; check if i have length = 1
LDX HEAD_PAGE_POSITION
BEQ update_tail_position
; remove last distance
LDX TAIL_PAGE_POSITION
DEC $00, X
LDA $00, X
AND BITMASK_VALUES
; if lastdistance become XXX0000 shift all distances
BNE not_shift_distances
JSR shift_distances
; add new distance
not_shift_distances:
update_tail_position:
JSR calulcate_tail
; update tail position
RTS

shift_distances:
LDX HEAD_PAGE_POSITION
DEX
; get first direction
LDA $00, X
CLC
AND BITMASK_DIRECTION
LSR  A
LSR  A
LSR  A
LSR  A
CMP DIRECTION
BNE not_increase
INC $00, X
; save thath I have just added last direction
LDA MAX
STA ADDED_LAST_DIRECTION_FLAG
not_increase:
loop_shif_ditances:
; store next value to Y
DEX
LDA $00, X
TAY
; return to current value
INX
LDA $00, X
DEX
; if index become < 0 reached end of pages
BMI end_loop_shif_ditances
STA $00, X
JMP loop_shif_ditances 
end_loop_shif_ditances:
; check if have alredy added last direction
LDA ADDED_LAST_DIRECTION_FLAG
EOR MAX
BEQ need_add_new_distance
; decrement head position
LDX HEAD_PAGE_POSITION
LDA $00, X
DEX
STA $00, X
TXA
STA HEAD_PAGE_POSITION
RTS
need_add_new_distance:
JSR add_new_distance
RTS


add_new_distance:
; get opposite of distance
LDA DIRECTION
AND RIGHT
CLC
BEQ not_right 
ASL A
ASL A
ASL A
ASL A
not_right:
ASL A
LDX HEAD_PAGE_POSITION
DEX
; store new distance
STA $00, X
; increase it
INC $00, X
RTS

calulcate_tail:
LDX HEAD_PAGE_POSITION
LDA $00, X
loop_calulcate_tail:
DEX
BEQ end_loop_calulcate_tail
; store curr A position in tmp
STA TAIL_TMP_A_POSITION
; store X value
TXA
STA TAIL_TMP_X_POSITION
; get direction
LDA $00, X
; get value
AND BITMASK_VALUES
; store it to Y
TAY 
LDA $00, X
; get direction
LDA DIRECTION
AND RIGHT
CLC
BEQ not_right_check 
ASL A
ASL A
ASL A
ASL A
not_right_check:
ASL A
single_direction_loop:
; compare with direction
AND TOP
BEQ check_bottom
;                             TODO -16
JMP end_compare_input
check_bottom:
LDA DIRECTION
AND BOTTOM
BEQ check_left
LDA #$10
JMP end_compare_input
check_left:
LDA DIRECTION
AND LEFT
BEQ check_right
;                             TODO -01
JMP end_compare_input
check_right:
LDA DIRECTION
AND RIGHT
BEQ end_compare_input
LDA #$01
end_compare_input:
ADC TAIL_TMP_A_POSITION
DEY
BNE single_direction_loop
; Move to nex loop_calulcate_tail
LDX TAIL_TMP_X_POSITION
JMP loop_calulcate_tail
end_loop_calulcate_tail:
STA TAIL_POSITION
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