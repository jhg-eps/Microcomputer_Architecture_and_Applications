//*********************************************************************
// @file    main.c
// @Joseph Garcia 
// @1/21/2014
// @This program will use User Push Button to light up LEDs via polling    
// @brief   C code for STM32L1xx Discovery Kit
//		      Light up BLUE LED When the user button is pushed
//*********************************************************************

#include <stdint.h>

/* Standard STM32L1xxx driver headers */
//#include "stm32l1xx.h"

/* STM32L1xx Discovery Kit:
    - USER Pushbutton: connected to PA0 (GPIO Port A, PIN 0), CLK RCC_AHBENR_GPIOAEN
    - RESET Pushbutton: connected RESET
    - GREEN LED: connected to PB7 (GPIO Port B, PIN 7), CLK RCC_AHBENR_GPIOBEN 
    - BLUE LED: connected to PB6 (GPIO Port B, PIN 6), CLK RCC_AHBENR_GPIOBEN
    - Linear touch sensor/touchkeys: PA6, PA7 (group 2),  PC4, PC5 (group 9),  PB0, PB1 (group 3)
*/


//******************************************************************************************
//* The following definitions are copied from stm32l1xx.h 
//******************************************************************************************

#define     __O     volatile                  /*!< defines 'write only' permissions     */
#define     __IO    volatile                  /*!< defines 'read / write' permissions   */

//Reset and Clock Control
typedef struct
{
  __IO uint32_t CR;
  __IO uint32_t ICSCR;
  __IO uint32_t CFGR;
  __IO uint32_t CIR;
  __IO uint32_t AHBRSTR;
  __IO uint32_t APB2RSTR;
  __IO uint32_t APB1RSTR;
  __IO uint32_t AHBENR;
  __IO uint32_t APB2ENR;
  __IO uint32_t APB1ENR;
  __IO uint32_t AHBLPENR;
  __IO uint32_t APB2LPENR;
  __IO uint32_t APB1LPENR;      
  __IO uint32_t CSR;    
} RCC_TypeDef;

// General Purpose IO
typedef struct
{
  __IO uint32_t MODER;
  __IO uint16_t OTYPER;
  uint16_t RESERVED0;
  __IO uint32_t OSPEEDR;
  __IO uint32_t PUPDR;
  __IO uint16_t IDR;
  uint16_t RESERVED1;
  __IO uint16_t ODR;
  uint16_t RESERVED2;
  __IO uint16_t BSRRL; /* BSRR register is split to 2 * 16-bit fields BSRRL */
  __IO uint16_t BSRRH; /* BSRR register is split to 2 * 16-bit fields BSRRH */
  __IO uint32_t LCKR;
  __IO uint32_t AFR[2];
} GPIO_TypeDef;



#define  RCC_AHBENR_GPIOAEN   ((uint32_t)0x00000001) /*!< GPIO port A clock enable */
#define  RCC_AHBENR_GPIOBEN   ((uint32_t)0x00000002) /*!< GPIO port B clock enable */
#define  RCC_APB1ENR_PWREN    ((uint32_t)0x10000000) /*!< Power interface clock enable */

// Peripheral memory map
#define FLASH_BASE            ((uint32_t)0x08000000) /*!< FLASH base address in the alias region */
#define SRAM_BASE             ((uint32_t)0x20000000) /*!< SRAM base address in the alias region */
#define PERIPH_BASE           ((uint32_t)0x40000000) /*!< Peripheral base address in the alias region */
#define SRAM_BB_BASE          ((uint32_t)0x22000000) /*!< SRAM base address in the bit-band region */
#define PERIPH_BB_BASE        ((uint32_t)0x42000000) /*!< Peripheral base address in the bit-band region */
#define APB1PERIPH_BASE       PERIPH_BASE
#define APB2PERIPH_BASE       (PERIPH_BASE + 0x10000)
#define AHBPERIPH_BASE        (PERIPH_BASE + 0x20000)

#define RCC_BASE              (AHBPERIPH_BASE + 0x3800)
#define GPIOA_BASE            (AHBPERIPH_BASE + 0x0000)
#define GPIOB_BASE            (AHBPERIPH_BASE + 0x0400)
#define GPIOA               	((GPIO_TypeDef *) GPIOA_BASE)
#define GPIOB                 ((GPIO_TypeDef *) GPIOB_BASE)
#define RCC                   ((RCC_TypeDef *) RCC_BASE)


 
//******************************************************************************************
// The main program starts here
//******************************************************************************************
 int main(){

//1	 (Enable Clock) 
	RCC->AHBENR &=~0x3;
	RCC->AHBENR |=0x3;     //enables the clock of GPIOB and GPIO Port A
	
//2	(GPIO output pin initializations) 
	GPIOB->MODER &=~0xF000;
	GPIOB->MODER |=0x5000;    // PB6 and PB7 mode set as output
	
	GPIOB->OTYPER &=~0xC0;    
	GPIOB->OTYPER |=0x00;     // PB6 and PB7 output set for push pull
	 
	GPIOB->PUPDR &=~ 0xF000;
	GPIOB->PUPDR |= 0x0000;  //, PB6 and PB7 configured for No pull-up no pull-down, PUPD VALUE IS 00
	 
	//3 (Configure PAO for the USER push button)
	 
	GPIOA->MODER &=~ 0x3;
	GPIOA->MODER |= 0x0;
	 
	 //3B (Set PA0 as No Pull-up No Pull-down)
	GPIOA->PUPDR &=~0x3;
	GPIOA->PUPDR |= 0x0;
	
	//4 (Read Digital Input from User Button and Write digital output to LEDs)

GPIOB->ODR &=~(0xC0);
GPIOB->ODR |= (0x40);   // light up blue light

while(1){
if(GPIOA->IDR&0x1/*is true*/)
{
	GPIOB->ODR ^=(0xC0);  //causes both bits to toggle, makes them opposite only once
	while(GPIOA->IDR&0x1)
	{
		//do nothing, checks to see if the button is pressed
	}
	
}
}
}