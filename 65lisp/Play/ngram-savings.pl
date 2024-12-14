$sum= 0;
while(<>) {
    if (/(\d+)\s+"(.*)"/) {
        ($freq, $n)= ($1, length($2));
        $bytes= $freq*($n-1);
        $sum+= $bytes;
        printf("%9d  %10d  $_", $bytes, $sum);
    } else {
        printf("-- $n-gram  %10d\n", $sum) if $sum;
        $sum= 0;
    }
}

        
