;******************** (C) Yifeng ZHU ********************
; @file    main.s
; @author    Joseph Garcia
; V1.0.0
; @date    April 13, 2014
; @note    
; @brief   This code uses the EXTI0 interrupt to toggle the Blue LED (PB6) through the  PAO pin (the user button)
;********************************************************

; STM32L1xx Discovery Kit:
;    - USER Pushbutton: connected to PA0 (GPIO Port A, PIN 0), CLK RCC_AHBENR_GPIOAEN
;    - RESET Pushbutton: connected RESET
;    - GREEN LED: connected to PB7 (GPIO Port B, PIN 7), CLK RCC_AHBENR_GPIOBEN 
;    - BLUE LED: connected to PB6 (GPIO Port B, PIN 6), CLK RCC_AHBENR_GPIOBEN
;    - Linear touch sensor/touchkeys: PA6, PA7 (group 2),  PC4, PC5 (group 9),  PB0, PB1 (group 3)


				INCLUDE stm32l1xx_constants.s		; Load Constant Definitions

				AREA    main, CODE, READONLY
				EXPORT	__main						; make __main visible to linker
				ENTRY
				
__main			PROC

				BL GPIO_RCC_INIT   ; GPIO clock and output initializations
				BL INTERRUPT_INIT	; interrupt initializations

while_loop		b while_loop    ; dead loop to ensure the program keeps running.

				ENDP


GPIO_RCC_INIT	PROC

				; GPIO, and RCC initializations
				
				; initialize GPIOB (PB6) and GPIOA (PA0) clocks
				LDR R0, =RCC_BASE
				
				LDR R1, [R0, #RCC_AHBENR]
				ORR R1, R1, #0x00000003
				STR R1, [R0, #RCC_AHBENR]
				
				; initialize the SYSCFG clock
				LDR R1, [R0, #RCC_APB2ENR]
				ORR R1, R1, #0x00000001
				STR R1, [R0, #RCC_APB2ENR]
				
				; GPIO mode type initializations
				
					; PA0 as input
				LDR R0, =GPIOA_BASE
				LDR R1, [R0, #GPIO_MODER]
				ORR R1, R1, #0x00000000
				STR R1, [R0, #GPIO_MODER]
				
					; PB6 as output
				LDR R0, =GPIOB_BASE
				LDR R1, [R0, #GPIO_MODER]
				BIC R1, R1, #0x00003000
				ORR R1, R1, #0x00001000
				STR R1, [R0, #GPIO_MODER]
				
				; No Pull-up/Pull-Down for both pins
				
					; PB6
				LDR R1, [R0, #GPIO_PUPDR]
				BIC R1, R1, #0x00003000
				STR R1, [R0, #GPIO_PUPDR]
	
					; PA0
				LDR R0, =GPIOA_BASE
				LDR R1, [R0, #GPIO_PUPDR]
				BIC R1, R1, #0x00000003
				STR R1, [R0, #GPIO_PUPDR] 
				
				BX LR
				
				ENDP
				
				; Interrupt Initializations 
INTERRUPT_INIT	PROC

				; Select source input for the interrupt (PA0)
				LDR R0, =SYSCFG_BASE
				
				LDR R1, [R0, #SYSCFG_EXTICR0]
				BIC R1, R1, #0x000F
				STR R1, [R0, #SYSCFG_EXTICR0]
				
				; initialize the rising edge trigger
				LDR R0, =EXTI_BASE
				
				LDR R1, [R0, #EXTI_RTSR]
				ORR R1, R1, #EXTI_RTSR_TR0
				STR R1, [R0, #EXTI_RTSR]
				
				; initialize the interrupt mask register for PA0
				LDR R1, [R0, #EXTI_IMR]
				ORR R1, R1, #EXTI_IMR_MR0 
				STR R1, [R0, #EXTI_IMR]
				
				; enable the EXTI0_IRQHandler (the number 6 listed interrupt)
				
				LDR R0, =NVIC_BASE 
				LDR R1, [R0, #NVIC_ISER0]
				BIC R1, R1, #NVIC_ISER_SETENA_6
				ORR R1, R1, #NVIC_ISER_SETENA_6
				STR R1, [R0, #NVIC_ISER0]
				
				; set the priority of the EXTI0 IRQ Handler 
				LDR R1, [R0, #NVIC_IPR0]
				BIC R1, R1, #NVIC_IPR0_PRI_0
				ORR R1, R1, #0x00000001
				STR R1, [R0, #NVIC_IPR0]
				
				BX LR
				ENDP
				

EXTI0_IRQHandler	PROC
					EXPORT		EXTI0_IRQHandler  ; make the EXTI0_IRQHandler visible to the linker.
				
				
retry				LDR R0, =EXTI_BASE
					LDR R1, [R0, #EXTI_PR]         ; R1 = EXTI->PR
					
					AND R2, R1, #1		; R2 = (EXTI->PR & 1)
					CMP R2, #1				;R2 ==1 ?
					BEQ light_toggle		; Yes, interrupt is pending. Toggle the light
					BNE retry				; No, wait until the interrupt is pending. Branch back to retry.

light_toggle								; light toggling routine.
					LDR R0, =GPIOB_BASE
					LDR R1, [R0, #GPIO_ODR]
					EOR R1, R1, #(1<<6)   ; PB6 0light goes off for one rising edge, and then engages on once another 
					STR R1, [R0, #GPIO_ODR]  ;rising edge has occurred.
					
					LDR R0, =EXTI_BASE
					LDR R1, [R0, #EXTI_PR]
					ORR R1, R1, #0x00000001             ; clear pending interrupt bit
					STR R1, [R0, #EXTI_PR]     
					
					BX LR   ; branch back to main routine
					
					ENDP

					END
					
