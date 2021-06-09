


open IN, "op-mnc-mod.lst" or die "bad file";
my @ops, %mnc, %mod;
while (<IN>) {
    my ($op, $mnc, $mod) =/^(..) (\w+) ?(|\w*)$/;    die "no op: $_" unless $op;
    next if $c6502 =~ /$op/;

    my $b = hex($op);
    my $iii = ($b >> 5);
    my $mmm = ($b >> 2) & 7;
    my $cc = ($b & 3);

    print sprintf("%03b %03b %02b     $op    $mnc $mod\n", $iii, $mmm, $cc);


    if (0 && ($mod =~ /\w/)) {

        my ($v, $iii, $mmm, $cc, $x, $n, $m) = &decode($op); 
        my $neq = ($mnc eq $n) ? '=' : ' ';
        my $meq = ($mod eq $m) ? '==' : '  ';
        if (!$neq || !$meq) {
            print "Decoding error!\n";
            print "= $op $mnc $neq $n $iii $cc     $mmm $mod $meq $m\n";
        }
        if ($shortercode && !($op =~ /(86|8E|96|B6|BE|4C|6C|20)/)
            && !((0b00011111 & $v) == 0b00010000)) # no branch
        {
            next;
        }

        unless ($mod eq $modes[$mmm]) {
            # print "------foobar\n"; print works
            # doesn't seem to want to add this?
            $comment = " // MODE $mod instead of mmm";
        }

    }
}

