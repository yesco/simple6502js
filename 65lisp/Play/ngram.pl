#open(IN, "sherlock.txt");
$s = join("", <>);
#while($s =~ /(....)/g) {
$len= length($s);
for $i (0..$len) {
    print '"', substr($s,$i,10), '"', "\n";
}
