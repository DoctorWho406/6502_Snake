.define VSYNC_COUNTER $0300
.define TIME $0301
.define FRAME #60

; where is the head
.define HEAD_POSITION $FF
; next head position
.define HEAD_NEXT_POSITION $0310
; where is the tail in zero page
.define TAIL_PAGE_POSITION $0311
; where is the tail
.define TAIL_POSITION $0312
.define DIRECTION $0320
; ?
.define ADDED_LAST_DIRECTION_FLAG $0321
.define GAME_OVER_TIMER $0322

; args for SubRoutine calculate_pos_by_distance
.define POSITION_TO_CALCULATE  $0330
.define DIRECTION_FOR_CALCULATION  $0331
; flag for check if is firt loop iteration
.define FIRST_LOOP_ITERATION  $0332
; args for SubRoutine get_opposite_direction
.define DIRECTION_TO_INVERT  $0333

.define TAIL_TMP_A_POSITION  $0334
.define TAIL_TMP_X_POSITION  $0335

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
JMP game

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

game_over:
LDA GAME_OVER_TIMER
BEQ game
JMP game_over

game:
; clear Screen Page
JSR clear_screen
; clear ZeroPage
JSR clear_zero_page
; set head and tail page position to $00
STA TAIL_PAGE_POSITION
; set head next to $00
STA HEAD_NEXT_POSITION
; set initial direction to $00
STA DIRECTION
; set tail position to $FF
LDA MAX
STA TAIL_POSITION
; draw snake
LDA SNAKE_COLOR
LDX HEAD_PAGE_POSITION
STA $0200, X

main_loop:
; ------------------------ READ INPUT ------------------------
LDA INPUT
BEQ else_store_input
; store input only if is not queal to 0
STA DIRECTION
else_store_input:
; ----------------------- CHECK INPUT ------------------------
LDA TIME
; move snake 1 "pixel" at second
BEQ main_loop
; reset time
LDA ZERO
STA TIME
; ------------------- HEAD NEXT POSITION ---------------------
LDA HEAD_POSITION
STA POSITION_TO_CALCULATE
JSR calculate_pos_by_distance
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

calculate_pos_by_distance:
LDA DIRECTION_FOR_CALCULATION
AND TOP
BEQ else_bottom
LDA POSITION_TO_CALCULATE
SBC #$10
STA POSITION_TO_CALCULATE
RTS
else_bottom:
LDA DIRECTION_FOR_CALCULATION
AND BOTTOM
BEQ else_left
LDA POSITION_TO_CALCULATE
ADC #$10
STA POSITION_TO_CALCULATE
RTS
else_left:
LDA DIRECTION_FOR_CALCULATION
AND LEFT
BEQ else_right
LDA POSITION_TO_CALCULATE
AND BITMASK_VALUES
BNE not_at_start
LDA POSITION_TO_CALCULATE
ADC #$10
not_at_start:
DEC
STA POSITION_TO_CALCULATE
RTS
else_right:
LDA DIRECTION_FOR_CALCULATION
AND RIGHT
BEQ end_check_input
LDA POSITION_TO_CALCULATE
INC
AND BITMASK_VALUES
BNE not_at_end
LDA POSITION_TO_CALCULATE
SBC #$10
not_at_end:
DEC
STA POSITION_TO_CALCULATE
end_check_input:
RTS

update_distances:
; check if i have length = 1
LDX TAIL_PAGE_POSITION
EOR MAX
BNE update_tail_position
; set tail in head position
LDA HEAD_POSITION
STA TAIL_POSITION
RTS
update_tail_position:
; get opposite of current direction
LDA DIRECTION
JSR get_opposite_direction
LDA MAX
SBC TAIL_PAGE_POSITION
TAY
; now in Y i have snake length
LDX #$FE
LDA #$01
STA FIRST_LOOP_ITERATION
start_loop_update_distance:
LDA FIRST_LOOP_ITERATION
BEQ not_first_iteration
LDA ZERO
STA FIRST_LOOP_ITERATION
LDA $00, X
AND BITMASK_DIRECTION
CLC
LSR A
LSR A
LSR A
LSR A
CMP DIRECTION_TO_INVERT
; -------------------------------------- I'M HERE! I compare first direction with incoming direction (DIRECTION_TO_INVERT)
BNE not_the_same

not_the_same:
not_first_iteration:
DEX
DEY
BNE start_loop_update_distance
end_start_loop_update_distance:

; remove last distance
LDX TAIL_PAGE_POSITION
DEC $00, X
LDA $00, X
AND BITMASK_VALUES
; if last distance become XXXX0000 shift all distances
BNE not_shift_distances
JSR shift_distances
; add new distance
not_shift_distances:
RTS

get_opposite_direction:
LDA DIRECTION_TO_INVERT
AND TOP
BEQ else_bottom_direction
LDA BOTTOM
STA DIRECTION_TO_INVERT
RTS
else_bottom_direction:
LDA DIRECTION_TO_INVERT
AND BOTTOM
BEQ else_left_direction
LDA TOP
STA DIRECTION_TO_INVERT
RTS
else_left_direction:
LDA DIRECTION_TO_INVERT
AND LEFT
BEQ else_right_direction
LDA RIGHT
STA DIRECTION_TO_INVERT
RTS
else_right_direction:
LDA DIRECTION_TO_INVERT
AND RIGHT
BEQ end_check_direction
LDA LEFT
STA DIRECTION_TO_INVERT
end_check_direction:
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