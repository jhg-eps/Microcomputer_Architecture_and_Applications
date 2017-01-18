;;******************** (C) Yifeng ZHU ********************
;; @file    main.s
;; @author  
;; V1.0.0
;; @date    Feb-07-2014
;; @note    In this lab, I use the TIM4 IRQ Handler in conjunction with the sine function to do DAC (in the form of         ;;    creating a 440Hz sine wave)
;; @brief   Assembly code for STM32L1xx Discovery Kit
;;********************************************************

;; STM32L1xx Discovery Kit:
;;    - USER Pushbutton: connected to PA0 (GPIO Port A, PIN 0), CLK RCC_AHBENR_GPIOAEN
;;    - RESET Pushbutton: connected RESET
;;    - GREEN LED: connected to PB7 (GPIO Port B, PIN 7), CLK RCC_AHBENR_GPIOBEN 
;;    - BLUE LED: connected to PB6 (GPIO Port B, PIN 6), CLK RCC_AHBENR_GPIOBEN
;;    - Linear touch sensor/touchkeys: PA6, PA7 (group 2),  PC4, PC5 (group 9),  PB0, PB1 (group 3)


				;INCLUDE stm32l1xx_constants.s		; Load Constant Definitions
				
		;AREA myData, DATA
		;ALIGN
		;EXPORT
			
;sin_data     ; DAC has 12 bits.
		;DCD	0x800,0x823,0x847,0x86b,0x88e,0x8b2,0x8d6,0x8f9,0x91d,0x940
		;DCD	0x963,0x986,0x9a9,0x9cc,0x9ef,0xa12,0xa34,0xa56,0xa78,0xa9a
		;DCD	0xabc,0xadd,0xaff,0xb20,0xb40,0xb61,0xb81,0xba1,0xbc1,0xbe0
		;DCD	0xc00,0xc1e,0xc3d,0xc5b,0xc79,0xc96,0xcb3,0xcd0,0xcec,0xd08
		;DCD	0xd24,0xd3f,0xd5a,0xd74,0xd8e,0xda8,0xdc1,0xdd9,0xdf1,0xe09
		;DCD	0xe20,0xe37,0xe4d,0xe63,0xe78,0xe8d,0xea1,0xeb5,0xec8,0xedb
		;DCD	0xeed,0xeff,0xf10,0xf20,0xf30,0xf40,0xf4e,0xf5d,0xf6a,0xf77
		;DCD	0xf84,0xf90,0xf9b,0xfa6,0xfb0,0xfba,0xfc3,0xfcb,0xfd3,0xfda
		;DCD	0xfe0,0xfe6,0xfec,0xff0,0xff4,0xff8,0xffb,0xffd,0xffe,0xfff
		;DCD	0xfff


				;AREA    main, CODE
				;EXPORT	__main						; make __main visible to linker
				;ENTRY
				
;__main			PROC

				;BL GPIO_RCC_INIT	
				;BL TIM_INIT
				;BL DAC_INIT
				
;dead_loop		b dead_loop 
				
				;ENDP
			
