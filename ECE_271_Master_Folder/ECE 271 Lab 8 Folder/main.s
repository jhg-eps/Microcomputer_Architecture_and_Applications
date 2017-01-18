
;******************** (C) Yifeng ZHU ********************
; @file    main.s
; @author  
; V1.0.0
; @date    April 3, 2014
; @note    This code uses an ultrasonic tone generator and sensor to measure the distance from the sensor to a nearby ;          object.
; @brief   Assembly code for STM32L1xx Discovery Kit
;********************************************************


; STM32L1xx Discovery Kit:
;    - USER Pushbutton: connected to PA0 (GPIO Port A, PIN 0), CLK RCC_AHBENR_GPIOAEN
;    - RESET Pushbutton: connected RESET
;    - GREEN LED: connected to PB7 (GPIO Port B, PIN 7), CLK RCC_AHBENR_GPIOBEN 
;    - BLUE LED: connected to PB6 (GPIO Port B, PIN 6), CLK RCC_AHBENR_GPIOBEN
;    - Linear touch sensor/touchkeys: PA6, PA7 (group 2),  PC4, PC5 (group 9),  PB0, PB1 (group 3)

    INCLUDE stm32l1xx_constants.s  ; Load Constant Definitions
 ;   INCLUDE core_cm3_constant.s

 AREA    main, CODE, READONLY

    EXPORT __main      ; make __main visible to linker

    ENTRY

    

;*************************************************************************************************  ; begin main    

__main   PROC

    

    BL GPIO_CLK_INIT
    BL INTERRUPT_ABLE
    BL PRT_2_INIT
	MOV R2, #0      ; old value
	MOV R3, #0  ; new value
    MOV R4, #0      ; period (new value - old value)
  
while_cond  B while_cond      ; while(1) loop to make sure programs run forever

     ENDP         

     

;************************************************************************************************* ; end main    

