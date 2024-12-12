open(IN, "./Play/wordfreq |");
while (<IN>) {
    if (/^\s*(\d+)\s+(\w+)/) {
        my ($n, $w) = ($1, $2);
        # nibbles
        $S= 0;
        foreach $c (split("", $w)) {
            $S++ if $c =~ /[eariotnslcd]/; 
        }
        $savings= $n * (length($w)+2+$S) - 2 + $S;

        printf("%8d %8d\t%s\n", $savings, $n, $w);
    } else {
        print STDERR "--ERROR: ", $_;
    }
}

