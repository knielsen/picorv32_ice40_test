#include <stdint.h>


#define LED_WORD (*(volatile uint8_t *)0x400000ff)
#define sdram ((volatile uint16_t *)0x20000000)

int
main(void)
{
  uint8_t counter = 0;
  uint32_t i;

  LED_WORD = 1;
  LED_WORD = 2;
  LED_WORD = 5;
  for (;;) {
    for (counter = 0; counter < 16; ++counter)
    {
      LED_WORD = counter ^ (counter >> 1);
      sdram[2*counter] = counter ^ (counter >> 1);
      LED_WORD = sdram[2*counter];
    }
    for (counter = 0; counter < 16; ++counter)
    {
      LED_WORD = sdram[2*counter];
      for (i = 0; i < 1; ++i)
        ;
      LED_WORD = 0xca;
    }
  }
}
