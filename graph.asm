        P286
        MODEL   tiny

        CODESEG

X_SIZE  EQU     320
Y_SIZE  EQU     200
APPROX  EQU     100

        ORG 100h

Start:
        mov     al, 13h                 ; 320*200*256 (MCGA)
        int     10h

        mov     ax, 0A000h
        mov     es, ax

        mov     ax, 0
        mov     bx, 0
        mov     cx, 100
        mov     dx, 50
        call    Line

Bye:
        xor     ah, ah                  ; Flush keyboard buffer
        int     16h

        mov     ax, 3h                  ; Normal text mode
        int     10h
        ret

;**********************************************************
; Point: draws point at specified coords and color
;**********************************************************
; # Input:
;       (BX, AX) = Coords
;       CL = Color
;       ES = Video Segment
; # Output:
;       NONE
; # Registers:
;       NONE
;**********************************************************
Point   PROC
        pusha

        mov     dx, X_SIZE
        mul     dx
        add     bx, ax
        mov     es:[BYTE PTR bx], cl

        popa
        ret
Point   ENDP

;**********************************************************
; Line: draws line at specified coords and color
;**********************************************************
; # Input:
;       (AX, BX), (CX, DX) = Coords
;       First word in stack = Color
;       ES = Video Segment
; # Output:
;       NONE
; # Registers:
;       NONE
;**********************************************************
Line    PROC
; LINE (AX, BX) - (CX, DX)
@@05:
        pusha

        cmp     cx, ax
        jae     @@10
        xchg    ax, cx
        xchg    bx, dx

@@10:
; SI = CX - AX
        mov     si, cx
        sub     si, ax
; DI = DX - BX
        mov     di, dx
        sub     di, bx

        mov     dx, di
        test    dx, 8000h                       ; Is DI negative?
        jz      @@20
        xor     dx, 0FFFFh                      ; Shortest way to say (X*(-1))

@@20:
        cmp     si, dx                          ; Do we need an axes filp?
        jae     @@30
        popa                                    ; If so, restore registers...
        xchg    ax, bx                          ; ...and filp them
        xchg    cx, dx
        mov     cs:[flip], 0FFh                 ; Remind for later
        jmp     short @@05

@@30:
; Save initial coords
        mov     cs:[x1], ax
        mov     cs:[y1], bx

; AX = (DI * APPROX) / SI
        mov     ax, APPROX
        imul    di
        idiv    si

        mov     ch, cs:[flip]                   ; CH is accessed faster than
                                                ; cs:[flip]
        mov     cl, 4                           ; Color

@@Draw:
        push    ax
; AX = (AX * SI) / APPROX
        imul    si
        mov     bx, APPROX
        idiv    bx

        mov     bx, si
        add     bx, cs:[x1]
        add     ax, cs:[y1]

        or      ch, ch
        jz      @@40
        xchg    ax, bx

@@40:
        call    Point
        pop     ax

        or      si, si
        jz      short @@Bye
        dec     si

        jmp     short @@Draw

@@Bye:
        popa
        ret

flip    DB      0
x1      DW      ?
y1      DW      ?
Line    ENDP

END Start
