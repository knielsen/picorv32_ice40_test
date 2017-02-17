#include <stdint.h>


#define LED_WORD (*(volatile uint8_t *)0x1ff)
int
main(void)
{
  uint8_t counter = 0;
  uint32_t i;

  for (;;) {
    LED_WORD = counter ^ (counter >> 1);
    ++counter;
    for (i = 0; i < 1000000; ++i)
      asm volatile("");
  }
}
