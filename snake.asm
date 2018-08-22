;
; Snek2Dangernoodle.asm
;
; Created: 2017-05-03 18:59:06
; Author : Johan Lavén, Erik Holm, Anna Kristoffersson
;


; Replace with your application code

.DEF	rTemp			=	r16				//rTemp - Temporära register som används för att göra ekvationer och maska m.m
.DEF	rTemp2			=	r17
.DEF	rTemp3			=	r18
.def	rTemp4			=	r19
.DEF	radItteratorn	=	r20				//En räknare som går igenom raderna för att se vilka som ska vara tända
.DEF	stepItterator	=	r21				//En räknare som används i ormens rörelse
.Def	snekHead		=	r22				//Ormens huvud
.DEF	appleCounter	=	r23				//Håller koll på hur många äpplen ormen ätit
.def	loopTemp0		=	r24
.def	loopTemp1		=	r25
.def	randomItt		=	r26				//En iterator som räknar och ger ett randomnummer. Används för att spawna äpplen.

.DEF	nollReg	=	r1						//Ett nollregister

.DEF	rad0	=	r3						//Register för alla rader.
.DEF	rad1	=	r4
.DEF	rad2	=	r5
.DEF	rad3	=	r6
.DEF	rad4	=	r7
.DEF	rad5	=	r8
.DEF	rad6	=	r9
.DEF	rad7	=	r10
.DEF	radTemp	=	r11						//Register för rad 0-7 för att kolla igenom vilka lampor som ska tändas.
.DEF	yInput	=	r12						//Register för inputen i y led från Joysticken
.DEF	xInput	=	r13						//Register för inputen i x led från Joysticken

.DSEG
	minnesarray:	.byte 64				//En minnesarray för 64 bytes som representerar lamporna i ledjoyen
	AppleLocation:	.byte 1					//En minnesadress som sparar äpplets position på en byte


.CSEG
.ORG 0x0000									//Resetknappen
	jmp init								//hoppar till INITIALIIIZE

.ORG 0x0012
	jmp timer2Interupt

.ORG 0x0020
	jmp timer0Interupt
afterDeath:									//AfterDeath - En rutin som nollställer hela matisen av lampor innan restart. 
	out PORTC, nollreg						//Nollsätter alla portar
	out portD, nollreg
	out PORTB, nollreg
	ldi rTemp, 0x3f							//Nollställer minnesarrayen
	ldi YH, HIGH(minnesarray)
	clearLoop:
	ldi YL, LOW(minnesarray)
	add YL, rTemp
	st Y, nollReg
	subi rTemp, 1
	cpi rTemp, 0x00
	brne clearLoop
	clr rad0								//Clearar alla rader
	clr rad1
	clr rad2
	clr rad3
	clr rad4
	clr rad5
	clr rad6
	clr rad7


init:										//INITIALIZEEE
	
	CLR r1
	// Sätt stackpekaren till högsta minnesadressen

    ldi rTemp, HIGH(RAMEND)
    out SPH, rTemp
    ldi rTemp, LOW(RAMEND)
    out SPL, rTemp


	SEI	//TILLÅT INTERUPTS

	ldi raditteratorn, 0b00000001			// sätter raditteratorn till 00000001

	ldi rTemp, 0b00001111					//sätter bittar 0-3 till 1(00001111) i register DDRC (port C) Detta pga portartna är konstigt uppdelade i raderna och kolumnerna
	out DDRC, rTemp							//för att visa att det är OUTPUT-pins och inte input

	ldi rTemp, 0b00111111					//sätter bittar 0-5 till 1(00111111)
	out DDRB, rTemp

	ldi rTemp, 0b11111100					//sätter bittar 2-7 till 1(11111100)
	out DDRD, rTemp
	

	ldi appleCounter, 0x00					//Nollar applecounter

	
	/*MATRIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIS*/ // Matris för alla lampor på ledjoyen
	MATRIX:
	ldi rtemp, 0b00000000
	mov rad0, rtemp
	ldi rtemp, 0b00000000
	mov rad1, rtemp
	ldi rtemp, 0b00000000
	mov rad2, rtemp
	ldi rtemp, 0b00000000
	mov rad3, rtemp
	ldi rtemp, 0b00000000
	mov rad4, rtemp
	ldi rtemp, 0b00000000
	mov rad5, rtemp
	ldi rtemp, 0b00000000
	mov rad6, rtemp
	ldi rtemp, 0b00000000
	mov rad7, rtemp
	/*MATRIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIS*/
	
	/*CLEARA minnesarray upp till pixeladress + 64*/ // Nollar alla bytes i minnesarrayyen
	ldi rTemp, 0x00

	ldi YH, HIGH(minnesarray)
	ldi YL, LOW(minnesarray)

	ClearMemoryLoop:
	ldi YL, LOW(minnesArray)
	add YL, rTemp
	
	st Y, nollreg

	subi rTemp, -1
	cpi rTemp, 0xff
	breq snekstartPosition
	jmp ClearMemoryLoop

	snekstartPosition:						// Sätter ormens start pos och riktning
	ldi snekHead, 0b10011101

