;******************** (C) Yifeng ZHU ********************
; @file    main.s
; @author  
; V1.0.0
; @date    4/19/14
; @note    This code allows the STM32L Discovery board to be a very simple music player! (single notes only, no chords)
; @brief   Assembly code for STM32L1xx Discovery Kit
;********************************************************

; STM32L1xx Discovery Kit:
;    - USER Pushbutton: connected to PA0 (GPIO Port A, PIN 0), CLK RCC_AHBENR_GPIOAEN
;    - RESET Pushbutton: connected RESET
;    - GREEN LED: connected to PB7 (GPIO Port B, PIN 7), CLK RCC_AHBENR_GPIOBEN 
;    - BLUE LED: connected to PB6 (GPIO Port B, PIN 6), CLK RCC_AHBENR_GPIOBEN
;    - Linear touch sensor/touchkeys: PA6, PA7 (group 2),  PC4, PC5 (group 9),  PB0, PB1 (group 3)

; R0:  Voltage output variable for audio
; R1: degree variable for sine (output) waves
; R2:
; R3: fundamental delay constant for a 120BPM song 
; R4:
; R5: Base address of STAR_T array
; R6: 
; R7: Base address of STAR_F array
; R8:
; R9: value(note_array[i]) (what note are we on?)
; R10: value(beat_array[i]) (what is the beat associated with the note?)
; R11:
; R12: angle incrementing variable, dependent on the frequency of a particular array note.
; R13: SP
; R14: LR
; R15: PC



				INCLUDE stm32l1xx_constants.s		; Load Constant Definitions
				INCLUDE core_cm3_constant.s

				AREA myMusic, DATA 
				ALIGN 
				EXPORT
 ; Size, Frequency, Time Duration of Twinkle Twinkle Little Star 
STAR_S DCD 42 ; Number of notes 
STAR_F DCD 262, 262, 392, 392, 440, 440, 392 ; Twinkle twinkle little star 
		   DCD 349, 349, 330, 330, 294, 294, 262 ; How I wonder what you are 
		   DCD 392, 392, 349, 349, 330, 330, 294 ; Up above the world so high 
           DCD 392, 392, 349, 349, 330, 330, 294 ; Like a diamond in the sky 
           DCD 262, 262, 392, 392, 440, 440, 392 ; Twinkle twinke little star 
           DCD 349, 349, 330, 330, 294, 294, 262 ; How I wonder what you are! 

 ; Set Beats Per Minute (BMP) as 120 
STAR_T DCD 1, 1, 1, 1, 1, 1, 2 ; Twinkle twinkle little star 
	   DCD 1, 1, 1, 1, 1, 1, 2 ; How I wonder what you are 
       DCD 1, 1, 1, 1, 1, 1, 2 ; Up above the world so high 
	   DCD 1, 1, 1, 1, 1, 1, 2 ; Like a diamond in the sky 
       DCD 1, 1, 1, 1, 1, 1, 2 ; Twinkle twinke little star 
       DCD 1, 1, 1, 1, 1, 1, 2 ; How I wonder what you are! 

;*****************************************************************************
;Something Cool Song: The (improvised) Theme from Excitebike, the video game (1984) 

excitebike_F DCD 330, 392, 523, 330, 392, 523, 523
			 DCD 415, 494, 660, 415, 494, 660, 660
			 DCD 587, 523, 587, 523, 440, 392, 330 
			 DCD 392, 523, 330, 392, 523, 523, 415 
		     DCD 494, 660, 415, 494, 660, 660, 587 
			 DCD 587, 523, 587, 523 , 440, 392	

excitebike_T DCD 2,2,2,2,2,2,2
			 DCD 2,2,2,2,2,2,2
			 DCD 1,1,1,1,1,1,3
			 DCD 3,4,1,2,5,2,3
			 DCD 2,1,3,4,1,2,1
			 DCD 1,2,3,1,2,3
***************************************************************************** 
 ; Size, Frequency, Time Duration of Happy Birthday 
HB_S 	DCD 25 
HB_F 	DCD 392, 392, 440, 392, 523, 494 ; Happy Birthday to You 
		 DCD 392, 392, 440, 392, 523, 494 ; Happy Birthday to You 
		 DCD 392, 392, 784, 659, 523, 494, 440 ; Happy Birthday to Dear (name) 
		 DCD 349, 349, 330, 262, 294, 262 ; Happy Birthday to You 
 
 ; Set Beats Per Minute (BMP) as 240 
HB_T 	DCD 1, 1, 2, 2, 2, 4 ; Happy Birthday to You 
		 DCD 1, 1, 2, 2, 2, 4 ; Happy Birthday to You 
		 DCD 1, 1, 2, 2, 2, 2, 6 ; Happy Birthday to Dear (name) 
		 DCD 2, 2, 2, 2, 2, 4 ; Happy Birthday to You 

