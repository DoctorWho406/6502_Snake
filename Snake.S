; Time
.define VSYNC_COUNTER $0300
.define TIME $0301
.define FRAME #60
; Random
.define SEED $0302

; length of snake
.define SNAKE_LENGTH $0310
; where is the head
.define HEAD_POSITION $FF
; next head position
.define HEAD_NEXT_POSITION $0311
; where is the tail in zero page
.define TAIL_PAGE_POSITION $0312
; where is the tail
.define TAIL_POSITION $0313

; stored direction
.define DIRECTION $0320
; stored direction waiting to be validated
.define DIRECTION_VALIDATION $0321
; timer for game over
.define GAME_OVER_TIMER $0322

; args for SubRoutine calculate_pos_by_distance
.define POSITION_TO_CALCULATE  $0330
.define DIRECTION_FOR_CALCULATION  $0331
; flag for check if is firt loop iteration
.define FIRST_LOOP_ITERATION  $0332
; args for SubRoutine get_opposite_direction
.define DIRECTION_TO_INVERT  $0333
; flag for check if I need to move directions
.define NO_MOVE_DIRECTIONS $0334
; tmp register for ster direction
.define TMP_DIRECTION_1 $0335
.define TMP_DIRECTION_2 $0336
; args for SubRoutine calculate_next_pos_by_distance
.define POSITION_TO_CALCULATE_NEXT  $0337
.define DIRECTION_FOR_CALCULATE_NEXT  $0338
; args for SubRoutine get_ripetition_and_direction
.define INPUT_DIRECTION $0339
.define OUTPUT_REPETITION $033A
.define OUTPUT_DIRECTION $033B

.define INPUT $4000
.define TOP #$01
.define BOTTOM #$02
.define LEFT #$04
.define RIGHT #$08

.define ZERO #$00
.define MAX #$FF
.define BITMASK_VALUES #$0F
.define BITMASK_REPETITION #$F0
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
    ; set SNAKE_LENGTH to 0
    STA SNAKE_LENGTH
    ; set head and tail position to $00
    STA TAIL_POSITION
    STA HEAD_POSITION
    ; set head next to $00
    STA HEAD_NEXT_POSITION
    ; set initial direction to $00
    STA DIRECTION
    ; set seed to 0
    STA SEED
    ; spawn apple in middle of screen
    LDA APPLE_COLOR
    STA $0287
    ; set tail page position to $FF
    LDA MAX
    STA TAIL_PAGE_POSITION
    ; draw snake
    LDX TAIL_POSITION
    LDA SNAKE_COLOR
    STA $0200, X

    main_loop:
    ; ------------------------ READ INPUT ------------------------
    LDA INPUT
    ; store input only if is not queal to 0 ...
    BEQ else_store_input
    ; ... AND not opposito of current direction
    STA DIRECTION_VALIDATION
    STA DIRECTION_TO_INVERT
    JSR get_opposite_direction
    LDA DIRECTION_TO_INVERT
    CMP DIRECTION
    BEQ else_store_input
    LDA DIRECTION_VALIDATION
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
    LDA DIRECTION
    STA DIRECTION_FOR_CALCULATION
    JSR calculate_pos_by_distance
    LDA POSITION_TO_CALCULATE
    STA HEAD_NEXT_POSITION
    ; check if hit something 
    TAX
    LDA $0200, X
    CMP SNAKE_COLOR
    ;                               TODO Check if not is tail
    BEQ game_over
    ; check if hit apple 
    CMP APPLE_COLOR
    BNE not_apple
    INC SNAKE_LENGTH
    JSR update_distances
    ; draw new apple
    JSR random
    LDX SEED
    LDA APPLE_COLOR
    STA $0200, X
    ; ----------------------------------------------------------- I'M HERE
    ; LDA HEAD_NEXT_POSITION
    ; STA HEAD_POSITION
    not_apple:
    ; ------------------------- DRAW ----------------------------
    ; clear old tail
    LDX TAIL_POSITION
    LDA ZERO
    STA $0200, X
    ; --------------------- TAIL POSITION -----------------------
    ; update distances
    JSR update_distances
    ; save new head position
    LDA HEAD_NEXT_POSITION
    STA HEAD_POSITION
    ; ------------------------- DRAW ----------------------------
    ; draw head
    TAX
    LDA SNAKE_COLOR
    STA $0200, X
JMP main_loop