INPUT:										//Joystickens input					
	lds rTemp2, ADMUX						//Maskar in ettor i bittar 5 och 6 i registret ADMUX
	ori rTemp2, 0b01100000
	sts ADMUX, rTemp2

	lds rTemp2, ADMUX						//Maskar  in en nolla i bitt 7 i registret ADMUX
	andi rTemp2, 0b01111111
	sts ADMUX, rTemp2
					
	lds rTemp2, ADCSRA						//Maskar in ettor i bittar 0, 1, 2, 7 i registret ADCSRA
	ori rTemp2, 0b10000111						
	sts ADCSRA, rTemp2


TIMER:											//Timers där man ställer in timern för scanlines eller ormens rörelse
												// Här ska scanline-timerhastigheten ställas
	rcall snabb				
	ldi rTemp, (1<<TOIE0)
	lds rTemp2, TIMSK0
	or rTemp, rTemp2
	sts TIMSK0, rTemp

							// Här ska Snake-rörelsetimer ställas 
	rcall lugn				
	ldi rTemp, (1<<TOIE2)
	lds rTemp2, TIMSK2
	or rTemp, rTemp2
	sts TIMSK2, rTemp

	resetRandomItt:			//Resettar randomItteratorn till noll
	ldi randomItt, 0x00

mainLoop:					//Mainloopen där vi tänder rätt rad med rätt lampor
	subi randomItt, -1						//Lägger på 1 på randomitteratorn
	cpi randomItt, 0xff						//Jämför randomitteratorn med 255 och branchar till resetRandomItt när dom är lika.
	breq resetRandomItt
//************Y-STÄLL***************-//
	lds loopTemp1, ADMUX			//Maskar in en etta i bitt 2 i registret ADMUX
	ori loopTemp1, 0b00000100
	sts ADMUX, loopTemp1

	lds loopTemp1, ADMUX			//Maskar in nollor i bittarna 0, 1, 3 i registret ADMUX
	andi loopTemp1, 0b11110100
	sts ADMUX, loopTemp1

	SET										//Sätter T-bitten till ett (T ÄR EN BIT I STATUSREGISTRET)
	lds loopTemp1, ADCSRA					//Sätter ADSC-bitten i ADCSRA till det som va i T-bitten
	BLD loopTemp1, ADSC
	sts ADCSRA, loopTemp1

	yItteration:				//Startar en konvertering som konverterar analog input till digital input och loopar tills konverteringen är klar. 
	lds loopTemp1, ADCSRA				//Resultatet hamnar i y-input
	sbrs loopTemp1, ADIF
	jmp yItteration
	lds yInput, ADCH

