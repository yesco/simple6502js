sub rch {
    return chr(33+int(rand(94)));
}

sub rstr {
    my $len = 1+int(rand(42));
    #my $len = 1+int(rand(1024));
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
    #$s .= "\xff\xff";
    while ($y) {
        $y = int($y/2);
        next if $b+$y >= $len;
        my $c = substr($s, $b+$y, 1);
        print "=\t$b\t$y\t'$c'\n" if $trace;
        if ($c lt $a) { # too small
            $b += $y+1;
        }
    }
    return $b;
}

sub one {
    my ($len, $s) = @_;
    print "$len\t\"$s\"\n" if $trace;
    
    my @f = split('', $s);
    for $a (split('', $s)) {
        my $p = index($s, $a);
        my $b = bs($len, $s, $a);
        if ($trace || $b != $p) {
            print "$a\t\"$s\"\n";
            print "  $b $p\t ", ' ' x ($b-1), "'$a'\n";
        }

        if ($f[$b] eq $a) {
            $f[$b] = ' ';
        }
        print "=@f\n" if $trace;
    }

    my $f = join('', @f);
    if ($f =~ /^ +$/) {
        print "OK   $len >$s<\n";
    } else {
        print "     $len >$s<\n";
        print "ERR: $len >$f<\n";
    }
}


if (0) {
    one(3, "AQq");;
    exit;
}

#$trace = 1;
for $n (1..10000) {
    one(rstr());
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

$FACEBOOK = <<'HERE';
I just think I "invented" a simple binary search (for 6502). I thought the normal method of adding, summing low+hi, dividing by two, floor etc, and then two tests > < where you then modify low or hi with mid +/- 1.

```
   while(low < hi) {
     mid = low + floor((low+hi)/2);
     if (s[mid] < key)
        low = mid+1;
     if (s[mid] > key)
        hi = mid-1;
   }
```

typically

So, since 6502 has an cool indirect addressing mode IY m(w[A]+y), which means that you point at a zero page location where the address of your data is and Y is used to index that data, I thought I saw a possiblity of using this.

The algorithm in "psuedo C" is

s is an array of sorted chars
len is the length
key is what we're searching for

```
   b = 0;
   y = len;

   while (y >>= 1) {
     if (s[b+y] < key)
        b += y + 1;
   }
```

*** it's a possibily that an extra byte is address either:

1) modify the test with b+y < len &&
2) or pad the string with one \xff (255) byte (no change of len)

I've searched but not found this "simplified" binary search. I just like how short it is!

Now, the 6502 assembly is working, but I feel it's a bit too long, and the cycles in the loop too many.

A few thoughts for "yakshaving"; move the key searched for to ZP; reverse the test (and use only BCS); move Y to zp as we then can LSR it, just need to load to Y.
HERE
