
PortB EQU 0x40010C00
PortA EQU 0x40010800
RCC EQU 0x40021000

; ADDress = Base ADDress + Offset 
       AREA mycode, CODE, READONLY
       EXPORT __main
	   ENTRY

__main
   ;Set up
   ;enaBLe clock port A,B
   LDR r3,=RCC
   MOV32 r0,#0x0C
   STR r0,[r3,#0x18]
   
   ; GPIOx_CRH: 0 - 15,
   ;configure A0,A1 as input pull down
   LDR r1,=PortA
   MOV32 r0,#0x088
   STR r0,[r1,#0x00]
   MOV32 r0,#0x00
   STR r0,[r1,#0x0C]
   
   ;configure B0 as output push pull 
   LDR r2,=PortB
   MOV32 r0,#0x02
   STR r0,[r2,#0x00]; GPIOx_CRL
   MOV32 r0,0x00
   STR r0,[r2,#0x0C]; GPIO_ODR
   
   ;dutycycle
   ;initialy r5=600000
   MOV32 r5,#600000 ;30% duty cycle
   MOV32 r6,#2000000 ;2s->0.5Hz
   MOV32 r8,#10000 ;100hz
kiemtra
   LDR r0,[r1,#0x08]; Kiem tra A0(Breathe Switch)
   ANDS r0,r0,#0x01
   BEQ next ;Kiem tra A1(Change Switch)
   BL breathing
   b kiemtra

   
next   LDR r0,[r1,#0x08] ; Kiem tra A0
   ANDS r0,r0,#0x02
   BEQ this ; if A0 == 0
while ; stop oscilation
   LDR r0,[r1,#0x08]
   ANDS r0,r0,#0x02
   BNE while
; Kiem tra neu tha nut Change 
   MOV32 r4,#400000;20%
   ADD r5,r5,r4
   CMP r5,r6 ;neu dang o 90% duty cycle thi chuyen duty cycle sang 10%
   BLs this 
   MOV32 r5,#200000;10%
this   BL toggle
   b kiemtra
   
   
   ;Nhay theo duty cycle 
toggle
   push {lr}
   MOV32 r0,#0x01
   STR r0,[r2,#0x0C]
   MOV r0,r5
   BL delay1
   MOV32 r0,#0x00
   STR r0,[r2,#0x0C]
   SUB r0,r6,r5
   BL delay1
   pop{lr}
   MOV pc,lr ; return

delay1;8n cycle
  CMP r0,#0x00
  nop
  nop
  nop
  BEQ return1
  SUB r0,r0,#1
  b delay1
return1
  MOV pc,lr
  
breathing
   push{lr,r5}
   LDR r7,=SinTaBLe
   ADD r3,r7,#200
for
   CMP r7,r3
   bge return3
   LDR r0,[r1,#0x08]; co the bo 107-109
   ANDS r0,#0x01
   BEQ return3
   BL breathloop
   ADD r7,r7,#2
   b for
   
return3   pop {lr,r5}
          MOV pc,lr
		  
		  
; breath loop		  
breathloop
   MOV32 r5,#0
   push {lr}
for2
   CMP r5,#2 ; lap 2 lan tai duty cycle tai [r7]
   bgt donebreath
   LDR r0,[r1,#0x08] ; kiem tra nut A0 
   ANDS r0,#0x01
   BEQ donebreath
   MOV r0,#0x01
   STR r0,[r2,#0x0C]
   LDRH r0,[r7,#0]
   BL delay1
   LDR r0,[r1,#0x08] ;kiem tra nut A0
   ANDS r0,#0x01
   BEQ donebreath
   MOV r0,#0x00
   STR r0,[r2,#0x0C]
   LDRH r0,[r7,#0]
   SUB r0,r8,r0
   BL delay1
   ADD r5,r5,#1
   b for2
donebreath
   pop{lr}
   MOV pc,lr
   

          ALIGN 4
SinTaBLe 
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
 
   
   
      
   ALIGN
	   
	   
   END
