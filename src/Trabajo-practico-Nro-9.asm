;extern	gets,puts,fgets,fputs,fwrite,rewind,fread

global 	main
extern 	printf,sscanf,fopen,fread,fclose, scanf

section  .data
	; Definiciones del archivo binario
	fileName	            db	    "datos.txt",0
	mode		            db	    "rb",0		; modo lectura del archivo binario
	msgErrOpen	            db      "Error en apertura de archivo",10,0

    msgIngOp                db      "Ingrese un operando de longitud 16 (caracteres 0 o 1) de la forma:%s ej. 1111111110000110",10,0
    saltoLinea              db      '',10,0

    posOp                   dq      0

    printInicio             db      "Inicio de operaciones...",13,10,0
    printResul              db      "%16s %3s %16s = %16s",10,0
    stringOr                db      " or"
    stringXor               db      "xor"
    stringAnd               db      "and"

;Esto '',0 es para printf
    opString                db      "   "
                            db      '',0
    resultado    times  16  db      " "
                            db      '',0
    operandoUno  times  16  db      " "
                            db      '',0
    operandoDos  times  16  db      " "
                            db      '',0
    varOp        times  16  db      " "

	registro	times   0 	db      ""
	operando	times   16	db      " "
	operador               	db      " "

	formScanfString         db      "%16s",0 ;solo lee 16 caracteres
    unString    times   30  db      "f",0
section  .bss
    plusRsp		resq	1
	fileHandle	resq	1
	esValid		resb	1
	estadoBit   resb	1
	contador	resq	1
	posBits     resq    1

section .text

;----------------------------------MAIN--------------------------------
main:

pedirOp:
    call    mostrarMsgOp
    call    scanfString
    call    validarScanf
    cmp		byte[esValid],'S'
    jne		pedirOp

    mov     rcx,16
    lea     rsi,[unString]
    lea     rdi,[operandoUno]
    rep     movsb

    call    inicioOperaciones

	call	abrirArch
	cmp		qword[fileHandle],0				;Error en apertura?
	jle		errorOpen
    call	leerArch
endProg:
	ret

errorOpen:
	mov		rdi, msgErrOpen
    call	checkAlign
    sub		rsp,[plusRsp]
    call	printf
    add		rsp,[plusRsp]
	jmp		endProg
;------------------------------------FIN-MAIN---------------------------

;************************************INICIO-RUTINA*********************
scanfString:
    lea     rdi,[formScanfString]
    lea     rsi,[unString]
    call	checkAlign
    sub		rsp,[plusRsp]
    call	scanf
    add		rsp,[plusRsp]
    ret
;*************************************FIN-RUTINA***********************

;************************************INICIO-RUTINA*********************
abrirArch:
	mov		rdi,fileName			;Parametro 1: dir nombre del archivo
	mov		rsi,mode				;Parametro 2: dir string modo de apertura
	call	fopen					;ABRE el archivo y deja el handle en RAX
	mov		qword[fileHandle],rax
	ret
;*************************************FIN-RUTINA***********************

;************************************INICIO-RUTINA*********************
leerArch:
leerReg:
	mov		rdi,registro				;Parametro 1: dir area de memoria donde se copia
	mov		rsi,17						;Parametro 2: longitud del registro
	mov		rdx,1						;Parametro 3: cantidad de registros
	mov		rcx,qword[fileHandle]		;Parametro 4: handle del archivo
	call	fread						;LEO registro. Devuelve en rax la cantidad de bytes leidos

	cmp		rax,0				   ;Fin de archivo?
	jle		eof                    ;<=0

    mov     rcx,16
    lea     rsi,[operando]
    lea     rdi,[operandoDos]
    rep     movsb

    call   VALREG
    cmp		byte[esValid],'S'
    jne		leerReg                 ;<>
    call    OPERAR
    jmp     leerReg

eof:
;	Cierro archivo cuando llega a fin del archivo
	mov		rdi,qword[fileHandle]	;Parametro 1: handle del archivo
	call	fclose
	ret
;*************************************FIN-RUTINA***********************
;************************************INICIO-RUTINA*********************
OPERAR:

    cmp     byte[operador],'O'
    je      orString
    cmp     byte[operador],'X'
     je     xorString
    cmp     byte[operador],'N'
    je      andString
    ret
;*************************************FIN-RUTINA***********************


