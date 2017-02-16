#include <stdint.h>


int
main(void)
{
  for (;;) {
    *(volatile uint8_t *)0x103 = 0x42;
    (void)*(volatile uint8_t *)0x103;
    *(volatile uint16_t *)0x112 = 0xcafe;
    (void)*(volatile uint16_t *)0x112;
  }
}
