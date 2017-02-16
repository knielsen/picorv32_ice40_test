#include <stdint.h>


int
main(void)
{
  uint32_t counter = 0;
  for (;;) {
    (void)*((volatile uint32_t *)(counter & 0x7c));
    counter += 4;
  }
}