//************X-STÄLL***************-//
	
	lds loopTemp1, ADMUX					//Maskar in ettor i bittarna 0, 2 i registret ADMUX
	ori loopTemp1, 0b00000101
	sts ADMUX, loopTemp1

	lds loopTemp1, ADMUX		//Maskar in nollor i bittarna 1, 3 i registret ADMUX
	andi loopTemp1, 0b11110101
	sts ADMUX, loopTemp1

	SET										//Sätter T-bitten till ett
	lds loopTemp1, ADCSRA					//Sätter ADSC-bitten i ADCSRA till det som va i T-bitten
	BLD loopTemp1, ADSC
	sts ADCSRA, loopTemp1

	xItteration:				//Startar en konvertering som konverterar analog input till digital input och loopar tills konverteringen är klar. 
	lds loopTemp1, ADCSRA				//Resultatet hamnar i x-input
	sbrs loopTemp1, ADIF
	jmp xItteration
	lds xInput, ADCH
	
	rcall saveRow				//Hoppar till saveRow

	cpi radItteratorn, 0b00000001			//Här kollas det vilken rad som ska vara tänd just nu. Sen branchar vi till rätt ställe beroende på vilken rad. 
	breq rad0LIGHT
	cpi radItteratorn, 0b00000010
	breq rad1LIGHT
	cpi radItteratorn, 0b00000100
	breq rad2LIGHT
	cpi radItteratorn, 0b00001000
	breq rad3LIGHT
	cpi radItteratorn, 0b00010000
	breq rad4LIGHT
	cpi radItteratorn, 0b00100000
	breq rad5LIGHT
	cpi radItteratorn, 0b01000000
	breq rad6LIGHT
	cpi radItteratorn, 0b10000000
	breq rad7LIGHT
	skip:

jmp mainLoop				//Loopar mainloopen genom att hoppa tillbaka till början igen.

rad0LIGHT:					//Här tänds den utvalda raden
	rcall LedLighter

	ldi loopTemp1, 0b00000001	//Sätter så att rad0 är aktiverad
	out PORTC, loopTemp1

	jmp skip

rad1LIGHT:
	rcall LedLighter

	ldi loopTemp1, 0b00000010	//Sätter så att rad1 är aktiverad
	out PORTC, loopTemp1

	jmp skip

rad2LIGHT:
	rcall LedLighter
	
	ldi loopTemp1, 0b00000100	//Sätter så att rad2 är aktiverad
	out PORTC, loopTemp1

	jmp skip

rad3LIGHT:
	rcall LedLighter

	ldi loopTemp1, 0b00001000	//Sätter så att rad3 är aktiverad
	out PORTC, loopTemp1
	
	jmp skip

rad4LIGHT:
	ldi loopTemp1, 0x00
	out PORTC, loopTemp1

	rcall LedLighter

	ldi loopTemp0, 0b00000100
	or loopTemp0, loopTemp1
	out PORTD, loopTemp0

	jmp skip

rad5LIGHT:
	rcall LedLighter

	ldi loopTemp0, 0b00001000
	or loopTemp0, loopTemp1
	out PORTD, loopTemp0

	jmp skip

rad6LIGHT:
	rcall LedLighter

	ldi loopTemp0, 0b00010000
	or loopTemp0, loopTemp1
	out PORTD, loopTemp0

	jmp skip

rad7LIGHT:
	rcall LedLighter

	ldi loopTemp0, 0b00100000
	or loopTemp0, loopTemp1
	out PORTD, loopTemp0

	jmp skip

timer0Interupt:
	cli										//Stänger av interrupts
											//Släcker alla portar
	
		ldi loopTemp1, 0x00		
		out PORTC, loopTemp1
		out PORTD, loopTemp1
		out PORTB, loopTemp1
			
											//skiftar raditteratorn åt vänster/neråt i matrisen
		BST radItteratorn, 7
		lsl radItteratorn	
		BLD radItteratorn, 0

		cpi stepItterator, 0xff
		breq readHead

	sei										//Tillåter interrupts
	RETI
readHead:									//Ormmekaniken
	rcall directionChecker					//Rutin för att kolla rikting som huvudet rör sig
	rcall kolumnChecker						//Rutin för att kolla vilken kolumn huvudet befinner sig
	rcall radChecker						//Rutin för att kolla vilken rad huvudet befinner sig
	rcall moveTailByte						//Rutin för att förskuta alla ormbytes en adress i minnet.
	rcall saveHead							//Sparar nya positionen på huvudet
	rcall drawApple							//Ritar ut äpplet.
	clr stepItterator						//Resettar stegitteratorn
	RETI									//Återvänder från interruptet
