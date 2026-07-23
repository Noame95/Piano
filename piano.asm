IDEAL
MODEL small
STACK 100h

DATASEG

;---------------; ;---------------; ;---------------; ;---------------;

filename dw ?

background db 'secret.bmp', 0
psanter   db 'psanter.bmp', 0

p0 db 'p0.bmp', 0
p1 db 'p1.bmp', 0
p2 db 'p2.bmp', 0
p3 db 'p3.bmp', 0
p4 db 'p4.bmp', 0
p5 db 'p5.bmp', 0
p6 db 'p6.bmp', 0
p7 db 'p7.bmp', 0
p8 db 'p8.bmp', 0
p9 db 'p9.bmp', 0

blackW db 'W.BMP', 0
blackE db 'E.BMP', 0
blackR db 'R.BMP', 0
blackT db 'T.BMP', 0
blackY db 'Y.BMP', 0
blackU db 'U.BMP', 0
blackI db 'I.BMP', 0


; 1, 2, 3, 4, 5, 6, 7, 8, 9, 0
pianoFreqs dw 262, 294, 330, 349, 392
           dw 440, 494, 523, 587, 659



pianoFiles dw offset p1, offset p2, offset p3, offset p4, offset p5
           dw offset p6, offset p7, offset p8, offset p9, offset p0
		   


; W, E, R, T, Y, U, I
blackFreqs dw 277, 311, 370, 415, 466, 554, 622

blackFiles dw offset blackW, offset blackE, offset blackR
           dw offset blackT, offset blackY, offset blackU
           dw offset blackI


Clock equ es:6Ch

filehandle dw ?

Header  db 54 dup (0)
Palette db 256*4 dup (0)
ScrLine db 320 dup (0)

ErrorMsg db 'Error', 13, 10, '$'

oldPicMask db ?


;---------------; ;---------------; ;---------------; ;---------------;

CODESEG

include 'photo.asm'


;---------------;
;---------------;
;---------------;


proc createImage
    ; CX = address of BMP filename

    call OpenFile
    call ReadHeader
    call ReadPalette
    call CopyPal
    call CopyBitmap
    call closeFile

    ret
endp createImage


;---------------;
;---------------;
;---------------;


proc StartTone
    push ax
    push dx
    ; DX:AX = 1193180, PIT base frequency
    mov dx, 12h
    mov ax, 34DCh

    ; AX = 1193180 / requested frequency
    div bx
    mov bx, ax

    ; Channel 2, low byte + high byte, square wave mode
    mov al, 0B6h
    out 43h, al
	
    mov al, bl
    out 42h, al
    mov al, bh
    out 42h, al
    in al, 61h
    or al, 00000011b
    out 61h, al

    pop dx
    pop ax

    ret
endp StartTone


;---------------;
;---------------;
;---------------;


proc StopTone
    push ax

    in al, 61h
    and al, 11111100b
    out 61h, al

    pop ax

    ret
endp StopTone


;---------------;
;---------------;
;---------------;


proc input
    mov ah, 1
    int 21h

    ret
endp input


;---------------;
;---------------;
;---------------;


proc delay
    push ax
    push cx
    push es

    mov ax, 40h
    mov es, ax

    mov ax, [Clock]

FirstTick:
    cmp ax, [Clock]
    je FirstTick

    ; 54 * 0.055 is approximately 3 seconds
    mov cx, 54

DelayLoop:
    mov ax, [Clock]

Tick:
    cmp ax, [Clock]
    je Tick

    loop DelayLoop

    pop es
    pop cx
    pop ax

    ret
endp delay


;---------------;
;---------------;
;---------------;


proc GraphicMode
    mov ax, 13h
    int 10h

    ret
endp GraphicMode


;---------------;
;---------------;
;---------------;


proc TextMode
    mov ax, 2
    int 10h

    ret
endp TextMode


;---------------;
;---------------;
;---------------;


proc closeFile
    push ax
    push bx

    mov bx, [filehandle]
    mov ah, 3Eh
    int 21h

    pop bx
    pop ax

    ret
endp closeFile


;---------------;
;---------------;
;---------------;


proc ShowBackground
    mov cx, offset background
    call createImage

    ret
endp ShowBackground


;---------------;
;---------------;
;---------------;


proc ShowPiano
    mov cx, offset psanter
    call createImage

    ret
endp ShowPiano


;---------------;
;---------------;
;---------------;


proc FlushKeyboardBuffer
    push ax

