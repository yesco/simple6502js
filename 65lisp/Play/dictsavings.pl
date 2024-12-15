open(IN, "./Play/wordfreq |");
$i= 0;
while (<IN>) {
    if (/^\s*(\d+)\s+(\w+)/) {
        my ($n, $w) = ($1, $2);
        $i++;
        # nibbles
        $N= 0;
        foreach $c (split("", $w)) {
            if ($c =~ /[ eariotnslcdu]/) {
                $N++;
            } elsif ($c =~ /[pmhgfyw<\/>.,"]/) {
                $N+= 2;
            } else {
                # quoted
                $N+= 3;
            }
        }

        # WTF? - maybe I was drunk?

        # bytes
        #   $N nibbles for the word, 2 for preceeding/succeeding spaces, -2 for 'D?' entry
        $savings= $n * ($N+2-2-(($i>14)?1:0))/2;
        $save128= $n * (length($w)+2-1);

        printf("%8d %8d\t%s\n", $savings, $n, $w);
        #printf("%8d %8d\t%s\n", $save128, $n, $w);
    } else {
        print STDERR "--ERROR: ", $_;
    }
}

