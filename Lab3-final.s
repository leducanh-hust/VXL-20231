GPIO_PORTA_CRL EQU 0x40010800
GPIO_PORTB_CRL EQU 0x40010C00
GPIO_PORTA_ODR EQU 0x4001080C
GPIO_PORTB_ODR EQU 0x40010C0C
GPIO_PORTA_IDR EQU 0x40010808
GPIO_PORTB_IDR EQU 0x40010C08
RCC EQU 0x40021000


   AREA mycode, CODE, READONLY
   EXPORT __main
	ENTRY  

__main
   LDR R0,=RCC
   LDR R1,[R0]
   MOV32 R1,#0x0C
   STR R1,[R0, #0x18]
	
	NOP

   LDR R0,=GPIO_PORTA_CRL
   LDR R1,[R0]
   MOV32 R1,#0x88
   STR R1,[R0]

   LDR R0,= GPIO_PORTA_ODR
   LDR R1,[R0]
   MOV32 R1, #0x00  ;enable PA5 digital port
   STR R1,[R0]

   LDR R0,=GPIO_PORTB_CRL
   LDR R1,[R0]
   MOV32 R1,#0x02
   STR R1,[R0]

   LDR R0,= GPIO_PORTB_ODR
   LDR R1,[R0]
   MOV32 R1, #0x00  ;enable PB0 digital port
	
   MOV R2, #30 
loop
    
	LDR R0, =GPIO_PORTA_IDR
    LDR R1, [R0]
    ANDS R1, R1, #0x02
    BEQ check_breathe
    BAL changePressed

check_breathe
    LDR R0, =GPIO_PORTA_IDR
    LDR R1, [R0]
    ANDS R1, R1, #0x01
    BEQ default
    BAL breathePressed

changePressed
    LDR R0, =GPIO_PORTA_IDR
    LDR R1, [R0]
    ANDS R1, R1, #0x02
    BNE changePressed
    ADD R2, R2, #20
    CMP R2, #90
    BLE default
    MOV R2, #10

default
    BL toggle
	B loop

breathePressed
    LDR R0, =GPIO_PORTA_IDR
    LDR R1, [R0]
    ANDS R1, R1, #0x01
    CMP R1, #0x01
    BNE default
    BL breathe
    B breathePressed



breathe
    LDR R0, =SinTable
    add r1,r0,#200
    push{lr}
for 
    cmp r0,r1
    bge done
    ldrh r3,[r0]
    bl breathloop
    add r0,r0,#2
	b for
done
   pop {lr}
   BX LR

   
breathloop
    push {lr,r1}
    LDR R4, =GPIO_PORTB_ODR
    LDR R6, [R4]
    MOV32 R6, #0x01
    STR R6, [R4]
	mov r1,r3
    bl Delay
    LDR R4, =GPIO_PORTB_ODR
    LDR R6, [R4]
    MOV32 R6, #0x00
    STR R6, [R4]
	mov32 r4,#10000
	sub r1,r4,r3
    bl Delay
    pop{lr,r1}
    BX LR



toggle
	LDR R0,=GPIO_PORTB_ODR
    LDR R1,[R0]
    MOV32 R1, #0x01 ;set PE5 to 1
    STR R1,[R0]
	
	LDR R0, =GPIO_PORTA_IDR
    LDR R1, [R0]
    ANDS R1, #0x02
    BNE changePressed

    MOV R3, #20
	MUL R1, R2, R3
	push {lr}
    BL DelayFunc

    LDR R0,=GPIO_PORTB_ODR
    LDR R1,[R0]
    MOV32 R1, #0x00 ;set PE5 to 0
    STR R1,[R0]
	
	LDR R0, =GPIO_PORTA_IDR
    LDR R1, [R0]
    ANDS R1, R1, #0x02
    BNE changePressed
	
    MOV R5, #100
	SUB R5, R5, R2
	MUL R1, R5, R3
    BL DelayFunc
	
	LDR R0, =GPIO_PORTA_IDR
    LDR R1, [R0]
    ANDS R1, R1, #0x02
    BNE changePressed
	pop {lr}
    BX LR
    
DelayFunc
	MOV32 R5, #1000
	MUL R1, R1, R5
Delay NOP ;dummy operation 8cycle->1v 100ns->5000000
      NOP
      NOP
      NOP
      SUBS R1,R1,#1
      BNE  Delay
      BX   LR

  ALIGN 4
; 256 points with values from 100 to 9900      
SinTable
     DCW  5000, 5308, 5614, 5918, 6219, 6514, 6804, 7086, 7361, 7626
  DCW  7880, 8123, 8354, 8572, 8776, 8964, 9137, 9294, 9434, 9556
  DCW  9660, 9746, 9813, 9861, 9890, 9900, 9890, 9861, 9813, 9746
  DCW  9660, 9556, 9434, 9294, 9137, 8964, 8776, 8572, 8354, 8123
  DCW  7880, 7626, 7361, 7086, 6804, 6514, 6219, 5918, 5614, 5308
  DCW  5000, 4692, 4386, 4082, 3781, 3486, 3196, 2914, 2639, 2374
  DCW  2120, 1877, 1646, 1428, 1224, 1036,  863,  706,  566,  444
  DCW   340,  254,  187,  139,  110,  100,  110,  139,  187,  254
  DCW   340,  444,  566,  706,  863, 1036, 1224, 1428, 1646, 1877
  DCW  2120, 2374, 2639, 2914, 3196, 3486, 3781, 4082, 4386, 4692
     ALIGN      ; make sure the end of this section is aligned
     END        ; end of file
