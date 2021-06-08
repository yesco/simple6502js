# try to match definitions


# read ALF def and find actual name
open(IN, "ALF-AlphabeticForth.txt");
my %map = (), $m = 0;
while(<IN>) {
    if (/   (\S+)  +(\S+)/) {
        print "=\t$1\t$2\n";
        $map{$2} = $1;
        $m++;
    }
}
close(IN);

$map{'um+'} = '+';

$map{'char+'} = '1+';
$map{'chars'} = ' ';

$map{'cell+'} = '2+';
$map{'cells'} = '2*';

$map{'space'} = "' emit";
$map{'spaces'} = "' c#";

for $k (split(' ',  '1+ 2+ 4+ 1- 2- 4- 0= 0< 0> ')){
    $map{$k} = $k; # lol
}

# read eforth
open(IN, "Ref/EFORTH.SRC");
$all = join('', <IN>);
$all = lc $all;
$all =~ s/(\\.*?\n)/ /g;
$all =~ s/\n/ /g;
$all =~ s// /g;
$all =~ s/\(.*?\)/ /g;
$all =~ s/ +/ /g;

$all =~ s/\bchar (.)\S/'$1/g;

close(IN);
my %def = (), $d = 0;
my %trans = ();
while ($all =~ /: (\S+) (.*?);/g) {
    print ":\t$1\t$2\n";
    my ($name, $code) = ($1, $2);
    $def{$name} = $code;
    $d++;
    my $x = $code;
    $code =~ s/(\S+)/replace($1)/ge;
    print "T:\t$name\t$code\n";
    print "\n";
}

sub replace {
    my ($n) = @_;
    return $n if $n =~ /^[0-9]+$/;

    my $t = $map{$n};
    return $t if $t;

    $missfreq{$n}++;
    return "__".$n."__";
}

for $k (sort keys %missfreq) {
    print "T\t$missfreq{$k}\t$k\t__\n";
}

print "\n$m maps\n$d defs\n";