calculate_pos_by_distance:
    PHA                             ; globbering
    LDA DIRECTION_FOR_CALCULATION
    AND TOP
    BEQ else_bottom
    LDA POSITION_TO_CALCULATE
    SEC
    SBC #$10
    STA POSITION_TO_CALCULATE
    PLA                             ; globbering
    RTS
    else_bottom:
    LDA DIRECTION_FOR_CALCULATION
    AND BOTTOM
    BEQ else_left
    LDA POSITION_TO_CALCULATE
    ADC #$10
    STA POSITION_TO_CALCULATE
    PLA                             ; globbering
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
    STA POSITION_TO_CALCULATE
    not_at_start:
    DEC POSITION_TO_CALCULATE
    PLA                             ; globbering
    RTS
    else_right:
    LDA DIRECTION_FOR_CALCULATION
    AND RIGHT
    BEQ end_check_input
    LDA POSITION_TO_CALCULATE
    ADC #$01
    AND BITMASK_VALUES
    BNE not_at_end
    LDA POSITION_TO_CALCULATE
    SEC
    SBC #$10
    STA POSITION_TO_CALCULATE
    not_at_end:
    INC POSITION_TO_CALCULATE
    end_check_input:
    PLA                             ; globbering
    RTS
    
random:
    PHA                             ; globbering
    LDA	SEED	; get seed
	AND	#$B8	; mask non feedback bits
				; for maximal length run with 8 bits we need
				; taps at b7, b5, b4 and b3
	LDX	#$05	; bit count (shift top 5 bits)
	LDY	#$00	; clear feedback count
f_loop:
	ASL	A		; shift bit into carry
	BCC	bit_clr		; branch if bit = 0

	INY			; increment feedback count (b0 is XOR all the
				; shifted bits from A)
bit_clr:
	DEX			; decrement count
	BNE	f_loop	; loop if not all done
no_clr:
	TYA			; copy feedback count
	LSR	A		; bit 0 into Cb
	LDA	SEED	; get seed back
	ROL	A		; rotate carry into byte
	STA	SEED	; save number as next seed
    PLA                             ; globbering
	RTS			; done

update_distances:
    PHA                             ; globbering
    ; check if i have length == 1
    LDA SNAKE_LENGTH
    BNE update_tail_position
    ; set tail in future head position
    LDA HEAD_NEXT_POSITION
    STA TAIL_POSITION
    PLA                             ; globbering
    RTS
    update_tail_position:
    ; get opposite of current direction
    LDA DIRECTION
    STA DIRECTION_TO_INVERT
    JSR get_opposite_direction
    LDA MAX
    SEC
    SBC TAIL_PAGE_POSITION
    TAY
    BNE no_zero_directions
    LDX MAX
    LDA $00, X
    STA POSITION_TO_CALCULATE_NEXT
    LDA DIRECTION_TO_INVERT
    CLC
    ASL A
    ASL A
    ASL A
    ASL A
    ADC #$01
    STA DIRECTION_TO_INVERT
    STA TMP_DIRECTION_1
    JMP end_start_loop_update_distance
    no_zero_directions:
    ; now in Y i have directions length
    LDX #$FE
    LDA #$01
    STA FIRST_LOOP_ITERATION
        start_loop_update_distance:
        LDA FIRST_LOOP_ITERATION
        BEQ not_first_iteration
        ; reset FIRST_LOOP_ITERATION
        LDA ZERO
        STA FIRST_LOOP_ITERATION
        ; compare first direction with DIRECTION_TO_INVERT
        LDA $00, X
        AND BITMASK_REPETITION
        CLC
        LSR A
        LSR A
        LSR A
        LSR A
        CMP DIRECTION_TO_INVERT
        BNE not_the_same
        ; Here i know tath last direction is equal to last
        ; Increse last direction
        INC $00, X
        ; set NO_MOVE_DIRECTIONS to "true"
        LDA #$01
        STA NO_MOVE_DIRECTIONS
        JMP end_compare_first_direction
        not_the_same:
        LDA DIRECTION_TO_INVERT
        CLC
        ASL A
        ASL A
        ASL A
        ASL A
        ADC #$01
        STA DIRECTION_TO_INVERT
        STA TMP_DIRECTION_1
        end_compare_first_direction:
        ; reset X to HEAD
        LDX MAX
        STA $00, X
        STA POSITION_TO_CALCULATE_NEXT
        not_first_iteration:
        DEX
            ; need to move?
            LDA NO_MOVE_DIRECTIONS
            BNE no_need_to_move_direction
            ; store current direction to TMP_DIRECTION_2
            LDA $00, X
            STA TMP_DIRECTION_2
            ; store TMP_DIRECTION_1 to current_position
            LDA TMP_DIRECTION_1
            STA $00, X
            ; store TMP_DIRECTION_1 to TMP_DIRECTION_2
            LDA TMP_DIRECTION_2
            STA TMP_DIRECTION_1
        no_need_to_move_direction:
        ; read and store current direction
        LDA $00, X
        STA DIRECTION_FOR_CALCULATE_NEXT
        JSR calculate_next_pos_by_distance
        DEY 
        BNE start_loop_update_distance
    end_start_loop_update_distance:
    ; need to move?
    LDA NO_MOVE_DIRECTIONS
    BNE no_need_to_move_last_direction
    DEX
    ; store TMP direction to current direction (new)
    LDA TMP_DIRECTION_1
    STA $00, X
    ; summ new direction to position
    STA DIRECTION_FOR_CALCULATE_NEXT
    JSR calculate_next_pos_by_distance
    ; disable NO_MOVE_DIRECTIONS
    LDA ZERO
    STA NO_MOVE_DIRECTIONS
    ; reduce tail page position
    DEC TAIL_PAGE_POSITION
    no_need_to_move_last_direction:
    ; save current tail position
    LDA POSITION_TO_CALCULATE_NEXT
    STA TAIL_POSITION
    PLA                             ; globbering
    RTS