saveRow:									//Berättar vilken rad som är aktuell. Den aktuella raden läggs i radTemp
	cpi radItteratorn, 0b00000001
	brne set1
	mov radTemp, rad0
	set1:
	cpi radItteratorn, 0b00000010
	brne set2
	mov radTemp, rad1
	set2:
	cpi radItteratorn, 0b00000100
	brne set3
	mov radTemp, rad2
	set3:
	cpi radItteratorn, 0b00001000
	brne set4
	mov radTemp, rad3
	set4:
	cpi radItteratorn, 0b00010000
	brne set5
	mov radTemp, rad4
	set5:
	cpi radItteratorn, 0b00100000
	brne set6
	mov radTemp, rad5
	set6:
	cpi radItteratorn, 0b01000000
	brne set7
	mov radTemp, rad6
	set7:
	cpi radItteratorn, 0b10000000
	brne dip
	mov radTemp, rad7
	dip:
	ret

LedLighter:						//Kollar och sätter vilka kolumner som ska vara tända på nuvarande rad.

	//B-SET
	clr loopTemp1

	bst radTemp, 5				//Lagrar bit 5 från radTemp till T-bitten i statusregistret
	bld loopTemp1, 0			//Skriver till bit 0 i looptemp1 från T-bitten

	bst radTemp, 4
	bld loopTemp1, 1

	bst radTemp, 3
	bld loopTemp1, 2

	bst radTemp, 2
	bld loopTemp1, 3

	bst radTemp, 1
	bld loopTemp1, 4

	bst radTemp, 0
	bld loopTemp1, 5

	out PORTB, loopTemp1

	// D-SET
	clr loopTemp1
	
	bst radTemp, 7
	bld loopTemp1, 6

	bst radTemp, 6
	bld loopTemp1, 7
	
	out PORTD, loopTemp1
	
	RET



timer2Interupt:								//Här läses inputen och skriver till snekheadregistrets två högsta bittar
	
	subi stepItterator, -1					//Ökar stepitteratorn med ett. 
	
	ldi rTemp, 0b00000111					//Anger tolerans för joysticken
	cp yInput, rTemp						//Jämför toleransen med inputvärdet
	brlo downset							//Branchar till rutin för att sätta riktningen

	ldi rTemp, 0b11111000
	cp yInput, rTemp
	brsh upset

	ldi rTemp, 0b11111000
	cp xInput, rTemp
	brsh leftset

	ldi rTemp, 0b00000111
	cp xInput, rTemp
	brlo rightset
	backaraaaaaa:
		
RETI
downset:									//Rutiner för att sätta riktningar
	clt
	bld snekHead, 7
	bld snekHead, 6
	jmp backaraaaaaa
upset:
	set
	bld snekHead, 7
	bld snekHead, 6
	jmp backaraaaaaa
leftset:
	set
	bld snekHead, 7
	clt
	bld snekHead, 6
	jmp backaraaaaaa
rightset:
	clt
	bld snekHead, 7
	set
	bld snekHead, 6
	jmp backaraaaaaa					//Slut på riktningsrutiner

saveHead:									//Kollar kollisioner ifall tillåten förflyttning. Lagrar huvudet till första adressen i minnesarrayen.
	ldi rTemp, 0b00111111					
	and rTemp, snekHead						//Maskar ut dom två första bittarna  i snekHead. 
	rcall checkForCollision					//Hoppar till checkForCollision(Som innehåller kollisionhantering mot orm resp. äpple)
	ori rTemp, 0b11000000						
	ldi YH, HIGH(minnesarray)
	ldi YL, LOW(minnesarray)
	st Y, rTemp								//Lagrar positionen av huvudet  i minnesarrayen med ettor som två högsta bittar.
	
