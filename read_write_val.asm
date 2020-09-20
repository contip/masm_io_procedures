TITLE Input-Output Procedures     (read_write_val.asm)

; Author: Peter Conti
; Last Modified: 7 Jun 2020
; OSU email address: contip@oregonstate.edu
; Course number/section: CS271 / 400
; Project Number: 6               Due Date: 7 Jun 2020
; Description: Implements macros getString to save user input strings to memory
;	locations and displayString to print strings to the screen; Implements a
;	readVal procedure that uses getString to prompt user to enter a signed
;	integer, then converts the raw digit string to numeric while performing
;	data validation; Implements a writeVal procedure which takes an input
;	numeric value, converts it to a digit string (using ASCII codes), and 
;	prints it to the screen using displayString; Tests the I/O procedures by
;	getting 10 valid signed integers from user and displaying them back to the
;	user, along with their sum and rounded average.

INCLUDE Irvine32.inc


getString	MACRO promptAddress, toSaveAddr, toSaveSize, byteCountAddr
;;	displays input prompt to user and writes their input to toSaveAddr
;;	assumes string of bytes
	pushad
	mov	EDX, promptAddress
	call	WriteString
	;; set ECX (max characters + 1) to the size of the toSave variable
	mov	ECX, toSaveSize
	mov	EDX, toSaveAddr
	call	ReadString
	mov	byteCountAddr, EAX
	popad
	ENDM

displayString	MACRO strAddress
;;	writes the string pointed to by strAddress to the screen
	push	EDX
	mov	EDX, strAddress
	call	WriteString
	pop	EDX
	ENDM 


.data

intro1	BYTE	"Program 6: Input-Output Procedures, by Pete", 10, 10, 0
intro2	BYTE	"Please enter 10 signed integers whose sum will fit in a 32bit "
		BYTE	"register (total: -2,147,483,648 to +2,147,483,647).", 10, 0
intro3	BYTE	"I'll display a list of the numbers, their sum, and their "
		BYTE	"average.", 10, 10, 0
inputPrompt	BYTE	"Please enter a signed number: ", 0
invalidPrompt	BYTE	"Invalid Entry!  Number too large or input contains "
			BYTE	"illegal characters.  Please re-enter.", 10, 0
displayPrompt	BYTE "Valid numbers entered: ", 10, 0
sumPrompt	BYTE	"The sum of the valid numbers is: ", 0
avgPrompt	BYTE "The rounded average of the valid numbers is: ", 0
outro	BYTE	"It's been wonderful using Input-Output Procedures to calculate"
		BYTE	" some values for you...  Bye!", 0
goodBye	BYTE	" ",0
converted	SDWORD	?	; stores user string input converted to signed int
userNums	SDWORD	10 DUP (?)
userSum	SDWORD	?
userAvg	SDWORD	?

.code
main PROC

; call introduction procedure to display program title and instructions
push OFFSET intro1
push OFFSET intro2
push OFFSET intro3
call introduction

; call getNums procedure to get 10 valid signed numbers from user
push	OFFSET inputPrompt
push	OFFSET invalidPrompt
push	OFFSET userNums 
push	LENGTHOF userNums
call	getNums

; call displayNums procedure to print user numbers to screen
call	Crlf
push	OFFSET userNums
push	OFFSET displayPrompt
push LENGTHOF userNums
call displayNums

; call the sumArray procedure to sum user numbers and print to the screen
call Crlf
push	OFFSET sumPrompt
push OFFSET userNums   
push	OFFSET userSum
push	LENGTHOF userNums
call sumArray

; call the avgArray procedure to get average of user numbers and print result
call Crlf
push	OFFSET avgPrompt
push LENGTHOF userNums
push	userSum
call	avgArray

; say goodbye; reuse intro procedure with goobye prompt and 2 extra spaces
call	Crlf
call	Crlf
push OFFSET outro
push OFFSET goodBye
push OFFSET goodBye
call	introduction

	exit	; exit to operating system
main ENDP


;------------------------------------------------
introduction PROC
; Procedure to display program title and instructions
; receives: intro1, intro2, intro3 (reference parameters)
; returns: none
; preconditions: none
; registers changed: none
; stack frame
	;[EBP]		prev. EBP value
	;[EBP + 4]	gen purpose registers
	;[EBP + 32]	@return address
	;[EBP + 36] 	@intro3
	;[EBP + 40]	@intro2
	;[EBP + 44]	@intro1
