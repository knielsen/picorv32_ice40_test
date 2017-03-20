#include <stdint.h>


#define LED_WORD (*(volatile uint8_t *)0x400000ff)
#define sdram ((volatile uint16_t *)0x20000000)

int
main(void)
{
  uint8_t counter = 0;
  uint32_t i;

  for (;;) {
    sdram[0] = 0x0000;
    sdram[2] = 0xffff;
    LED_WORD = sdram[0];
    for (i = 0; i < 1000000; ++i)
      asm volatile("");
    LED_WORD = sdram[2];
    for (i = 0; i < 1000000; ++i)
      asm volatile("");
  }

/*
  for (;;) {
    LED_WORD = counter ^ (counter >> 1);
    ++counter;
    for (i = 0; i < 1000000; ++i)
      asm volatile("");
  }
*/

/*
  for (;;) {
    LED_WORD = 1;
    sdram[0] = 2;
    LED_WORD = sdram[0];
    LED_WORD = 5;
    sdram[2] = 10;
    sdram[4] = 12;
    LED_WORD = sdram[2];
    LED_WORD = 11;
    LED_WORD = sdram[4];
  }
*/
}
