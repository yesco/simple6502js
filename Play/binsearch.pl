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
        next if $b+$y > $len;
        my $c = substr($s, $b+$y, 1);
        print "=\t$b\t$y\t'$c'\n" if $trace;
        if ($c lt $a) { # too small
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

$FACEBOOK = <<'HERE';
Implementerade just Binary Search för 6502, men tyckte att den "vanliga" metoden var lite jobbig; summera, dela med 2 addera low, två tester då man modifierar low, eller hi med mid+/-1, dvs

while(low < hi) {
  mid = low + floor((low+hi)/2);
  if (s[mid] < key)
     low = mid+1;
  if (s[mid] > key)
     hi = mid-1;
}

typ.

Så då 6502 har en addressing mode m(w[A]+y), som betyder att man pekar på en address i ZP (0-255) som  innehåller adressen på strängen, och Y är index i strängen, så såg jag en möjlighet att använda den.

Algorithmen är

s är en array med sorterade chars
len är längen
key är tecknet vi letar efter

b = 0;
y = len;

while (y >>= 1) {
  if (s[b+y] < key)
     b += y + 1;
}

*** det finns en möjlighet att den addresserar en extra byte:
antingen:
1) modifiera testet med b+y < len &&
2) eller padda strängen med \xff (255) byte (utan att modda len)

Jag har sökt men inte hittat motsvarande "variant" av binary search. Men jag tyckte det var kul att den var så "liten".
HERE
