.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 2               ; 2x 16KB PRG code
  .byte 1               ; 1x  8KB CHR data
  .byte $01, $00        ; mapper 0, vertical mirroring

.segment "VECTORS"
  ;; When an NMI happens (once per frame if enabled) the label nmi:
  .addr nmi
  ;; When the processor first turns on or is reset, it will jump to the label reset:
  .addr reset
  ;; External interrupt IRQ (unused)
  .addr 0

; "nes" linker config requires a STARTUP section, even if it's empty
.segment "STARTUP"

; Main code segement for the program
.segment "CODE"

reset:
  sei		; disable IRQs
  cld		; disable decimal mode
  ldx #$40
  stx $4017	; disable APU frame IRQ
  ldx #$ff 	; Set up stack
  txs		;  .
  inx		; now X = 0
  stx $2000	; disable NMI
  stx $2001 	; disable rendering
  stx $4010 	; disable DMC IRQs

;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit $2002
  bpl vblankwait1

clear_memory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne clear_memory

;; second wait for vblank, PPU is ready after this
vblankwait2:
  bit $2002
  bpl vblankwait2

main:
load_palettes:
  lda $2002
  lda #$3f
  sta $2006
  lda #$00
  sta $2006
  ldx #$00
@loop:
  lda palettes, x
  sta $2007
  inx
  cpx #$20
  bne @loop

enable_rendering:
  lda #%10000000	; Enable NMI
  sta $2000
  lda #%00010000	; Enable Sprites
  sta $2001

forever:
  jmp forever

nmi:
  ldx #$00 	; Set SPR-RAM address to 0
  stx $2003
@loop:	lda hello, x 	; Load the hello message into SPR-RAM
  sta $2004
  inx
  cpx #$1c
  bne @loop
  rti

hello:
  .byte $00, $00, $00, $00 	; Why do I need these here?
  .byte $00, $00, $00, $00
  .byte $6c, $00, $00, $6c ; P
  .byte $6c, $01, $00, $76 ; A
  .byte $6c, $02, $00, $80 ; U
  .byte $6c, $03, $00, $8A ; L
;  .byte $6c, $03, $00, $94 ; L

palettes:
  ; Background Palette
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00

  ; Sprite Palette
  .byte $0f, $20, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00

; Character memory
.segment "CHARS"
  .byte %11111100	; P (00)
  .byte %11000110
  .byte %11000110
  .byte %11000110
  .byte %11111100
  .byte %11000000
  .byte %11000000
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %00111000	; A (01)
  .byte %01101100
  .byte %11000110
  .byte %11000110
  .byte %11111110
  .byte %11000110
  .byte %11000110
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %11000110	; U (02)
  .byte %11000110
  .byte %11000110
  .byte %11000110
  .byte %11000110
  .byte %11000110
  .byte %01111100
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00


  .byte %01100000	; L (03)
  .byte %01100000
  .byte %01100000
  .byte %01100000
  .byte %01100000
  .byte %01100000
  .byte %01111110
  .byte %00000000
  .byte $00, $00, $00, $00, $00, $00, $00, $00