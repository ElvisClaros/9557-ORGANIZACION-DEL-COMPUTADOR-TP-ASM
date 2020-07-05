;extern	gets,puts,fgets,fputs,fwrite,rewind,fread

global 	main
extern 	printf,sscanf,fopen,fread,fclose, scanf

section  .data
	; Definiciones del archivo binario
	fileName	            db	    "datos.txt",0
	mode		            db	    "rb",0		; modo lectura del archivo binario
	msgErrOpen	            db      "Error en apertura de archivo",10,0

    msgIngOp                db      "Ingrese un operando de longitud 16 (caracteres 0 o 1) de la forma:%s ej. 1111111110000110",10,0
    saltoLinea              db      "",10,0

    posOp                   dd      0

	registro	times   0 	db      ""
	operando	times   16	db      " "
	operador				db      ' '
	finReg                  db      "",13,10,0
    unString    times   17  db      0
	formScanfString         db      "%16s",0 ;solo lee 16 caracteres
    formPrintString         db      "Ingreso :---->%s",13,10,0

    formPrint               db      "Ingreso :---->%i",13,10,0
    formScanf               db      "%i",0
    unEntero    times   1   dd      0
section  .bss
    plusRsp		resq	1
	fileHandle	resq	1
	esValid		resb	1
	contador	resq	1
	varOp       times   16  resb      1
	buffer		resb	10

section .text

;----------------------------------MAIN--------------------------------
main:

pedirOp:
    call    mostrarMsgOp
    call    scanfString
    call    validarScanf
    cmp		byte[esValid],'S'
    jne		pedirOp

	call	abrirArch
	cmp		qword[fileHandle],0				;Error en apertura?
	jle		errorOpen
    call	leerArch
    call    mostrarString
    call    mostrarReg
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
scanfEntero:
    lea     rdi,[formScanf]
    lea     rsi,[unEntero]
    call	checkAlign
    sub		rsp,[plusRsp]
    call	scanf
    add		rsp,[plusRsp]
    ret
;*************************************FIN-RUTINA***********************

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

;    call   VALREG
    cmp		byte[esValid],'S'
    jne		leerReg                 ;<>

    jmp     leerReg

eof:
;	Cierro archivo cuando llega a fin del archivo
	mov		rdi,qword[fileHandle]	;Parametro 1: handle del archivo
	call	fclose
	ret
;*************************************FIN-RUTINA***********************
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

    call    validarBits
    cmp		byte[esValid],'S'
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
    ret
bitInvalido:
    mov		qword[posOp],0
    mov		byte[esValid],'N'
    ret
;*************************************FIN-RUTINA***********************

;************************************INICIO-RUTINA*********************
mostrarReg:
	mov		rdi,operando			;Parametro 2: campo que se encuentra en el formato indicado q se imprime por pantalla
    call	checkAlign
    sub		rsp,[plusRsp]
    call	printf
    add		rsp,[plusRsp]
    ret
;*************************************FIN-RUTINA***********************

;************************************INICIO-RUTINA*********************
mostrarEntero:
	mov     rdi,formPrint
	mov     rsi,[unEntero]
    call	checkAlign
    sub		rsp,[plusRsp]
    call	printf
    add		rsp,[plusRsp]
	ret
;*************************************FIN-RUTINA***********************

;************************************INICIO-RUTINA*********************
mostrarString:
	mov     rdi,formPrintString
	mov     rsi,unString
    call	checkAlign
    sub		rsp,[plusRsp]
    call	printf
    add		rsp,[plusRsp]
	ret
;*************************************FIN-RUTINA***********************

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