sin_data     ; DAC has 12 bits.
		DCD	0x800,0x823,0x847,0x86b,0x88e,0x8b2,0x8d6,0x8f9,0x91d,0x940
		DCD	0x963,0x986,0x9a9,0x9cc,0x9ef,0xa12,0xa34,0xa56,0xa78,0xa9a
		DCD	0xabc,0xadd,0xaff,0xb20,0xb40,0xb61,0xb81,0xba1,0xbc1,0xbe0
		DCD	0xc00,0xc1e,0xc3d,0xc5b,0xc79,0xc96,0xcb3,0xcd0,0xcec,0xd08
		DCD	0xd24,0xd3f,0xd5a,0xd74,0xd8e,0xda8,0xdc1,0xdd9,0xdf1,0xe09
		DCD	0xe20,0xe37,0xe4d,0xe63,0xe78,0xe8d,0xea1,0xeb5,0xec8,0xedb
		DCD	0xeed,0xeff,0xf10,0xf20,0xf30,0xf40,0xf4e,0xf5d,0xf6a,0xf77
		DCD	0xf84,0xf90,0xf9b,0xfa6,0xfb0,0xfba,0xfc3,0xfcb,0xfd3,0xfda
		DCD	0xfe0,0xfe6,0xfec,0xff0,0xff4,0xff8,0xffb,0xffd,0xffe,0xfff
		DCD	0xfff

				AREA    main, CODE
				EXPORT	__main						; make __main visible to linker
				ENTRY
				