FlushKeyboardLoop:
    ; Check if keyboard controller contains data
    in al, 64h
    test al, 1
    jz KeyboardBufferEmpty

    ; Remove old scan code
    in al, 60h
    jmp FlushKeyboardLoop

KeyboardBufferEmpty:
    pop ax

    ret
endp FlushKeyboardBuffer


;---------------;
;---------------;
;---------------;


proc EnableRawKeyboard
    push ax

    ; Temporarily disable interrupts while changing PIC mask
    cli

    ; Read and save the current interrupt mask
    in al, 21h
    mov [oldPicMask], al

    ; Mask IRQ 1, the BIOS keyboard interrupt
    or al, 00000010b
    out 21h, al

    sti

    pop ax

    ; Remove scan codes left from earlier input
    call FlushKeyboardBuffer

    ret
endp EnableRawKeyboard


;---------------;
;---------------;
;---------------;


proc RestoreKeyboard
    push ax

    ; Remove any scan codes left in the controller
    call FlushKeyboardBuffer

    cli

    ; Restore the original PIC interrupt mask
    mov al, [oldPicMask]
    out 21h, al

    sti

    pop ax

    ret
endp RestoreKeyboard


;---------------;
;---------------;
;---------------;


proc ReadScanCode

WaitForScanCode:
    ; Port 64h bit 0 indicates available keyboard data
    in al, 64h
    test al, 1
    jz WaitForScanCode

    ; Read the scan code
    in al, 60h

    ret
endp ReadScanCode


;---------------;
;---------------;
;---------------;


proc PlayWhiteNote
    ; Input:
    ; AL = note index from 0 through 9
    push ax
    push bx
    push cx
    push si
    cmp al, 9
    ja InvalidNote
    xor ah, ah
    mov si, ax
    shl si, 1
    push si
    mov cx, [pianoFiles + si]
    call createImage
    pop si
    mov bx, [pianoFreqs + si]
    call StartTone

    clc
    jmp PlayNoteFinished

InvalidNote:
    stc

PlayNoteFinished:
    pop si
    pop cx
    pop bx
    pop ax

    ret
endp PlayWhiteNote



;---------------;
;---------------;
;---------------;


proc PlayBlackNote
    ; AL = black-note index from 0 through 6
    push ax
    push bx
    push cx
    push si
    cmp al, 6
    ja BlackInvalidNote
    xor ah, ah
    mov si, ax
    ; Every table entry is a word: multiply index by 2
    shl si, 1
    push si
    mov cx, [blackFiles + si]
    call createImage
    pop si
    mov bx, [blackFreqs + si]
    call StartTone
    clc
    jmp BlackNoteFinished


BlackInvalidNote:
    stc


BlackNoteFinished:
    pop si
    pop cx
    pop bx
    pop ax

    ret
endp PlayBlackNote


;---------------;
;---------------;
;---------------;

proc checkInput

GetInput:
    call ReadScanCode
    ; Q make code = 10h
    cmp al, 10h
    je QuitGame
    ; 1 = 02h
    ; 2 = 03h
    ; ...
    ; 9 = 0Ah
    ; 0 = 0Bh

    cmp al, 02h
    jb CheckBlackKeys

    cmp al, 0Bh
    jbe WhiteKeyPressed


CheckBlackKeys:
    ; W = 11h
    ; E = 12h
    ; R = 13h
    ; T = 14h
    ; Y = 15h
    ; U = 16h
    ; I = 17h
    cmp al, 11h
    jb GetInput

    cmp al, 17h
    ja GetInput


BlackKeyPressed:
    mov bl, al
    sub al, 11h
    call PlayBlackNote
    jc GetInput
    jmp PrepareForRelease


WhiteKeyPressed:
    mov bl, al
    sub al, 02h
    call PlayWhiteNote
    jc GetInput


PrepareForRelease:
    ; Break code = make code + 80h
    add bl, 80h


WaitForRelease:
    call ReadScanCode
    ; Wait until the same key is released
    cmp al, bl
    jne WaitForRelease

    call StopTone
    call ShowPiano

    jmp GetInput

endp checkInput


;---------------;
;---------------;
;---------------;


proc QuitGame
    call StopTone

    ; Return keyboard control to BIOS
    call RestoreKeyboard

    call TextMode

    mov ax, 4C00h
    int 21h

    ret
endp QuitGame


;---------------;
;---------------;
;---------------;


start:
    mov ax, @data
    mov ds, ax

    call GraphicMode
    call ShowBackground
    call input

    call GraphicMode
    call ShowPiano
    ; Prevent BIOS from consuming scan codes
    call EnableRawKeyboard
    call checkInput


END start