GPIO_CLK_INIT PROC

    ; Enable Clock for GPIO Port B 

    LDR R0, =RCC_BASE 
	LDR R1, [R0, #RCC_AHBENR]
	BIC R1, R1, #RCC_AHBENR_GPIOBEN
	ORR R1, R1, #RCC_AHBENR_GPIOBEN        ; verified
	STR R1, [R0, #RCC_AHBENR]

    ; Set Pb6 as Alternative Function

    LDR R0, = GPIOB_BASE
    LDR R1, [R0, #GPIO_MODER]
	BIC R1, R1, #0x00003C00    
    ORR R1, R1, #0x00002400             ; possibly verified
    STR R1, [R0, #GPIO_MODER]

	; Set PB6 and as alternative function 2

    LDR R1, [R0, #GPIO_AFR0]
    BIC R1, R1, #0x0F000000
    ORR R1, R1, #0x02000000     ; verified
    STR R1, [R0, #GPIO_AFR0]

   ;ECHO PIN PB6 as no PU NO PD

    LDR R1, [R0, #GPIO_PUPDR]
	BIC R1, R1, #0x3C00          ; possibly verified 3C00 would set pb5 and pb6 as no pupd  
	STR R1, [R0, #GPIO_PUPDR] 
	
    ; turn off Blue LED to begin the program properly   

    LDR R1, [R0, #GPIO_ODR]
    BIC R1, R1, #0x4
    STR R1, [R0, #GPIO_ODR]     ; verified
	
    ; Enable the Clock of Timer 4

    LDR R0, = RCC_BASE
    LDR R1, [R0, #RCC_APB1ENR]
    BIC R1, R1, #RCC_APB1ENR_TIM4EN   ; verified
    ORR R1, R1, #RCC_APB1ENR_TIM4EN
    STR R1, [R0, #RCC_APB1ENR]

    ; Set the prescaler to configure the frequency of the free-run counter (should be zero)

    LDR R0, =TIM4_BASE
    LDR R1, [R0, #TIM_PSC]
    BIC R1, R1, #0xFF  ; clear all bits     ; verified
    ORR R1, R1, #2096
    STR R1, [R0, #TIM_PSC]
	
    ; Select the active input

    LDR R1, [R0, #TIM_CCMR1]
    BIC R1, R1, #TIM_CCMR1_CC1S           ; verified
    ORR R1, R1, #0x1                         
    STR R1, [R0, #TIM_CCMR1]                      


    ; Select the edge of the active transition (rising edge or falling edge)
    LDR R1, [R0, #TIM_CCER]
    ORR R1, R1, #0x0000000A   ; verified captures rising and falling edge.
    
    ; Enable Capture from the Counter (set enable to  1)

    LDR R1, [R0, #TIM_CCER]
    ORR R1, R1,#TIM_CCER_CC1E             ; verified
    STR R1, [R0, #TIM_CCER]
	
    ;Enable the interrupt

    LDR R1, [R0, #TIM_DIER]
    ORR R1, R1, #TIM_DIER_CC1IE  ; Capture/Compare for Channel 1 Enabled
    ;ORR R1, R1, #TIM_DIER_CC1DE  ; Capture/Compare DMA request Enabled         ; verified 
    STR R1, [R0, #TIM_DIER]

	; Enable the counter

    LDR R1, [R0, #TIM_CR1]
    ORR R1, R1, #TIM_CR1_CEN        ; verified
    STR R1, [R0, #TIM_CR1]

    BX LR

    ENDP

    

INTERRUPT_ABLE  PROC
  

    ; Enable the interrupt priority

    LDR R1, [R0, #NVIC_IPR0]
    ORR R1, R1, #NVIC_IPR0_PRI_1   ; verified
    STR R0, [R0, #NVIC_IPR0]

    ; Enable the interrupt TIM4_IRQn

    LDR r0, =NVIC_BASE
    LDR r1, [R0,#NVIC_ISER0]
    BIC R1, R1, #NVIC_ISER_SETENA_30         ; verified
	ORR R1, R1, #NVIC_ISER_SETENA_30
	STR R1, [R0, #NVIC_ISER0]

    BX LR

    ENDP
 

PRT_2_INIT  PROC

    ;  initializations for part 2 of  lab to go here. (where signal comes from PB5 and goes into PB6, as opposed to just putting
    ; signals into PB6 from the function generator) as was done in part 1.
    ; Configure RCC_APB1ENR to enable clock of Timer 3

    LDR R0, =RCC_BASE
    LDR R1, [R0, #RCC_APB1ENR]
    ORR R1, R1, #RCC_APB1ENR_TIM3EN               ; verified
    STR R1, [R0, #RCC_APB1ENR]

    ; Configure Timer 3 with PSC, CCR, and ARR values to generate a pulse of 10 us

    ; no autoreload preload enable necessary

    LDR R0, =TIM3_BASE
    LDR R1, [R0, #TIM_PSC]
    BIC R1, R1, #0    ; verified
    STR R1, [R0, #TIM_PSC]

    LDR R1, [R0, #TIM_CCR1]
    BIC R1, R1, #21
    ORR R1, R1, #21    ; verified
    STR R1, [R0, #TIM_CCR1]

    LDR R1, [R0, #TIM_ARR]
    BIC R1, R1, #42
    ORR R1, R1, #42    ; verified
    STR R1, [R0, #TIM_ARR]

    ; Configure Timer 3 CR1 with "One Pulse Mode" (TIM_CR1_OPM)

    LDR R1, [R0, #TIM_CR1]
    BIC R1, R1, #0x8    ; verified
    ORR R1, R1, #0x8
    STR R1, [R0, #TIM_CR1]
	
    ; Enable Channel 2 in CCER register (PB5 Timer 3, Channel 2)

    LDR R1, [R0, #TIM_CCER]
    BIC R1, R1, #0x10
    ORR R1, R1, #0x10
    STR R1, [R0, #TIM_CCER]    ; verified

    ; Enable Timer 3 in CR1 register

    LDR R1, [R0, #TIM_CR1]
    BIC R1, R1, #0x1     ; verified
    ORR R1, R1, #0x1
    STR R1, [R0, #TIM_CR1]

    BX LR 

    ENDP 

     

TIM4_IRQHandler PROC                            ; interrupt routine 

    EXPORT TIM4_IRQHandler
		
    MOV r7, #148
    MOV r6, #2
	
    LDR R0, =TIM4_BASE
    LDR R1, [R0, #TIM_SR]     ; R1 = TIM_SR Register
    AND R1, R1, #TIM_SR_CC1IF
    CMP R1, #0   ; (TIM4->SR & TIM_SR_CC1IF) !=0
    BNE continue ; wait for the UIF flag to be set to 1
    BEQ wait
	
continue  LDR R1, [R0, #TIM_CCR1]  ; r1 = address of R0, offset of TIM_CCR1

    MOV R3, R1    ; r3 = r1 value
    SUB R4, R3, R2           ;r4 = r3 - r2  (difference between new value and old value in time) 
    MOV R2, R3              ; r2 = old value
    UDIV r8, r4, r7   ; r8 = distance
    UDIV r8, r8, r6   ; total distance/2

    LDR R0, =GPIOB_BASE
    LDR R1, [R0, #GPIO_ODR]
    EOR R1, R1, #0x40  ; LED goes on at rising edge, goes off at falling edge
    STR R1, [R0, #GPIO_ODR]  ; In other words, each time the ISR is called, the light is toggled

    
wait LDR R1, [R0, #TIM_SR]
     BIC R1, R1, #TIM_SR_CC1IF
     STR R1, [R0, #TIM_SR]

    BX LR  

    ENDP

     

    END  