# Generates a 6502 javascript file on stdout!
#
# ref for 6502
# - https://github.com/jamestn/cpu6502/blob/master/cpu6502.c
# - http://rubbermallet.org/fake6502.c
# (the latter ones got cycle counting)
#
# consider testing using:
# - https://github.com/pmonta

# TODO: illegal instructions that HLT or freeze
#
# http://ist.uwaterloo.ca/~schepers/MJK/ascii/65xx_ill.txt

# address calculation of argument
# (this is intended to be used inline, so cannot have second expression
#  there (pc+=2)-2: there is no post add 2... (pc++++)
#
%modes = (
    'acc', ' ', # lol: true!
    'imm', 'd= pc++',
    'zp',  'd= m[ pc++]',
     #zpy is zpx but for STX it's senseless
    'zpx', 'd= ((m[ pc++] + x)& 0xff)',
    'zpy', 'd= ((m[ pc++] + y)& 0xff)',
    'abs', 'd= w( (pc+=2)-2)',
    'absx', 'd= w( (pc+=2)-2) + x',
    'absy', 'd= w( (pc+=2)-2) + y',
    'zpi',  'd= wz( m[pc++])', # 6502C?
    'zpxi', 'd= (wz( m[pc++]+x ))',
    'zpiy', 'd= ( wz( m[pc++]) + y )',
);

