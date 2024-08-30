sub report {
    return if !$unix;
    if ($exit) {
        print "FAIL: $unix\n";
    } elsif (1) {
        print "ERR" if $error;
        chop($res);
        chop($res);
        print sprintf("%*s:%6d# %9dc %7.3fs - $expr \t=> $res\n",
          $error?13:16, $name, $times, $cycles, $secs);
        print "\t\t  $error" if $error; 
    } else {
        print "--- $name\n";
        print "unix: $unix\n";
        print "name: $name\n";
        print "tims: $times\n";
        print "expr: $expr\n";
        print "cycl: $cycles\n";
        print "secs: $secs\n";
        print "resl: $res\n";
    }
}

while(<>) {
    chop;
    if (/^unix> (.*)/) {
        &report();
        $unix= $times= $name= $expr= $cycles= $secs= $error= $res= undef;
        $unix= $1;
        $times= (/-b (\d+)/)? $1: 5000;
        $name= <>;
        chop($name);
    }
    # what if 2?
    if (/^> (.*)/) {
        $expr= $1;
        $res = "";
        while(($_=<>) && !/\d+ cycles/ && !/ERROR/) {
            $res.= "$_";
            #print "RES: $res\n";
        }
    }
    $expr= $1 if /^> (.*)/;
    $cycles= $1 if /(\d+) cycles/;
    $exit= $1 if /--- EXIT=(%d+) ---/;
    $secs= $1 if /^(\d*.\d+)$/;
    $error= $_ if /ERROR/;
}
&report();
