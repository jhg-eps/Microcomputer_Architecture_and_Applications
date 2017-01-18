;******************** (C) Yifeng ZHU ********************
; @file    main.s
; @author  Joseph Garcia
; V1.0.0
; @date    March 25, 2014
; @note  This lab involves the usage of the SysTick timer to generate an interrupt every 1 ms, which will be applied in a ; ;        delay function to light up and turn off an LED with 1 second time intervals.
; @brief   Assembly code for STM32L1xx Discovery Kit
;********************************************************

; STM32L1xx Discovery Kit:
;    - USER Pushbutton: connected to PA0 (GPIO Port A, PIN 0), CLK RCC_AHBENR_GPIOAEN
;    - RESET Pushbutton: connected RESET
;    - GREEN LED: connected to PB7 (GPIO Port B, PIN 7), CLK RCC_AHBENR_GPIOBEN 
;    - BLUE LED: connected to PB6 (GPIO Port B, PIN 6), CLK RCC_AHBENR_GPIOBEN
;    - Linear touch sensor/touchkeys: PA6, PA7 (group 2),  PC4, PC5 (group 9),  PB0, PB1 (group 3)							

				INCLUDE stm32l1xx_constants.s		; Load Constant Definitions
				INCLUDE core_cm3_constant.s
					
				AREA    main, CODE
				EXPORT	__main						; make __main visible to linker
				ENTRY
				
__main			PROC         
				
				BL GPIO_INITIALIZE 		; Initialize the LEDs
				BL SysTick_INITIALIZE  ; Initialize System Timer
				
				MOV r8, #500      ; timingdelay = ntime 
				LDR r11, = GPIOB_BASE 

while_loop		CMP r8, #0			; timingdelay >0?
				BL delay_function	; branch to delay_function
				
				LDR r1, [r11, #GPIO_ODR]
				CMP r1, #0xC0
				BEQ equal
				BNE not_equal
equal			AND r1, r1, #0x0000 
				B STORE
not_equal		ORR r1, r1, #0xC0
				B STORE
				;EOR r1, r1, #0xC0			; If lights are active, they go dark. If they are dark, then they light up
STORE			STR r1, [r11, #GPIO_ODR]	; store result
				B while_loop      ; branch back to infinite while loop
	
				ENDP
					
GPIO_INITIALIZE PROC

				;1 Configure RCC_AHBENR to enable clock of GPIO Port B
				LDR r0, =RCC_BASE              ; load address of reset and clock control
				LDR r1, [r0, #RCC_AHBENR]      ; load RCC_AHBENR offset into r1 target register 
				BIC r1, r1, #RCC_AHBENR_GPIOBEN
				ORR r1, r1, #RCC_AHBENR_GPIOBEN  ; enable GPIO Clock B
				STR r1, [r0, #RCC_AHBENR]        ; store the enabling of GPIO Clock B
				
				;3 Configure PB 6 (Blue LED), PB 7(Green LED) as output
				LDR r0, =GPIOB_BASE
				LDR r1, [r0, #GPIO_MODER]
				BIC r1, r1, #0x0000F000    
				ORR r1, r1, #0x00005000
				STR r1, [r0, #GPIO_MODER]
				
				;4a configure and select the correct alternative function for PB6 and PB7
				LDR r1, [r0, #GPIO_AFR0]
				BIC r1, r1, #0xFF000000
				ORR r1, r1, #0x22000000
				STR r1, [r0, #GPIO_AFR0]
				
				;Turn on LEDs through the output data registry
				LDR r1, [r0, #GPIO_ODR]
				BIC r1, r1, #0xC0
				ORR r1, r1, #0xC0
				STR r1, [r0, #GPIO_ODR]
				
				BX LR
				
				ENDP

SysTick_INITIALIZE	PROC

				; Configure SysTick
				;1. Set SysTick register Control and Status Register to disable SysTick IRQ and SysTick Timer
				LDR r0, =SysTick_BASE
				
				LDR r1, [r0, #SysTick_CTRL]
				BIC r1, r1, #0x7  ; 0x07
				STR r1, [r0, #SysTick_CTRL]  ; cleared ENABLE, TICKINT, and the clock source
				
				;2. Set SysTick Reload Value Register to specify the number of clock cycles between interrupts 
				LDR r2, =262 
				STR r2, [r0, #SysTick_LOAD]
				
				;3. Clear the SysTick Current Value Register 
				MOV r2, #0x00
				STR r2, [r0, #SysTick_VAL]
								
				;4. Set the interrupt Priority and enable NVIC SysTick interrupt
				LDR r0, =NVIC_BASE
				LDR r1, [r0,#NVIC_ISER0]
				BIC r3, r3, #(0x03 << 0x0F)
				ORR r3, r3, #(0x01 << 0x0F)
				STR r3, [r0, #NVIC_ISER0]
				
				LDR r3, [r0,#NVIC_IPR0]
				BIC r3, r3, #0xFF
				STR r3, [r0, #NVIC_IPR0]
				
				;5. Set SysTick Control and Status Register to Enable SysTick IRQ and SysTick Timer
				
				LDR r0, =SysTick_BASE
				LDR r1, [r0, #SysTick_CTRL]
				ORR r1, r1, #0x01      ; set ENABLE
				ORR r1, r1, #0x02		; set TICKINT				
				STR r1, [r0, #SysTick_CTRL]
				
				BX LR
				
				ENDP
				
SysTick_Handler	PROC
				
				EXPORT	SysTick_Handler
				SUB r10, r10, #1  ; r10 = r10 -1 This ensures that the delay_loop below will eventually quit, causing the blinking
				BX LR
				
				ENDP
					
delay_function	PROC
				EXPORT delay_function	
					
				PUSH {r10, LR}
				MOV r10, r8   ; r10 = r8, the input of time delay, this is decremented by one via the Systick_Handler
delay_loop		CMP r10, #0   ; wait for systick_handler to decrement r10 to zero
				BNE delay_loop  ; r10 goes to zero every time systick_handler gets to zero
				POP {r10, PC}     ; does this go inside of the SysTick_Handler
				
				ENDP
				
				END