# instructions to generated code
#
# alt 1:
#   MEM  - substitute by $modes{$m}
#   ADDR - prefix by addr=$modes{$m}, subst: addr
# alt 2:
#   do calculations before and store
#     addr = ...
#     (b    = byte value
#      w    = word value)
%impl = (
    'lda', 'g= n(z(a= MEM))',
    'ldx', 'g= n(z(x= MEM))',
    'ldy', 'g= n(z(y= MEM))',

    'sta', 'g= MEM= a',
    'stx', 'g= MEM= x',
    'sty', 'g= MEM= y',
    'stz', 'g= MEM= 0', # 6502C

    'and', 'g= n(z(a &= MEM))',
    'eor', 'g= n(z(a ^= MEM))',
    'ora', 'g= n(z(a |= MEM))',

# TODO: check how c() is implemented!
# C     Carry Flag      Set if A >= M
#  uint16_t result = regs.y - mem_read(addr);
#
#  regs.p.c = result > 255;
    'cmp', 'sc(0 <= n(z(g= a - (MEM))))',
    'cpx', 'sc(0 <= n(z(g= x - (MEM))))',
    'cpy', 'sc(0 <= n(z(g= y - (MEM))))',

    'asl',   'g= m[ADDR]= n(z(c( m[ADDR] << 1)))',
    'asl_a', 'g=       a= n(z(c(       a << 1)))',

    'lsr',   'g= n(z( m[ADDR]= sc(m[ADDR]) >> 1))',
    'lsr_a', 'g= n(z(       a=       sc(a) >> 1))',

    'rol',   'g= m[ADDR]= c(n(z(m[ADDR]<<1) + (p&C)))',
    'rol_a', 'g=       a= c(n(z((     a<<1) + (p&C))))',

    'ror',    'tmp=m[ADDR];g= m[ADDR]= n(z((m[ADDR]>>>1) | ((p&C)<<7)));sc(tmp)',
    'ror_a',  'tmp=a;      g=       a= n(z((  a    >>>1) | ((p&C)<<7)));sc(tmp)',

    'adc', 'adc(MEM)',
    'sbc', 'sbc(MEM)', # lol

    # notice B.. uses signed byte!
    'bra', 'pc += RMEM', # 6502C

    # 'bpl', 'if (~p & N) pc+= RMEM; else pc++',
    # 'bvc', 'if (~p & V) pc+= RMEM; else pc++',
    # 'bcc', 'if (~p & C) pc+= RMEM; else pc++',
    # 'bne', 'if (~p & Z) pc+= RMEM; else pc++',

    # 'bmi', 'if (p & N) pc+= RMEM; else pc++',
    # 'bvs', 'if (p & V) pc+= RMEM; else pc++',
    # 'bcs', 'if (p & C) pc+= RMEM; else pc++',
    # 'beq', 'if (p & Z) pc+= RMEM; else pc++',

    'bpl', '(~p & N)?pc+=RMEM:pc++',
    'bvc', '(~p & V)?pc+=RMEM:pc++',
    'bcc', '(~p & C)?pc+=RMEM:pc++',
    'bne', '(~p & Z)?pc+=RMEM:pc++',

    'bmi', '(p & N)?pc+=RMEM:pc++',
    'bvs', '(p & V)?pc+=RMEM:pc++',
    'bcs', '(p & C)?pc+=RMEM:pc++',
    'beq', '(p & Z)?pc+=RMEM:pc++',
    
# BIT - Bit Test
# A & M, N = M7, V = M6
#
# This instructions is used to test if one or more bits are set in a target memory location. The mask pattern in A is ANDed with the value in memory to set or clear the zero flag, but the result is not kept. Bits 7 and 6 of the value from memory are copied into the N and V flags.
#
# jsk: not clear: 76 from memory are copied or from the combined result?

    'bit', 'g= z( v(n(m[ADDR])) & a)',
#   'bit', 'g= m6m7(n(z(m[ADDR])))',

    'nop', '',

    # it seems assumed pc points to next memory
    # location. Hmmm. Maybe change that???

    'jmp',   'pc= w(pc)',
    'jmpi',  'pc= w(w(pc))',
    # TODO: BUG! this depends on how generating cod.... if mode inline
    'jsr',   'pc++;PH(pc>>8);PH(pc & 0xff);pc= w(pc-1)',

    'brk', 'pc++; tmp= p; p|= B; irq(); p|= tmp|I',
    'rts', 'pc= PL(); pc+= PL()<<8; pc++',
    'rti', 'p= PL(); pc=PL(); pc+= PL()<<8',

    'php', 'PH(g= p | 0x30)',
    'pha', 'PH(g= a)',

    'phx', 'PH(g= x)', # 6502C
    'phy', 'PH(g= y)', # 6502C
    
    'plp', 'g= p= PL()',
    'pla', 'g= n(z(a= PL()))',
    'plx', 'g= n(z(x= PL()))', # 6502C
    'ply', 'g= n(z(y= PL()))', # 6502C

    # cleverly (a=777) returns 777,
    # even if a is byte from byte array
    'dec', 'g= n(z(--m[ADDR]))',
    'dea', 'g= n(z(a= (a-1) & 0xff))', # 6502C
    'dex', 'g= n(z(x= (x-1) & 0xff))',
    'dey', 'g= n(z(y= (y-1) & 0xff))',

    'inc', 'g= n(z(++m[ADDR]))',
    'ina', 'g= n(z(a= (a+1) & 0xff))', # 6502C
    'inx', 'g= n(z(x= (x+1) & 0xff))',
    'iny', 'g= n(z(y= (y+1) & 0xff))',

    'clc', 'g= p &= ~C',
    'cli', 'g= p &= ~I',
    'clv', 'g= p &= ~V',
    'cld', 'g= p &= ~D',

    'sec', 'g= p|= C',
    'sei', 'g= p|= I',
    'sed', 'g= p|= D',

    'txa', 'g= n(z(a= x))',
    'tya', 'g= n(z(a= y))',
    'txs', 'g= n(z(s= x))',
    'tay', 'g= n(z(y= a))',
    'tax', 'g= n(z(x= a))',
    'tsx', 'g= n(z(x= s))',
);

# prelude w wrappings

print <<'PRELUDE';
//    ____   ______   ____    ____         Generated 6502(C) simulator
//   /    \  |       /    \  /    \   
//   |____   -----,  |    |   ____/        ("C") 2021 Jonas S Karlsson
//   |    \       |  |    |  /
//   \____/  \____/  \____/  |_____                  jsk.org