ret
drawApple:									// RITA UT ÄPPLE PÅ RÄTT PLATS. 
	ldi YH, HIGH(AppleLocation)
	ldi YL, LOW(AppleLocation)
	ld rTemp2, Y

	ldi rTemp, 0b00000111
	and rTemp, rTemp2

	cpi rTemp, 0b00000000					//Kollar positionen på äpplet.Sedan lägger vi motsvarande kolumn i rTemp3 på grund av hur det är mappat i matrisen			
	brne nextCollumnApplePos1
	ldi rTemp3, 0b10000000
	nextCollumnApplePos1:
	cpi rTemp, 0b00000001
	brne nextCollumnApplePos2
	ldi rTemp3, 0b01000000
	nextCollumnApplePos2:
	cpi rTemp, 0b00000010
	brne nextCollumnApplePos3
	ldi rTemp3, 0b00100000
	nextCollumnApplePos3:
	cpi rTemp, 0b00000011
	brne nextCollumnApplePos4
	ldi rTemp3, 0b00010000
	nextCollumnApplePos4:
	cpi rTemp, 0b00000100
	brne nextCollumnApplePos5
	ldi rTemp3, 0b00001000
	nextCollumnApplePos5:
	cpi rTemp, 0b00000101
	brne nextCollumnApplePos6
	ldi rTemp3, 0b00000100
	nextCollumnApplePos6:
	cpi rTemp, 0b00000110
	brne nextCollumnApplePos7
	ldi rTemp3, 0b00000010
	nextCollumnApplePos7:
	cpi rTemp, 0b00000111
	brne nextStuffToDo
	ldi rTemp3, 0b00000001
	nextStuffToDo:
	
	ldi rTemp, 0b00111000					//Gör samma sak som med kolumnerna fast med raderna
	and rTemp, rTemp2

	cpi rTemp, 0b00000000					//OR'ar in resultatet från kolumnhanteraren på rätt rad
	brne nextrowApplePos1
	or rad0, rTemp3
	nextrowApplePos1:
	cpi rTemp, 0b00001000
	brne nextrowApplePos2
	or rad1, rTemp3
	nextrowApplePos2:
	cpi rTemp, 0b00010000
	brne nextrowApplePos3
	or rad2, rTemp3
	nextrowApplePos3:
	cpi rTemp, 0b00011000
	brne nextrowApplePos4
	or rad3, rTemp3
	nextrowApplePos4:
	cpi rTemp, 0b00100000
	brne nextrowApplePos5
	or rad4, rTemp3
	nextrowApplePos5:
	cpi rTemp, 0b00101000
	brne nextrowApplePos6
	or rad5, rTemp3
	nextrowApplePos6:
	cpi rTemp, 0b00110000
	brne nextrowApplePos7
	or rad6, rTemp3
	nextrowApplePos7:
	cpi rTemp, 0b00111000
	brne nextStuffToDo2
	or rad7, rTemp3
	nextStuffToDo2:
ret
checkForCollision:						//Kollar om ormen kolliderat i ett äpple eller sig själv
	ldi YH, HIGH(AppleLocation)				//Laddar in äpplets position i rTemp2
	ldi YL, LOW(AppleLocation)
	ld rTemp2, Y
	cp rTemp2, rTemp						//Jämför ormhuvudets position med äpplets position.
	breq eat								//Om dom är lika så hoppa till eat.
					
	ori rTemp, 0b11000000					//Maska in ettor i rTemps två största bittar eftersom två ettor representerar en del av ormen

	ldi YH, HIGH(minnesarray)
	mov rTemp4, appleCounter				//Loopa igenom alla ormens kroppsdelaroch jämför positionen med positionen på ormens huvud. 
	colLoop:
	ldi YL, LOW(minnesarray)
	add YL, rTemp4
	subi rTemp4, 1
	ld rTemp3, Y
	cp rTemp, rTemp3						//Om positionerna är lika brancha till die.
	breq die

	cp rTemp4, nollreg						//Jämför rTemp4 med nollregistret. Om dom är lika bryt ut ur loopen annars fortsätt.
	breq brekk
	jmp colLoop
	brekk:
ret
eat:										//Här äts äpplet.
	subi appleCounter, -1					//Lägger på ett på appleCounter
	rerollApplePos:
	mov rTemp2, randomItt					//Lägger in äpplets nya position i applelocation
	andi rTemp2, 0b00111111
				/*	subi rTemp2, 1

					ldi ZH, HIGH(minnesarray)			*********************************************************
					ldi ZL, LOW(minnesarray)			*********************************************************
														*********************************************************
					clr rTemp4							*********************************************************
					appleKnyckarJazz:					ICKE FUNGERANDE CHECK IFALL ÄPPLETS NYA POSITION ÄR TAGEN
					ld rTemp3, Z+						*********************************************************
					andi rTemp3, 0b00111111				*********************************************************
					cp rTemp2, rTemp3					*********************************************************
					breq rerollApplePos					*********************************************************
					subi rTemp4, -1						*********************************************************
					cp rTemp4, appleCounter				*********************************************************
					brne appleKnyckarJazz				*********************************************************
				*/
	

	st Y, rTemp2
ret


die:										//Här dör ormen vilket hoppar till afterDeath
	jmp afterDeath
