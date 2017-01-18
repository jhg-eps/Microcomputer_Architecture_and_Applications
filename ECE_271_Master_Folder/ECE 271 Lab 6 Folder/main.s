;******************** (C) Yifeng ZHU ********************
; @file    main.s
; @author  Joseph Garcia
; V1.0.0
; @date    Feb-15-2014
; @note   This code uses PWM to have the blue LED and green LED on the STM32L Discovery Board brighten and dim 180 degrees ;         out of phase with each other
; @brief   Assembly code for STM32L1xx Discovery Kit
;********************************************************

; STM32L1xx Discovery Kit:
;    - USER Pushbutton: connected to PA0 (GPIO Port A, PIN 0), CLK RCC_AHBENR_GPIOAEN
;    - RESET Pushbutton: connected RESET
;    - GREEN LED: connected to PB7 (GPIO Port B, PIN 7), CLK RCC_AHBENR_GPIOBEN 
;    - BLUE LED: connected to PB6 (GPIO Port B, PIN 6), CLK RCC_AHBENR_GPIOBEN
;    - Linear touch sensor/touchkeys: PA6, PA7 (group 2),  PC4, PC5 (group 9),  PB0, PB1 (group 3)

; r0 (constant #4, r8 = r8+r0)
; r1 The GPIO_MODER offset of r7
; r2 base address of halfstep_array, full
; r3 base address of GPIO_ODR register
; r4 (temporary storage of r5)                                                           												
; r5 (stores substep/halfstep array index values)
; r6 (not used)
; r7  (RCC_Base register)
; r8(counter variable for 48 step routine)
; r9  (delay loop counter variable)
; r10 (not used)
; r11  (substep routine counter variable)
; r12 (not used)
; r13 (Stack Pointer)
; r14 (link register)
; r15 (program counter)									

				INCLUDE stm32l1xx_constants.s		; Load Constant Definitions
				INCLUDE core_cm3_constant.s
								
				
				AREA    main, CODE
				EXPORT	__main						; make __main visible to linker
				ENTRY
				
__main			PROC         
											 ;begins procedure of command section 		              
				;1 Configure RCC_AHBENR to enable clock of GPIO Port B
				LDR r0, =RCC_BASE              ; load address of reset and clock control
				LDR r1, [r0, #RCC_AHBENR]      ; load RCC_AHBENR offset into r1 target register 
				BIC r1, r1, #RCC_AHBENR_GPIOBEN
				ORR r1, r1, #RCC_AHBENR_GPIOBEN  ; enable GPIO Clock B
				STR r1, [r0, #RCC_AHBENR]        ; store the enabling of GPIO Clock B
				
				;2 enable the TIMER clock for Timer 4
				LDR r0, =RCC_BASE
				LDR r1, [r0, #RCC_APB1ENR]
				BIC r1, r1, #RCC_APB1ENR_TIM4EN 
				ORR r1, r1, #RCC_APB1ENR_TIM4EN 
				STR r1, [r0, #RCC_APB1ENR]   ; store into r1 the register r0 with offset APB1ENR after setting timer 4 active
				
				;3 Configure PB 6 (Blue LED), PB 7(Green LED) as Alternative Function Mode
				LDR r0, =GPIOB_BASE
				LDR r1, [r0, #GPIO_MODER]
				BIC r1, r1, #0x0000F000    
				ORR r1, r1, #0x0000A000
				STR r1, [r0, #GPIO_MODER]
				
				;4a configure and select the correct alternative function for PB6 and PB7
				LDR r1, [r0, #GPIO_AFR0]
				BIC r1, r1, #0xFF000000
				ORR r1, r1, #0x22000000
				STR r1, [r0, #GPIO_AFR0]
								
				;5a set the prescaler (which allows frequency modulation???)
				LDR r0, =TIM4_BASE
				LDR r1, [r0, #TIM_PSC]
				MOV r2, #TIM_PSC_PSC
				BIC r1, r1, r2  ; mask
				ORR r1, r1, #0x1  
				STR r1, [r0, #TIM_PSC]
				
				;5b set the auto reload value
				LDR r1, [r0, #TIM_ARR]
				MOV r2, #TIM_ARR_ARR
				BIC r1, r1, r2 ; 
				ORR r1, r1, #0x000000F0  ; switches direction value at 200
				STR r1, [r0, #TIM_ARR]
				
				;5c set PWM Mode 1 on Channel 1, PWM MODE 2 for channel 2 (for cool thing) 
				LDR r1, [r0, #TIM_CCMR1]
				BIC r1, r1, #TIM_CCMR1_OC1M
				ORR r1, r1, #0x60     ; set OC1M as 110, PWM Mode 1
				BIC r1, r1, #TIM_CCMR1_OC2M  
				ORR r1, r1, #0x7000      
				
				; 5c part 2: enable output preload for channel 1
				BIC r1, r1, #0x800     
				BIC r1, r1, #0x8
				ORR r1, r1, #0x800 
				ORR r1, r1, #0x8
				STR r1, [r0, #TIM_CCMR1]
				
				;6a enable auto-reload preload for Channel 1 and Channel 2(TIM4_CR1)
				MOV r1, #0
				LDR r1, [r0, #TIM_CR1]
				BIC r1, r1, #0x80
				ORR r1, r1, #0x80
				STR r1, [r0, #TIM_CR1]
				
				; 7 enable output for Channel 1 and Channel 2
				LDR r1, [r0, #TIM_CCER]
				;BIC r1, r1, #0x1
				ORR r1, r1, #0x11 ; enable both CH 1 and CH 2           
				ORR r1, r1, #0x22 ; activate them as high polarity       
				STR r1, [r0, #TIM_CCER]
				
				;8 enable output compare register for Channel 1
				LDR r1, [r0, #TIM_CCR1]
				MOV r2, #0xFFFF
				BIC r1, r1, r2 ; or ffff
				ORR r1, r1, #0x00
				STR r1, [r0, #TIM_CCR1]
				
				;9 enable the counter for Channel 1
				LDR r1, [r0, #TIM_CR1]
				ORR r1, r1, #0x1
				STR r1, [r0, #TIM_CR1]
				
brightness 		RN 3
direction		RN 4
delay_constant	EQU 4000

				MOV r5, #0x0      ; delay loop counter variable
				MOV brightness, #1  ; brightness = 1
				MOV direction, #1   ; direction = 1
	
	
primary_loop    CMP brightness, #199   ; r1 < / >= 199 ?
				BLO bright_test ; if( r1 <199)
				BGE continue_loop   ; if (r1  >=199)

bright_test		CMP brightness, #0 ; brightness > 0 ?
				BGT bright_test_y ; if (brightness > 0)
				BLE continue_loop ; if (brightness <= 0)
continue_loop	RSB direction, direction, #0   ; direction = 0 - direction
bright_test_y	ADD brightness, brightness, direction ; brightness = brightness + direction
				
				STR brightness, [r0, #TIM_CCR1]  ; TIM_CCR1 = brightness, PWM 1, Blue LED lights when CNT is above CCR value
				STR brightness, [r0, #TIM_CCR2]  ; TIM_CCR2 = brightness, PWM 2, Green LED lights when CNT is below CCR value
								
time_delay		CMP r5, #delay_constant    ; r5 < delay_constant ?
				BEQ reinit_r5
				;do nothing as this is a time delay      ; delay loop
				ADD r5, r5, #1
				B time_delay

reinit_r5		MOV r5, #0   ; reset delay loop variable
				B primary_loop  ; branch back to inifinite lighting loop

				ENDP
				
				END