function cpu6502() { // generates one instance

// registers & memory
var a= 0, x= 0, y= 0, p= 0, s= 0, pc= 0, m= new Uint8Array(0xffff + 1);
const NMI= 0xfffa, RESET= 0xfffc, IRQ= 0xfffe;

function reset(a) { pc= w(a || RESET) }
function nmi(a) { PH(p); PH(pc >> 8); PH(pc & 0xff); reset(a || NMI) }
function irq() { nmi(IRQ) }

let w = (a) => m[a] + (m[(a+1) & 0xffff]<<8),
    wz= (a) => m[a] + (m[(a+1) & 0xff]<<8),
    PH= (v) =>{m[0x100 + s]= v; s= (s-1) & 0xff},
    PL= ( ) => m[0x100 + (s= (s+1) & 0xff)];

let C= 0x01, Z= 0x02, I= 0x04, D= 0x08, B= 0x10, Q= 0x20, V= 0x40, N= 0x80;

// set flag depending on value (slow?)
let z= (x)=> (p^= Z & (p^(x&0xff?0:Z)), x),
    n= (x)=> (p^= N & (p^ x)          , x),
    c= (x)=> (p^= C & (p^ !!(x & 0xff00))  , x & 0xff),
    v= (x)=> (p^= V & (p^ (x & V))    , x),
    // set carry if low bit set (=C!)
    sc=(x)=> (p^= C & (p^ x)          , x);

function adc(v) {
  // TODO: set overflow?
  let oa= a;
  a= n(z(c(a + v + (p & C))));
  if ((a & N) != (oa & N)) p |= V; else p &= ~V;
  if (~p & D) return; else c(0);
  if ((a & 0x0f) > 0x09) a+= 0x06;
  if ((a & 0xf0) <= 0x90) return;
  a+= 0x60;
  sc(1);
}

function sbc(v) {
  // TODO: set overflow?
  let oa= a;
  a= a - v - (1-(p & C))
  sc( a>= 0 );
  a= z(n(a & 0xff));
  if ((a & N) != (oa & N)) p |= V; else p &= ~V;
  //if ((oa^a) & (v^a)) ...
  if (~p & D) return; else sc(0);
  if ((a & 0x0f) > 0x09) a+= 0x06;
  if ((a & 0xf0) <= 0x90) return;
  a+= 0x60;
  sc(1);
}

let op /*Dutch!*/, ic= 0, f, ipc, cpu, d, g, q, cycles= 0, tmp;

// default is to run forever as count--...!=0 !
// pc=0 will exit (effect of unvectored BRK)
// return hash on BRK (why, where pc, count)
function run(count= -1, trace= 0, patch= 0)  {
  trace= 1==trace ? tracer : trace;
  trace && trace('print', 'head');
  let t= count;
  while(t--) {
    if (!pc) return {why: 'BRK', where:hex(4,w(0x100+s+1)-2), count: count-t};
    ic++; ipc= pc; mod= d= g= q= undefined;
    if (patch && patch(pc, m, cpu)) continue;
    switch(op= m[pc++]) {
PRELUDE

my @modes = (
    'imm/zpx', 'zp', 'acc/imm', 'abs', 
    'zpiy', 'zpx', 'absy', 'absx',
);

my %mod2i = ();

$i = 0;
for $m (@modes) {
    $mod2i{$m} = $i++;
}

# - Excepton modes

# 96 stx = stx 4 2      zpy    zpxi
# 20 jsr = jsr 1 0     0 abs    -
# A2 ldx = ldx 5 2     0 imm    zpxi
# B6 ldx = ldx 5 2     5 zpy    zpx
# BE ldx = ldx 5 2     7 absy    absx

# * = done


# maping from op code to instruction name
sub decode {
    my ($op, $mnc, $mod) = @_;

    my $v = hex($op);
    my $mmm = ($v >> 2) & 7;
    my $iii = ($v >> 5);
    my $cc = ($v & 3);
    my @arr;

    my $x, $n, $m = '-', $exception;;

    
#   0xx 000 00 = call&stack       BRK JSR RTI RTS
if ((0b10011111 & $v) == 0b00000000) {
    @arr = ('brk', 'jsr', 'rti', 'rts');
    die "Already have x:$x<!" if defined($x);
    $x = $iii;
    $m = 'abs';
}

#   0xx 010 00 = stack            PHP PLP PHA PLA
elsif ((0b10011111 & $v) == 0b00001000) {
    @arr = ('php', 'plp', 'pha', 'pla');
    die "Already have x:$x<!" if defined($x);
    $x = $iii;
}

#
#   xx0 110 00 = magic flags =0   CLC CLI*TYA CLD
#   xx1 110 00 = magic flags =1   SEC SEI --- SED
elsif ((0b00011111 & $v) == 0b00011000) {
    @clc = ('clc','sec','cli','sei','tya','---','cld','sed');
    die "Already have x:$x<!" if defined($x);
    $x = $iii;
}

#
#   1xx 010 00 = v--transfers--> *DEY TAY INY INX
elsif ((0b10011111 & $v) == 0b10001000) {
    @dey = ('dey', 'tay', 'iny', 'inx');
    die "Already have x:$x<!" if defined($x);
    $x = $iii;
}

#   1xx x10 10 = TXA TXS TAX TSX  DEX --- NOP ---
elsif ((0b10001111 & $v) == 0b10001010) {
    @arr = ('tsa', 'txs', 'tax', 'tsx', 'dex', '---', 'nop', '---');
    die "Already have x:$x<!" if defined($x);
    $x = ($v >> 4) & 7;;
}

#
#   ffv 100 00 = branch instructions:
#   ff0 100 00 = if flag == 0     BPL BVC BCC BNE
#   ff1 100 00 = if flag == 1     BMI BVS BCS BEQ
elsif ((0b00011111 & $v) == 0b00010000) {
    @arr = ('bpl','bmi','bvc','bvs','bcc','bcs','bne','beq');
    die "Already have x:$x<!" if defined($x);
    $x = $iii;
    $m = 'imm';
    $mmm = $mod2i{$m};
}

#                            (v--- indirect)
#   xxx mmm 00 = --- BIT JMP JMP* STY LDY CPY CPX
#   xxx mmm 01 = ORA AND EOR ADC  STA LDA CMP SBC
#   xxx mmm 10 = ASL ROL LSR ROR  STX LDX DEC INC
elsif ((0b00000000 & $v) == 0b00000000) {
    @arr = (
  '---','bit','jmp','jmpi', 'sty','ldy','cpy','cpx',
  'ora','and','eor','adc',  'sta','lda','cmp','sbc',
  'asl','rol','lsr','ror',  'stx','ldx','dec','inc');
    die "Already have x:$x<!" if defined($x);

    # 61         = ADC ($44,X)
    # 011 000 01 

    $x = ($cc << 3) + $iii;
    $m = $modes[$mmm];

    #print "x op=$op  iii=$iii mmm=$mmm cc=$cc   m=$m\n";

    # exceptions
    $mmm = $mod2i{'absy'} if $op eq 'BE';

    # name it
    $m = $modes[$mmm];
    #   use cc to clarify
    $m = $cc & 1 ? 'zpxi' : 'imm' if $mmm == 0;
    $m = $cc & 1 ? 'imm'  : 'acc' if $mmm == 2;
    $m = 'zpy' if $op =~ /(96|B6)/;

    #print "x op=$op  iii=$iii mmm=$mmm cc=$cc   m=$m\n";

# FAIL
} else {
    die "No found x!";
}

    my $n = $arr[$x];

    return ($v, $iii, $mmm, $cc, $x, $n, $m);
}

# 6502C ? ignore...

# 72 adc   ror 3 2  19     4 zpi
# 32 and   rol 1 2  17     4 zpi
# 80 bra   sty 4 0  4     0 imm
# D2 cmp   dec 6 2  22     4 zpi
# 52 eor   lsr 2 2  18     4 zpi
# B2 lda   ldx 5 2  21     4 zpi
# 12 ora   asl 0 2  16     4 zpi
# F2 sbc   inc 7 2  23     4 zpi
# 92 sta   stx 4 2  20     4 zpi
# 64 stz   jmpi 3 0  3     1 zp
# 74 stz   jmpi 3 0  3     5 zpx
# 9C stz   sty 4 0  4     7 abs
# 9E stz   stx 4 2  20     7 absx
# 14 trb   --- 0 0  0     5 zp
# 1C trb   --- 0 0  0     7 abs
# 04 tsb   --- 0 0  0     1 zp
# 0C trb   --- 0 0  0     3 abs
$c6502 = ' 72 32 80 D2 52 B2 12 F2 92 64 74 9C 9E 14 1C 04 0C 3A 1A ';

# generate instructions
my $shortercode = 1;
my $debuginfo = 1;
my $genfun = 0;

open IN, "op-mnc-mod.lst" or die "bad file";
my @ops, %mnc, %mod, %saved;
while (<IN>) {
    my ($op, $mnc, $mod) =/^(..) (\w+) ?(|\w*)$/;    die "no op: $_" unless $op;

    next if $c6502 =~ /$op/;


    my $line = "    case 0x$op: ";
    my $comment = '';

    # TODO: test if mod aggrees w mmm bits?
    my $node = '';
    if ($mod =~ /\w/) {
        my ($v, $iii, $mmm, $cc, $x, $n, $m) = &decode($op); 
        my $neq = ($mnc eq $n) ? '=' : ' ';
        my $meq = ($mod eq $m) ? '==' : '  ';
        if (!$neq || !$meq) {
            print "Decoding error!\n";
            print "= $op $mnc $neq $n $iii $cc     $mmm $mod $meq $m\n";
        }
        if ($shortercode && !($op =~ /(86|8E|96|B6|BE|4C|6C|20)/)
            && !((0b00011111 & $v) == 0b00010000)) # no branch
        {
            #$saved{$mnc} .= " $op,$mnc,$mod ";
            $saved_m{$mnc} |= 1 << $mmm;
            $saved_x{$mnc} = $x;
            $saved{$mnc} .= "case 0x$op: ";
            next;
        }
# #($shortercode && $mod
#       unless (($mod eq $modes[$mmm]) || ($mnc =~ /^b../)) {
        unless ($mod eq $modes[$mmm]) {
            #print "------foobar\n"; print works
            # doesn't seem to want to add this?
            #$comment = " // MODE $mod instead of mmm";
        }

    }

    if ($debuginfo) {
        $line .= "f='".(uc $mnc)."';";
        $line .= "q='$mod';" if $mod;
    }

    # address stuff
    my $i = $impl{$mnc};
    #print "/y $op $i\n";
    $i =~ s/RMEM/\(\(MEM ^ 0x80\)-127\)/;
    $i =~ s/MEM/m[$modes{$mod}]/;
    if ($i =~ /ADDR/) {
	if ($modes{$mod}) {
	    $i = 'd= '.$modes{$mod}."; $i";
	}
        $i =~ s/ADDR/d/g;
    }
    die "MEM:only use once:$i" if $i =~ /MEM/;
    $i =~ s/ +/ /g;
    #print "\\y $op $i\n";

    $line .= $i;

    if ($genfun) {
        my $r = sprintf("%s(){ $i }\n", uc $mnc);
        print ",$r";
        $gendata{$op} = uc $mnc;
    }

    my $wid = 55;

    if (0) { # format
        print sprintf("%-${wid}s", $line);
    } else { # plain
        print $line;
    }

    if (!$debuginfo) {
        print "; break; // ",uc($mnc)," $mod $comment\n";
    } else {
        print "; break; $comment\n";
    }

    #print '----LINE TOO LONG: ', length($line), "\n" if length($line) > $wid;

}

# LATER!
if ($shortercode) {

    # first generate mode stuff

    # trouble instructions
    # avoid in generic code
    # /(86|8E|96|B6|BE)/
    # zpy is zpx but for STX it's senseless
    #
    # 'zpy', '(m[pc++] + y) & 0xff', 
    # 'zpi',  'wrap(m[pc++])', # 6502C?
    # 'zpxi', 'wrap(m[pc++ + (x & 0xff)])',

    print "    default:
      // d= address of operand (data)
      switch(mod= (op >> 2) & 7) {
      case 0: op&1 ?
             (q='zpxi',   d= wz( m[pc++]+x))
          :  (q='imm',    d= pc++);                           break;
      case 1: q='zp';     d= m[pc++];                         break;
      case 2: q='imm';    d= op&1 ? pc++ : q='';              break;
      case 3: q='abs';    d= w(pc); pc+= 2;                   break;
      case 4: q='zpiy';   d= wz(m[pc++]) + y;                 break;
      case 5: q='zpx';    d= (m[pc++] + x) & 0xff;            break;
      case 6: q='absy';   d= w(pc) + y; pc+= 2;               break;
      case 7: q='absx';   d= w(pc) + x; pc+= 2;               break;
      }
";

    # print generic instructions
    print "      switch(i= (op>>5) + ((op&3)<<3)) {\n";

    foreach $inst (sort { $saved_x{$a} <=> $saved_x{$b} } keys %saved) {
        my $iiiii = sprintf("0x%02x", $saved_x{$inst});
        my $mod = $saved{$inst};

        # instruction
        my $i = $impl{$inst};
        $i =~ s/MEM/m[d]/;
        if ($i =~ /ADDR/) {
            $i =~ s/ADDR/d/g;
            die "MEM:only use once:$i" if $i =~ /MEM/;
            $i =~ s/ +/ /g;
        }
#       print "      // IMPL: $impl{$inst}\n";
#       print "      // $saved{$inst}\n";
#       print sprintf("      // if (%#2x & mod) {...\n", $saved_m{$inst});
        if ($debuginfo) {
            print "      case $iiiii: f='", uc $inst, "'; $i; break;\n";
        } else {
            print "      case $iiiii: $i; break; // ", uc $inst, "\n";
        }

        if ($genfun) {
            my $r = sprintf("%s(){ $i }\n", uc $inst);
            print ",,$r";
            $gendata{$op} = uc $mnc;
        }

    }

#    print "      }\n";
    print "      }\n";

}

# postlude
print "    }
    if (trace && trace(cpu, { ic, ipc, op, f, mod, d, val: g, cyc: cyc(op)})) return 'quit';
    cycles+= cyc(op);
  }
}
  
return cpu = {
  run, flags:ps, tracer, hex, dump, printStack, memFormat, w,
  state() { return { a, x, y, p, pc, s, m, ic, cycles}},
  last() { return { ipc, op, inst: f, addr: d, val: g}},
  reg(n,v=run) { return eval(n+(v!=run?'='+v:''))},
  setFlags(v){ n(z(v)) },
  consts() { return { NMI,RESET,IRQ, C,Z,I,D, B,Q,V,N}}};

////////////////////////////////////////
// optional: mini disasm and debugger

function hex(n,x,r=''){for(;n--;x>>=4)r='0123456789ABCDEF'[x&0xf]+r;return r};
function ps(i=7,v=128,r=''){for(;r+=p&v?'CZIDBQVN'[i]:' ',i--;v/=2);return r};
function is(v){ return typeof v!=='undefined'};

function cyc(op){return +('7600033032000440350004402400044066003330422044404500044024004440660003303220444035000440240004406600033042204440450004402400044006003330302044403500444024200400362033304220444045004440242044403600333032204440350004402400044036003330422044404500044024000440'[op])};

function tracer(how, what) {
  let line;
  if (what == 'head') {
    line = '= pc    op mnemonic   flags    a  x  y  s';
  } else {
    line = '= '+hex(4,ipc)+'  '+hex(2,op)+' '+
      ((f?f:'???')+(q?q:'---')).padEnd(9, ' ')+
      ps()+'  '+hex(2,a)+' '+hex(2,x)+' '+hex(2,y)+' '+hex(2,s)+' '+what.cyc+
      (is(d)&&(d!=ipc+1)?' d='+hex(4,d):'') +(is(g)?' g='+hex(2,g):'')
  }

  if (how == 'string') {
    return line;
  } else {
    console.log(line);
  }
}

function memFormat(a = dump.last,n = 8, dochars = 1) {
  let r = '', p = '', c;
  r= hex(4, a) + '  ';

  while(n--) {
    let c = m[a++];
    r += hex(2, c) + ' ';
    p += (c >= 32 && c < 128) ? String.fromCharCode(c) : '.';
  }
  return r+'  '+p;
}

function dump(a = dump.last, lines = 16, n = 8, nz=0) {
  let firsttime= 1;
  while(lines--) {
    let s= 0;
    for(let i=0; i<n; i++) s+= m[a+i];
    if (firsttime || !lines || !nz || s)
       console.log(memFormat(a, n));
    firsttime= 0;
    a += n;
  }
  dump.last = a;
}
dump.last = 0; // static variable

function printStack() {
  let x = cpu.reg('x');
  princ(`  STACK[\${(0x101-x)/2}]: `)
  x--;
  while(++x < 0xff) {
    princ(hex(4, cpu.w(x++)));
    princ(' ');
  }
  print();
}

} // end cpu6502

module.exports = { cpu6502 };

";

if ($genfun) {
    for $i (0..255) {
        my $h = sprintf('%02X', $i);
        my $f = $gendata{$h};
        print $f ? "$f" : "";
        print ",";
    }
}

# Well, overambitious... just some tools

print <<'DEBUGGER';

if (0) {
  // testing
  let cpu = cpu6502();
  let m = cpu.state().m;
  let hex = cpu.hex;

  // run 3 times with 3 instr:s each time
  let nn= 3;
  while (nn--) {
    console.log('cpu= ', cpu);
    console.log('state= ', cpu.state());
    console.log('last= ', cpu.last());
    console.log('consts= ', cpu.consts());
    console.log(cpu.run(3, 1));
  }

  if (0) {
    // not sure this is correct
    console.log('=======================');
    let start = 0x501, p = start;
    m[p++] = 0xa9; // LDA# 42
    m[p++] = 0x42;
    m[p++] = 0xa2; // LDX# fe
    m[p++] = 0xfe;
    m[p++] = 0xe8; // INX
    m[p++] = 0xd0; // BNE -1
    m[p++] = 0xff;
    m[p++] = 0xad; // LDY# 17
    m[p++] = 0x17;
    m[p++] = 0xad; // STYZP 07
    m[p++] = 0x07;
    m[p++] = 0x00; // BRK
    cpu.reg('pc', start);

    console.log('state= ', cpu.state());

    console.log(cpu.run(10, 1));

    cpu.dump(0);

  } else {

    // this seems to work
    console.log('=======================');
    cpu.reg('a', 0x42);
    cpu.reg('x', 0x00);
    cpu.reg('y', 0x69);
    cpu.reg('p', 0);
    console.log('state= ', cpu.state());

    let start = 0x501, p = start;
    m[p++] = 0x48; // PHA
    m[p++] = 0x8a; // TXA
    m[p++] = 0x48; // PHA
    m[p++] = 0x98; // TYA
    m[p++] = 0xaa; // TAX
    m[p++] = 0x68; // PLA
    m[p++] = 0xa8; // TAY
    m[p++] = 0x68; // PLA
    m[p++] = 0x00; // BRK

    cpu.reg('pc', start);

    console.log('state= ', cpu.state());

    console.log('SWAP X Y');
    console.log(cpu.run(10, 1));
    cpu.dump(start);
    console.log("STACK:");
    cpu.dump(0x200-16, 2);
  }

  // speedtest BRK lol
  if (1) {
    cpu.reg('pc', 0);

    let start = Date.now();
    let n = 1000000;

      cpu.run(n, 0);

    let ms = Date.now() - start;
    console.log(n, ms, Math.round(1000*n/ms), 'instructions/s');
  }
} // testing

DEBUGGER