moveTailByte:								//Flyttar alla ormens positioner ett steg i minnet
	ldi YH, HIGH(minnesarray)
	ldi YL, LOW(minnesarray)
	add YL, appleCounter
	rcall removeLast						//släcker sista lampan i ormen.

	mov rTemp, appleCounter
	
	ldi rTemp3, 0x01		
	loopaloop:								//Loopa denna lika många gånger som äpplen vi plockat upp eftersom det är så många kroppsdelar ormen har.
	ldi YL, LOW(minnesarray)
	cpi rTemp, 0b00000000
	breq out0
	subi rTemp, 1
	
	add YL, rTemp
	ld rTemp2, Y
	add YL, rTemp3
	st Y, rTemp2	
	
	jmp loopaloop
	out0:
ret

removeLast:									//Översätter det tre minsta bittarna från rTemp2 till kolumner och sätter den bit som matchar kolumnen i rTemp4.
	ld rTemp2, Y
	andi rTemp2, 0b00000111

	cpi rTemp2, 0b00000000
	brne nextCollumXspot1
	ldi rTemp4, 0b01111111
	nextCollumXspot1:
	cpi rTemp2, 0b00000001
	brne nextCollumXspot2
	ldi rTemp4, 0b10111111
	nextCollumXspot2:
	cpi rTemp2, 0b00000010
	brne nextCollumXspot3
	ldi rTemp4, 0b11011111
	nextCollumXspot3:
	cpi rTemp2, 0b00000011
	brne nextCollumXspot4
	ldi rTemp4, 0b11101111
	nextCollumXspot4:
	cpi rTemp2, 0b00000100
	brne nextCollumXspot5
	ldi rTemp4, 0b11110111
	nextCollumXspot5:
	cpi rTemp2, 0b00000101
	brne nextCollumXspot6
	ldi rTemp4, 0b11111011
	nextCollumXspot6:
	cpi rTemp2, 0b00000110
	brne nextCollumXspot7
	ldi rTemp4, 0b11111101
	nextCollumXspot7:
	cpi rTemp2, 0b00000111
	brne getdown0101
	ldi rTemp4, 0b11111110
	
	getdown0101:
	ld rTemp2, Y
	andi rTemp2, 0b00111000

	cpi rTemp2, 0b00000000						//Översätter bittar 3, 4, 5 från rTemp2 till rader och sätter den bit som matchar raden i rTemp4.
	brne nextRowYspot1
	and rad0, rTemp4
	nextRowYspot1:
	cpi rTemp2, 0b00001000
	brne nextRowYspot2
	and rad1, rTemp4
	nextRowYspot2:
	cpi rTemp2, 0b00010000
	brne nextRowYspot3
	and rad2, rTemp4
	nextRowYspot3:
	cpi rTemp2, 0b00011000
	brne nextRowYspot4
	and rad3, rTemp4
	nextRowYspot4:
	cpi rTemp2, 0b00100000
	brne nextRowYspot5
	and rad4, rTemp4
	nextRowYspot5:
	cpi rTemp2, 0b00101000
	brne nextRowYspot6
	and rad5, rTemp4
	nextRowYspot6:
	cpi rTemp2, 0b00110000
	brne nextRowYspot7
	and rad6, rTemp4
	nextRowYspot7:
	cpi rTemp2, 0b00111000
	brne getDown1010
	and rad7, rTemp4
	getDown1010:

ret
directionChecker:						//Här använder vi en sort direktion matematik för att underlätta 
	ldi rTemp3, 0b00000111
	and rTemp3, snekHead

	ldi rTemp, 0b11000000
	and rTemp, snekHead

	cpi rTemp, 0b00000000
	brne nextDirectionCompare1

	subi snekHead, -0x08
	andi snekHead, 0b00111111 
	ret

	nextDirectionCompare1:
	cpi rTemp, 0b11000000
	brne nextDirectionCompare2

	subi snekHead, 0x08
	ldi rTemp2, 0b11000000
	or snekHead, rTemp2
	ret

	nextDirectionCompare2:
	cpi rTemp, 0b01000000
	brne nextDirectionCompare3

	cpi rTemp3, 0b00000111
	breq loopRowLeft

	subi snekHead, -0x01
	ori snekHead, 0b01000000
	andi snekHead, 0b01111111
	ret

	nextDirectionCompare3:
	cpi rTemp, 0b10000000

	cpi rTemp3, 0b00000000
	breq loopRowRight

	subi snekHead, 0x01
	ori snekHead, 0b10000000
	andi snekHead, 0b10111111
	ret

	loopRowLeft:					
	subi snekHead, 0x07					//Subtraherar sju från snekHead eftersom de tre minsta bittarna representerar vilken kolumn huvudet är i så vi går från 111 till 000
	ori snekHead, 0b01000000
	andi snekHead, 0b01111111
	ret

	loopRowRight:						
	subi snekHead, -0x07				//Adderar sju till snekHead eftersom de tre minsta bittarna representerar vilken kolumn huvudet är i så vi går från 000 till 111
	ori snekHead, 0b10000000
	andi snekHead, 0b10111111
	ret

