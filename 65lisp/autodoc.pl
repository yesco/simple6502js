open(IN, "cat *.s |");
while (<IN>) {
    if (/^;.*cc65 runtime: (.*)/i) {
        $doc = $1;
        print "\n";
    }
    print sprintf("%-15s - $doc\n", $1) if /^(\w+):/;
}

close(IN);
