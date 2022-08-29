.section .data
num1: .byte 0b00000000, 0b01110000, 0b11111100, 0b00111111 @ sign bit= 0 exponent =011 1111 1111 1100 = 16380 - 16383(bias)  = -3 mantisaa = 0111 0000 0000 0000 number = 1.0111 * 2^ -3 =.0010111 = 0.1796875
num2: .byte 0b00000000, 0b00101000, 0b11111110, 0b00111111 @ number = 1.00101 * 2^-1 = 0.578125 as little endian so reversly bytes stored
num3: .byte 0b00000000, 0b01000000, 0b11111101, 0b00111111 @ number = 1.01 * 2^-2 = 0.3125 
num4: .byte 0b00000000, 0b10000000, 0b11111110, 0b00111111 @ number = 1.1 * 2^-1 = 0.75 as little endian so reversly bytes stored
con1: .word 0x7fff0000
con2: .word 0x0000ffff
con3: .word 0xfffe0000
con4: .word 16383
resultAdd: .skip 32
resultMul: .skip 32

.section .text 
.global _start

lpfpAdd:
@r2>r1
stmfd sp!, {r0-r9,lr}
ldr r0, =num1
ldr r1, [r0]
ldr r0, =num2
ldr r2, [r0]

sign:
and R3, R1, #0x80000000
and R4, R2, #0x80000000
eor r3, r3, r4  @if same sign then equal to 0 else not 0

exponent: 
ldr r9, =con1
ldr r9, [r9]
and r5, r1, r9
and r6, r2, r9
sub r5, r6, r5  @ to store exponent difference 

mantissa:
ldr r9, =con2
ldr r9, [r9]
and r7, r1, r9
orr r7, r7, #0x00010000   @add 1 of significand 
and r8, r2, r9
orr r8, r8, #0x00010000

mov r5, r5, lsr #16
mov r7, r7, lsr r5   
cmp r3, #0  @2's complement if one is negative(smaller one will be)
mvnne r7, r7 
addne r7, r7, #1

add r7, r7, r8
convertback:
and r8, r7, #0xfffeffff   @remove one(of significand)
mov r1, #0
add r1, r4, r6
add r1, r1, r8

ldr r0, =resultAdd
str r1, [r0]
ldmfd sp!, {r0-r9,pc}

lpfpMultiply:

stmfd sp!, {r0-r9,lr}
ldr r0, =num3
ldr r1, [r0]
ldr r0, =num4
ldr r2, [r0]

signmul:
and R3, R1, #0x80000000
and R4, R2, #0x80000000
eor r3, r3, r4  @if same sign then equal to 0 else not 0

exponentmul: 
ldr r9, =con1
ldr r9, [r9]
and r5, r1, r9
and r6, r2, r9
add r5, r5, r6 @addition of exponent
ldr r9, =con4
ldr r9, [r9]
mov r9, r9, lsl #16
sub r5, r5, r9

mantissamul:
ldr r9, =con2
ldr r9, [r9]
and r7, r1, r9
orr r7, r7, #0x00010000   @add 1 of significand 
and r8, r2, r9
orr r8, r8, #0x00010000
mul r8, r8, r7 
mov r8, r8, lsr #16
and r8, r8, r9

normalisation:
mov r1, #0x00008000
loopRight:
and r7, r1, r8
cmp r7, #0
subeq r5, r5, #1
moveq r8, r8, lsl #1
 
mov r1, #0
add r1, r5, r3
add r1, r1, r8

ldr r0, =resultMul
str r1, [r0]
ldmfd sp!, {r0-r9,pc}

_start:
bl lpfpAdd
bl lpfpMultiply
mov r0, #0
