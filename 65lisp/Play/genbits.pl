print "#define B(a,b,c,d,e,f,g,h) (128*a+64*b+32*c+16*d+8*e+4*f+2*g+h)\n";
print "\n";
print "#define _ 0\n";

for $i (0..255) {
    $b= sprintf("%08b", $i);
    $d= $b;
    $d=~ s/0/_/ge;
    print sprintf("#define B_$d     %3d\n", $i);
    # for "sprites"
    if ($i<64) {
        $d=~ s/^..//;
        print sprintf("#define    _$d     %3d,\n", $i+64);
    }
}