get_opposite_direction:
    PHA                             ; globbering
    LDA DIRECTION_TO_INVERT
    AND TOP
    BEQ else_bottom_direction
    LDA BOTTOM
    STA DIRECTION_TO_INVERT
    PLA                             ; globbering
    RTS
    else_bottom_direction:
    LDA DIRECTION_TO_INVERT
    AND BOTTOM
    BEQ else_left_direction
    LDA TOP
    STA DIRECTION_TO_INVERT
    PLA                             ; globbering
    RTS
    else_left_direction:
    LDA DIRECTION_TO_INVERT
    AND LEFT
    BEQ else_right_direction
    LDA RIGHT
    STA DIRECTION_TO_INVERT
    PLA                             ; globbering
    RTS
    else_right_direction:
    LDA DIRECTION_TO_INVERT
    AND RIGHT
    BEQ end_check_direction
    LDA LEFT
    STA DIRECTION_TO_INVERT
    end_check_direction:
    PLA                             ; globbering
    RTS

calculate_next_pos_by_distance:
    PHA                             ; globbering
    TYA
    PHA                             ; globbering
    LDA DIRECTION_FOR_CALCULATE_NEXT
    STA INPUT_DIRECTION
    JSR get_ripetition_and_direction
    ; now i have direction AND repetition
    LDA POSITION_TO_CALCULATE_NEXT
    STA POSITION_TO_CALCULATE
    LDY OUTPUT_REPETITION
    BEQ end_loop_calculate_next_pos_by_distance
    loop_calculate_next_pos_by_distance:
    LDA OUTPUT_DIRECTION
    STA DIRECTION_FOR_CALCULATION
    JSR calculate_pos_by_distance
    DEY
    BEQ loop_calculate_next_pos_by_distance
    end_loop_calculate_next_pos_by_distance:
    LDA POSITION_TO_CALCULATE
    STA POSITION_TO_CALCULATE_NEXT
    PLA                             ; globbering
    TAY
    PLA                             ; globbering
    RTS
    
get_ripetition_and_direction:
    PHA                             ; globbering
    LDA INPUT_DIRECTION
    AND BITMASK_VALUES
    STA OUTPUT_DIRECTION
    LDA INPUT_DIRECTION
    AND BITMASK_REPETITION
    CLC
    LSR A
    LSR A
    LSR A
    LSR A
    STA OUTPUT_REPETITION
    PLA                             ; globbering
    RTS
    
nmi:
    PHA                             ; globbering
    DEC VSYNC_COUNTER
    BEQ reset_vsync
    LDA DIRECTION
    BEQ not_generate_seed
    LDA SEED
    BNE not_generate_seed
    LDA VSYNC_COUNTER
    STA SEED
    PLA                             ; globbering
    RTI
    reset_vsync:
    LDA FRAME
    STA VSYNC_COUNTER
    ; check_game_over
    LDA GAME_OVER_TIMER
    BEQ not_game_over
    DEC GAME_OVER_TIMER
    PLA                             ; globbering
    RTI
    not_game_over:
    ; check direction for first move
    LDA DIRECTION
    BEQ not_increase_time
    LDA #$01
    STA TIME
    LDA SEED
    BNE not_generate_seed
    LDA FRAME
    STA SEED
    not_generate_seed:
    not_increase_time:
    PLA                             ; globbering
    RTI

.goto $FFFA
.dw nmi ; non maskable
.dw start ; reset
.dw start ; interrupt