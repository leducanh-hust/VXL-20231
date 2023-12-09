;****************** Lab3.s ***************
; Program written by: Le Duc Anh
; Date Created: 2/4/2017
; Last Modified: 1/4/2023
; Brief description of the program
;   The LED toggles at 2 Hz and a varying duty-cycle
; Hardware connections (External: Two buttons and one LED)
;  Change is Button input  (1 means pressed, 0 means not pressed)
;  Breathe is Button input  (1 means pressed, 0 means not pressed)
;  LED is an output (1 activates external LED)
; Overall functionality of this system is to operate like this
;   1) Make LED an output and make Change and Breathe inputs.
;   2) The system starts with the the LED toggling at 2Hz,
;      which is 2 times per second with a duty-cycle of 30%.
;      Therefore, the LED is ON for 150ms and off for 350 ms.
;   3) When the Change button is pressed-and-released increase
;      the duty cycle by 20% (modulo 100%). Therefore for each
;      press-and-release the duty cycle changes from 30% to 50% to 70%
;      to 90% to 10% to 30% so on
;   4) Implement a "breathing LED" when Breathe Switch is pressed:
; PortE device registers
GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_DEN_R   EQU 0x4002451C
SYSCTL_RCGCGPIO_R  EQU 0x400FE608
frequency_100Hz    EQU 10 ; 100 Hz   


        IMPORT  TExaS_Init
        THUMB
        AREA    DATA, ALIGN=2
;global variables go here

       AREA    |.text|, CODE, READONLY, ALIGN=3
       THUMB
       EXPORT EID1
EID1   DCB "20213687",0  ;replace ABC123 with your EID
       EXPORT EID2
EID2   DCB "20213698",0  ;replace ABC123 with your EID
       ALIGN 4

     EXPORT  Start

Start
; TExaS_Init sets bus clock at 80 MHz, interrupts, ADC1, TIMER3, TIMER5, and UART0
    MOV R0,#2  ;0 for TExaS oscilloscope, 1 for PORTE logic analyzer, 2 for Lab3 grader, 3 for none
    BL  TExaS_Init ;enables interrupts, prints the pin selections based on EID1 EID2

; Your Initialization goes here
    LDR R0,=SYSCTL_RCGCGPIO_R
    LDR R1,[R0]
    ORR R1,R1,#0x10  ;activate clock for Port E
    STR R1,[R0]
	
	NOP

    LDR R0,=GPIO_PORTE_DIR_R
    LDR R1,[R0]
    MOV R1,#0x20  ;direction PE0, PE3 as input; PE5 as output
    STR R1,[R0]

    LDR R0,= GPIO_PORTE_DEN_R
    LDR R1,[R0]
    ORR R1,R1,#0x29  ;enable PA5 digital port
    STR R1,[R0]
	
    MOV R2, #30 
loop
    
	LDR R0, =GPIO_PORTE_DATA_R
    LDR R1, [R0]
    ANDS R1, R1, #0x01
    CMP R1, #0x01
    BNE default
    BAL ChangePressed

changeduty
    ADD R2, R2, #20
    CMP R2, #100
    BLS default
    MOV r2,#10
    b default

ChangePressed
    BL toggle
    LDR R0, =GPIO_PORTE_DATA_R
    LDR R1, [R0]
    ANDS R1, R1, #0x01
    CMP R1, #0x01
    BNE changeduty
    B ChangePressed



default
    LDR R0, =GPIO_PORTE_DATA_R
    LDR R1, [R0]
    ANDS R1, R1, #0x08
    CMP R1, #0x08
    BEQ breathePressed
    BL toggle
	B loop

breathePressed
    LDR R0, =GPIO_PORTE_DATA_R
    LDR R1, [R0]
    ANDS R1, R1, #0x08
    CMP R1, #0x08
    BNE default
    BL breathe
    B breathePressed



breathe
    LDR R0, =PerlinTable
    add r1,r0,#512
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
   mov pc,lr

   
breathloop
    push {lr,r1}
    LDR R4, =GPIO_PORTE_DATA_R
    LDR R6, [R4]
    ORR R6, R6, #0x20
    STR R6, [R4]
	mov r1,r3
    bl Delay
    LDR R4, =GPIO_PORTE_DATA_R
    LDR R6, [R4]
    BIC R6, R6, #0x20
    STR R6, [R4]
	mov32 r4,#10000
	sub r1,r4,r3
    bl Delay
    pop{lr,r1}
    mov pc,lr



toggle
	LDR R0,=GPIO_PORTE_DATA_R
    LDR R1,[R0]
    ORR R1,R1,#0x20  ;set PE5 to 1
    STR R1,[R0]
	

    MOV R3, #5
	MUL R1, R2, R3
	push {lr}
    BL DelayFunc

    LDR R0,=GPIO_PORTE_DATA_R
    LDR R1,[R0]
    BIC R1,R1,#0x20  ;set PE5 to 0
    STR R1,[R0]
	
    MOV R5, #100
	SUB R5, R5, R2
	MUL R1, R5, R3
    BL DelayFunc
	pop {lr}
    MOV PC, LR
    
DelayFunc
	MOV32 R5, #10000
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
PerlinTable
     DCW 5880,6225,5345,3584,3545,674,5115,598,7795,3737,3775,2129,7527,9020,368,8713,5459,1478,4043,1248,2741,5536,406
     DCW 3890,1516,9288,904,483,980,7373,330,5766,9555,4694,9058,2971,100,1095,7641,2473,3698,9747,8484,7871,4579,1440
     DCW 521,1325,2282,6876,1363,3469,9173,5804,2244,3430,6761,866,4885,5306,6646,6531,2703,6799,2933,6416,2818,5230,5421
     DCW 1938,1134,6455,3048,5689,6148,8943,3277,4349,8866,4770,2397,8177,5191,8905,8522,4120,3622,1670,2205,1861,9479
     DCW 1631,9441,4005,5574,2167,2588,1057,2512,6263,138,8369,3163,2895,8101,3009,5153,7259,8063,3507,789,6570,7756,7603
     DCW 5268,5077,4541,7297,6187,3392,6378,3928,4273,7680,6723,7220,215,2550,2091,8407,8752,9670,4847,4809,291,7833,1555
     DCW 5727,4617,4923,9862,3239,3354,8216,8024,7986,2359,8790,1899,713,2320,751,7067,7335,1172,1708,8637,7105,6608,8254
     DCW 4655,9594,5919,177,1784,5995,6340,2780,8560,5957,3966,6034,6493,1746,6684,445,5038,942,1593,9785,827,3852,4234
     DCW 4311,3124,4426,8675,8981,6914,7182,4388,4081,8445,9517,3813,8828,9709,1402,9364,7488,9211,8139,5613,559,7412
     DCW 6952,6302,9326,3201,2052,5651,9096,9632,636,9249,4196,1976,7450,8292,1287,7029,7718,4158,6110,7144,3316,7909
     DCW 6838,4502,4732,2014,1823,4962,253,5842,9823,5383,9134,7948,3660,8598,4464,2665,1210,1019,2856,9402,5498,5000
     DCW 7565,3086,2627,8330,2435,6072,6991
      
     ALIGN      ; make sure the end of this section is aligned
     END        ; end of file