kolumnChecker:							//Översätter de tre minsta bittarna i snekhead till en kolumn och sätter motsvarande bit i rTemp
	ldi rTemp, 0b00000000
	ldi rTemp2, 0b00000111
	and rTemp2, snekHead

	cpi rTemp2, 0b00000000
	brne nextKolumn1
	ldi rTemp, 0b10000000
	ret
	
	nextKolumn1:
	cpi rTemp2, 0b00000001
	brne nextKolumn2
	ldi rTemp, 0b01000000
	ret
	
	nextKolumn2:
	cpi rTemp2, 0b00000010
	brne nextKolumn3
	ldi rTemp, 0b00100000
	ret	

	nextKolumn3:
	cpi rTemp2, 0b00000011
	brne nextKolumn4
	ldi rTemp, 0b00010000
	ret

	nextKolumn4:
	cpi rTemp2, 0b00000100
	brne nextKolumn5
	ldi rTemp, 0b00001000
	ret

	nextKolumn5:
	cpi rTemp2, 0b00000101
	brne nextKolumn6
	ldi rTemp, 0b00000100
	ret

	nextKolumn6:
	cpi rTemp2, 0b00000110
	brne nextKolumn7
	ldi rTemp, 0b00000010
	ret

	nextKolumn7:
	ldi rTemp, 0b00000001
ret

radChecker:								//Kollar vilken rad huvudet är på och på den rad huvudet är på maskar vi in ettan som ligger i rTemp från kolumnChecker
	ldi rTemp2, 0b00000000
	ldi rTemp3, 0b00111000
	and rTemp3, snekHead

	cpi rTemp3, 0b00000000
	brne nextRad1
	or rad0, rTemp
	ret
	
	nextRad1:
	cpi rTemp3, 0b00001000
	brne nextRad2
	or rad1, rTemp
	ret
	
	nextRad2:
	
	cpi rTemp3, 0b00010000
	brne nextRad3
	or rad2, rTemp
	ret
	
	nextRad3:
	
	cpi rTemp3, 0b00011000
	brne nextRad4
	or rad3, rTemp
	ret
	
	nextRad4:
	
	cpi rTemp3, 0b00100000
	brne nextRad5
	or rad4, rTemp
	ret
	
	nextRad5:
	
	cpi rTemp3, 0b00101000
	brne nextRad6
	or rad5, rTemp
	ret

	nextRad6:
	
	cpi rTemp3, 0b00110000
	brne nextRad7
	or rad6, rTemp
	ret
	
	nextRad7:
	or rad7, rTemp
	ret


//Klockor som använda för att byta hastighet på scanlinesen eller ormen
snabb:
	ldi rTemp, 0b11111010
	in rTemp2, TCCR0B
	and rTemp, rTemp2
	out TCCR0B, rTemp

	ldi rTemp, (1<<CS01)
	in rTemp2, TCCR0B
	or rTemp, rTemp2
	out TCCR0B, rTemp

	RET

lugn:
	ldi rTemp, (1<<CS20)
	lds rTemp2, TCCR2B
	or rTemp, rTemp2
	sts TCCR2B, rTemp

	ldi rTemp, 0b11111101
	lds rTemp2, TCCR0B
	and rTemp, rTemp2
	sts TCCR2B, rTemp

	ldi rTemp, (1<<CS22)
	lds rTemp2, TCCR2B
	or rTemp, rTemp2
	sts TCCR2B, rTemp

	RET
	//slut på klockor******************************************************************************
	