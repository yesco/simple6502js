sub report {
    return if !$unix;
    if ($exit) {
        print "FAIL: $unix\n";
    } elsif (1) {
        print "ERR" if $error;
        chop($res);
        chop($res);
        $eops= $ops+$eval;
        print sprintf("%*s:%6d# %9dc %7.3fs %7do %4.0fo/s - $expr \t=> $res\n",
          $error?13:16, $name, $times, $cycles, $secs, $ops, $secs?($eops/$secs):0);
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
        print "ops : $ops\n";
        print "eval: $eval\n";
    }
}

while(<>) {
    chop;
    if (/^unix> (.*)/) {
        &report();
        $ops= $unix= $times= $name= $expr= $cycles= $secs= $error= $res= undef;
        $unix= $1;
        $times= (/-b (\d+)/)? $1: 5000;
        $name= <>;
        chop($name);
    }
    # what if 2?
    if (/^> (.*)/) {
        $expr= $1;
        $res = "";
        while(($_=<>) && !/\d+ cycles/ && !/ERROR/ && !/Ops:/) {
            $res.= "$_";
            #print "RES: $res\n";
        }
    }
    $ops= $1 if /Ops: \+(\d+)/;
    $eval= $1 if /Eval: \+(\d+)/;
    $expr= $1 if /^> (.*)/;
    $cycles= $1 if /(\d+) cycles/;
    $exit= $1 if /--- EXIT=(%d+) ---/;
    $secs= $1 if /^(\d*.\d+)$/;
    $error= $_ if /ERROR/;
}
&report();
