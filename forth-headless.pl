my $last = "", $name = "";

use List::Util qw/shuffle/;

# 15 collisions out of 113 forth words
my @p1 = shuffle(1,12,8,5,6,3,7,9,10,13,15,11,2,0,4,14);
my @p2 = shuffle(12,1,2,14,9,11,13,4,10,15,0,8,3,6,5,7);

sub pearson{
    my ($s) = @_;

    my $h = 0;
    for(my $i=0; $i<length($s); $i++){
        my $c = ord(substr($s, $i, 1));
        my $x = $h ^ $c;
        my $a = $p1[(($x >> 4))] << 4;
        my $b = $p2[(($x & 15))];
        $h = $a | $b;
        #print "\t$s\ti=$i\tx=$x\ta=$a\tb=$b\t$h\n";;
    }
    return sprintf("%02x", $h);
}

sub pearson3{
    my ($s) = @_;

    my $h = 0;
    for(my $i=0; $i<length($s); $i++){
        my $c = ord(substr($s, $i, 1));
        my $x = $h ^ $c;
        my $a = $p1[(($x >> 4))];
        my $b = $p1[(($x & 15))] << 4;
        $h = $a | $b;
        #print "\t$s\ti=$i\tx=$x\ta=$a\tb=$b\t$h\n";;
    }
    return sprintf("%02x", $h);
}

my @p = shuffle(0..255);

sub pearson2{
    my ($s) = @_;

    my $h = 0;
    for(my $i=0; $i<length($s); $i++){
        my $c = ord(substr($s, $i, 1));
        my $x = $h ^ $c;
        $h = $p[$x];
        #print "\t$s\ti=$i\tx=$x\ta=$a\tb=$b\t$h\n";;
    }
    return sprintf("%02x", $h);
}

my %have = ();
my $c = 0;

while (<>) {
    $last = $name;
    chop;
    $name = $_;
    next if $name =~ / /;
    
    my $h = pearson3($name);
    $c++ if $have{$h};
    $have{$h}++;

#    print $name, "\t", $h, "\n";

    next;;

}



print "$c\tp1: @p1\tp2: @p2\n";

exit;

while(1) {


    if (1) {
        # requires sorted input!

        print substr($name, 0, 2), "\t\t", $name, "\n";

        if (substr($last, 0, 2) eq substr($name, 0, 2)) {
            # conflict
            print substr($last, -2, 2), "\t=1\t", $last, "\n";
            print substr($name, -2, 2), "\t=2\t", $name, "\n";
        }
        next;
    } elsif (1) {
        # COOL first two + last two
        #   is unique!
        print substr($name, 0, 2).substr($name, -2, 2), "\t", $name, "\n";
        next;
    }




    my $first = ord(substr($name, 0, 1)) || 32;
    my $second = ord(substr($name, 1, 1)) || 32;
    my $third = ord(substr($name, 2, 1)) || 32;
    my $last = ord(substr($name, -1, 1)) || 32;

    my $sum = 0, $h2 = 0xbeef, $h3 = 0xbeef, $hx = 0, $hxor = 0;
    my $fsll = 0;
    for $i (0..length($name-1)) {
        my $c = ord(substr($name, $i, 1));
        $sum += $c;

        my $h2l = $h2; 
        $h2 += $c * 3;
        $h2 <<= 3;
        $h2 ^= $h2l;

        $h3 = ($h3 << 2)^$h3;
        $h3 ^= $c*3;

        $hx += $c;
        $hx ^= (($c+5) << 2);

        if ($i >= 2) {
            $fsll <<= 1; 
            $fsll ^= $ci<<3;
        }

        $hxor ^= $c;
    }
    $h2 &= 0xffff;
    $h3 &= 0xffff;

    print $name, "\t";
    my $fs = $first + 256*$second;
    my $ft = $first + 256*$third;
    my $fl = $first + 256*$last;

    my $fsl = $fs + ord($last);

    print sprintf("%04x\t", $sum);
    print sprintf("%04x\t", $fs);
#    print sprintf("%04x\t", $fl);
#    print chr($first),chr($second),chr($third),chr($last), "\t";
#    my $x = $first*256 + $second + $third*7 + $last*3 + length($name)*8 + $hx;
#    print sprintf("%04x\t", $x);

    # WHOA! a unique hash function!
#    my $y = $first*256 + $second + $third*4 + $last*3 + length($name)*8 + $hxor;

#    print sprintf("%04x\t", $y);
    print $four,"\t";
    print "\n";
}
