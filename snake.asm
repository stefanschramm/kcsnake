; snake

; TODO:
; - schlangenlaenge begrenzen - waechst bisher unbegrenzt in den speicher rein - teilweise done
; - weitere optimierung: anhand der schlangenlaenge pause anpassen, so dass bei laengerer schlangenzeichendauer die pause verkuerzt wird
; - grenzen definieren (ereigniskontrolle)
; - items zum einsammeln, dabei schlange wachsen lassen


; definitions

	IRM:	EQU 0x8000 ; pixel ram: 0x8000 - 0xa7ff
	OFFSET:	EQU 0x2000
	PAUSE:	EQU 0x0200

; file header

	DEFM	'SNAKE' ; program name
	DEFB	0x00
	DEFB	0x00
	DEFB	0x00
	DEFM	'COM' ; filetype
	DEFB	0x00 ; reserved
	DEFB	0x00
	DEFB	0x00
	DEFB	0x00
	DEFB	0x00
	DEFB	0x02
	DEFW	OFFSET ; start
PROGRAMLENGTH:
	DEFW	0x0000 ; gets overwritten at the end
	DEFS	107, 0x00 ; fill header

	ORG	OFFSET

; caos menu entry

	DEFW	0x7f7f
	DEFM	'SNAKE'
	DEFB	0x01

; actual program

	; top border
	LD	B, 0x26
	LD	HL, IRM + 0x0100
	CALL	ROW

	; right border
	LD	B, 0x00
	LD	HL, IRM + 0x2700
	CALL	COLUMN

	; bottom border
	LD	B, 0x26
	LD	HL, IRM + 0x01f8
	CALL	ROW

	; left border
	LD	B, 0x00
	LD	HL, IRM
	CALL	COLUMN

	; main loop
STEP:
	CALL	MOVESNAKE
	CALL	DRAWSNAKE
	LD	HL, PAUSE
	LD	DE, 0x0001
WAIT:
	CALL	0xf003 ; Programmverteiler I
	DEFB	0x0c ; KBDS
	CP	'W'
	JR	Z, GOTKEY
	CP	'D'
	JR	Z, GOTKEY
	CP	'S'
	JR	Z, GOTKEY
	CP	'A'
	JR	Z, GOTKEY
	JR	GOTNOKEY
GOTKEY:
	LD	(DIRECTION), A
GOTNOKEY:
	OR	A ; just for resetting carry flag to 0 for SBC and JR NZ
	SBC	HL, DE
	JR	NZ, WAIT
	JR	STEP
	RET ; currently never executed

; subroutines

COLUMN:
	; draw column
	; B = length (0x00 = 256)
	; HL = upper end
	; destroys: B, HL
	LD	(HL), 0xff
	INC	HL
	DJNZ	COLUMN
	RET

ROW:
	; draw row
	; B = length
	; HL = left end
	; destroys: B, HL
LOOPROW:
	PUSH	HL
	PUSH	BC
	LD	B, 0x08
	CALL	COLUMN
	POP	BC
	POP	HL
	INC	H
	DJNZ	LOOPROW
	RET

DRAWAT:
	; draw square at position
	; B = column
	; C = row
	; destroys: B, C, HL
	LD	HL, IRM
	; since B is used as high-nibble it's as if it's multiplied by 256 automatically
	; 3 times shift left == multiplication with 8
	SLA	C
	SLA	C
	SLA	C
	ADD	HL, BC
	LD	B, 0x08 ; column length
	CALL	COLUMN
	RET

DRAWSNAKE:
	; draw snake which segments are at stored in memory at offset SNAKE
	; destroys: A, B, C, HL
	LD	HL, SNAKE
DRAWSNAKENEXT:
	LD	B, (HL) ; read column
	LD	A, 0x00 ; for comparing snake-value from reg B with 0 to determine snake's end
	CP	B
	RET	Z ; return if end reached (B is 0x00)
	INC	HL
	LD	C, (HL) ; read row
	INC	HL
	PUSH	HL
	CALL	DRAWAT
	POP	HL
	JR	DRAWSNAKENEXT
	; TODO: hier hinter der schlange noch immer eine leere position zeichnen? also schlange ein segment kuerzer?
	; TODO: ausserdem schlange nicht dort zeichnen, wo bereits gezeichnet ist ( - also einmal komplett zeichnen, dann immer nur kopf dazu zeichnen und schwanz loeschen - insb. gute ersparnis, wenn schlange lang wird)

MOVESNAKE:
	; move snake for one segment (shifts all segments by one position towards snakes tail)
	; destroys: A, B, C, D, E, HL
	LD	HL, SNAKE
	; read head of snake to calculate next position
	LD	D, (HL) 
	INC	HL
	LD	E, (HL)
	DEC	HL
	; determine direction
	LD	A, (DIRECTION)
	CP	'D'
	JR	Z, DIRECTIONRIGHT
	CP	'S'
	JR	Z, DIRECTIONBOTTOM
	CP	'A'
	JR	Z, DIRECTIONLEFT
	DEC	E ; top (default)
	JR	DIRECTIONEND
DIRECTIONRIGHT:
	INC	D ; right
	JR	DIRECTIONEND
DIRECTIONBOTTOM:
	INC	E ; bottom
	JR	DIRECTIONEND
DIRECTIONLEFT:
	DEC	D ; left
DIRECTIONEND:
	; TODO: hier ereignisbehandlung (kollision mit wand [oben, rechts, unten, links] oder schlange selbst)
	LD	A, 0x00 ; for comparing snake-value from reg B with 0 to determine snake's end
MOVESNAKENEXT:
	; D = new position for snake (column)
	; E = (row)
	LD	B, (HL) ; read column
	CP	B
	RET	Z ; return if end reached (B is 0x00) - last segment gets removed
	LD	(HL), D
	INC	HL
	LD	C, (HL) ; read row
	LD	(HL), E
	LD	D, B ; old position is the new position of next segment
	LD	E, C
	INC	HL ; continue with next snake segment
	JR	MOVESNAKENEXT

; data

DIRECTION:
	; direction of snake
	; W = top, D = right, S = bottom, A = left
	DEFB 'D'

SNAKE:
	; snake segments
	; 1st byte: column
	; 2nd byte: row
	; 0x00 means end of snake (because it's impossible, that the snake can be at the border)

	; testsnake:
	DEFB	0x08 ; 1
	DEFB	0x08
	DEFB	0x09 ; 2
	DEFB	0x08
	DEFB	0x0a ; 3
	DEFB	0x08
	DEFB	0x0a ; 4
	DEFB	0x09
	DEFB	0x00 ; end

; put program length in file header

	seek PROGRAMLENGTH
	DEFW	$