;:::::::::::::::::::::::::::::::::::INICIO-AND:::::::::::::::::::::::::
;************************************INICIO-RUTINA*********************
andString:
    mov     qword[posBits],0
    mov     rcx,16
compBitsAnd:
    call    compararBitAnd
    loop    compBitsAnd

    mov     rcx,3
    lea     rsi,[stringAnd]
    lea     rdi,[opString]
    rep     movsb
    call    printResultado

    mov     rcx,16
    lea     rsi,[resultado]
    lea     rdi,[operandoUno]
    rep     movsb
    ret
;*************************************FIN-RUTINA***********************
;************************************INICIO-RUTINA*********************
compararBitAnd:
    mov     qword[contador],rcx
    mov		rcx,0
    mov     rax,0

    mov     rbx,qword[posBits]
    mov		al,byte[operandoUno + rbx]
    mov     cl,byte[operandoDos + rbx]

    cmp     rcx,rax
    je      bitIgualesAnd

    mov     byte[resultado + rbx],'0'
    mov		rcx,qword[contador]
    add     rbx,1
    mov     qword[posBits],rbx
    ret
bitIgualesAnd:
    cmp     byte[operandoDos + rbx],'1'
    je      sonUnoAnd
    mov     byte[resultado + rbx],'0'
    mov		rcx,qword[contador]
    add     rbx,1
    mov     qword[posBits],rbx
    ret
sonUnoAnd:
    mov     byte[resultado + rbx],'1'
    mov		rcx,qword[contador]
    add     rbx,1
    mov     qword[posBits],rbx
    ret
;*************************************FIN-RUTINA***********************
;::::::::::::::::::::::::::::::::::::::FIN-AND:::::::::::::::::::::::::



;:::::::::::::::::::::::::::::::::::INICIO-XOR:::::::::::::::::::::::::
;************************************INICIO-RUTINA*********************
xorString:
    mov     qword[posBits],0
    mov     rcx,16
compBitsXor:
    call    compararBitXor
    loop    compBitsXor

    mov     rcx,3
    lea     rsi,[stringXor]
    lea     rdi,[opString]
    rep     movsb

    call    printResultado

    mov     rcx,16
    lea     rsi,[resultado]
    lea     rdi,[operandoUno]
    rep     movsb
    ret
;*************************************FIN-RUTINA***********************
;************************************INICIO-RUTINA*********************
compararBitXor:
    mov     qword[contador],rcx
    mov		rcx,0
    mov     rax,0

    mov     rbx,qword[posBits]
    mov		al,byte[operandoUno + rbx]
    mov     cl,byte[operandoDos + rbx]

    cmp     rcx,rax
    je      bitIgualesXor

    mov     byte[resultado + rbx],'1'
    mov		rcx,qword[contador]
    add     rbx,1
    mov     qword[posBits],rbx
    ret
bitIgualesXor:
    mov     byte[resultado + rbx],'0'
    mov		rcx,qword[contador]
    add     rbx,1
    mov     qword[posBits],rbx
    ret
;*************************************FIN-RUTINA***********************
;:::::::::::::::::::::::::::::::::::::FIN-XOR::::::::::::::::::::::::::



;:::::::::::::::::::::::::::::::::::INICIO-OR::::::::::::::::::::::::::
;************************************INICIO-RUTINA*********************
orString:
    mov     qword[posBits],0
    mov     rcx,16
compBitsOr:
    call    compararBitOr
    loop    compBitsOr

    mov     rcx,3
    lea     rsi,[stringOr]
    lea     rdi,[opString]
    rep     movsb
    call    printResultado

    mov     rcx,16
    lea     rsi,[resultado]
    lea     rdi,[operandoUno]
    rep     movsb
    ret
;*************************************FIN-RUTINA***********************
;************************************INICIO-RUTINA*********************
compararBitOr:
    mov     qword[contador],rcx
    mov		rcx,0
    mov     rax,0

    mov     rbx,qword[posBits]
    mov		al,byte[operandoUno + rbx]
    mov     cl,byte[operandoDos + rbx]

    cmp     rcx,rax
    je      bitIgualesOr

    mov     byte[resultado + rbx],'1'
    mov		rcx,qword[contador]
    add     rbx,1
    mov     qword[posBits],rbx
    ret
bitIgualesOr:
    cmp     byte[operandoDos + rbx],'1'
    je      sonUno
    mov     byte[resultado + rbx],'0'
    mov		rcx,qword[contador]
    add     rbx,1
    mov     qword[posBits],rbx
    ret
