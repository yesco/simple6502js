#open IN, "op-mnc-mod.lst";
open IN, "opcodes.lst";
while(<IN>) {
    s/^(..) /sprintf("%c", hex($1)). " $1 "/ge;
    s/^=\s+(\S+)\s+(\S\S)\s*;/sprintf("%c", hex($2)). " $2 $1"/ge;
    print;
}

