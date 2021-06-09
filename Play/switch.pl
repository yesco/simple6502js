$n = 256*1;
$choice = 'fun';
$choice = 'switch';

if ($choice eq 'fun') {
    print "var f = [\n";
    for $i (0..($n-1)) {
	print "function f$i(n){ nn += n; },\n";
    }
    print "];\n";
}

print "

var nn = 0;
var n = 100000000;
while(n--) {
";

if ($choice eq 'fun') {
    print "f[n % $n](n);\n";
} elsif ($choice eq 'switch') {
    print "switch(n % $n) {\n";
#    for $q (0..($n-1)) { 	$i = $n - $q;
    for $i (0..($n-1)) {
	print "case $i: nn += n; break;\n";
    }
    print "}\n";
}

print "
}

console.log(nn);
";