;------------------------------------------------
	pushad
	mov	EBP, ESP
	mov	EDX, [EBP + 44]
	call	WriteString
	mov	EDX, [EBP + 40]
	call	WriteString
	mov	EDX, [EBP + 36]
	call	WriteString
	popad
	ret 12
introduction ENDP



;------------------------------------------------
readVal	PROC
; Procedure to prompt user to enter a signed number, convert the resulting
;	digit string to a number, and perform data validation
; receives: converted, inputPrompt, invalidPrompt (reference parameters)
; returns: converted variable updated to hold user's input
; preconditions: none
; registers changed: none
; stack frame:
	;[EBP - 25]	userInput  (the user's string input)
	;[EBP - 12]	multiplier
	;[EBP - 8]	isNeg
	;[EBP - 4]	lenUserInput
	;[EBP]		old EBP
	;[EBP + 4]	gen purpose registers
	;[EBP + 32]	@return address
	;[EBP + 36]	@invalidPrompt
	;[EBP + 40]	@inputPrompt
	;[EBP + 44]	@converted  (the converted number to return)
;------------------------------------------------
	pushad
	mov	EBP, ESP
	sub	ESP, 25
	lenUserInput	EQU DWORD PTR [EBP - 4]
	isNeg	EQU DWORD PTR [EBP - 8]
	multiplier	EQU DWORD PTR [EBP - 12]
	userInput		EQU BYTE PTR [EBP - 25]
	; userInput is a string representing an SDWORD, so max valid length is 11
	;	chars (sign + 10 digits); 12th byte checks if input too large, 13th 0
	userInputInit:
		mov	ECX, 13
		lea	EDI, userInput
		mov	EAX, 0
		rep	stosb
	mov	multiplier, 10

	getUserInput:
		mov	EDI, [EBP + 44]  ; point EDI to address of converted
		mov	EDX, 0	; use EDX as an accumulator for building the integer
		mov	lenUserInput, 0
		mov	isNeg, 0
		mov	EBX, 0

		lea	ESI, userInput  ; point ESI to addr of userInput string
		; populate userInput string by calling getString 
		;	(@prompt, @strToSave, sizeOfStrToSave, @numCharsEntered)
		getString [EBP + 40], ESI, 13, lenUserInput

	firstCharCheck:  ;check if the first character is a plus/minus symbol
		lodsb
		cmp	AL, 2Bh
		je	posNumber		; first character is a "+"
		cmp	AL, 2Dh
		je	negNumber		; first chracter is a "-"
		jmp	noPlusMinus

		; if the first character is a sign symbol, decrease lenUserInput
		posNumber:
			dec	lenUserInput
			mov	isNeg, 0
			jmp	doneFirstChar
		negNumber:
			mov	isNeg, 1
			dec	lenUserInput
			jmp	doneFirstChar

		noPlusMinus:
			; if the first char wasn't + or -, point ESI back to the first
			;	character in userInput (lods auto increments ESI)
			lea	ESI, userInput 
			
	doneFirstChar:
		;  if lenUserInput == 11, user entered too many characters (max
		;	10 plus sign symbol); jump to invalidEntry prompt and retry
		cmp lenUserInput, 11
		jge invalidPromptEntry

		mov	ECX, lenUserInput  ; loop for each character in userInput string
	convertLoop:
		; if character value is between 0x30 and 0x39 (ASCII codes for digits
		;	0-9), character is a valid digit, otherwise invalid entry
		lodsb
		push	ECX
		mov	BL, 30h
		mov	ECX, 10
		compLoop:    ; compare character value with each 0x30 thru 0x39
			cmp	AL, BL
			je	digitOkay
			inc	BL
			loop compLoop
		jmp invalidPromptEntry
			
		digitOkay:
			; the character value maps to a valid digit and is added to the 
			;	accumulator (EDX) used for building the integer conversion
			mov EAX, EDX	 ; put accumulator in EAX
			mul multiplier  ; multiply it by 10 to go right one place
			sub BL, 30h	 ; get actual digit from ASCII code
			add	EAX, EBX  ; place digit at empty place opened by multiplier
			mov	EDX, EAX  ; store result back in the accumulator
			pop ECX
			cmp ECX, 1  
			je negCheck  ; skip invalidPrompt if last iteration
			loop	convertLoop
			
		invalidPromptEntry:
			displayString [EBP + 36]
			jmp getUserInput
		
		negCheck:
		; accumulator EDX has pos integer representataion of userInput string
		mov EAX, EDX  
		cmp	isNeg, 1  ; if entry had leaading "-", negate the integer
		je	negate
		jmp done
		negate:
			neg	EAX
		done:
			stosd  ; write the integer to the output variable, converted
			
	mov	ESP, EBP
	popad
	ret 12
readVal	ENDP


;------------------------------------------------
writeVal	PROC
; Procedure to take an input signed integer value, and display it to the screen
;	by converting it to an ASCII string and calling the displayString macro
; receives: inputNum (value)
; returns: none (prints string representation of inputNum to screen)
; preconditions: inputNum is a signed int that will fit in 32bit register
; registers changed: none
; stack frame:
	;[EBP - 20] 	tempStr
	;[EBP - 8]	negTracker
	;[EBP - 4]	numDigits
	;[EBP]		old EBP
	;[EBP + 4]	gen purpose registers
	;[EBP + 32]	@return address
	;[EBP + 36]	inputNum
;------------------------------------------------
	pushad
	mov	EBP, ESP
	sub	ESP, 24
	numDigits EQU DWORD PTR [EBP - 4]
	negTracker EQU DWORD PTR [EBP - 8]
	mod10	EQU DWORD PTR [EBP - 12]
	tempStr	EQU BYTE PTR [EBP - 24]
	mov mod10, 10
	mov numDigits, 0
	mov negTracker, 0

	tempStrInitializer:
	; because inputNum is signed 32bit integer with numDigits <= 10, string to
	;	hold ASCII codes of inputNum is 12 bytes (11 chars + terminal 0)
		mov	ECX, 12
		lea	EDI, tempStr
		mov	EAX, 0
		rep	stosb
	
	; point EDI to the address of the temp string (for use with stos)
	lea	EDI, tempStr  

	mov	EAX, [EBP + 36] ; put inputNum in EAX and check if it's negative
	cmp	EAX, 0
	jl negNum
	jmp getDigitsLoop
	negNum:
	; if number is negative, set negTracker and negate number (i.e. make pos)
		mov negTracker, 1
		neg EAX

	getDigitsLoop:
		; divide inputNum by 10, push extracted last digit on stack
		cdq
		div mod10
		push EDX
		inc	numDigits
		cmp	EAX, 0
		jne	getDigitsLoop

		mov	ECX, numDigits  ; set to loop for each digit saved to the stack

		cmp	negTracker, 1  ; if inputNum negative, push "-" symbol on stack
		je	addNegSign
		jmp	writeLoop
		addNegSign:
			push 00FDh
			inc	ECX
			jmp writeLoop

	writeLoop:
		pop	EAX  ; pop saved digit into EAX
		add	EAX, 30h  ; add 0x30 to get the digit's ASCII representation
		cld
		stosb	; write the value
		loop writeLoop
		
	; print the built string representation using the displayString macro
	lea	EDI, tempStr
	displayString EDI
	
	mov	ESP, EBP
	popad
	ret 4
writeVal	ENDP



;------------------------------------------------
getNums PROC
; Procedure to get 10 valid numbers from user and store them in an array
; receives: @inputPrompt, @invalidPrompt, @array (reference parameters);
;	arraySize (value)
; returns: the 10 valid numbers in the userNums array
; preconditions: assumes userNums is an array that can store 10 SDWORD values
; registers changed: none
; stack frame:
	;[EBP - 4]	toAdd
	;[EBP]		old EBP
	;[EBP + 4]	gen purpose registers
	;[EBP + 32]	@return address
	;[EBP + 36]	arraySize
	;[EBP + 40]	@array
	;[EBP + 44]	@invalidPrompt
	;[EBP + 48]	@inputPrompt
;------------------------------------------------
	pushad
	mov	EBP, ESP
	sub	ESP, 4
	toAdd EQU SDWORD PTR [EBP - 4]  ; holds validated userNum to add to array
	mov	ECX, [EBP + 36]  ; ECX set to get arraySize (10) total numbers
	mov	EDI, [EBP + 40]  ; point EDI to userNums array for use with stos

	getNumsLoop:
	; call readVal procedure with (@toAdd, @inputPrompt, @invalidprompt)
		lea	EDX, toAdd
		push EDX
		push [EBP + 48]
		push [EBP + 44]
		call	readVal

		; toAdd holds the number to be added; place in userNums array
		mov	EAX, toAdd
		stosd
		loop getNumsLoop

	mov	ESP, EBP
	popad
	ret 16
getNums ENDP



;------------------------------------------------
displayNums PROC
; Procedure to print the user's array of numbers to the screen
; receives: array, prompt (reference parameters); arraySize (value)
; returns: none (prints array to screen)
; preconditions: assumes userNums contains 10 valid numbers
; registers changed: none
; stack frame:
	;[EBP - 3]	spaceStr		[ESP]
	;[EBP]		old EBP
	;[EBP + 4]	gen purpose registers
	;[EBP + 32]	@return address
	;[EBP + 36]	arraySize
	;[EBP + 40]	@prompt
	;[EBP + 44]	@array
;------------------------------------------------
	pushad
	mov	EBP, ESP
	sub ESP, 3   ; allocate 3 bytes to hold string for spacing b/w characters
	mov	[EBP - 3], BYTE PTR 2Ch  ; comma
	mov	[EBP - 2], BYTE PTR 20h  ; space
	mov	[EBP - 1], BYTE PTR 0	; terminal 0

	displayString [EBP + 40]  ; print the prompt message to the screen
	mov	ESI, [EBP + 44]	 ; point ESI to the array for use with LODS
	mov	ECX, [EBP + 36]	 ; set ECX to loop arraySize times

	myLoop:
	; LODS current number into EAX; print number with writeVal; print spacing
		lodsd
		push	EAX 
		call	writeVal

		cmp	ECX, 1
		je	noSpaces	; no spaces on last iteration

		lea EDX, [EBP - 3]
		displayString EDX  ; print spaces
		loop myLoop  ; repeat for every element (number) in input array

	noSpaces:
		mov	ESP, EBP
		popad
		ret 12
displayNums ENDP



;------------------------------------------------
sumArray proc
; Procedure to get sum of the elements in input array of numbers, print result
;	to screen, and return the sum in a memory location
; receives: prompt, array (reference parameters), arraySize (value)
; returns: the sum in userSum
; preconditions: assumes userNums contains 10 valid numbers
; registers changed: none
; stack frame:
	;[EBP]		old EBP
	;[EBP + 4]	gen purpose registers
	;[EBP + 32]	@return address
	;[EBP + 36]	arraySize
	;[EBP + 40]	@sumToSave
	;[EBP + 44]	@array
	;[EBP + 48]	@prompt
;------------------------------------------------
	pushad
	mov	EBP, ESP

	mov	ECX, [EBP + 36]	; set ECX to loop arraySize times
	mov	ESI, [EBP + 44]	; point ESI to array for use with LODS
	mov	EBX, 0			; use EBX as an accumulator

	sumLoop:
	; LODS array element into EAX, add it to the EBX accumulator
		lodsd
		add EBX, EAX
		loop sumLoop  ; repeat for every element in array
	
	; mov calculated sum to EAX and save to output variable sumToSave
	mov	EAX, EBX
	mov EDI, [EBP + 40]
	stosd
	
	; print the prompt message and the sum to the screen
	displayString [EBP + 48]
	push	EAX
	call	writeVal

	popad
	ret 16
sumArray ENDP



;------------------------------------------------
avgArray proc
; Procedure to get average of numbers in input array
; receives: prompt (reference parameter); arraySize, arraySum (values)
; returns: none (prints average to screen)
; preconditions: does not directly calculate array's average; relies on sum
;	having already been determined and passed as a parameter
; registers changed: none
; stack frame:
	;[EBP]		old EBP
	;[EBP + 4]	gen purpose registers
	;[EBP + 32]	@return address
	;[EBP + 36]	arraySum
	;[EBP + 40]	arraySize
	;[EBP + 44]	@prompt
;------------------------------------------------
	pushad
	mov	EBP, ESP
	
	displayString [EBP + 44]  ; print the prompt message

	; divide arraySum by arraySize and print quotient (floor of average)
	mov EAX, [EBP + 36]
	mov EBX, [EBP + 40]
	cdq
	idiv	EBX
	push	EAX
	call	writeVal
	
	popad
	ret 12
avgArray ENDP


END main
