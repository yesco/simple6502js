while(<>) {
    last if /Exports list by value/;
}

$last=0;
$sum=0;
$lastsize=0;

while(<>) {
    last if /Imports list/;

    while(s/^(\w+)\s+(\w+)\s+\w+\s+//) {

        $lastname= $name;
        $name= $1;
        $addr= hex($2);
        $size= $addr-$last;
        $last= $addr;

        next if $name =~ /__/;
        next if $name =~ /^[A-Z]$/;
        next if $name =~ /^CINT$/;

        print $size,"\t",$lastname,"\n";
        #print $size,"\t$2\t$1\n";
        $sum+= $size;
    }
}

print "\n\nSUM: $sum\n";
