MEMORY
{
	RAM_FPGA (rwx) : ORIGIN = 0x00000000, LENGTH = 512
}
_estack = 0x00000200;


SECTIONS
{
	.text :
	{
		KEEP(*(.isr_vector))
		*(.text*)
		*(.rodata*)
		. = ALIGN(4);
		_etext = .;
	} > RAM_FPGA

	_sidata = .;

	.data : AT(_sidata)
	{
		_sdata = .;
		*(.data*)
		. = ALIGN(4);
		_edata = .;
	} > RAM_FPGA

	.bss :
	{
		_sbss = .;
		*(.bss*)
		*(COMMON)
		. = ALIGN(4);
		_ebss = .;
	} > RAM_FPGA

	/* Check that there is room for stack. */
	._stack_free_space :
	{
		. = . + 64;  /* Minimum 64 byte stack free. */
	} > RAM_FPGA
}

ENTRY(_cpu_init)
