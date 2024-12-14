$sum= 0;
while(<>) {
    $sum+= $1 if /^\s*(\d+)/;
    printf("%12d  $_", $sum);
}

