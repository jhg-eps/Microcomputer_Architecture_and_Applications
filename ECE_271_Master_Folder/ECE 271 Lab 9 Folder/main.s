
;******************** (C) Yifeng ZHU ********************
 ;@file    main.s
 ;@author  Joseph Garcia
 ;V1.0.0
 ;@date    Feb-15-2014
 ;@note   This code uses the STM32L Discovery Board's onboard ADC to determine an input signal's value. If the value is  ;   ;     below Vcc/2, one LED is lit. If the incomign signal is above Vcc/2, a different LED is lit
; @brief   Assembly code for STM32L1xx Discovery Kit
;********************************************************

 ;STM32L1xx Discovery Kit:
    ;- USER Pushbutton: connected to PA0 (GPIO Port A, PIN 0), CLK RCC_AHBENR_GPIOAEN
    ;- RESET Pushbutton: connected RESET
   ;; - GREEN LED: connected to PB7 (GPIO Port B, PIN 7), CLK RCC_AHBENR_GPIOBEN 
    ;- BLUE LED: connected to PB6 (GPIO Port B, PIN 6), CLK RCC_AHBENR_GPIOBEN
  ;  - Linear touch sensor/touchkeys: PA6, PA7 (group 2),  PC4, PC5 (group 9),  PB0, PB1 (group 3)

 ;r0 (constant #4, r8 = r8+r0)
 ;r1 The GPIO_MODER offset of r7
 ;r2 base address of halfstep_array, full
 ;r3 base address of GPIO_ODR register
 ;r4 (temporary storage of r5)                                                           												
 ;r5 (stores substep/halfstep array index values)
 ;r6 (not used)
 ;r7  (RCC_Base register)
 ;r8(counter variable for 48 step routine)
 ;r9  (delay loop counter variable)
 ;r10 (not used)
 ;r11  (substep routine counter variable)
 ;r12 (not used)
 ;r13 (Stack Pointer)
 ;r14 (link register)
; r15 (program counter)									

				INCLUDE stm32l1xx_constants.s		; Load Constant Definitions
				;INCLUDE core_cm3_constant.s
								
				
				AREA    main, CODE
				EXPORT	__main						; make __main visible to linker
				ENTRY
				
__main			PROC  
	
				BL CLK_INIT
				BL GPIO_INIT
				BL OTHER_INIT
	
while_loop		B while_loop

				ENDP 
CLK_INIT		PROC
				
				LDR r0, = RCC_BASE

				; Turn on the HSI clock
				LDR r1, [r0, #RCC_CR]
				ORR r1, r1, #RCC_CR_HSION
				STR r1, [r0, #RCC_CR]
				
				; Wait for the HSI clock to be ready 
check		LDR r1, [r0, #RCC_CR]
				
				BIC r1, r1, #0xFFFFFFFD			; set every bit to zero except for HSI_READY flag
				CMP r1, #2
				BEQ continue
				BNE check

continue		; Configure clocks for GPIOB and GPIOC
				LDR r1, [r0, #RCC_AHBENR]
				ORR r1, r1, #RCC_AHBENR_GPIOBEN
				ORR r1, r1, #RCC_AHBENR_GPIOCEN
				STR r1, [r0, #RCC_AHBENR]
				
				BX lr
				
				ENDP

GPIO_INIT		PROC

				LDR r0, = GPIOB_BASE
				
				; Configure PB6 as output
				LDR r1, [r0, #GPIO_MODER]
				BIC r1, r1, #0x3000
				ORR r1, r1, #0x1000
				STR r1, [r0, #GPIO_MODER]
				
				; Configure PB6 as push-pull
				LDR r1, [r0, #GPIO_OTYPER]
				BIC r1, r1, #0x40
				STR r1, [r0, #GPIO_OTYPER]
				
				LDR r0, = GPIOC_BASE
				
				; Set PC0 as analog input mode
				LDR r1, [r0, #GPIO_MODER]	
				BIC r1, r1, #0x3
				ORR r1, r1, #0x3
				STR r1, [r0, #GPIO_MODER]
				
				BX lr
				
				ENDP
				
OTHER_INIT		PROC

				LDR r0, = RCC_BASE
				
				; Turn on ADC clock
				LDR r1, [r0, #RCC_APB2ENR]
				ORR r1, r1, #RCC_APB2ENR_ADC1EN
				STR r1, [r0, #RCC_APB2ENR]
				
				LDR r0, =ADC1_BASE
				; Disable the ADC Conversions
				LDR r1, [r0, #ADC_CR2]
				BIC r1, r1, #0x1
				STR r1, [r0, #ADC_CR2]
				
				; Select only one conversion in the regular channel conversion sequence
				LDR r1, [r0, #ADC_SQR1]
				BIC r1, r1, #0x1F00000
				STR r1, [r0, #ADC_SQR1]
				
				; Set channel 10 as first conversion in the regular sequence.
				LDR r1, [r0, #ADC_SQR5]
				BIC r1, r1, #0x1F
				ORR r1, r1, #0xA
				STR r1, [r0, #ADC_SQR5]
				
				; Configure the sample time register for Channel 10
				LDR r1, [r0, #ADC_SMPR2]
				BIC r1, r1, #0x7
				ORR r1, r1, #0x4			
				STR r1, [r0, #ADC_SMPR2]
				
				; Enable End-of-Conversion interrupt
				LDR r1, [r0, #ADC_CR1]
				ORR r1, r1, #0x20
				STR r1, [r0, #ADC_CR1]
				
				; Enable Continuous Conversion mode
				LDR r1, [r0, #ADC_CR2]
				ORR r1, r1, #0x2
				STR r1, [r0, #ADC_CR2]
				
				
				LDR r0, = NVIC_BASE
				
				; Enable the interrupt of ADC1_IRQn
				LDR r1, [r0, #NVIC_ISER0]
				BIC r1, r1, #NVIC_ISER_SETENA_18
				ORR r1, r1, #NVIC_ISER_SETENA_18
				STR r1, [r0, #NVIC_ISER0]
				
				; Enable the Priority of ADC1_IRQn
				LDR r1, [r0, #NVIC_IPR0]
				BIC r1, r1, #0xFF
				ORR R1, R1, #0x1
				STR r1, [r0, #NVIC_IPR0]
				
				LDR r0, = ADC1_BASE
				
				; Configure delay selection as delayed until the converted data has been read
				LDR r1, [r0, #ADC_CR2]
				BIC r1, r1, #0x70
				ORR r1, r1, #0x10
				STR r1, [r0, #ADC_CR2]
				
				; Turn on the ACD conversion
				LDR r1, [r0, #ADC_CR2]
				ORR r1, r1, #0x1
				STR r1, [r0, #ADC_CR2]
				
				; Start the conversion of the Regular Channel
				LDR r1, [r0, #ADC_CR2]
				ORR r1, r1, #0x40000000
				STR r1, [r0, #ADC_CR2]
				
				BX lr
				
				ENDP

ADC1_IRQHandler	PROC
				
				EXPORT ADC1_IRQHandler
				
				LDR R0, = ADC1_BASE
				LDR R1, [R0, #ADC_SR]  ; R1 = ADC1_SR
				AND R2, R1, #0x00000002 ; ADC1->SR & ADC_SR_EOC
				
Compare_test	CMP R2, #2    ; if (ADC1->SR  & ADC_SR_EOC) ==1
				BEQ continue2
				BNE Compare_test

continue2		LDR R1, [R0, #ADC_DR]  ; ADC result = ADC1->DR
				
				; ADC1->DR = Vmax. Max resolution of voltage is 12 bits, so we must have the maximum voltage as 2^12 = 4096
				MOV R3, #2047
				CMP R1, R3
				BGE engage_light
				BLT disengage_light

engage_light	LDR R0, =GPIOB_BASE
				LDR R1, [R0, #GPIO_ODR]
				ORR R1, R1, #0x00000040
				STR R1, [R0, #GPIO_ODR]
				b done
				
disengage_light	
				LDR R0, =GPIOB_BASE
				LDR R1, [R0, #GPIO_ODR]
				BIC R1, R1, #0x00000040
				STR R1, [R0, #GPIO_ODR]
				b done

done			BX LR
				
				ENDP
					
				; input voltage is higher than Vcc/2,, the light goes up
				; input voltage is lower than Vcc/2, the light is off.
				END