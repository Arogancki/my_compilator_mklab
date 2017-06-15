.data
	.String0:	.asciiz	"\nPodaj numer liczby fib\n"
	.String1:	.asciiz	"\nWynik: "
	.iStack0:	.word	0
	.iStack1:	.word	0
	.iStack2:	.word	0
	.iStack3:	.word	0
	.iStack4:	.word	0
	arg1:	.word	0
	fib_arg1:	.word	0
	fib_arg2:	.word	0
	temp:	.word	0
.text
	li	$t0,	0
	li	$t1,	0
	beq	$t0,	$t1,	omit0
fun_fib2:
	addi	$sp,	$sp,	-4
	sw	$ra,	0($sp)

	lw	$t0,	fib_arg2
	sw	$t0,	temp

	lw	$t1,	fib_arg2
	lw	$t2,	fib_arg1
	add	$t0,	$t1,	$t2
	sw	$t0,	.iStack0

	lw	$t0,	.iStack0
	sw	$t0,	fib_arg2

	lw	$t0,	temp
	sw	$t0,	fib_arg1

	li	$t4,	0
	lw	$ra,	0($sp)
	add	$sp,	$sp,	4
	jr	$ra

omit0:
	li	$t0,	0
	li	$t1,	0
	beq	$t0,	$t1,	omit1
fun_fib:
	addi	$sp,	$sp,	-4
	sw	$ra,	0($sp)

	lw	$t1,	arg1
	li	$t2,	2
	slt	$t0,	$t1,	$t2
	sw	$t0,	.iStack1

	lw	$t0,	.iStack1
	li	$t1,	1
	li	$t4,	1
	bne	$t0,	$t1,	if2
	li	$t0,	0
	sw	$t0,	arg1

	li	$t4,	0
if2:
	li	$t1,	0
	beq	$t4,	$t1,	else3
	lw	$t1,	arg1
	li	$t2,	2
	beq	$t1,	$t2,	l4
	li	$t0,	0
	bne	$t1,	$t2,	l5
l4:
	li	$t0,	1
l5:
	sw	$t0,	.iStack2

	lw	$t0,	.iStack2
	li	$t1,	1
	li	$t4,	1
	bne	$t0,	$t1,	if6
	li	$t0,	1
	sw	$t0,	arg1

	li	$t4,	0
if6:
	li	$t1,	0
	beq	$t4,	$t1,	else7
	li	$t0,	0
	sw	$t0,	fib_arg1

	li	$t0,	1
	sw	$t0,	fib_arg2

	lw	$t1,	arg1
	li	$t2,	2
	sub	$t0,	$t1,	$t2
	sw	$t0,	.iStack3

	lw	$t0,	.iStack3
	sw	$t0,	arg1

	li	$t0,	1
WHIS8:
	li	$t1,	0
	beq	$t0,	$t1,	WHIE9

	jal	fun_fib2
	lw	$t1,	arg1
	li	$t2,	1
	sub	$t0,	$t1,	$t2
	sw	$t0,	.iStack4

	lw	$t0,	.iStack4
	sw	$t0,	arg1

	li	$t4,	0
	jal	WHIS8
WHIE9:
	lw	$t0,	fib_arg2
	sw	$t0,	arg1

	li	$t4,	0
else7:
	li	$t4,	0
else3:
	li	$t4,	0
	lw	$ra,	0($sp)
	add	$sp,	$sp,	4
	jr	$ra

omit1:
	li	$v0,	4
	la	$a0,	.String0
	syscall

	li	$v0,	5
	syscall

	sw	$v0,	arg1
	jal	fun_fib
	li	$v0,	4
	la	$a0,	.String1
	syscall

	li	$v0,	1
	lw	$a0,	arg1
	syscall



	li	$v0,	10
	syscall