;GPIO_RCC_INIT		PROC

			;LDR R0, =RCC_BASE
			;LDR R1, [R0, #RCC_CR]
			;ORR R1, R1, #RCC_CR_HSION
			;STR R1, [R0, #RCC_CR]
			
			;; Wait for the HSI to be ready
;test_HSIRDY	LDR R1, [R0, #RCC_CR]
			;AND R2, R1, #0x00000002
			;CMP R2, #2
			;BEQ continue
			;BNE test_HSIRDY

			;; Select HSI as the system clock
;continue	LDR R1, [R0, #RCC_CFGR]
			;ORR R1, R1, #RCC_CFGR_SW_HSI ; ORR R1, R1, #0x00000001
			;STR R1, [R0, #RCC_CFGR]

				;; Wait until HSI is selected as System Clock
;HSI_Check	LDR r1, [r0, #RCC_CFGR]
			;AND r1, r1, #0xC
			;CMP r1, #4
			;BEQ second_continue
			;BNE HSI_Check
			
			;; enable the clock of GPIOA
;second_continue	LDR R0, =RCC_BASE
			;LDR R1, [R0, #RCC_AHBENR]
			;ORR R1, R1, #RCC_AHBENR_GPIOAEN
			;STR R1, [R0, #RCC_AHBENR]
			
			;; set PA4 and PA5 as analog (using MODER register)
			;LDR R0, =GPIOA_BASE
			;LDR R1, [R0, #GPIO_MODER]
			;BIC R1, R1, #0x00000F00
			;ORR R1, R1, #0x00000F00
			;STR R1, [R0, #GPIO_MODER]
			
			;;Configure TIM4 as Master Trigger
			
			;; enable the clock of TIM4 
			;LDR R0, =RCC_BASE
			;LDR R1, [R0, #RCC_APB1ENR]
			;ORR R1, R1, #RCC_APB1ENR_TIM4EN
			;STR R1, [R0, #RCC_APB1ENR]
			
			;BX LR
			;ENDP

;TIM_INIT	PROC
			
			;;Set the Prescaler
			;LDR R0, =TIM4_BASE
			;LDR R1, [R0, #TIM_PSC]
			;MOV R2, #TIM_PSC_PSC
			;BIC R1, R1, R2
			;ORR R1, R1, #18
			;STR R1, [R0, #TIM_PSC]
			
			;;Set the Autoreload Value
			;LDR R1, [R0, #TIM_ARR]
			;MOV R2, #TIM_ARR_ARR
			;BIC R1, R1, R2
			;ORR R1, R1, #18
			;STR R1, [R0, #TIM_ARR]
			
			;;Set the compare register (CCR = ARR/2)
			;LDR R1, [R0, #TIM_CCR1]
			;MOV R2, #TIM_CCR1_CCR1
			;BIC R1, R1, R2
			;ORR R1, R1, #9
			;STR R1, [R0, #TIM_CCR1]
			
			;; Set the OC1M bits of TIM4_CCMR1 for channel 1 to 
			;; toggle OC1REF when TIM4_CNT = TIM4_CCR1

			;LDR R1, [R0, #TIM_CCMR1]
			;ORR R1, R1, #TIM_CCMR1_OC1M_0
			;ORR R1, R1, #TIM_CCMR1_OC1M_1
			;BIC R1, R1, #TIM_CCMR1_OC1M_2
			;STR R1, [R0, #TIM_CCMR1]
			
			;; Enable Compare Output 1

			;LDR R1, [R0, #TIM_CCER]
			;ORR R1, R1, #TIM_CCER_CC1E
			;STR R1, [R0, #TIM_CCER]
			
			;; Enable the Update
			
			;LDR R1, [R0, #TIM_EGR]
			;ORR R1, R1, #TIM_EGR_UG
			;STR R1, [R0, #TIM_EGR]
			
			;; Clear the update flag
			
			;LDR R1, [R0, #TIM_SR]
			;BIC R1, R1, #TIM_SR_UIF
			;STR R1, [R0, #TIM_SR]
			
			;; Enable the TIM4 interrupts 
			;LDR R1, [R0, #TIM_DIER]
			;ORR R1, R1, #0x00000003
			;STR R1, [R0, #TIM_DIER]
			
			;; Select the master mode as OC1REF signal
			;; as the trigger output TRGO
			
			;LDR R1, [R0, #TIM_CR2]
			;BIC R1, R1, #0x00000070
			;ORR R1, R1, #0x00000040
			;STR R1, [R0, #TIM_CR2]
			
			;; Enable the Timer
			
			;LDR R1, [R0, #TIM_CR1]
			;ORR R1, R1, #TIM_CR1_CEN
			;STR R1, [R0, #TIM_CR1]
			
			;BX LR
			;ENDP
			
;DAC_INIT	PROC
			;; Configure DAC
			
			;;Enable DAC clock
			;LDR R0, =RCC_BASE
			;LDR R1, [R0, #RCC_APB1ENR]
			;ORR R1, R1, #RCC_APB1ENR_DACEN
			;STR R1, [R0, #RCC_APB1ENR]
			
			;; Enable the DAC output buffer
			
			;LDR R0, =DAC_BASE
			;LDR R1, [R0, #DAC_CR]
			;BIC R1, R1, #DAC_CR_BOFF1
			;BIC R1, R1, #DAC_CR_BOFF2
			;STR R1, [R0, #DAC_CR]
			
			;; Enable the triggers for channel 1 and channel 2
			;LDR R1, [R0, #DAC_CR]
			;ORR R1 , R1, #DAC_CR_TEN1
			;ORR R1 , R1, #DAC_CR_TEN2
			;STR R1, [R0, #DAC_CR]
			
			;; select TIM4 TRGO as trigger for both outputs 
			;LDR R1, [R0, #DAC_CR]
			;BIC R1, R1, #DAC_CR_TSEL2
			;ORR R1, R1, #0x00280000                   ; possible problem 
			;BIC R1, R1, #DAC_CR_TSEL1
			;ORR R1, R1,  #0x00000028
			;STR R1, [R0, #DAC_CR]
			
			;; Enable DAC1 and DAC2 (DAC_CR_EN1, DAC_CR_EN2)
			;LDR R1, [R0, #DAC_CR]
			;ORR R1, R1, #DAC_CR_EN1
			;ORR R1, R1, #DAC_CR_EN2
			;STR R1, [R0, #DAC_CR]
			
			;;NVIC initializations down here
			
			;; enable the TIM4 IRQn handler
			;LDR R0, =NVIC_BASE
			;LDR R1, [R0, #NVIC_ISER0]
			;BIC R1, R1, #NVIC_ISER_SETENA_30
			;ORR R1, R1, #NVIC_ISER_SETENA_30
			;STR R1, [R0, #NVIC_ISER0]
						
			;; set the priority of the TIM4_IRQn handler
			;LDR R1, [R0, #NVIC_IPR0]
			;BIC R1, R1, #NVIC_IPR0_PRI_0
			;STR R1, [R0, #NVIC_IPR0]
				
			;BX LR
			;ENDP 

		;ALIGN
;sine	PROC 
		;EXPORT sine

	;PUSH  {r1,r4,r5,r6,lr}  
	;MOV   r6, r1            ; make a copy
	;LDR   r5, =270          ; won't fit into rotation scheme
	;LDR   r4, =sin_data      ; load address of sin table
	;CMP   r1, #90           ; determine quadrant
	;BLS   retvalue          ; first quadrant
	;CMP   r1, #180
	;RSBLS r1, r1, #180      ; second quadrant
	;BLS   retvalue			
	;CMP   r1, r5
	;SUBLE r1, r1, #180      ; third quadrant
	;BLS   retvalue
	;RSB   r1, r1, #360      ; fourth quadrant
	
;retvalue	
	;LDR   r0, [r4, r1, LSL #2]  ; get sin value from table
	;CMP   r6, #180              ; should we return a negative value?
	;RSBGT r0, r0, #4096         ; 4096 ?C sin(x)    

		;POP {r1,r4,r5,r6,pc}
		;ENDP

;TIM4_IRQHandler 	PROC
					;EXPORT TIM4_IRQHandler    ;make the handler visible to the linker.
					
						
					;PUSH {LR}  				; store the current LR, in case we must jump to another subroutine
;test_routine		LDR R6, =TIM4_BASE      
					;LDR R7, [R6, #TIM_SR]     ; R7 = TIM4->SR
	
					;AND R8, R7, #TIM_SR_CC2IF  ; R8 = R7 & TIM_SR_CC2IF
					;CMP R8, #0                 ; R8 = 0 ? 
					;BEQ test_routine		  ; if R8 = 0, go do the CC2IF test again until it is 1.
					;BNE the_handler_routine

;the_handler_routine LDR R6, =DAC_BASE             
					
					;MOV R10, #100     ; r10 = 10 
					;ADD R11, R11, #36  ; r11 = r11 +36
					;UDIV R1, R11, R10 ; r1 = (r11 +36)/10
										
					;CMP R1, #360   ; the test to see if the angle has reached 360 degrees. 
					;BGE go_to_zero
					;BNE do_the_clear	

;do_the_clear		BL sine	
					;ADD R11, R11, #55      ; r11 = r11 + 55 (increment was enough to ensure that the overall frequency was 439.69 Hz.)
					;STR R0, [R6, #DAC_DHR12R1]			; output to PA4
					;STR R0, [R6, #DAC_DHR12R2] 			; output to PA5
					;B finish_clear
					
;go_to_zero			MOV R1, #0		; r1 = 0 (if r1 >=360 from other increment cycles
					;MOV R11, #0

					;;clear the CC1IF bit down here before exiting the interrupt
;finish_clear		LDR R6, =TIM4_BASE       
					;LDR R7, [R6, #TIM_SR]
					;BIC R7, R7, #TIM_SR_CC2IF
					
					;POP {LR}
					;BX LR  ; actual branching back to the link register pushed earlier and now popped. 
					
					;ENDP
	
					;END


;******************** (C) Yifeng ZHU ********************
; @file    main.s
; @author  Michael Tudor
; V1.0.0
; @date    Feb-07-2014
; @note    
; @brief   Assembly code for STM32L1xx Discovery Kit
;********************************************************

; STM32L1xx Discovery Kit:
;    - USER Pushbutton: connected to PA0 (GPIO Port A, PIN 0), CLK RCC_AHBENR_GPIOAEN
;    - RESET Pushbutton: connected RESET
;    - GREEN LED: connected to PB7 (GPIO Port B, PIN 7), CLK RCC_AHBENR_GPIOBEN 
;    - BLUE LED: connected to PB6 (GPIO Port B, PIN 6), CLK RCC_AHBENR_GPIOBEN
;    - Linear touch sensor/touchkeys: PA6, PA7 (group 2),  PC4, PC5 (group 9),  PB0, PB1 (group 3)