__main			PROC
	
				BL GPIO_RCC_INIT
				BL TIM_INIT
				BL DAC_INIT
				BL SysTick_INITIALIZE
				
				MOV R1, #0   ; This will help with the incrementing later
				MOV R0, #0
				LDR R6, =TIM4_BASE
				LDR R7, =excitebike_F    ; R7 = base_address of STAR_F note array
				MOV R8, #0
				LDR R5, =excitebike_T     ; R5 = base address of STAR_T array
				LDR R9, [R7, R4, LSL #2]     ; R9 = value(note_array[i]) (what note are we on)
				LDR R10, [R5, R4, LSL #2]    ; R10 = value(beat_array[i]) (what is the beat associated with the note?)			
								
while_loop		B while_loop
				ENDP

GPIO_RCC_INIT		PROC

			LDR R0, =RCC_BASE
			LDR R1, [R0, #RCC_CR]
			ORR R1, R1, #RCC_CR_HSION
			STR R1, [R0, #RCC_CR]
			
			; Wait for the HSI to be ready
test_HSIRDY	LDR R1, [R0, #RCC_CR]
			AND R2, R1, #0x00000002
			CMP R2, #2
			BEQ continue
			BNE test_HSIRDY

			; Select HSI as the system clock
continue	LDR R1, [R0, #RCC_CFGR]
			ORR R1, R1, #RCC_CFGR_SW_HSI ; ORR R1, R1, #0x00000001
			STR R1, [R0, #RCC_CFGR]

				; Wait until HSI is selected as System Clock
HSI_Check	LDR r1, [r0, #RCC_CFGR]
			AND r1, r1, #0xC
			CMP r1, #4
			BEQ second_continue
			BNE HSI_Check
			
			; enable the clock of GPIOA
second_continue	LDR R0, =RCC_BASE
				LDR R1, [R0, #RCC_AHBENR]
				ORR R1, R1, #RCC_AHBENR_GPIOAEN
				STR R1, [R0, #RCC_AHBENR]
			
			; set PA4 and PA5 as analog (using MODER register)
			LDR R0, =GPIOA_BASE
			LDR R1, [R0, #GPIO_MODER]
			BIC R1, R1, #0x00000F00
			ORR R1, R1, #0x00000F00
			STR R1, [R0, #GPIO_MODER]
			
			;Configure TIM4 as Master Trigger
			
			; enable the clock of TIM4 
			LDR R0, =RCC_BASE
			LDR R1, [R0, #RCC_APB1ENR]
			ORR R1, R1, #RCC_APB1ENR_TIM4EN
			STR R1, [R0, #RCC_APB1ENR]
			
			BX LR
			ENDP

TIM_INIT	PROC
			
			;Set the Prescaler
			LDR R0, =TIM4_BASE
			LDR R1, [R0, #TIM_PSC]
			MOV R2, #TIM_PSC_PSC
			BIC R1, R1, R2
			ORR R1, R1, #18
			STR R1, [R0, #TIM_PSC]
			
			;Set the Autoreload Value
			LDR R1, [R0, #TIM_ARR]
			MOV R2, #TIM_ARR_ARR
			BIC R1, R1, R2
			ORR R1, R1, #18
			STR R1, [R0, #TIM_ARR]
			
			;Set the compare register (CCR = ARR/2)
			LDR R1, [R0, #TIM_CCR1]
			MOV R2, #TIM_CCR1_CCR1
			BIC R1, R1, R2
			ORR R1, R1, #9
			STR R1, [R0, #TIM_CCR1]
			
			; Set the OC1M bits of TIM4_CCMR1 for channel 1 to 
			; toggle OC1REF when TIM4_CNT = TIM4_CCR1

			LDR R1, [R0, #TIM_CCMR1]
			ORR R1, R1, #TIM_CCMR1_OC1M_0
			ORR R1, R1, #TIM_CCMR1_OC1M_1
			BIC R1, R1, #TIM_CCMR1_OC1M_2
			STR R1, [R0, #TIM_CCMR1]
			
			; Enable Compare Output 1

			LDR R1, [R0, #TIM_CCER]
			ORR R1, R1, #TIM_CCER_CC1E
			STR R1, [R0, #TIM_CCER]
			
			; Enable the Update
			
			LDR R1, [R0, #TIM_EGR]
			ORR R1, R1, #TIM_EGR_UG
			STR R1, [R0, #TIM_EGR]
			
			; Clear the update flag
			
			LDR R1, [R0, #TIM_SR]
			BIC R1, R1, #TIM_SR_UIF
			STR R1, [R0, #TIM_SR]
			
			; Enable the TIM4 interrupts 
			LDR R1, [R0, #TIM_DIER]
			ORR R1, R1, #0x00000003
			STR R1, [R0, #TIM_DIER]
			
			; Select the master mode as OC1REF signal
			; as the trigger output TRGO
			
			LDR R1, [R0, #TIM_CR2]
			BIC R1, R1, #0x00000070
			ORR R1, R1, #0x00000040
			STR R1, [R0, #TIM_CR2]
			
			; Enable the Timer
			
			LDR R1, [R0, #TIM_CR1]
			ORR R1, R1, #TIM_CR1_CEN
			STR R1, [R0, #TIM_CR1]
			
			BX LR
			ENDP
			
DAC_INIT	PROC
			; Configure DAC
			
			;Enable DAC clock
			LDR R0, =RCC_BASE
			LDR R1, [R0, #RCC_APB1ENR]
			ORR R1, R1, #RCC_APB1ENR_DACEN
			STR R1, [R0, #RCC_APB1ENR]
			
			; Enable the DAC output buffer
			
			LDR R0, =DAC_BASE
			LDR R1, [R0, #DAC_CR]
			BIC R1, R1, #DAC_CR_BOFF1
			BIC R1, R1, #DAC_CR_BOFF2
			STR R1, [R0, #DAC_CR]
			
			; Enable the triggers for channel 1 and channel 2
			LDR R1, [R0, #DAC_CR]
			ORR R1 , R1, #DAC_CR_TEN1
			ORR R1 , R1, #DAC_CR_TEN2
			STR R1, [R0, #DAC_CR]
			
			; select TIM4 TRGO as trigger for both outputs 
			LDR R1, [R0, #DAC_CR]
			BIC R1, R1, #DAC_CR_TSEL2
			ORR R1, R1, #0x00280000                    
			BIC R1, R1, #DAC_CR_TSEL1
			ORR R1, R1,  #0x00000028
			STR R1, [R0, #DAC_CR]
			
			; Enable DAC1 and DAC2 (DAC_CR_EN1, DAC_CR_EN2)
			LDR R1, [R0, #DAC_CR]
			ORR R1, R1, #DAC_CR_EN1
			ORR R1, R1, #DAC_CR_EN2
			STR R1, [R0, #DAC_CR]
			
			;NVIC initializations down here
			
			; enable the TIM4 IRQn handler
			LDR R0, =NVIC_BASE
			LDR R1, [R0, #NVIC_ISER0]
			BIC R1, R1, #NVIC_ISER_SETENA_30
			ORR R1, R1, #NVIC_ISER_SETENA_30
			STR R1, [R0, #NVIC_ISER0]
						
			; set the priority of the TIM4_IRQn handler
			LDR R1, [R0, #NVIC_IPR0]
			BIC R1, R1, #NVIC_IPR0_PRI_0
			ORR R1, R1, #NVIC_IPR0_PRI_1
			STR R1, [R0, #NVIC_IPR0]
		
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
				
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sine function goes here

		ALIGN
sine	PROC 
		EXPORT sine

	PUSH  {r1,r4,r5,r6,lr}  
	MOV   r6, r1            ; make a copy
	LDR   r5, =270          ; won't fit into rotation scheme
	LDR   r4, =sin_data      ; load address of sin table
	CMP   r1, #90           ; determine quadrant
	BLS   retvalue          ; first quadrant
	CMP   r1, #180
	RSBLS r1, r1, #180      ; second quadrant
	BLS   retvalue			
	CMP   r1, r5
	SUBLE r1, r1, #180      ; third quadrant
	BLS   retvalue
	RSB   r1, r1, #360      ; fourth quadrant
	
retvalue	
	LDR   r0, [r4, r1, LSL #2]  ; get sin value from table
	CMP   r6, #180              ; should we return a negative value?
	RSBGT r0, r0, #4096         ; 4096 ?C sin(x)    

		POP {r1,r4,r5,r6,pc}
		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Handlers and delay_function go down here 
TIM4_IRQHandler 	PROC
					EXPORT TIM4_IRQHandler    ;make the handler visible to the linker.
					PUSH {LR}  				; store the current LR, in case we must jump to another subroutine  
				
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;				
test_routine		LDR R6, =TIM4_BASE      
					LDR R7, [R6, #TIM_SR]     ; R7 = TIM4->SR
	
					AND R3, R7, #TIM_SR_CC2IF  ; R8 = R7 & TIM_SR_CC2IF
					CMP R3, #0                 ; R8 = 0 ? 
					BEQ test_routine		  ; if R8 = 0, go do the CC2IF test again until it is 1.
					BNE go_thru_notes
					
go_thru_notes   	CMP R4, #50    ; R4 < number of notes in song?
					BEQ done
					BNE the_handler_routine

the_handler_routine BL angle_increment_formula		; make sure we have the right increment based on the frequency of particular note)
				 	ADD R11, R11, R12       ; Must be r11 = r11 + r12, because R1 is on the stack, its standing value will not change with this update
					MOV R1, R11
					
					CMP R1, #360   ; the test to see if the angle has reached 360 degrees. 
					BGE go_to_zero
					BNE do_the_clear	

do_the_clear		BL sine	
					
					LDR R6, =DAC_BASE
					STR R0, [R6, #DAC_DHR12R1]			; output to PA4
					STR R0, [R6, #DAC_DHR12R2] 			; output to PA5
					B finish_clear
					
					; We only go here upon the completion of a sine wave.
go_to_zero			MOV R1, #0		; r1 = 0 (if r1 >=360 from other increment cycles
					MOV R11, #0			

					;clear the CC2IF bit down here before exiting the interrupt
finish_clear		LDR R6, =TIM4_BASE       
					LDR R7, [R6, #TIM_SR]
					BIC R7, R7, #TIM_SR_CC2IF  ; clear that flag
					STR R7, [R6, #TIM_SR]
					
					POP {PC}
					ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SysTick_Handler		PROC                         ; For some reason, r4 is incrementing everytime that I go into the SysTick Handler.
					EXPORT	SysTick_Handler      ; This must be fixed so that it doesn't happen. R4 is incrementing every 1ms. NOT GOOD.   
					PUSH {LR,R11}
					
					ADD R8, R8, #1   ; increment r8 since we have entered the handler
					MOV R11, #500   ; R11 = 500
					
					MUL R11, R11, R10   ; R11 = 500*(1,2, or 3)
test				CMP R8, R11			; is the amount of beats for a particular note equal to what the array says it should be?
					BGE increment_note  ; we have done all the required beats for the note at hand (r4), move onto the next one
					BLT finish_SysTick	; we have not done all the required notes, we must go through at least one more sysTick cycle
					
increment_note		ADD R4, R4, #1
					MOV R8, #0 				
					B finish_SysTick
					
finish_SysTick		LDR R7, =excitebike_F
					LDR R9, [R7, R4, LSL #2]    ; grab the appropriate note in our array
					LDR R10, [R5, R4, LSL #2]    ; R10 = value(beat_array[i]) (what is the beat associated with the note?)
					
					POP{PC,R11}
					ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

angle_increment_formula PROC
				
						PUSH {LR,R8,R7,R10,R11}
				
						MOV R8, #36000
						MOV R7, #44100
						MOV R10, #100
						MUL R11, R9, R8   ; R11 = R9*R8 = f*36000
						UDIV R11, R11, R7 ; R11 = f*36000/44100
						UDIV R11, R11, R10 ; R11 = f*36000/(44100*100)
						MOV R12, R11  ; R12 = R11 (R12 is the angle increment variable, dependent on the note in the array. 
				
						POP{PC,R8,R7,R10,R11}    
						ENDP
done
						END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;