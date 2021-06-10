for $i (32..126) {
    if (chr($i) eq '"') {
        print "'",chr($i),"'","\n";
    } elsif (chr($i) eq '^') {
#        print '"^^"',"\n";
    } elsif (chr($i) eq '\\') {
        print '"\\\\"',"\n";
    } else {
        print '"',chr($i),'"',"\n";
    }
}