sonUno:
    mov     byte[resultado + rbx],'1'
    mov		rcx,qword[contador]
    add     rbx,1
    mov     qword[posBits],rbx
    ret
;*************************************FIN-RUTINA***********************
;::::::::::::::::::::::::::::::::::::::FIN-OR::::::::::::::::::::::::::





;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$MENSAGES$$$$$$$$$$$$$$$$$$$$$$$$$$
;************************************INICIO-RUTINA*********************
mostrarMsgOp:
	mov     rdi,msgIngOp
	mov     rsi,saltoLinea
    call	checkAlign
    sub		rsp,[plusRsp]
    call	printf
    add		rsp,[plusRsp]
	ret
;*************************************FIN-RUTINA***********************

;************************************INICIO-RUTINA*********************
printResultado:
    mov     rdi,printResul
	mov		rsi,operandoUno
	mov     rdx,opString
	mov     rcx,operandoDos
	mov     r8,resultado
    call	checkAlign
    sub		rsp,[plusRsp]
    call	printf
    add		rsp,[plusRsp]
    ret
;*************************************FIN-RUTINA***********************

;************************************INICIO-RUTINA*********************
inicioOperaciones:
	mov     rdi,printInicio
    call	checkAlign
    sub		rsp,[plusRsp]
    call	printf
    add		rsp,[plusRsp]
	ret
;*************************************FIN-RUTINA***********************
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$FIN-MENSAGES$$$$$$$$$$$$$$$$$$$$$$




;#####################################-VALIDACION-######################

;************************************INICIO-RUTINA*********************
validarScanf:
    mov     rcx,16
    lea     rsi,[unString]
    lea     rdi,[varOp]
    rep movsb
    call    validarBits
    ret
;*************************************FIN-RUTINA***********************

;************************************INICIO-RUTINA*********************
VALREG:
    mov     rcx,16
    lea     rsi,[operandoDos]
    lea     rdi,[varOp]
    rep movsb
    call    validarBits
    cmp		byte[esValid],'S'
    je      valOperador
    mov		byte[esValid],'N'
    ret
valOperador:
    mov		byte[esValid],'N'
    call    validarOperador
    ret
;*************************************FIN-RUTINA***********************


;************************************INICIO-RUTINA*********************
validarOperador:

    cmp		byte[operador],'O'
    je		opValido
    cmp		byte[operador],'X'
    je		opValido
    cmp		byte[operador],'N'
    je		opValido

    jmp		opInvalido
opValido:
    mov		byte[esValid],'S'
    ret
opInvalido:
    mov		byte[esValid],'N'
    ret
;*************************************FIN-RUTINA***********************

;************************************INICIO-RUTINA*********************
validarBits:

    mov     rax,0
    mov     eax,dword[posOp]
compBit:
	cmp		byte[varOp+rax],'0'
	je		bitValido
	cmp		byte[varOp+rax],'1'
	je		bitValido

	jmp		bitInvalido

bitValido:
    inc     rax
    mov		qword[posOp],rax
    cmp     rax,16                       ;valido los 16 bits
    jl      validarBits
    mov		byte[esValid],'S'
    mov		qword[posOp],0
    ret
bitInvalido:
    mov		qword[posOp],0
    mov		byte[esValid],'N'
    ret
;*************************************FIN-RUTINA***********************
;#################################-VALIDACION-FIN-######################


	;----------------------------------------
    ;----------------------------------------
    ; ****	checkAlign ****
    ;----------------------------------------
    ;----------------------------------------
    checkAlign:
    	push rax
    	push rbx
    ;	push rcx
    	push rdx
    	push rdi

    	mov   qword[plusRsp],0
    	mov		rdx,0

    	mov		rax,rsp
    	add   rax,8		;para sumar lo q restó la CALL
    	add		rax,32	;para sumar lo que restaron las PUSH

    	mov		rbx,16
    	idiv	rbx			;rdx:rax / 16   resto queda en RDX

    	cmp  rdx,0		;Resto = 0?
    	je		finCheckAlign
    ;mov rdi,msj
    ;call puts
    	mov   qword[plusRsp],8
    finCheckAlign:
    	pop rdi
    	pop rdx
    ;	pop rcx
    	pop rbx
    	pop rax
    	ret
