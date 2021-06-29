sub rch {
    return chr(33+int(rand(94)));
}

sub rstr {
    my $len = 1+int(rand(42));
    my %c = ();
    for $i (1..$len) {
        $c{rch()} = 1;
    }
    my $s = '';
    for $c (sort(keys(%c))) {
        $s .= $c;
    }
    $len = length($s);
    return $len, $s;
}

sub bs {
    my ($len, $s, $a) = @_;
    # binary seearch
    my $b = 0;
    my $y = $len;
    while ($y) {
        $y = int($y/2);
        my $c = substr($s, $b+$y, 1) || chr(255);
        print "=\t$b\t$y\t'$c'\n" if $trace;
        if ($c lt $a) {
            $b += $y+1;
        }
    }
    return $b;
}

sub one {
    
    my ($len, $s) = rstr();
    
    my @f = split('', $s);
    for $a (split('', $s)) {
        my $p = index($s, $a);
        my $b = bs($len, $s, $a);
        if ($trace) {
            print "$a\t\"$s\"\n";
            print "  $b $p\t ", ' ' x ($b-1), "'$a'\n";
        }

        if ($f[$p] eq $a) {
            $f[$p] = ' ';
        }
    }

    my $f = join('', @f);
    unless ($f =~ /^ +$/) {
        print "     >$s<\n";
        print "ERR: >$f<\n";
    }
}

for $n (1..10000) {
    one();
}

