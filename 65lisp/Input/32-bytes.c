// 32 byte Apple II fractal program
// - https://www.facebook.com/share/p/17uiM3PbJ6/

// A partial explanation of how it
// works: When the program starts it
// calls $F3D8 which is the same as
// doing HGR2 in basic. Memory location
// $E0 has a $FF in it, $E2, $FE, $FF
// have a $00 in them. The programmer
// took advantage that these memory
// locations were already loaded with
// the values needed for the demo after
// the computer booted.JSR$F457(HPLOT)
// draws the individual dots on the
// screen using the current HCOLOR
// which defaults to white.  

word main() {
  JSR $f3d8; // HGR2 select page 2($4000-$$5fff) full sc/
loop:
  LDA $e2;
  TAX;
  LSR;
  ADC $e0;
  STA $e0;
  SBC $ff;
  TAY;
  TXA;
  SBC $e0;
  STA $e2;
  LDY #$00;
  JSR $f457; // Plot a dot horiz=(Y,X) vertical=A
  DEC $ff;
  BVC loop;
  $ff;
  $ff;
}
