#include <stdint.h>

struct gdt_entry {
  uint16_t limit1;
  uint16_t base1;
  uint8_t base2;
  uint8_t access;
  uint8_t limitflags;
  uint8_t base3;
}__attribute__((packed));

struct gdt_pointer {
  uint16_t limit;
  size_t table;
}__attribute__((packed));

void gdt_init();

void gdt_entry_init(uint32_t index, uint32_t base, uint32_t limit, uint8_t access, uint8_t flags);

