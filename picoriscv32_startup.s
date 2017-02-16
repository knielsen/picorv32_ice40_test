	.option nopic
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	_cpu_init
	.type	_cpu_init, @function
_cpu_init:
	lui	sp, %hi(_estack)
	addi	sp, sp, %lo(_estack)
	jal	main
.L1:
	j	.L1
	.size	_cpu_init, .-_cpu_init
