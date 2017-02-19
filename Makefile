PROJ = ice40_picorv32
PIN_DEF = ice40_picorv32.pcf
DEVICE = hx8k

RISCV_DIR=/kvm/src/riscv/install/bin
GCC=$(RISCV_DIR)/riscv32-unknown-elf-gcc
OBJCOPY=$(RISCV_DIR)/riscv32-unknown-elf-objcopy

all: $(PROJ).rpt $(PROJ).bin picorv32_tb.vvp

picorv32_tb.vvp: picorv32_tb.v picorv32.v useblockram.v debugleds.v addr_decoder.v
	iverilog -o picorv32_tb.vvp picorv32_tb.v picorv32.v useblockram.v debugleds.v addr_decoder.v

test3.bin: test3.elf
	$(OBJCOPY) -O binary test3.elf test3.bin

test3.elf: test3.o picoriscv32.ld picoriscv32_startup.o
	$(GCC) -nostdlib -T picoriscv32.ld -o test3.elf picoriscv32_startup.o test3.o -Wl,--gc-sections

test3.o: test3.c
	$(GCC) -Os -Wall test3.c -c -o test3.o

picoriscv32_startup.o: picoriscv32_startup.s
	$(GCC) $< -c -o $@

ramdata.list: test3.bin
	perl -le 'open F, "<", $$ARGV[0] or die "$$!\n"; for (;;) { $$l = sysread(F, $$x, 4); last unless $$l; printf("%08x\n", unpack("V", $$x));}' test3.bin > ramdata.list

sim: picorv32_tb.vvp ramdata.list
	vvp picorv32_tb.vvp -lxt2

%.blif: %.v
	yosys -q -p 'synth_ice40 -top top -blif $@' $< \
		picorv32.v useblockram.v debugleds.v addr_decoder.v

%.asc: $(PIN_DEF) %.blif
	arachne-pnr -d $(subst hx,,$(subst lp,,$(DEVICE))) -o $@ -p $^

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

$(PROJ).blif: picorv32.v useblockram.v debugleds.v addr_decoder.v ramdata.list

prog: $(PROJ).bin
	iceprog -S $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin

.SECONDARY:
.PHONY: all prog clean sim
