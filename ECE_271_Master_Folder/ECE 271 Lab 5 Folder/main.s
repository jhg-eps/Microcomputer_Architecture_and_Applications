;******************** (C) Yifeng ZHU ********************
; @file    main.s
; @author  Joseph Garcia
; V1.0.0
; @date    Feb-15-2014
; @note   This code does full and half-stepping so that the stepper motor can rotate 360 degrees. The cool thing is having the motor 
;rotate in reverse by only switching an array component 
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
				 ;Enable GPIOB clock
				LDR r7, =RCC_BASE          ; put address of RCC (reset and Clock Control address) into r7
				
				LDR r1, [r7, #RCC_AHBENR]     ; load memory address of r7 into r1 w/ pre-indexing, r1 = r7 + offset of RCCHABENR 
				ORR r1, r1, #RCC_AHBENR_GPIOBEN     ;OR ing result of r1 | RCC_AHBENR_GPIOBEN stored into r1
				STR r1, [r7, #RCC_AHBENR]        ;enables GPIOB clock by storing back r1 into r7, which has RCC_AHBENR offset
				
				;Initialize Pins PB12,PB13,PB14,PB15, using GPIO MODER offset from GPIOB_BASE
				
				LDR r7, =GPIOB_BASE    ; load into r7 the GPIO port B base address (pseudo instruction)
				LDR r1, [r7, #GPIO_MODER] ; r1 is assigned r7 w/ GPIO_MODER offset
				BIC r1, r1, #0xffffffff		;mask pins PB12-15, clear them for setting
				ORR r1, r1, #0x55000000		; toggle bits to set the pins as output (function 01)						
				STR r1, [r7, #GPIO_MODER]   ; stores r1 into r7 w/ GPIO_MODER offset

				; Set Port B Pin 12, 13, 14, 15 as Push-Pull Output Type
				LDR r1, [r7, #GPIO_OTYPER]          ; r1 = GPIOB->OTYPER
				BIC r1, r1, #(0xF000)	        	; Dir mask Pin 12-15, Clear bit 12-15
				ORR r1, r1, #0x0					; Push-Pull(0, reset), Open Drain(1)
				STR r1, [r7, #GPIO_OTYPER]			; OTYPER (16-bit): output type register
				
				; Update pull-up pull down registry
				LDR r1, [r7, #GPIO_PUPDR]    
				BIC r1, r1, #0xFF000000
				ORR r1, r1, #0x0
				STR r1, [r7, #GPIO_PUPDR]


num_of_steps    EQU 48      ; number of times the program will run the 4 step routine
num_of_substeps EQU 4	; number of components in 4 member array of 4 bit commands
time_constant   EQU 2000  ; time delay constant  
fullstep_array	DCD 	0x9,0xA,0x6,0x5   ; array of 4 pin commands for full stepping

half_substeps	EQU 8  ; number of components in 8 member 4 bit command array
halfstep_array  DCD     0xA, 0x8, 0x9, 0x1, 0x5, 0x4, 0x6, 0x2 ; array of 8 4pin commands for half-stepping
rvs_hs_array	DCD		0x2, 0x6, 0x4, 0x5, 0x1, 0x9, 0x8, 0xA	; array of 8 4pin commands for reverse half-stepping				
 
				 ;full-stepping routine
				LDR r2, = fullstep_array  ; r2 is given base address of pin array, which corresponds to pin A  (acts as pointer) 				
				LDR r3, [r7, #GPIO_ODR]     ; r3 is given base address of GPIO_ODR offset from GPIO_Base
				
				; counter register initializations
				MOV r8, #0x00000000     ; the variable for the number of steps                                              
				MOV r0, #0x00000004     ; main loop counter index variable
				MOV r11, #0x00000000	; secondary loop index counter variable
				MOV r9, #0x00000000     ; third loop time counter variable

				; full-stepping routine
loopprime       CMP r8, #num_of_steps			; step <= num_of_steps				
				BEQ done                        ; branch to end of program
				BNE secondaryloop     			; if r8 <= 48

secondaryloop	CMP r11, #num_of_substeps      ; r11 <= 4 (8 w/ half-stepping)
				BEQ stepcalc					; if (r11 = 4 (8 w/  half-stepping))
				LDR r5, [r2, r11, LSL #2]		; r5 = fullstep_array[r11];											
				MOV r4, r5						; r5 = r4 (temporarily)
				BIC r3, #(15<<12)				; clear bits 12-15 
				MOV r3, r4, LSL #12				; assign GPIO->ODR pins 12-15 as 1 or 0
				STR r3, [r7, #GPIO_ODR]         ; store into GPIO ODR register the bit assignments
				
delayloop		CMP r9, #time_constant                   ; r9 <= time constant, delay loop to let solenoids stay activated
				BEQ returntoloop
				;do nothing in this loop
				ADD r9, r9, #1
				b delayloop

returntoloop	MOV r9, #0              ;reinitialize delay loop counter variable
				ADD r11, r11, #1  		; r11 = r11 + 1
				b secondaryloop

stepcalc		MOV r11, #0             ; end of loop for incrementing thgrough halfstep/fullstep command arrays
				ADDS r8, r8, #4         ; r8 = r8+4, incrementing until 48 (num_of_steps) is reached
				b loopprime				; branch back to loopprime
done 			                             ; end of program
				ENDP
				END

; half-stepping/reverse half-stepping routine
; to use normal halfstepping, use halfstep_array

				 ;pointer type registers 
				LDR r2, = halfstep_array  ; r2 is given base address of pin array, which corresponds to pin A  (acts as pointer) 				
				LDR r3, [r7, #GPIO_ODR]     ; r3 is given base address of GPIO_ODR offset from GPIO_Base
				
				; counter register initializations
				MOV r8, #0x00000000     ; the variable for the number of steps                                              
				MOV r0, #0x00000004     ; main loop counter index variable
				MOV r11, #0x00000000	; secondary loop index counter variable
				MOV r9, #0x00000000     ; third loop time counter variable
				MOV r12, #1250

loopprime       CMP r8, #num_of_steps			; step < num_of_steps				
				BEQ done                       ; branch to end of program
				BNE secondaryloop     

secondaryloop	CMP r11, #half_substeps
				BEQ stepcalc
				LDR r5, [r2, r11, LSL #2]													
				MOV r4, r5
				BIC r3, #(15<<12)
				MOV r3, r4, LSL #12
				STR r3, [r7, #GPIO_ODR]
				
delayloop		CMP r9, #time_constant
				BEQ returntoloop
				;do nothing in this loop
				ADD r9, r9, #1
				b delayloop

returntoloop	MOV r9, #0
				ADD r11, r11, #1
				b secondaryloop

stepcalc		MOV r11, #0
				ADDS r8, r8, #4
				b loopprime
done 			              
				;;1 Configure RCC_AHBENR to enable clock of GPIO Port B
				;LDR r0, =RCC_BASE              ; load address of reset and clock control
				;LDR r1, [r0, #RCC_AHBENR]      ; load RCC_AHBENR offset into r1 target register 
				;BIC r1, r1, #RCC_AHBENR_GPIOBEN
				;ORR r1, r1, #RCC_AHBENR_GPIOBEN  ; enable GPIO Clock B
				;STR r1, [r0, #RCC_AHBENR]        ; store the enabling of GPIO Clock B
				
				;;2 enable the TIMER clock for Timer 4
				;LDR r0, =RCC_BASE
				;LDR r1, [r0, #RCC_APB1ENR]
				;BIC r1, r1, #RCC_APB1ENR_TIM4EN 
				;ORR r1, r1, #RCC_APB1ENR_TIM4EN 
				;STR r1, [r0, #RCC_APB1ENR]   ; store into r1 the register r0 with offset APB1ENR after setting timer 4 active
				
				;;3 Configure PB 6 (Blue LED), PB 7(Green LED) as Alternative Function Mode
				;LDR r0, =GPIOB_BASE
				;LDR r1, [r0, #GPIO_MODER]
				;BIC r1, r1, #0x0000F000    
				;ORR r1, r1, #0x0000A000
				;STR r1, [r0, #GPIO_MODER]
				
				;;4a configure and select the correct alternative function for PB6 and PB7
				;LDR r1, [r0, #GPIO_AFR0]
				;BIC r1, r1, #0xFF000000
				;ORR r1, r1, #0x22000000
				;STR r1, [r0, #GPIO_AFR0]
								
				;;5a set the prescaler (which allows frequency modulation???)
				;LDR r0, =TIM4_BASE
				;LDR r1, [r0, #TIM_PSC]
				;MOV r2, #TIM_PSC_PSC
				;BIC r1, r1, r2  ; mask
				;ORR r1, r1, #0x1  
				;STR r1, [r0, #TIM_PSC]
				
				;;5b set the auto reload value
				;LDR r1, [r0, #TIM_ARR]
				;MOV r2, #TIM_ARR_ARR
				;BIC r1, r1, r2 ; 
				;ORR r1, r1, #0x000000C8  ; switches direction value at 200
				;STR r1, [r0, #TIM_ARR]
				
				;;5c set PWM Mode 1 on Channel 1, PWM MODE 2 for channel 2 (for cool thing) 
				;LDR r1, [r0, #TIM_CCMR1]
				;BIC r1, r1, #TIM_CCMR1_OC1M
				;ORR r1, r1, #0x60     ; set OC1M as 110, PWM Mode 1
				;BIC r1, r1, #TIM_CCMR1_OC2M  
				;ORR r1, r1, #0x7000      
				
				;; 5c part 2: enable output preload for channel 1
				;BIC r1, r1, #0x800     
				;BIC r1, r1, #0x8
				;ORR r1, r1, #0x800 
				;ORR r1, r1, #0x8
				;STR r1, [r0, #TIM_CCMR1]
				
				;;6a enable auto-reload preload for Channel 1 and Channel 2(TIM4_CR1)
				;MOV r1, #0
				;LDR r1, [r0, #TIM_CR1]
				;BIC r1, r1, #0x80
				;ORR r1, r1, #0x80
				;STR r1, [r0, #TIM_CR1]
				
				;; 7 enable output for Channel 1 and Channel 2
				;LDR r1, [r0, #TIM_CCER]
				;;BIC r1, r1, #0x1
				;ORR r1, r1, #0x11 ; enable both CH 1 and CH 2           
				;ORR r1, r1, #0x22 ; activate them as high polarity       
				;STR r1, [r0, #TIM_CCER]
				
				;;8 enable output compare register for Channel 1
				;LDR r1, [r0, #TIM_CCR1]
				;MOV r2, #0xFFFF
				;BIC r1, r1, r2 ; or ffff
				;ORR r1, r1, #0x00
				;STR r1, [r0, #TIM_CCR1]
				
				;;9 enable the counter for Channel 1
				;LDR r1, [r0, #TIM_CR1]
				;ORR r1, r1, #0x1
				;STR r1, [r0, #TIM_CR1]
				
;brightness 		RN 3
;direction		RN 4
;delay_constant	EQU 4000

				;MOV r5, #0x0      ; delay loop counter variable
				;MOV brightness, #1  ; brightness = 1
				;MOV direction, #1   ; direction = 1
	
	
;primary_loop    CMP brightness, #199   ; r1 < / >= 199 ?
				;BLO bright_test ; if( r1 <199)
				;BGE continue_loop   ; if (r1  >=199)

;bright_test		CMP brightness, #0 ; brightness > 0 ?
				;BGT bright_test_y ; if (brightness > 0)
				;BLE continue_loop ; if (brightness <= 0)
;continue_loop	RSB direction, direction, #0   ; direction = 0 - direction
;bright_test_y	ADD brightness, brightness, direction ; brightness = brightness + direction
				
				;STR brightness, [r0, #TIM_CCR1]  ; TIM_CCR1 = brightness, PWM 1, Blue LED lights when CNT is above CCR value
				;STR brightness, [r0, #TIM_CCR2]  ; TIM_CCR2 = brightness, PWM 2, Green LED lights when CNT is below CCR value
				
;time_delay		CMP r5, #delay_constant    ; r5 < delay_constant ?
				;BEQ reinit_r5
				;;do nothing as this is a time delay      ; delay loop
				;ADD r5, r5, #1
				;B time_delay

;reinit_r5		MOV r5, #0   ; reset delay loop variable
				;B primary_loop  ; branch back to inifinite lighting loop

				;ENDP
				
				END
