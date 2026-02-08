;; This is for debugging... lol

.ifnblank
;;; These gives trouble...
;; commit 988a90bfdbdc9750ceb748b59fba51e7429e95d2
;; Author: Jonas S Karlsson <jsk@yesco.org>
;; Date:   Mon Feb 2 22:30:27 2026 +0700

;;     printvariables: update comment about code sizes

;; commit 11e4eb7cdfdac95703d8749331fcdcd273247c57
;; Author: Jonas S Karlsson <jsk@yesco.org>
;; Date:   Mon Feb 2 21:30:26 2026 +0700

;;     printvariables: delimit functions

;; commit c52ae3cc5a3c40c039e2fa013d05a75a05600db4
;; Author: Jonas S Karlsson <jsk@yesco.org>
;; Date:   Mon Feb 2 21:24:39 2026 +0700

;;     parse:
;;     - printvariables() in C, make a better one, lol
;;     - -q disasm
;;     - -pv print vars
;;     - -pe print env
;;     - -pV printvariables()

;; commit 7f98b785192fe21c7b09b783c5121421d540d86f
;; Author: Jonas S Karlsson <jsk@yesco.org>
;; Date:   Mon Feb 2 17:43:25 2026 +0700

;;     parse:
;;     - got rid of warnings
;;     - command line parameters
;;     - c compile
;;     - f file input
;;     - r run (1)
;;     - r10 run 10 times
;;     - when exiting the (byte) exitcode of the last program is returned

;; commit 2e1b9e9ce9612f20f2632cfdfc45ac79824ed815
;; Author: Jonas S Karlsson <jsk@yesco.org>
;; Date:   Mon Feb 2 14:44:44 2026 +0700

;;     cycles: need new cc65 and sim65

;; commit d329549cfcdaf2bf33d551adc302226b5c35d6c1
;; Author: Jonas S Karlsson <jsk@yesco.org>
;; Date:   Mon Feb 2 14:39:59 2026 +0700

;;     cycles,fopen: Play with io on sim65 and getting cycles

;; ;;; This one ok!
;; commit 704fae71e47a4ea6fe5bc3b52bb503ede56e3989
;; Author: Jonas S Karlsson <jsk@yesco.org>
;; Date:   Sun Feb 1 23:19:46 2026 +0700

;;     IDE:
;;     -
;;     atmos-constants.asm:
;;     - updated from cc65


.endif

;;; (C) 2025 jsk@yesco.org (Jonas S Karlsson)
;;; 
;;; ALL RIGHTS RESERVED
;;; - Generated code in tap-files are free,
;;;   and without royalty. The source code of
;;;   the compiler, the rules are (C) me.
;;; 


;;; TITLE
;;; 
;;; MeteoriC: A native on-device 6502, minimalist
;;; C-compiler & IDE using Code Generating BNF-Rules
;;; 
;;; 
;;; It interprets a BNF-description of a programming
;;; language while reading and matching it with a
;;; source text of that langauge. The BNF contains
;;; generative "templated" rules of code generation,
;;; with minimal instrumentation generates runnable
;;; machine code.
;;;
;;; There are "token"-matchers: as %D to parse numeric
;;; constants; %S %s strings, and %V %A %N to match
;;; variable and function names giving addresses and
;;; enabling scope management.
;;; 
;;; The generative directives allow for substitutions
;;; of bytes: < > lo and hi-byte; <> full address;
;;; +> for one address higher (next byte);
;;; ':' (push here) '{{' (push to patch);
;;; '#' (push) ';' (pop) 'D' 'd' copy, '?N' pick
;;; completes it with value juggling.
;;; 
;;; A hack %{ is available to inject and run immediate
;;; code during parsing enabling experimential 
;;; features, like matching a byte value, or enabling
;;; partial (constant) expression evaluations. Many ushc
;;; functions have later been generlized and become '%'
;;; features.
;;; 


;;; 
;;; GOALS:
;;; - an actual machine 6502 compiler running ON 6502
;;; - "simple" rule-driven
;;; - provide full screen (emacs) editor
;;; - many languages (just change rules)
;;; - have MINIMAL workable subset
;;; - have OPTRULES extentions for efficient codegen
;;; More specifically:
;;; - be a "proper" subset of C (at least syntactically)
;;; - *minimal* sized BNF-engine asm code engine (~ 1.5 KB)
;;; - data driver "minimal" codegen rules (~ 2.4 KB+)
;;; - optional optimization by specialization rules (~ +2.1 KB)
;;; - fast "enough" to run "a few screens of code"
;;;   (~ 133 "ops" compiled/s ~ 19 lines/s) - LOL
;;;   (Turbo Pascal did 2000 lines in less than 60s on Z80)
;;;   (== 33 lines/s)
;;; - somewhat useful error messages
;;;   (difficult w recursive descent BNF-style parsing)
;;; 

;;; 
;;; NON-Goals:
;;; - not be the best super-optimizing compiler (no global opt)
;;; - not be the fastest
;;; - no constant folding (yet)
;;; 

;;; 
;;; NAME
;;; 
;;; The idea has gone through several prototypes; starting with
;;; a BNF-style compiler generating byte code for a simple]
;;; forth-style byte-code interpreter (ALF-AlphaBetical Forth);
;;; to later get reincarnated as a prototype LISP byte-code compiler
;;; and optimized rule-based machine code generator, often
;;; generating better code than cc65, but still relying on it.
;;; 
;;; This incarnation has shredded it's depency on any other code,
;;; thus the BNF-interpreter is coded with small size in mind.
;;; It doesn't know about C at all, however the rules does.
;;; 
;;; The BNF-interpreter is currently about 1400 bytes. 
;;; It will be optimized for size (and speed) later.
;;; Currently, it's pretty minimally capable.
;;; 
;;; However, the goal is to provide an ON-DEVICE, 6502,
;;; compiler IDEA: editor, compiler, library, run all
;;; without needing to leave the program during development.
;;; 
;;; Here at the names, I though it had:
;;; - Mucc = Minimal Universal C-Compiler
;;; - CC02 = like a little brother of cc65
;;; - MeteoriC = as it's specificially targetting ORIC ATMOS
;;;   this is the currrent working name.
;;; 
;;; <TODO: insert grok ideas about what an MeteoriC-compiler
;;;  would be>
;;; 

;;; 
;;; MINIMAL SIZE COMPILER
;;; 
;;; The current size in bytes of the compiler is:
;;; 
;;;          TOTAL   BNF-interpr.   C-rules   BYTESIEVE   run it
;;;          ----    ------------   -------   ---------   ------
;;; FULL:    5866           1361      4505          303   2.458s
;;; NOBYTE:  4971           1361      3610          303   2.458s
;;; NOOPT:   3786           1361      2425          366   3.082s
;;; 
;;; The FULL compiler is just below 6KB, the big cost is
;;; byte rules optimizatation, this is experimental but
;;; could cut down on using byte/char variables instead of 
;;; ints, saving 50% code generated for those operations.
;;; 
;;; The next big size cost is OPTIMIZIZING GENERATING RULES,
;;; we talk more about it in the next section.
;;; 
;;; These are not required, but as can be seen in the 
;;; BYTESIEVE=1 benchmark, not having them, increase the
;;; compiled size by 66 bytes, 21%, and time with 25%!
;;; They basically, adds specific common pattern cases
;;; that can have highly specialized code. 
;;; 
;;; OPTIMIZING GENERATION RULES
;;; 
;;; MeteoriC isn't like most other compilers. It doesn't
;;; have an optimizer per se! Normal compilers do peep-hole
;;; optimizations, as well as complex analyzes of their parse
;;; trees. MC doesn't have any parse-tree, we've dispensed with 
;;; that. Instead the compiler is entirely rule-driven. You could
;;; say that it generates code by templates. This isn't unusual
;;; for simple compilers ala small-C, tinyC etc.
;;; 
;;; MeteoriC, instead, has added rules that are specific and
;;; can generate highly efficient, but very specialized, code.
;;; 
;;; As an example. Consider: a= 0;
;;; 
;;; Using the rule "%A=%D;" we generate generic:
;;; 
;;;    lda #0
;;;    ldx #0
;;; 
;;; But any decent 6502 asm programer would write:
;;; 
;;;    lda #0
;;;    tax
;;; 
;;; instead. So by adding an earlier rule "%A=0;"
;;; we get the same result.
;;; 
;;; These rules may seem a bit ad-hoc, but appear
;;; often to be sufficient to get similar effcient code
;;; as the best compilers, at least in simple cases.
;;; 
;;; Whole program optimization is where advanced
;;; optimizers can win big; it may analyze whole sections of
;;; the program; inline functions; simplify using constants etc;
;;; and particularly dead-code optimization.
;;; 
;;; This isn't easily done in MeteoriC. It also takes
;;; much time thus making compilation slow, so we won't go there.
;;; 
;;; Simpler big wins could be done by adding more optimization
;;; rules, adn possibly recognize what's in the AX (and Y) register.
;;; 
;;; It's not unusual to see code like "a=b+17; if (a==42) ...",
;;; where a variable is set, and then used in the next statement.
;;; In MeteoriC's case each statement generates code indepdendent
;;; of the preceding statement, similarly to small-C, tiny-C, etc.
;;; 



;;; 
;;; OPTIMIZATION RULE EXAMPLE
;;; 
;;; One example is "while(a<42)..."; first the '<' doesn't
;;; need to generate a true (!0) or false (0) value; second,
;;; we don't need to test for it; third, the loop test is
;;; hardcoded to use the compare flags, so that's also optimized.
;;; 
;;; A simple program like: 
;;; 
;;;       word main(){
;;;         while(a<42) ++a;
;;;       }
;;; 
;;; will without any optmization rules compile to 46 bytes.
;;; But, with OPTRULES it's 33 bytes. This could further
;;; be optimized with BYTERULES ("$a<42" "++$a;") giving
;;; 26 B. The actual loop is only 12 B (no + etc).
;;;
;;; Counting down, from 42 is even more efficient in
;;; an "DO-WHILE" loop (26 B OPTRULES, no opt: 41 B!),
;;; and finally BYTERULES opt giving 20 B!
;;; 
;;; NOTE: The BYTERULES is currently a hack, requiring 
;;;   variable usages to be prefixed by a '$' and for
;;;   do while to be written DO WHILE (uppercase!).
;;;   These limitations will be worked on.
;;; 
;;;   One thing at a time ;-)
;;; 
;;; The loop is only 5 B and this could be further optimized,
;;; potentially, for small-sized loops, with 3 bytes less.
;;; 
;;; However, at some point, the recepies gets too be too many
;;; and using this form of limited rules will easily be
;;; beaten by more traditional optimization methods that are
;;; more flexible.
;;; 
;;; But, I still like to see them run on an actual 6502 in
;;; limited memory (around 6 KB)!
;;; 



;;; 
;;; MINIMAL C-LANGUAGE SUBSET
;;; 
;;; - basically just one type: word (uint_16)
;;; - decimal numbers: 4711 42 0x2a 0052 '*'
;;; - char constants: 'x' ''' (lol) '\t' and '\n' '\\'
;;; - "string" constants and arrays (are just considered a constant number)
;;; 
;;; - word main() ... - no args
;;; - { ... }
;;; - + - *2 /2 >> << & | ^ == < ! (TODO: && || ? != > <= >=)
;;; - a= b+10;  // simple expressions, one operator
;;; - ++a; --a; // and in expressions
;;; - a+= 42;   // simple right-hand expressions (var/const)
;;; - a=b=c=42+3;
;;; - a OP= simple; // += -= /=2; *=2; >>= <<= |= &= ^= 
;;; 
;;; - return ...;
;;; - if () statement; [else statement;]
;;; - label:
;;; - goto label;
;;; - do ... while();
;;; - while() ...
;;; 
;;; - word fun() { ... } - function definitions
;;; - fun() goo() - function calls (no parameters)
;;; 
;;; - memory access peek, poke, deek, doke
;;; 
;;; - Standard library (inlined, see section below)
;;; 
;;; - putchar(c); getchar(); puts(); putz();
;;; - putu(42); puth(666); putz("foo"); puts("bar");
;;; 
;;; - printf("%u",v);
;;; - printf("%x",x);
;;; - printf("%s",s);
;;; 
;;;   (TODO: *compiled* printf - in progres, no big printf!)
;;; 

;;; Extras:
;;; - limited char support: *(char*)p=...  *(char)p  p[i] 
;;; - limited: char (uint_8) void support for optimization
;;; - &v *(char*)v
;;; - currently NO PRIRIOTIES of operators; strictly left-to-right
;;;   (Also, no support parantheses at the moment, just a temporary
;;;    variable...)
;;; 
;;;      // n=r*40;            // libmatch need to be enabled
;;;      n=r<<2+r<<3;          // LEFT-TO-RIGHT (incorrect C)
;;;      // n=(((r<<2)+r)<<3); // "compatible C"
;;;      //n := r<<2+r<<3;     // PASCALish?
;;;      //n = PIPE r SHR 2 PLUS r SHL 3; // stream pipe?

;;; 
;;; Limits:
;;; - only *unsigned* values
;;; - if supported ops/syntax should (mostly)
;;;   work the same on normal C-compiler
;;; - NO priorities on * / (OK, this deviates from C)
;;;   TODO: could force to write:
;;;       a+3<<24+3*2+r<<2;
;;;       ((((((a+3)<<2)+3)*2)+r)<<2)
;;; - mostly no error messages uneless get stuck
;;;   and can't complete compilation
;;; - "types" aren't enforced
;;; - long variable names
;;; - same for fucntions
;;; - NO parenthesis
;;; - NO generic * / % or (unless add library)
;;; 

;;; 
;;; Extentions:
;;; - 42=>x+7=>y;     forward assignement
;;; - 35.sqr          single arg function call
;;; - 3 + $ v         byte operator (acts only on A not AX
;;; 

;;; USER MANUAL
;;; 
;;; The program "lives" in the editor. It allows
;;; for fullscreen editing (currently: ORIC ATMOS).
;;; 
;;; Arrow keys for movement, backspace, delete (forward).

;;; Emacs commands are extras:
;;; line: ^Prev ^Next ^A=stArt ^End
;;; char: ^Back ^Forward ^Delete BackSpace
;;; 
;;; ^T - caps toggle (ORIC style, lol)
;;; 
;;; ESC - toggles between editing and command mode
;;; (ctrl functions available all the time through)
;;; 
;;;   ^Help summary (navigation, lang, symbols)
;;;   ^Compile buffer
;;;   ^Run program
;;; 
;;;  (^Write file)
;;;  (^Load screen from origional/undo all?)
;;; 


;;; 
;;; Experimental features:
;;; 
;;;   ^V info of compiler/program/libraries
;;;   ^Q disasm program (sensitive)
;;;  (^Garnish program (pretty print))
;;; 
;;;  (^X extend features, file stuff)
;;;  (^Y quit - only .sim variant)
;;;   
;;;  ESC help
;;; 
;;; Not yet: ^Search ^J ^Killine ^Machinecode(^Q)
;;; 

;;; 
;;; COMPILE ERRORS
;;; 
;;; Basically, it'll highlight how far it could parse,
;;; and from then the rest of that line is highlightd in
;;; red background color.
;;; 
;;; The error lies somewhere around there!
;;; 
;;; BNF-parsers are knowsn
;;; 

;;; 
;;; % ERRORS - compiler errors
;;; 
;;; If there is an error a newline '%' letter error-code
;;; is printed, this error code is most likely a compiler
;;; code/rule error. Please report! Screenshot and code
;;; that you're compiling.
;;; 


;;; 
;;; LIBRARY-LESS! (NO LIBRARY, NO BIOS)
;;; 
;;; To incure as little storage overhead as possible,
;;; the compiler can, on ORIC ATMOS using only
;;; the BASIC ROM dispense with overhead of the
;;; "fancy BIOS", that "corrects" some issues
;;; 
;;; The compiler maps some common simple ideoms to
;;; direct code:
;;; 
;;; INPUT & OUTPUT
;;; - putchar(' ')
;;; - putchar('\n')
;;; - putchar(X)               // \n doesn't work!
;;; - putz(S)                  // ONLY putz not puts
;;;   (no printing numbers unsigned/decimal/hex)
;;; 
;;; MEMORY STUFF
;;; - peek(A) -> byte
;;; - poke(A, byte)
;;; - deek(A) -> word          // ORICism!
;;; - doke(A, word)
;;; - memcpy(CONST, CONST, const)  // const<256 => 14 B
;;; - memcpy(X,X,X)            // inline    => 23 B
;;; 
;;; CTYPE! (minimal)
;;; - isdigit()
;;; - isalpha()
;;; - isspace()
;;; 
;;; STDLIB
;;; - malloc(X)                // gives pointer after code
;;; - free(X)                  // does nothing
;;; (these are like sbrk, just increase a pointer)
;;; NOTE: will most likely crash the IDE
;;;       (TODO:? use for stand alone code generated)
;;; 


;;; 
;;; STANDARD LIBRARIES
;;; 
;;;     #include <stdio.h>
;;; 
;;; Yeah, that's just IGNORED! Anything starting with #
;;; is ignored to newline!
;;; 
;;; For now, to enable/disable libraries a recompile
;;; maybe needed. For your "convenience" a nubmer
;;; of variants of .tap files are provided with
;;; common configuration:
;;; 
;;; TODO:
;;; - MeteoriC.tap      = all libraries included
;;; - MeteoriC-none.tap = no libraries (not even "bios")
;;; - MeteoriC-raw.tap  = full libraries not using ROM
;;; 
;;;
;;; There are 8 libraries relevant to ORIC/6502
;;; - bios      :  72 B - getchar putchar
;;; - misc      :  17 B - nl spc routines i.e. putchar(' ')
;;; - runtime   :  36 B - runtime routines (RECURSION)
;;; 
;;; - stdio.h   : 114 B - putu puth putz puts (putd)
;;;  (printf.h) :       - not yet, maybe as inline!
;;; - ctype.h   :  99 B - isdigit is...
;;; - stdlib.h  :  20 B - 
;;; - string.h  : 144 B - strlen strcpy...
;;; - libmath.h :  41 B - TODO: div/mod
;;; 


;;; 
;;; PRINTF SUPPORT - nah, not yet
;;; 
;;; However, these works!
;;; 
;;; printf("%u", X)              // == putu
;;; printf("%x", X)              // == puth
;;; printf("%s", X)              // == putz (no nl)
;;; fputs(stdout, X)             // == putz (no nl)
;;; 
;;; // if SIGNED support has been enabled
;;; printf("%d", X);             // == putd
;;; 


;;; 
;;; == stdio.h
;;; == printf.h
;;; == ctype.h
;;; == stdlib.h
;;; == string.h
;;; == libmath.h
;;; 


;;; OTHER LIBRRARIES FOR CONSIDERATION
;;; 
;;; - stddef.h  :       - nah
;;; - assert.h  :       - nah
;;; - limits.h  :       - nah (INT_MAX INT_MIN, ffs)
;;; - system.h  :       - nah (exec?)
;;; - unistd.h  :       - nah (file system stuff)


;;; - graphics.h: TODO: ORIC ATMOS optmized graphics

;;; 
;;; ORIC ATMOS API
;;; ==============
;;; Refer to the ORIC ATMOS MANUAL for parameters.
;;;
;;; GRAPHICS: x=0..239 y=0..199 c=0..2
;;;   hires()
;;;   text()
;;;   clrscr()
;;;   curset(x, y, c)
;;;   curmov(dx, dy, c)
;;;   draw(dx, dy, c)
;;;   circle(r, c)
;;;   point(x, y)
;;;   hchar(...)
;;;   fill(...) 
;;;   paper(0-7)
;;;   ink(0-7)
;;;   pattern(0-255)
;;;
;;; SOUND:
;;;   play(...)
;;;   music(...)
;;;   sound(...)
;;;   ping(), shoot(), zap(), explode(),
;;;   tick(), tock()
;;;   
;;; FILE:
;;;   ; cload(...) - TODO
;;;   ; csave(...) - TODO
;;;   cwrite(0..255)
;;;   cread()->0..255 - todo: erh, should be function
;;;   ; cwritehdr() - TODO
;;;   ; creadsync() - TODO
;;; 

;;; 
;;; Implementation Notes
;;; 
;;; 
;;; The BNF parser is implemented as a giant statemachine,
;;; i.e., a pushdown automata. The program stack is used
;;; as a data-stack, mixed with *some* subroutine calls.
;;; The stack grows as rules are parsed, and shrinks
;;; as they are rejected or resolved. This allows for
;;; a simple backtracking parser.
;;; 
;;; One needs to be careful as you can't use subroutine
;;; to modify the "stack".
;;; 
;;; This allows one to configure the compilation as a
;;; "background" task. Ie, it performs a piecemeal work
;;; and you can then go on to other tasks. A simple
;;; continutation (address) to be called at specified
;;; opportunity. Then, later, the compilation can be
;;; called again, until finished.
;;; 
;;; Care must be taken so that there are no interleaving
;;; program calls left on the stack when the compilation
;;; process continues, it'll go bad!
;;; 

;;; 
;;; PERFORMANCE
;;; 
;;; 6502 is famous for begin a "difficult" C-compiler
;;; target, or for that matter any high-level compilation
;;; to it. New compilers may show that this isn't 
;;; necessarily true: oscar64, KickC, llvm-mos, Tigger C,
;;; and even the abanded (?) gcc-6502, challanges this:
;;; 
;;;   "The C64 executes 442 dhrystone V2.2 iteration
;;;    per second, when compiled with Oscar64 and -O3
;;;    (which shows that the ancient dhrystone benchmark
;;;    is no match to an optimizing compiler)."
;;; 
;;; There are more generic compilers like sbcc, vbcc,
;;; and finally cc65. That latter upholds a gold-standard
;;; in compliance and reliabitily, but is "known" for
;;; slow code, and sometimes bloated. But it is very
;;; well-rounded. It heavily relies on jsr-calls to
;;; a relatively big library, trading smaller size
;;; for loss of speed.
;;; 
;;; MeteoriC isn't about to challange oscar64 in this
;;; aspects, instead it's all about interactivety ON
;;; the actual 6502 device and fast edit-compile-run
;;; experience - basically an IDE on 6502 with acceptable
;;; performance.
;;; 
;;; There aren't many compilers that run NATIVELY on
;;; 6502. Most generate a kind of byte-code.
;;; 
;;; Worth mentioning:
;;; 
;;; - Aztec C-compiler: also existed on Z80. The 6502
;;;   variant could cross compile and genereate byte-code
;;;   for a smaller VM that interpreted this. There was
;;;   also a compiler than generated direct machine code.
;;;   I think it gave rather HUGE binaries. Some variant
;;;   of the compiler may have run natively ON the
;;;   6502, Apple II for example.
;;; 
;;; - PLASMA: Not C. A new langauge+OS/environment/editor
;;;   and compiler that natively runs on 6502, however,
;;;   it also generate byte-code for an VM. It's mostly
;;;   targetted to APPLE II, but not limited to.
;;; 
;;; - http://mdfs.net/System/C/BBC/




;;; 
;;; This doesn't stop us at taking best practices,
;;; which include, but are not limited to:
;;; 
;;; a) Static call graph analysis to eliminate call stack
;;; = Fixed location for paramter passing
;;; + very performant
;;; + simple code
;;; - uses precious zero page locations
;;; - doesn't (directly) support recursion
;;; - might "step on the toes" on other functions/itself!
;;;   Example: foo(34, foo(72, 64)); // !
;;; % cc02: see next section on CALLING CONVENTIONS
;;; 
;;; b) Static integer range analysis to simplify 16-bit
;;;    operations to faster 8-bit operations.
;;; + almost halves machine code instructions!
;;; - complicated
;;; - easy make mistakes/compliance
;;; % cc02: can do some "switching" to byte-context
;;;         BUT best is if user specify byte/char vars
;;;         AND we have $v rules (=byte context)!
;;; 
;;; c) Conversion of indirect addressing to indexed
;;;    addressing when feasible.
;;; + indirection only possible using Y and zp pointers
;;; + faster
;;; - may need advanced analysis & partial evaluation
;;; - or at least constant folding
;;; % cc02: see what we can do
;;; %       1) constant folding
;;; %       2) use that address match %D (?)
;;; 
;;; d) Whole program compilation by including library
;;; + can optimize away specific code by "code inlining"
;;; - very complicated and easy to intruduce bugs
;;; - (need libraries as source code - slower compilation)
;;; % cc02: probably cannot do inlining of source
;;; %       but might do some constant folding
;;; %       AND have memcpy() inlined in some cases!
;;; %       AND isdigit(), islapha(), printf()
;;; 
;;; e) Ongoing improvements driven by the development
;;;    of new games, with a focus on improving the
;;;    compiler rather than writing inline assembler code.
;;;    - offical goal of oscar64.
;;; % cc02: well, active now...



;;; 
;;; CALLING CONVENTIONS
;;; 
;;; As this compiler is initially targeting ORIC ATMOS,
;;; we're gonno have some specifics, that can be
;;; generalized.
;;; 
;;; 1) ruleY/Z: ORIC parameter block "procedure" calls
;;;    using parameter block 0x02e0...
;;; 
;;; 2) OJSR: no parameter JSR addresses (clrscr/hires)
;;; 
;;; 3) FAST: calling using dedicated ZP addresses
;;;    for the function (may be overlapping other
;;;    functions if not conflicting)
;;; 
;;; 4) SAFAST: (safe fast) like 3), but usess
;;;    pha/txa/pha and copies the parameters inside
;;;    the function (combination 3)+5) )
;;; 
;;; 5) __recursive__: pha/txa/pha JSK_CALLING
;;;    In progress! working, now 4 parameters hardcoded
;;;    Enter: SWAPS register/arguments!
;;;    Exit:  restores registers
;;; 
;;; ...
;;; 
;;; 9) ruleX: cc65 __cdecl__ (not __fastcal__)
;;;    compatible with cc65, TODO: remove?
;;;    we don't want to depend on cc65
;;; 
;;; 
;;; TODO:
;;; - parameters (without stack)
;;; - recursion? (requires stack)
;;;   1) use program stack (no tailrec)
;;;   2) separate stack ops/MINIMAL
;;; 


;;; 
;;; OPTIONAL FEATURES
;;;
;;; - pointers (no type checking): *p= *p+1
;;; - I/O: getchar putc putu puth
;;; - else statement;
;;; - optimized: &0xff00 &0xff >>8 <<8
;;; - optimized: ++v; --v; += -= &= |= ^= >>=1; <<=1;
;;; - optimized: ... op const   ... op var
;;; 

;;; 
;;; How-to use
;;; 
;;; 1. The BNF is inline, rule 'P' is executed
;;; 2. The source is pointed to at addr "inp"
;;; 3. The code is generated at "out"

;;; Compile with
;;; 
;;;    ./rasm parse
;;; 
;;; gives a parse.tap in ORIC folder (symlink)

;;; VERSION
;;; - v0.1 void main() return
;;; - v0.2 putc etc...
;;; - v0.3 expr
;;; - v0.4 unlimited statements (TAILREC)
;;; - v0.5 IDEA/editor
;;; - v0.60 long name variables
;;; - v0.61 (slow) function calls
.define VERSION "v0.61a"
;;; - v0.62 TODO: local variables
;;; - v0.63 TODO: (opt) function calls (static params)
;;; - v0.64 TODO: array indexing

;;; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;; TODO: before release
;;; - save edit buffer in compile snapshot
;;;   (this allows hires to be entered)
;;;   (also allows background compilation)
;;; - copy compile snapshot back to buffer
;;; 
;;; - when running; save, run, restore
;;; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

;;; - v0.69 TODO: ORIC DEMO release



;;; - v0.7 TODO: load/write files
;;; - v0.8 TODO: resolve expreessions issue
;;; - v0.9 TODO: optional functions/"linker"/opt
;;; - v0.99999...
;;; - v1.0a TODO: alpha
;;; - v1.0b TODO: beta
;;; - v1.0rc TODO: release candidate
;;; - v1.0 TODO: release
;;; - v1.1
;;; - v1.2
;;; - v1.3
;;; - v1.4
;;; - v1.5
;;; - v1.6
;;; - v1.61
;;; - v1.618
;;; - v1.6180
;;; - v1.61803...
;;; - v1.618033988749




;;; STATS:


;;;                          asm rules
;;; MINIMAL   :  1016 bytes = (+ 771  383) inc LIB!
;;; NORMAL    :  1134 bytes = (+ 771  501)
;;; OLDBYTERULES :  1293 bytes = (+ 771  660)
;;; OPTRULES  :  1463 bytes = (+ 771 1090)
;;; LONGNAMES :  (- 1633 1529) = 104
;;;   (TODO: these are new LONGNAMES, not complete
;;;          yet, needs hooking up with %A/%V/%N?)
;;; 
;;; v= #x392 = 914 (- 914 882) = 32 (but I count 22B, hmm)
;;; v= #x372 = 882 
;;; v= #x34c = 844 bytes!
;;; v= #x363 = 867 (+52 %U TAILREC-fix)
;;; v= #x32f = 815 (+75 D d : ; # d - WHILE!) :-(
;;; v= #x2f6 = 758
;;; (- 844 27 46) = 771 (-errpos/-checkstack?) 
;;;     100 byte more? lol)
;;; 
;;;    193 bytes backtrack parse w rule
;;;    239 bytes codegen with []
;;;    349 bytes codegen <> and  (+25 +36 mul10 digits)
;;;    450 bytes codegen +> and vars! (+ 70 bytes)
;;;    424 bytes codegen : %V %A fix recurse
;;;         ( moved out bunch of stuff - "not counting" )
;;;    438 bytes skip spc (<= ' ') on input stream!
;;;        (really 404? ... )
;;;    487 bytes IF ! (no else) (+ 43B)
;;;    493 bytes ... (+ 29 B???) I think more cmp????
;;;    517 bytes highlite error in source! (+ 24 B)
;;;    550 bytes ...fixed bugs... (lost _var code...)
;;;    554 bytes =>a+3=>c
;;;    663 bytes ... ?
;;; 73 B overhead to subtract (+ 26 47)
;;;    642 no ERRPOS no CHECKSTACK
;;;    668  +26 == ERRPOS
;;;    715  +47 == CHECKSTACK
;;;    844  +... ??? wtf? lol
;;;    914  +32B 'c' small char constants
;;; 
;;;        for(i=0
;;;        PRIME opt
;;;        peek/poke/deek/doke
;;;        TIMING cycles
;;;        ^Garnish (prettyprint)
;;;        memory layout, move stuff around
;;;        info()
;;;        faster skipping
;;;        move out library
;;;        printasm
;;;        full-FOR
;;;        function 4-parameter parsing experiments
;;;         (RECURSIVE COPY ZPPASSING)
;;;        bios move out, opt
;;;        lib-stdio opt (merge with print.asm)
;;;        new editor
;;;   1230 BNF Interpreter as reported from info()
;;;   1309 e1a282f51de092345419268f03c96619366a5db2
;;;        (new editor, compiles)
;;;   1361 %b working (+ 52 B)
;;;   1361 fixed %b (+ 32 B) 
;;;   1361 OPTRULES

;;;   1529 VARS binding setup a152c247a511d5112976b32ee02ac6406e649d78
;;; 
;;;   1529 better if
;;;        VARS

;;;   1587 memset
;;; 
;;;   1529 before long vars
;;;   1633 long vars finally (just define + )

;;;   1573 - removing _findvar (not used)
;;;          NOP problem, lol
;;;   .... (VARS: + (- 1573 1361) = 212 B?
;;;        (+ 29 97 8 7 93) = 234 
;;;       ; _newarr _newvar GEN/SKIP %I ctype (needed ctype always?)
;;; 
;;; not counting: putu, mul10, end: print out
;;; 
;;; C parse() == parse.lst (- #x715 #x463) = 690




;;; C-Rules: 469 B (- 593 56 68), LOL- long time ago!
;;; 
;;;   383 bytes = MINIMAL   (rules + library)
;;;   501 bytes = NORMAL
;;;   660 bytes = OLDBYTERULES (+ 159 B)
;;;   821 bytes = OPTRULES  (+ 320 B)
;;; 
;;; 
;;; 
;;;    71 bytes - voidmain(){return4711;}
;;;   112 bytes - ...return 8421*2; /2, +, -
;;;   124 bytes - ...return e+12305;
;;;   128 bytes -           1+2+3+4+5
;;;   262 bytes - +-&|^ %V %D == ... 
;;;   364 bytes - int,table,recurse,a=...; ...=>a; statements
;;;   379 bytes - IF(E)S;   (+ 17B)
;;;   392 bytes - &a
;;;   425 bytes -  =>a+3=>c; and function calls
;;;   525 bytes - &0xff00 &0xff >>8 <<8 (+ 44B) >>v <<v
;;;   593 bytes - putu puth putc getchar +68B TOOD: rem!
;;;   627 bytes - FUNS (=+21 partial) and ELSE!(=+13 B)
;;;   821 bytes - ++ -- += -= &= |= ^= >>=1 <<=1
;;;               and changed int=>word char=>byte
;;;   521 bytes
;;;   597 bytes FUNS: more %F and %f code
;;;   642 bytes +R* - not working yet
;;;   676 bytes plain rules (!OPTRULES)
;;;   715  +47 == CHECKSTACK
;;;   886 bytes ...
;;; 
;;;  1112 bytes rules? OPTRULES
;;;  1181 bytes DO...WHILE/WHILE... (+ 69 B)
;;;  1393 bytes - OPT: << >> <<= >>=
;;;  1481 bytes FUNCTIONS/TAILREC/FUNCDEF (+ 300 B)
;;;  1544 bytes FUNCTIONS+POINTERS (+ 63 B)
;;;  1582 bytes various opts for MUL (+ 38 B)
;;; 
;;;  3026 bytes BYTERULES (opt)
;;;  3434 bytes ORIC ATMOS API (+ 408 B)
;;; 
;;;  4710 bytes !!!
;;; (

;;; w= #x62e 1582

;;; TODO: not really rules...
;;;    56 B is table ruleA-ruleZ- could remove empty
;;;    68 B library putu/puth/putc/getchar
;;;         LONGNAMES: move to init data in env! "externals"
;;; 


;;; 
;;; BNF DEFINITION
;;; ==============
;;; 
;;; The BNF is very simplified and is interpreted
;;; using backtracking. It may be ambigious but first
;;; matching result/alternative is accepted.
;;; (Can this replace priorities?)
;;; 
;;; In a BNF-rule:
;;; - Most ASCII chars are matched literally, except
;;;   '%' '|' - they need to be quoted
;;; - ' ' - SPACE (or any char<=' ') cannot be matched!
;;;   because tey are removed from input parsed!
;;; - 'R'+128 - A letter with HI-BIT set is a reference
;;;   to another rule that is matched by recursion (const _E)
;;; - '|' Rules can have alternatives: E= aa | a | b that are
;;;   tried in sequence, if one fails, the next one after
;;;   '|' is tried, basically backtracking.
;;; - NO SUBRULES "(foo|bar)"
;;; - Put literal/longer matches first in rule alternatives.
;;;   input: "foobar"    ie:   R ::= foobar | foo
;;; - Right-recursion might work, but it's limited by the
;;;   6502 hardware stack (~ 256/6) ~42 deep/recursion
;;; - TAILREC constant '*"+128 jumps to match from beginning
;;;   of the same rule. This replaces KlEENE operators *+?[].
;;; 
;;; 
;;;      ' 'ABCDEFGHIJKLMNOPQRSTUVWXYZ {!=   <32
;;; Free:   ABC EFGH JKLM OPQR T  WXYZ
;;; Used:' 'A  D    I  L N   RS UV     {!=   -31
;;;          b d              s
;;; 
;;; CONSTANTS
;;; 
;;; - %D - tos= NUMBER; parses various constants
;;;        4711 - number
;;;        'c'  - char constant
;;; - %d - tos= number; only accept if <256!
;;; 
;;; - %S - parses string till " copying to code!
;;;        NOTE: you need to write >"%S<
;;;        "...\n\"..." - rest of string is matched
;;;        \0 \n \t is recognized, and \ANYCHAR
;;;     BUG: string cannot start with " " spaces, lol
;;; 
;;;        Returns:
;;;          gos= address of string
;;;          dos= count bytes of string (including \0)
;;;
;;; - %s - like %S but parse only, doesn't copy the string
;;; 
;;; 
;;; 
;;; TEST CONDITIONS ("asserts")
;;; 
;;; - %b - "word boundary test" (actually just test next char
;;;        to not be isident) for "1%b" so not match "12"
;;; 
;;; - "%=abc",$80
;;;      - lookahead FAIL if next input char is NO [abc]
;;; - "%!abc",$80
;;;      - lookaread FAIL if next ISs one of [abc]
;;; 
;;; - IMMEDIATE addr (ends with _fail or _next)
;;; 
;;; 
;;; 
;;; NAMES (variables, functions, labels)
;;; 
;;; - %I - read ident (really %N? but for longname)
;;;        (push (nameaddr/word, namelength/byte) on stack!)
;;; - %V - tos= address; match "Variable" name, pos= metaaddr
;;;        pos[0] == lo-addr of var
;;;        pos[1] == hi-addr of var
;;;        pos[2] == 'w' word 'W' - word* 'w'+128= `word[]`
;;;                  'c' char 'C' - char* 'c'+128= `char[]`
;;;        -- the following are optional --
;;;        pos[3] optional == lo-sizeof
;;;        pos[4] optional == hi-sizeof
;;;        -- arrays and pointer++ may need this
;;;        pos[5] optional == lo-element sizeof (array)
;;;        -- array indexing optimizations if < 255?
;;;        pos[6] optional == lo-items
;;;        pos[7] optional == hi-items

;;;        
;;; - %N - define NEW name (use: %I%N)
;;;
;;; - %* - dereference tos { tos= *(int*)tos; } - old %U?
;;; 
;;; 
;;; (TODO: might be broken? TODO: remove this thing)
;;;        (doesn't nest anyway needed for a=b=c;)
;;; - %A - dos= tos= address; address of named
;;;        variable (use for assignment)
;;; 

;;; 
;;; IMMEDATE (run code inline)
;;; 
;;; 
;;;   IMMEDIATE addr
;;; 
;;; - "%L" == "%" jmp dostuff == .byte "%L<>"
;;;        This jumps to immmediate code, typically
;;;        to set things up or to test conditions,
;;;        like "disallowlocal";
;;; 
;;;        to exit suceessfuly
;;;              jmp _next
;;; 
;;;        and if the parsing rule should fail
;;;              jmp _fail
;;; 
;;;   JSRIMMEDIATE addr
;;; 
;;; - "% " == "%" jsr dostuff == .byte "% <>" (jsr=' ')
;;;        This calls immmediate code, typically
;;;        to make action/sideeffect.
;;; 
;;;        Return with RTS
;;; 
;;;      NOTE: Do not call _next or _fail (use IMMEDIATE)
;;; 
;;; 
;;; TODO: remove - DON'T USE!!!! UNSAFE
;;; - %{ - immediate code, that runs NOW during parsing
;;;        This is used to do one-offs, like test that
;;;        last %D matched a byte-value (X=0), if not _fail.
;;; 
;;;        NOTE: can't RTS, must use IMM_RET ("jsr immret")
;;;        FAIL: it's ok to call "jsr _fail" !
;;; 
;;; 
;;; 
;;; CONTROL FLOW
;;;
;;; TODO: bug? if last byte 0 get ENV stuff messed up
;;; 
;;; - %len BINARYDATA (skipper!)
;;;        len is 7bits < ' '(32), hbit ignored
;;;        tos= address after len (TODO: include?)
;;;        TODO: mabye set dos too, like %A?
;;; 
;;;        pos= base address of BINARYDATA
;;; 
;;;        This is used to keep environment of
;;;        global/local variable bindings!
;;;        Slow linear, but very little code!
;;; 
;;;        
;;;        
;;; - %R addr - goto this rule addr, jump nil-willy!


;;; 
;;; TODO:?
;;; - %n - define NEW LOCAL
;;; 
;;; - %r - the branch can be relative
;;; - %P - match iff word* pointer (++ adds 2, char* add 1)
;;;    ?????


;;; 
;;; Don't use: usafe - quoting problem | and \0 ...;
;; 
;;; %{ machien code ... IMM_RET (or IMM_FAIL)


;;; Use:
;;;
;;; IMMEDIATE    addr   (replaces unsafe %{ ...)
;;; JSRIMMEDIATE addr   (replaces unsafe %{ ...)
;;; 
;;; TODO: rename to "CHECK disallowlocal" ?
.macro IMMEDIATE addr
      .byte "%"
        jmp addr
.endmacro

;;; TODO: rename to "ACTION dostuff" ?
.macro JSRIMMEDIATE addr
      .byte "%"
        jsr addr
.endmacro

;;; 
;;; Code can be executed inline *while* parsing.
;;; It's prefixed like this
;;; 
;;; RuleX: ;; match foobar, prints % after match foo
;;;        .byte "foo"
;;;      .byte "%{"
;;;        putc '%'                ; print debug info!
;;;or      IMM_FAIL                ; HOW TO FAIL

;;; NOTE: IMM_FAIL will skip to next '|'
;;;       must not find any '|' or \0
;;;       in the remaining code - OK'its a HACK!

;;;        IMM_RET                 ; HOW TO RETURN!

;;; NOTE: IMM_RET must be the last of the CODE!
;;;       as it tells the interpreter where BNF continuse

;;;      .byte "["
;;;        .byte "bar"
;;;        .byte 0                 ;
;;; 
;;; This will parse foo, then print %, then parse bar


;;; 
;;; [ GENERATIVE ]
;;; 
;;; The generative part of the rule may be invoked
;;; several times. Each one will generate code from
;;; a template.
;;; 
;;; NOTE: There is no backtradking/reset of code
;;;       generated, so use with care!
;;;       Once generated, it's there!
;;;       Typically just generate at end or when sure.
;;; 
;;; Inside the generative brackets normal *relative*
;;; 6502 asm is assumed to be used.
;;; 
;;; There are directives used that doesn't match
;;; any 6502 byte-codes, these come from this set
;;; of printable bytecodes.
;;;
;;;     missed: $(,08 KLORSTWZ`hloswz{| DEL

;;;      "#$'+/2347:;<?BCDGKORSTWZ[\_bcdgkortwz{|
;;; free  #$  /2347       GKORSTWZ \_bc gkortwz
;;; 
;;;             DON'T USE THE FOLOWING
;;;                | = used to skip to next |-or-rule
;;;                [ = start of block, if one left out...
;;;                ] = is actually EOR $nnnn,$x
;;;                > = is actually ROL $nnnn,x
;;;                < = used previously, but cannot >
;;; 
;;; 
;;; HI' '"#$'(+,/023478:;<?@BCDGHKLOPRSTWXZ[\_`bcdghkloprstwxz{| DEL

;;;  ( 168 freee? '8'

;;; GROK: free: (hex)
;;; 02,03, 03,83, 07,87, 08,88, 12,92, 13,93, 0f,bf
;;; 17,97, ESC: 1b,9b, 9c, 1f,9f 9e
;;;    "#'+/237;?BCGKORSW[_ bcgkorsw{ DEL
;;; hi: #'+/237;? CGKORSW[_  cgkorsw{ DEL


;;; CONFLICTS! (not used much but... TODO: fix?!)
;;; > is ROL $nnnn,x   62(dec)
;;; ] is EOR $nnnn,x   93(dec)




;;; 
;;; NOTE: not, there is *REAL* quoting problem
;;;       if any (data) byte matches | [ ]
;;; NOTE: JSR 0x4711 is autoquoted (thus "safe")
;;;       (unless there is a 0x20, or ' ' constant!)
;;; TODO: do the same for JMP BNE, JPI etc?
;;; 
;;; SUBSTITUTIONS
;;; 
;;;   C   - $20 (JSR) non-quoted value (can't JSR "<>")
;;;   ]   - ends the generation
;;;   <   - use LOVAL == lo byte of last %D number matched
;;;   >   - use HIVAL hi byte         - " -
;;;   <>  - little endian 2 bytes of %D     use VAL0 or VAR0
;;;   +>  -       - " -           of %D+1   use VAL1 or VAR1
;;;         (actually + and next byte will be replaced)
;;;         (can't do single '+')
;;;  
;;; DIRECTIVES (stripped from output)
;;;            (NOTE: relative jmps - don't know!)
;;; 
;;;   {{  - PUSHLOC (push and AUTO patch at accept rule)
;;;   #   - push tos (on to stack) (don't forget to pop!)
;;;   :   - push loc (onto stack, as backpatch! - careful)
;;;   ;   - pop loc (from stack) to %D/%A?? (tos)
;;;   ?n  - PICK n from stack (last is 0)
;;;   B   - BRACH here (patch jmp at TOS) (use ?n first)
;;; 
;;; TODO: remove - not used!
;;;   D   - set tos from dos
;;;   d   - set dos from tos
;;; 
;;; TODO: 'z' to swap two locs? replaces 'D and 'd'
;;; TODO: make a "pickN' rule instead! '#3' '?3'
;;; 
;;; maybe not needed
;;;   \n   - TODO: drop pos n from stack (overwrite)

;;; NOTE: if any constant being used, such as
;;;       address of JMP (library?) or a
;;;       variable/#constant matches any of these
;;;       characters.
;;; 
;;;       Hey it's a hack!
;;; 
;;; TODO: detect this and give assert error?
;;;       alt: parameterize any constants?



;;; TODO: this is the PLAN... MASTER PLAN?
;;; 
;;; TODO: experiment with
;;; - https://www.cc65.org/faq.php#ORG
;;; - http://forum.6502.org/viewtopic.php?f=2&t=4247
;;; - https://retrocomputing.stackexchange.com/questions/13188/putting-code-into-two-different-memory-areas-with-cc65-ca65
;;; 
;;; I think, one can just do .org (to after C-code)
;;; then memmove it to where it should be!
;;; 
;;; TODO: read about the linker and what it does
;;; 
;;; 
;;; (ORIC) MEMORY LAYOUT - COMILER/RUNTIME/OUTPUT
;;; ============================================
;;; _tap:       ---------jmp _output------------
;;;             bios        bios       bios
;;;             lib         lib        lib
;;; _output     compiler    gen prog   gen prog
;;;             input       ...        ...
;;;             ...         *_out      END
;;;             ...         ...        ...
;;;             END
;;;             ---------cc65-heap--   MYHEAP
;;;             ---------cc65-stack-   MYAXSTACK
;;; _compiler               input
;;;                         compiler
;;;                         END
;;; FIXED:
;;; ------
;;; _hcharset:
;;; _hires:
;;; 
;;; _charset:
;;; _textscreen:
;;; _hitext:



;;; ========================================
;;;              O P T I O N S 
;;; config options

;;; Model:
;;;   PICO - enable to get compiler+nolibrary
;;;   NANO - enable to 
;;;   TINY - enable to only get compiler+ide+library
;;;   -    - default: compiler+ide+library+help
;;;   DEMO - compiler+ide+full library+help+examples

;PICO=1
;NANO=1
;TINY=1
;
DEMO=1


.ifdef PICO

;        NOBIOS=1       ; needed by IDE save  72 B
;        NOLIBRARY=1    ; ? needed by compiler - 592 B
;        STDIO=1        ; ? needed by compiler - (100?)

;        NODISASM=1     ; 1580 B
;        NOPRETTYPRINT  ;  809 B
;        NOINFO=1       ; 1792 B

;;; Library used by IDE, 
;;; TODO: remove IDE!
;        NOIDE=1        ; 3580 B

        ;; POTENTIALL ++++
        ;; (+ 72 592 1580 809 1792 3580) = 8425 extra!

        ;; should be... lol
        ;; (- 64 8   1  16  2    2      8) = 27
        ;;   RAM TAP ZP ROM CHAR CSTACK HIRES


        OUTPUTSIZE=12*1024

.elseif .def(NANO)

        ;; BIOS
        ;; LIBRARY
;;; TODO:
        NOHELP=1                ; save 1 KB?

        OUTPUTSIZE=12*1024

.elseif .def(TINY)

        ;; BIOS
        ;; LIBRARY

        OUTPUTSIZE=12*1024

.elseif .def(DEMO)

        ;; BIOS
        ;; LIBRARY
        INTRO=1                 ; + 1   KB
        TUTORIAL=1              ; + 1   KB
        EXAMPLEFILES=1          ; + 4.5 KB

.ifndef __ATMOS__

        ;; --- SIM65 --- 31K binary+heap!

        ; (+ (* 31 1024) 512 256 32 16 2 1)
;         OUTPUTSIZE=31*1024   ... 32563 bytes!
;         OUTPUTSIZE= 31*1024+512+256+32+16+2+1

        OUTPUTSIZE=31*1024

.else
        ;; --- ATMOS --- 7K in demo...

        ;; Biggest on ORIC ATMOS
        ;; (- 64 30  1  16  2    2      8) = 5!!!
        ;;   RAM tap ZP ROM CHAR CSTACK HIRES
        OUTPUTSIZE=5*1024

;        OUTPUTSIZE=1*1024
.endif ; !__ATMOS__


.else ; DEFAULT

;;; TODO: fix... why fails? (32K limit somewhere?)
;;; 
;;; fails at 352 lines Input/lps-100.c
;;; (* 352 6) = 2112 should fit

.ifndef __ATMOS__
        
        ;; --- SIM65 ---

        OUTPUTSIZE=37*1024

.else

        ;; --- ATMOS ---

        OUTPUTSIZE=12*1024

.endif ; !__ATMOS__


.endif ; default target


;;; Allow inline (fixed-constant) ASM code!
;;; (adds 1637 bytes!)
;ASM=1


.ifndef OUTPUTSIZE
        ;; ++s; ===  6 B  (/ 4096 6) = 682x

;;; the bigger OUTPUTSIZE => the smaller heap
;;; to get more space remove EXAMPLEFILES!


;;; current binary 24708
;;; (- 37631 24708 2048   2048) = 8827 HEAP!
;;;          .tap  OUTPUT C-stack

;;; smallest binary/mem:
;;; (- 24708 3467   1500   4553  976  2048) = 12164
;;;    .tap  c-code "text" input help C-stack)

;;; (- 37631 12164) = 25467 == OUTPUT+HEAP

        OUTPUTSIZE=8*1000+50
.endif

;;; enable stack checking at each _next
;;; (save some bytes by turn off)

;;; TODO: if disabled maybe something wrong? - parse err! lol
;;; checking every _next gives 30% overhead? lol
;;; TODO: find better location? enterrule?
;
CHECKSTACK=1

;;; Zeropage vars should save many bytes!
;
;;; TODO: clear out? it's "default" now, requirement!
ZPVARS=1

;;; How many arguments? (each take 2 bytes in zeropage)
;;; used passing arguments of *recursive*
;;; (including locals!)
NPARAMS=8

;;; How much space for STatic parameters used directly
;;; by NON-OVERLAPPING functions. (not calling eachother)
;;; Requires, more or less, a call-tree analysis, and
;;; NON-RECURSIVE functions.

;;; TODO: BIGBIGBIGBIGBIGBIGBIG
NSTARGS=8




.export _asmstart
_asmstart:      

;;; This is like a "continuation"
;;; Treat it like a what to do next!
;;; This is because we "null" the stack in:
;;; - compilation
;;; - run/error
;;; 
;;; These routines will call this function
;;; 
;;; TODO: make it one level of indirection?

.import _processnextarg

.import _iasmstart, _iasm, _dasm, _dasmcc
.export _endfirstpage
.export _output, _out
.export _rules



.include "atmos-constants.asm"


;;; TODO: why is this not accepted?
;.define SCREENRC(r,c)   SCREEN+40*r+c-2

;;; TODO: not good idea?
;;; TODO: not working, parse error?
;COMPILESCREEN=1

;;; enable ORIC ATMOS raw TTY replacement
;;; 
;;; TTY=1



;;; TIMe events: compile/run
;;; disables interrupts and counts cycles!
;;; relatively accurately...
;;; It also seems to make the compiler NOT crash
;;; when run repeadetly... HMMM? "resetting" stack
;;; not good when interrupts running????
;;; (just enables interrupt before getchar)
;;; 
;;; TODO: BUG: i think there is some zeropage overlap
;;;   with oric timer and vars... lol
;TIM=1

;TTY=1


.macro SKIPONE
        .byte $24               ; BITzp 2 B
.endmacro

.macro SKIPTWO
        .byte $2c               ; BITabs 3 B
.endmacro

.macro FUNC name
  .export .ident(.string(name))
  .ident(.string(name)):
.endmacro


;;; ----------------------------------------
;;;      L I B R A R Y   C O N F I G 



;;; NOBIOS: will generate code that doesn't 
;;; rely on extra code for getchar/putchar
;;; NOTE: \n will not do as expected in
;;;   a string "foo\nbar\n", but putchar('\n') will!
;;; 
;NOBIOS=1


;;; NOLIBRARY: (minimize library)
;;; 
;;; still includes:
;;;     BIOS 26 + runtime 82 + misc 17
;;;     == (+ 26 82 17) = 125... lol
;;; 
;;; TODO: make sure can compile without "BIOS"
;;; TODO: make sure no need misc
;;; TODO: RUNTIME make option - no parameters fun-calls?
;;;   or just NORECURSIVE!!!
;;;   (NO runtime overhead if compile w static params!)
;;; 
;NOLIBRARY=1



;;; BYTESIEVE needs printf/putu

;;; TODO: we need a dynamic way to add a single
;;;       function dynamically during compilation!
;;;       (asumes rel jmp only)
;STDIO=1

;;; If STDLIB isn't included malloc(),free() will
;;; most likely clobber the IDE, so after ^Run
;;; it'll hang, or so...
;;; 
;;; TODO: how to work together?
;STDLIB=1


;;; ----------------------------------------
;;;                  BIOS

;;; -------- BIOS
;;; 17 - getchar (save XY)
;;; 19 - nl plaputchar putchar (save AXY, \n)
;;;  4 - rawputc
;;;(14)- 3 clrscr, 3 forward, 3 bs, 5 spc
;;; ========
;;; (+ 17 19 4 14) = 54 ( 56 according to info() ? )



;;; enable to invers on hibit
;TTY_HIBIT=1


FUNC _biosstart
.ifndef NOBIOS

  .ifdef __ATMOS__
    ;.include "bios-raw-atmos.asm"
    .include "bios-atmos-rom.asm"
  .else ; SIM
    .include "bios-sim.asm"
  .endif ; __ATMOS__ | SIM


  .ifndef putcraw
     putcraw= putchar
  .endif


.endif ; !NOBIOS
FUNC _biosend


;;; ========================================
;;;          D       A       T       A

.export zero,tos,dos,pos,gos,vos
.export savea,savex,savey
.export mode

.export __ZPCOMPILER__
.zeropage
__ZPCOMPILER__:
.code


.zeropage

;;; Data abouit current function being built
;;; number of parameters (0..n), 255==not valid
nparam: .res 1
curF:   .res 2                  ; points to "name%b..."
params: .res NPARAMS*2          ; "registers"
endparams:                      ; used for test

compilestatus:  .res 1          ; 

.code


;;; TODO:
.export _ruleVARS

.zeropage
;;; Vector pointing to beginning of current "ENVIRONMENT"
;;; (address bindings encoded as matching rules)
_ruleVARS:        .res 2
.code




.zeropage
;;; reserved, lol
;;; TODO make sure it at address zero
;;;   to be used to detect write using null pointer
zero:   .res 2  

;;; compilation : tos = %D (%V)
;;; running code: tos, dos temporary save/deref
tos:    .res 2
dos:    .res 2
;;; used as default for printing strings (putz)
pos:    .res 2
;;; used by FOLD, maybe memcpy ???
gos:    .res 2

;;; used by variable allocation in zeropage (grow down)
vos:    .res 2

;;; temporaries for saved register
savea:  .res 1
savex:  .res 1
savey:  .res 1


;;; IDE mode: V=64=init Mi=$ff=command Pl=0=editing=
;;;   (_init sets it to 64)
.export _mode
_mode:  
mode:  .res 1

;;; STATITISTICS
;;; 
;;; lines (number of '\n' seen
;;; (backtracking up may give few more))
nlines:   .res 2
naccepts: .res 2
nrules:   .res 2

.code




;;; ========================================
;;; ---------------- LIBRARY ---------------

;;; 
;;; Current byte count:
;;; 
;;; Bytes #functions
;;; ----- ---- 
;;; [  23(?) ]    BIOS: getchar putchar -- NOT LIBRARY!
;;;    17         misc: nl/newline spc bs clrscr...
;;;   (69)        Runtime: all=RECURSION
;;;    96    7    #include <stdio.h>
;;;  ((19))  1    (_print u/h/z/s OPT: _iprintz)
;;;    99   10    #include <ctype.h> isXXXX
;;;   144    6    #include <string.h> str len/cpy/...
;;;    20    2    #include <stdlib.h> rand srand
;;; ======
;;;   376 (+ 69)    (+ 17 96 99 144 20)   69 19
;;; =====
;;;   445
;;; +  23 bios



;;; 1284707
;;; 1150630 (/ 1284707 1150630.0) == 11.6% overhead
;;; 11.6% overhead parsing STRING CTYPE

.ifndef NOLIBRARY

;;; #include <string.h> // constants and functions
STRING=1

;;; #include <ctype.h> // isXXX()
CTYPE=1

;;; Runtime
;;; TODO: make it count, reduce runtime if not used!
;;;   (only need "restore")
RECURSION=1

;;; stdlib
STDLIB=1

;;; stdio
STDIO=1

;;; 
MATH=1

.endif ; NOLIBRARY




FUNC _librarystart

.include "tty-helpers.asm"      ; nl spc bs PUTC putc



FUNC _runtimestart

;;; TODO: IRQ put here!

;;; TODO: delete file?
;.include "lib-runtime-recursion.asm"

;;; Y is 2*params + 16*2*locals
;;; AX is pushed as next parameter
;;; (+ 2 12 12 20  9 3 +1) = 59 B   ; +14 B locals
;;; (+ 3 22 21 13 16 5) = 80 c + 27c * bytes
subparamY:
        ;; 2 B  3c
        sta savea

        ;; remove caller from stack, store in tos
        ;; 12 B+3 22c + 5c = 27c
        ;; (1B less  5c faster than save and pha/pha/RTS!)
        pla
        sta tos
        pla
        sta tos+1

        inc tos
        bne :+
        inc tos+1
:       

        ;; save last param (now YX) in register
        ;; 12 B  21c
        ;; push register old value, replace with saveaX
        ;; - lo
        lda params,y
        pha
        lda savea
        sta params,y
        ;; - hi
        lda params+1,y
        pha
        stx params+1,y

.ifdef LOCALS
;PUTC 'L'
        ;; create space for local variables
        ;; (no more than 15 parameters...)
        ;; 14 B  8c+ 13*bytes
        tya
:       
        ;; < 16 done
        cmp #16
        bcc :+
        sbc #14                 ; -16 + 2 !
        pha
        jmp :-
:       
        tay
.endif

        ;; TODO: not swap locals, just "store"
        ;;   generlize last param?

        ;; swap first arg & last reg
        ;; 20 B  13c + 27c / byte swap
        sty savey
;;; TODO: to handle Y=0 (one arg)
;;;    crashes??? why?
;        beq @nope

        ;; save to keep
        tsx
        stx savex
        ;; skip last arg (already swapped)
        pla
        pla
@loop:       
        ;; 13 B  27c / byte swapped
        ;; (TODO: SWAP macro +8 B 19c / byte)
        ldx params-1,y
        pla
        sta params-1,y
        txa
        pha
        ;; step up
        pla
        dey
        bne @loop
        ldx savex
        txs
@nope:

        ;; "inject" a restore1 call
        ;; 9 B  16c
        ;; push how many bytes to restore:
        ;;        2 * (nparam+nlocals)
        lda savey
        pha
        ;; push call to restore
        lda #>(restore-1)
        pha
        lda #<(restore-1)
        pha

        ;; "return" to caller (and actual FUNCTION)
        ;; 3 B  5c
        jmp (tos)


;;; TODO: do this optimization

;;; restore, in an optimized program, will onlyh
;;; get called for recursive functions,
;;; for "complicated", it only becomes a problem
;;; once we "return", so we could put a sentinel 
;;; on the stack the first thing (if a compiler-
;;; flag is set) to call to the extended version here
;;; instead. It only needs to check that the sentinel
;;; hasn't been overwritten. This isn't fool-proof
;;; but depending on the value (?) may in simple
;;; terms give a 254/255 chance to detect such an
;;; issue. I'd suggest to use 'S'+128, lol
;;; 
;;; 
SENTINEL='S'+128

restoreerror:   
        lda #'S'
runtimeerror:
        PUTC '%'
        jsr putchar
        jsr nl

;;; TODO: need to add to runtime!
        jmp _NMI_catcher
        

restorecheckstack:      
        ldy $01ff
        cpy #SENTINEL
        bne restoreerror

;;; Restores PLA byte registers
;;; preserves AX, trashes Y

;;; 15 B  16+6 +   13c x bytes
restore:
        sta savea

        pla
        ;; one more argument to restore (than swap)
        tay
        iny
        iny
:       
        ;; 13c / byte
        pla
        sta params-1,y
        dey
        bne :-

        lda savea
        rts

;;; Specialized
;;; Restore 1 register
;;; TODO: maybe remove when add locals?
;;;  9 B  18c+6=24c
restore1:
        tay

        pla
        sta params+1
        pla
        sta params

        tya
        rts


;;; TODO: remove, keep for bench refs?

;;; SUBPARAM2
;;; (- (- 2862601 2849494) (- 3406223 3393485) ) = 369
;;;   (/ 369 9.0) = 41.0 c slower per call
;;; (+ 12 27) = 39c ... hmmm, alignment?
;

;;; (+ 1 12 10 21 6 3)  = 53 B
;;; saved B: (+ 38 -3) =      - 35 B saved
;;; (+ 2 22 18 32 10 5) = 89c
;;; extra C: (+ 22 5)  =      + 27c

;;;        REMOVED ^


FUNC _runtimeend




FUNC _minimallibrarystart
 
;;; zoropage variant? together with few general rules
;;; but really small library...
;;; 
;;; (- #xdad #xd4d) = 96 B


.ifdef MINIMAL
;;; These are totally untested, just written to paly
;;; with...

;;; TODO: use a preexisting VM .include
;;;   preferable one with all stack
_SAVE:  
        sta tos
        stx tos
        rts

_AND: 
        and tos
        tay
        txa
        and tos+1
        tax
        tya
        rts
_OR:    
        ora tos
        tay
        txa
        ora tos+1
        tax
        tya
        rts
_EOR:   
        eor tos
        tay
        txa
        eor tos+1
        tax
        tya
        rts
_PLUS:  
        clc
        adc tos
        tay
        txa
        adc tos+1
        tax
        tya
        rts
_MINUS: 
        sec
        eor #$ff
        adc tos
        tay
        txa
        eor #$ff
        adc tos+1
        tax
        tya
        rts
_EQ:    
        ldy #0
        cmp tos
        bne false
        cpx tos+1
true:  
        dey
false: 
        tya
        tax
        rts
_LT:    
        ldy #0
        cpx tos+1
        bcc true
        bne false
        cmp tos
        bcc true
        bcs false
_SHL:   
        asl
        tay
        txa
        rol
        tax
        tya
        rts
_SHR:   
        tay
        txa
        lsr
        tax
        tya
        ror
        rts


.endif ; MINIMAL
FUNC _minimallibraryend


;;; inline str after jsr; +19 bytes
;;; saves 7 B at each puts/z("...");
;;; is it worth it?
;
INLINEPRINTZ=1  

FUNC _stdiostart
  .ifdef STDIO
    .include "lib-stdio.asm"
  .endif ; STDIO
FUNC _stdioend

;;; TODO
;include "lib-printf.asm"       ; not working
;;; TODO: looks at - https://github.com/charlesnicholson/nanoprintf

FUNC _ctypestart
  .ifdef CTYPE
    .include "lib-ctype.asm"
  .endif ; CTYPE
FUNC _ctypeend


FUNC _stdlibstart
  .ifdef STDLIB
    .include "lib-stdlib.asm"
  .endif ; STDLIB

  .import _malloc

FUNC _xmalloc  
        sta savea
        stx savex
        jsr _malloc
        tay
        bne @OK
        cpx #0
        bne @OK
        ;; AX == 0
        ;; FAIL
        jsr nl

;;; TODO: too big just "LDA #'m'; jmp error;"
        lda savea
        ldx savex
        jsr _printn
        PRINTZ {" bytes",10,"%malloc failed! ",10,10}

        jmp _NMI_catcher

@OK:       
        rts
        

FUNC _stdlibend


FUNC _stringstart
  .ifdef STRING
    .include "lib-string.asm"
  .endif ; STRING
FUNC _stringend


FUNC _mathstart
  .ifdef MATH
    .include "lib-math.asm"         ; mul div
  .endif ; MATH
FUNC _mathend



;;; ------- <time.h>
;;; - clock difftime
;;; - va_start va_arg va_copy va_end
;;; - signal (irq timer?)

;;; -------- <assert.h>
;;; - assert

;;; --------- <stddef.h

;;; TODO:
;;; - NULL
;;; - size_t
;;; - TYPE: ptrdiff_t
;;; 

;;; ---------- <limits.h>
;;;     {INT_MAX}
;;;            Maximum value for an object of type int.
;;;            Minimum Acceptable Value: 2 147 483 647
;;;     {INT_MIN}
;;;            Minimum value for an object of type int.
;;;            Maximum Acceptable Value: -2 147 483 647
;;;     {UINT_MAX}
;;;            Maximum value for an object of type unsigned.
;;;            Minimum Acceptable Value: 4 294 967 295

;;; ---------- <strings.h>
;;; 
;;; TODO:
;;; - ffs(int) -> bit set (32..1) 1== 0x01 input FFS!
;;; - strcasecmp
;;; - strncasecmp

;;; --------- <system.h>
;;; - exec?


FUNC _unistdstart
;;; ;;????
;;; ---------- <unistd.h>
;;; 
;;; - alarm
;;; - chdir
;;; - chown
;;; - close
;;; - crypt
;;; - dup/dup2
;;; - _exit
;;; - encrypt
;;; - _exit
;;; - fsync
;;; - ftruncate
;;; - getcwd
;;; - gethostname
;;; - getpid
;;; - getuid
;;; - isatty
;;; - link
;;; - lockf
;;; - lseek
;;; - nice
;;; - pause
;;; - read
;;; - rmdir
;;; - sleep
;;; - sync
;;; - truncate
;;; - ttyname
;;; - unlink
;;; - write
;;; ---- pthreads?
FUNC _unistdend



;;; TOOD: see Docs/oric-atmos-addresses.asm ?

;;; ORIC:
;;; - wait
;;; - plot scrn
;;; - plots


FUNC _graphicsstart
;;; ORIC-rom already have routines, only compiler
;;; rules are needed for those.
;;; 
;;; TODO:
;;; - faster line
;;; - faster setpixel
;;; - faster circle
;;; - paint (fill?)
;;; 
;;; Resources:
;;; - oric graphics book
;;; - dflat has nice routines
;;; - oric .. linebench.zip? has fast routines!
;;; 
;;; Ideas:
;;; - could have several new graphics-modes:
;;;   a) normal oric
;;;   b) oric but with "set color attribute"
;;;   c) 8 FULL colors (3x3 pixels)
;;;   d) 2 color/mixing (2x2 pixels)
;;;   e) lores graphics "driver"
FUNC _graphicsend






FUNC _libraryend


;;; IDE needs "fancy bios"
;;; TODO: have a fancy function called getkey()?

.ifdef NOBIOS


.ifdef __ATMOS__
  ;.include "bios-raw-atmos.asm"
  .include "bios-atmos-rom.asm"
.else ; SIM
  .include "bios-sim.asm"
.endif ; __ATMOS__ | SIM


.ifndef putcraw
        putcraw= putchar
.endif


.endif ; NOBIOS



;;; Compiler needs ctype (isident/isalpha/isdigit)
.ifndef CTYPE
  .include "lib-ctype.asm"
.endif ; CTYPE

;;; IDE needs PRINTZ
;;; (sneak it in
;;;    - take care not to use it in compiled code!)
.ifndef STDIO
  .include "lib-stdio.asm"
.endif ; STDIO

;;; Needs for atoi, and mul
.ifndef MATH
    .include "lib-math.asm"         ; mul div
.endif



;;; TODO: remove this and simplify,
;;;   it's it's own project now!


;;; See template-asm.asm for docs on begin/end.asm
NOSHOWSIZE=1
;.include "begin.asm"


.zeropage

.code




;;; ========================================
;;;   P A R S E R   O P T I M I Z A T I O N
;;; 
;;;   41% faster by CUT+CUT2
;;;   40% faster w  FASTSKIP in _fail (no jsr _inc)
;;;    4.53% faster w OPTSKIP (_incIspc inline in _next)
;;;
;;; TODO: (how many bytes added per opt?)
;;;
;;; TODO: maybe not optional anymore? - investigate!
;
OPTPARSEALL=1

;;; TODO:
;;; -1) %A %V lot's of redundant variable parsing %A+= ...
;;;    maybe HACK a guard and skip if not var?
;;; -2) %D also parse several times, similar patterns?
;;;    poke(%D,%D) poke(%D,%V) poke(%V,%D) ...
;;;    "tokenization" before would "solve" this...
;;; 0) jsr _incIspc - move it to before _next
;;;    find locations where "jsr _incIspc; ... jmp _next"!
;;;    it's at least 12c per character used!
;;; 1) byte < 32 ==> skip byte (at _fail)
;;;    check avg,max,min size of rules
;;; 2) ruleS could be directly TAILREC - must save some!
;;; 3) byte rules?
;;; 4) any %D many times is costly (parse number later?)
;;; 5) match %V many times very costly, maybe just store
;;;    pointer and look up later when syntax fine?
;;; 6) group functions by first letter, and skip?
;;; 7) bitmap hash to check if var exists (no care?)

;;; CUT and CUT2

;;; -- BYTESIEVE:
;;; 
;;; 3451213 before opt! 3.5s
;;; 2640900 CUT2
;;; 2863202 CUT
;;; 2052939 CUT+CUT2 !  2.1s!
;;; 2159... now... lol

;;; CUT2: 14.14% faster(/ 2640900 3451213.0)
;;; 
;;; both CUTs: (- 1 (/ 2052939 3451213.0))
        
;;   41% faster!
; OPTPARSEALL=1
.ifdef OPTPARSEALL

;;; CUT2 is simple ruleS cut by '}'
;
CUT2=1
;;; TODO: generalize! it now only cuts ruleD
;;;       cutting expressions at ',;:)]?'
;
CUT=1

;;; OPTSKIP inlines _incIspc in _next
;
OPTSKIP=1

.endif ; OPTPARSEALL






;;; ========================================
;;;                  M A I N

FUNC _bnfinterpstart

.ifnblank
        .macro TIMER
          jsr timer
        .endmacro
.else
        .macro TIMER
        .endmacro
 .endif

;;; TODO: not working yet
;;; Minimal set of rules (+ LIBRARY)
;MINIMAL=1

;;; Optimizing rules (bloats but fast!)
;;; 
;;; ++a; --a; &0xff00 &0xff <<8 >>8 >>v <<v 

;;; TODO: BYTESIEVE can be compiled but doesn't run correctly...
;
OPTRULES=1

;; 

; Remove to not support else; leaner IF... lol
;
ELSE=1

;;; Byte optimized rules
;;; typically used as prefix for BYTE operators
;;; (only operating on register A, no overflow etc)
;
BYTERULES=1

;;; Write debug info
;
TESTING=1

;;; used for PARAM4
;;; 
;PARAM4=1
;DEBUGFUN=1

;;; Enable for debug info
;DEBUG=1

;;; Debug long varnames
;DEBUGNAME=1

;;; wait for input on each new rule invocation
;DEBUGKEY=1

;;; TODO: no longer working (tos & puth)
;DEBUGRULE=1

;;; at FAIL prints [rulechar][inputchar]/iL[rule]
;;; 

;DEBUGRULE2=1

;DEB2=1

;DEBUGRULE2ADDR=1

;;; prints when skipping
;DEBUGRULESKIP=1

;;; gives a little bit more context for compile err...;
;TRACERULE=1
;;; backspaces out of rules done
;;; (works best if PRINTREAD not enabled)
;TRACEDEL=1

;;; TODO: not working reliable anymore
;;;   (same char repeated+crash, and skips many?)
;;; show input during parse \=backtrack
;;; Note: some chars are repeated at backtracking!
;SHOWINPUT=1

;;; print input ON ERROR (after compile)
;;; TOOD: also, if disabled then gives stack error,
;;;   so it has become vital code, lol
PRINTINPUT=1

;;; for good DEBUGGING
;;; print characters while parsing (show how fast you get)
;;; It will skip numbers etc (as they call jsr _incI)
;;; TODO: seems to miss some characters "n(){++a;" ...?
;;; Requires ERRPOS (?)

;;; TODO: useless - remove! or reimlement...
PRINTREAD=1

;;; more compact printing of source when compiling
;UPDATENOSPACE=1


;;; About 2% overhead (BYTESIEVE)
;
PRINTDOTS=1

;;; Print lines compiled 2.5%
;
LINECOUNT=1

;
PRINTNAME=1

;;; TODO: make it a runtime flag, if asm is included?
;PRINTASM=1

;;; If asm is on, you also want to see some code
.ifdef PRINTASM
  .ifndef UPDATENOSPACE
    UPDATENOSPACE=1
  .endif

  .ifndef PRINTDOTS
    PRINTDOTS=1
  .endif
.endif ; PRINTASM




;;; TODO:
;;;  capture which rule and pos
;;;  for longest match (only)



;;; TODO: do we envision "silent" complilation and
;;;   only linenumber error messages?
;;; 
;;; print/hilight ERROR position (with PRINTINPUT)
;
ERRPOS=1

.ifdef DEBUG
  .macro DEBC c
        jsr _printchar
  .endmacro
.else
  .macro DEBC c
  .endmacro
.endif



.export percentchar,whatvarpercentchar
.export rule,inp,_out,erp,env,valid,rulename,pframe

.zeropage
        
;;; if %V or %A stores 'V' or 'A'
;;; 'A' for assigment
percentchar:  .res 1

;;; TODO: remove! LOL
whatvarpercentchar:      .res 1


;;; not pushing all
;state:  
  rule:   .res 2
  inp:    .res 2
 _out:    .res 2
;stateend:       

erp:    .res 2
env:    .res 2
valid:  .res 1

rulename:       .res 1

;;; stackframe for parameter start
pframe: 

;;; TODO: chagne '>' is bad, so better change all!
LOVAL= '<'
HIVAL= '>'

VAL0 = LOVAL + 256* HIVAL
VAL1 = '+'   + 256* HIVAL

.ifdef ZPVARS
  VAR0= LOVAL
  VAR1= '+'
  VARRAY= VAL0
.else
  VAR0= VAL0
  VAR1= VAL1
  VARRAY= VAL0
.endif

PUSHLOC= '{' + 256*'{'
TAILREC= '*'+128
DONE= '$'

;;; TODO: maybe not ZP, not used that mutch
.export dirty, showbuffer

dirty:          .res 1
showbuffer:     .res 1

.code


;;; This is where the C-program loader starts
.export _start
_start:

;;; Magical references in [generate]
.macro DOJSR addr
        .byte 'C'
        .word addr
.endmacro



;;; parser to compile _
FUNC _init

        ;; editor states
        lda #255                ; first time
        sta dirty
        sta showbuffer

        ;; tell IDE/edit.asm it's first time
        lda #64
        sta mode



;;; ATMOS w BASIC ROM
;;; TODO: fix for ROM-less
.ifdef __ATMOS__

        putc CTRL('T')          ; caps off


        ;; NMI patching to break running program.
        ;; ORIC ATMOS points to:
        ;; 
        ;; Seems to catch once during running,
        ;; but then maybe get's overwrriten
        ;; (the vector?)
        ;; 
        lda #<_NMI_catcher
        ldx #>_NMI_catcher
        sta NMIVEC
        stx NMIVEC+1

        ;; Fix '_' character, which on ORIC ATMOS is
        ;; an English Pound sign, to be underscore.
        ;; (we null out 5 top rows, keep 6th bar=>underscore!)
        ;; 10 B
        ldx #5
        lda #0
:       
        sta CHARSET+'_'*8,x
        dex
        bpl :-

.endif ; __ATMOS__


;;; Only done here the first time
.ifdef INTRO
        lda #<_introtext
        ldx #>_introtext
        jsr _printz
.else
        PRINTZ {12,"MeteoriC-Compiler & IDE on 6502 ",VERSION,10,"`2025 Jonas S Karlsson",10,10,"compiling:"}
.endif        
        
        ;; compile from src first time
        ;; - fall-through

;;; BEWARE: never returns! ends up in _OK/_edit

;;; compile source from input to output
FUNC _compileInput

        ;; default input location
        lda #<input
        ldx #>input

;;; Compiles source from AX
;;; BEWARE: never returns! ends up in _OK/_edit
FUNC _compileAX

        ;; store what to compile
        sta inp
        stx inp+1

.data
originp:        .res 2
.code
        sta originp
        stx originp+1

.ifdef ERRPOS
        sta erp
        stx erp+1
.endif        
        

;;; compile same as last time
FUNC _compile
        ;; default output location
        lda #<_output
        ldx #>_output
        sta _out
        stx _out+1

.ifdef LINECOUNT
;        PRINTZ {10,10,"lines accepts rules",10}
        PRINTZ {10,10,"LINES",10}
        jsr tab
;        ldy #24
;        jsr spaces
.endif ; LINECOUNT

;;; Get's decreased by two before use
VOSSTART=256   ; grow down.
;;; TODO: use single ZP address!


;;; TODO: where to allocate, grow down like stack
;;;   what's safe margin
;;;   and can this become TOPOFMEMORY?
;;; want to keep around for debugging


;;; TODO: bad name, pointer to start VAR rule

;;; TODO: better name
VARS=HIRES-256

        ;; We name our dynamic rule '[' (hibit)
VARRULENAME='['+128
VARRRULEVEC=_rules+(VARRULENAME&31)*2


.ifdef ZPVARS
.else
        .error "%% not support non ZPVARS"
.endif

;;; zeropage assumption...

        ;; init variable vectors
        lda #<VOSSTART
        ldX #>VOSSTART
        sta vos
        stX vos+1

        lda #<VARS
        ldx #>VARS
        sta _ruleVARS
        stx _ruleVARS+1
        ;; zero-terminate the new rule
        ;; (write one after (VARS will be overwritten))
        lda #0
        ;; TODO: 6*2 bytes set to zero, loop? put together!
        sta VARS+1

        sta compilestatus

        sta nlines
        sta nlines+1
        sta naccepts
        sta naccepts+1
        sta nrules
        sta nrules+1


;;; INTERRUPT DEBUG TESTING
;        lda #$40                ; RTI
;        sta $0245


;;; 21 B

        sei

        ;; init/reset stack
        ldx #$ff
        txs
        cld
.ifdef CHECKSTACK
        ;; sentinel - if these not there stack bad!
        stx $100
        stx $101
.endif
        ;; X=$ff still for init!



;;; TODO: move to bios-atos-rom???

;;; Init ORIC
.ifdef __ATMOS__


;;; TODO:    cleanup!
;;; TODO:   move away from here to bios!


;;; #26A -- Oric status byte. Each bit relates to
;;; one aspect: from high bit to low bit – unused,
;;; double-height, protected-columns, ESC pressed,
;;; keyclick, unused, screen-on, cursor-off.
;;; (description sucks!)

;;; 0,0,protected on=0!,0, 1=off,0,screen=on=1,cursor=on=1
        lda #%00001010
        sta $26a
;;; $24E (KBDLY) delay for keyboard auto repeat, def 32
        lda #8
        sta $24e
;;; $24F (KBRPT) repeat rate for keyboard repeat, def 4

;;; TODO: not working?
        lda #1
        sta $24f

.endif


.ifdef TIM
        sei
.endif ; TIM





.ifdef INTERRUPT
ORICINTVEC=$0245
        ;; 
.export centis,seconds

.zeropage
centis:     .res 1              ; 1/100ths of seconds
seconds:    .res 2              ; (/ 65536 3600)= 18h
.code

initinterrupts:


        sei

XYZ=1
.ifdef XYZ
        lda ORICINTVEC-1
        sta tos
        ldx #0
        stx tos
        jsr puth
        
        ;; save old vector
        lda ORICINTVEC
        sta origint
        ldx ORICINTVEC+1
        stx origint+1

        sta tos
        stx tos+1
        jsr puth

        ;; install interrupt vector
        lda #<_interrupt
        sta ORICINTVEC
        ldx #>_interrupt
        stx ORICINTVEC+1

        lda #0
        sta centis
        sta seconds
        sta seconds+1

.ifnblank
.ifblank
        ;; set timers for 100x a second
        lda #<INTCOUNT
        sta READTIMER
        lda #>INTCOUNT
        ;; this write starts the timer
        sta READTIMER
.else
        lda #<INTCOUNT
        sta SETTIMER
        lda #>INTCOUNT
        ;; this write starts the timer
        sta SETTIMER+1
.endif
.endif ; BLANK

        ;; go!
        cli

.endif ; XYZ

.endif ; INTERRUPT



.ifdef DEBUG 
        putc 'S'
        jsr nl
.endif ; DEBUG

        ;; store an rts for safety
        _RTS=$60
        lda #_RTS
        sta _output


;;; TODO: improve using using ruleP 'P'
        lda #'P'+128
        sta rulename

        lda #<rule0
        sta rule
        lda #>rule0
        sta rule+1

        ;; end-all marker
;;; TODO: make it 0, can save many tests bytes???

        lda #DONE
        pha

.ifdef DEBUGRULE
        jsr _printstack
.endif

;.ifdef PRINTASM
        jsr _iasmstart
;.endif ; PRINTASM


        jmp _next




;;; TODO: opt?
;;; 1137800
;;; 1132809 ~6000 savings 0.4% - not worth it!
FUNC _nextI
;;; 3 B
        jsr _incI
;;; 6 B
;        inc inp
;        bne :+
;        inc inp+1
;:       
;;; TODO: move this to "the middle" then
;;;   can reach everything (?)
        ;; - fall-through from above
FUNC _next


;;; TODO: remove, disable here, maybe check and end of rule?

;;; This is very expensive, but keep to find overflow bugs
.ifdef CHECKSTACK
;;; TODO: measure overhead
	;; check stack sentinel
        lda #$ff
        cmp $100
        bne stackerror
        cmp $101
        bne stackerror
        jmp :+
stackerror:
        jsr nl
        jsr _printstack

        ;; reset stacck
        ldx #$ff
        txs

        PRINTZ {10,"%S>"}

        jmp _eventloop
        
:       
.endif ; CHECKSTACK


.ifdef DEBUGRULE
    pha
;    lda rulename
;    jsr putchar
;    putc '.'
    ldy #0
    lda (inp),y
    jsr _printchar
    putc ' '
    pla
.endif

.ifdef DEBUG
.else
  .ifdef SHOWINPUT
    pha
    ldy #0
    lda (inp),y
    jsr putchar
    pla
  .endif
.endif ; DEBUG

.ifdef DEBUG
    ;; RULE
    jsr nl
    lda rulename
    jsr _printchar
    putc '.'
    ldy #0
    lda (rule),y
    jsr putchar
    ;; INPUT
    putc ':'
    ldy #0
    lda (inp),y
    jsr _printchar
    putc ' '
.endif ; DEBUG

;;; TODO: ;;;;;
;xDEBUGRULE=1
.ifdef xDEBUGRULE
;    PUTC ' '
;    jsr nl
;    ldy #0
;    lda (rule),y
;    PUTC 10
;putc '!'
ldy #0
lda (rule),y
jsr _printchar
;jsr putchar
bmi :+
bne :++
:       
jsr nl
:       
cmp #'|'
beq :--
.endif ; DEBUG



;;; Actual code to process rule, lol

        ldy #0
        lda (rule),y

        ;; hibit - new rule?
        bpl @nohi

@hibit:

        ;; is it a skipper (7bit < ' ')
        cmp #128+' '
        bcc @skip
        ;; hibit with 'A'... - Enter new Rule
        jmp _enterrule
@skip:        
        ;; C=0
        jsr skipperPlusC
        jmp _next


@nohi:       
        ;; 0 - end = accept
        bne :+
jmpaccept:
        jmp _acceptrule
:       

;;; CHEAT!
;;; 1287500 before
;;; 1301114 after (inline inc, I extra cmp/bne costly?)
;;; 1244770 = 3.3% faster still _incI _incR
;;; 1233114 = 4.2% faster inline _inc
;;; 1232119 = 4.30% faster (no ldy)
;;; 1231955 = 4.31% cmp == skip (maybe not need?)
;;; 1230291 = 4.44% _donecompile
;;; 1247041
;;; 1229158 = 4.53% 0 => acceptrule
;;; 1252062 = 2.75% savings (PRINTDOTS add overhead...)

;;; 1278508 = 0.7% OVERHEAD from ERRPOS, acceptable...
;;;           need to insert it here.
;;; 
;;; (- 1 (/ 1252062 1287500.0))
;;; 
;;; 299 Bytes instead of 303, fail at least point?
;;; 
.ifdef OPTSKIP
        cmp (inp),y
        bne @noteq
@skipspc:
;        jsr _incI
        inc inp
        bne :+
        inc inp+1
:       

        lda (inp),y
        beq jmpaccept

;;; 3% cost... update lines count each line
.ifdef LINECOUNT
        ;; count newlines
        cmp #10
        bne :+
        
        ;; TODO: not totally accurate, because backtrack?
        ldx #nlines
        jsr _incRX

        putc 13

        lda nlines
        ldx nlines+1
        jsr _printu

.ifnblank
        jsr tab
        lda naccepts
        ldx naccepts+1
        jsr _printu

        jsr tab
        lda nrules
        ldx nrules+1
        jsr _printu
.endif        

        ldy #0
        lda #10
:       
.endif ; LINECOUNT

        ;; skip anything <= ' '  !
        ;; 
        ;; no need handling # // % [ as they'll
        ;; most likely fail problem is %D or [
        ;; could give strange bugs...
        cmp #' '+1
        bcc @skipspc

;;; TODO: hi-bit makes problem... ???
;;;      and #$7f


.ifdef xPRINTDOTS
;;; print next statement each time when
;;; there is a ';'

;;; TODO: it counts too many especially when 
;;;   matching putu, for every try it counts one ';'
;;;   not clear why it stands on ';' ???
;;;   tried "skipping it" but doesn't matter

        cmp #';'
        bne @nosemi

        putc ','

.ifnblank
lda rulename
jsr _printchar
jsr spc
lda (inp),y
jsr _printchar
jsr spc

lda inp
ldx inp+1
jsr _printh
jsr spc

ldy #0
:       
        lda (rule),y
        beq :+
        jsr _printchar
        iny
        cpy #20
        bne :-
:       
ldy #0

jsr nl
.endif

@nosemi:
.endif ; PRINTDOTS

        ;; A is current inp char
       
;;; Speed
;        jsr _incR
        inc rule
        bne :+
        inc rule+1
:       
        ;; comp rule?
        cmp (rule),y
        beq @skipspc
        jmp _next

;; fallback to more costly, check-all!
@noteq:
.endif ; OPTSKIP

        ;; \ - quoted
        ;; (can't quote 0, hmmm)
        cmp #'\'
        beq quoted

        ;; | - also accept
        cmp #'|'
        beq  jmpaccept

	;; - % handle special matchers
        cmp #'%'
        beq percent

        ;; - [ gen-rule
        cmp #'['
        bne testeq
        jmp _generate

        ;; literal equal test match
quoted:
        ;; - \[ for example, match special chars
        jsr _incR
        lda (rule),y

testeq: 
        ;; - lit eq?
        cmp (inp),y
;;; LOL: relocate to "middle"?
        bne failjmp
eq:  



;;; TODO: never get's here? only one time '/'
;;;   in Input/strlib.c ????

.ifnblank
        ;; - "   string" (no skip leading spaces)
PUTC '/'
        cmp #'"'                ; "
        bne :+
PUTC '?'
        lda (inp),y
        cmp #'%'                ; probably %s or %S
        bne :+
        ;; we have '%'
PUTC '!'
        dey
        jsr _incR
        jsr _incI
        jmp percent
:       
.endif

    DEBC '='
        jsr _incR

;;; TODO: removed, not needed?
;        lda (inp),y

        jmp _nextI


failjmp:
        jmp _fail


        ;; percent matchers
percent:
        jsr _incR
        ldy #0
        lda (rule),y

        sta percentchar

.ifdef DEBUGFUN
putc '%'
lda percentchar
jsr _printchar
.endif ; DEBUGFUN

        ;; Identifier?
        ;; (this goes to subrule and will do it's own _incR)

;;; TODO: %A - REMOVE!

        cmp #'A'                ; %A used often for Assign
        beq @vars

        cmp #'V'                ; %V used for the variable (value)
        bne :+

@vars:
        ;; HACK! - remove once we figure out the flow...
        ;; (maybe remove %A or it's usage of DOS? use stack)
        ;; (needed for %S and %s too)
        sta whatvarpercentchar

        ;; - make sure start with ident
        lda (inp),y
        cmp #'_'
        beq @ok
        jsr isalpha
        beq failjmp             ; 0 if !a-zA-Z
@ok:
        ;; - use rule
        lda #VARRULENAME
        jmp enterrulebyname

        ;; try next %... matces
:       

;;; TODO: no need skip for %V ?

        ;; - skip it assumes A not modified
        jsr _incR

        ;; %= -  require one of chars till $80
        ;; %! -  fail if one of chars till $80
        ;; that is : , ; ) ] }
        ;; 37 B
        cmp #'='
        beq @dotest
        cmp #'!'
        bne :+
@dotest:
        ;; lookahead at character
        jsr nextInp             ; skip spaces!
        lda (inp),y
        sta savea
@loop:
        lda (rule),y
        ;; A hibit (0x80) indicates end of sequence
        bmi @done
        jsr _incR
        cmp savea
        beq @done
        bne @loop
@done:
        jsr _incR
        ldx percentchar
        cpx #'='
        beq @eqtest
;        bne @eqtest
@neqtest:
        ;; reverse action
        eor #80
@eqtest:
        bmi failjmp
        bpl nextjmp
:       
        ;; %b - word boundary test
        cmp #'b'
        bne :+

        ;; (isdigit isdigit => fail)
        ;; isident isident => fail
        lda (inp),y
        jsr isident
        tax
        beq nextjmp
        bne failjmp

:       
        ;; "%$<ruleaddr>" JMP "rule" used
        ;; in env to skip local variables of funciton
        ;; once out of the scope
        cmp #'R'
        bne :+
        
;PUTC '/'
;;; TODO: what's this?
;;; Doesn't even get here, how come it works!?!?!
;PUTC'R'
        ;; Y=0
;;; loads wrong address (too early? jumps where?)
        lda (rule),y
        tax

        iny
        lda (rule),y

        sta rule+1
        stx rule

        jmp _next

:
        ;; "% " (JSR to routine that ends with RTS)
        ;;      (it cannot (easily) call _fail (palpla))
        ;; 
        ;;      .byte "%"
        ;;      jsr doseomthign
        ;; 
        ;;      .byte "%"
        ;;      jmp checkbobar
        ;; 
        cmp #' '
        bne :+
        
        jsr dojmp
        jmp _next

:       
        ;; "%L" (jmp to routine that ends w jmp _next)
        ;; 
        ;;      .byte "%"
        ;;      jmp foobar
        cmp #'L'
        bne :+

dojmp:  
        ;; Y=0
        ;; - load address
        lda (rule),y
.import tmp1
        sta tmp1
        iny
        lda (rule),y
        dey
        sta tmp1+1
        
        ;; - skip over address
        jsr _incR
        jsr _incR
        
        jmp (tmp1)
:       
;;; 26 B
;;; TODO: remove - UNSAFE (to 
        ;; %{ - immediate code! to run NOW!
        cmp #'{'
        bne noimm

        ;; - copy rule address (self-modifying)
        lda rule
        sta imm+1
        ldx rule+1
        stx imm+2
        ;; self-modifying code! (possibly move to ZP?)
        ;; - jump to the rule inline code!
imm:    jmp $ffff
        ;; that code "returns" by jsr immret!
        ;; (this puts after the code on stack)

;;; loads address of IMM_RET (inline in rule)
;;; and sets rule to it, to jump over it!
immret:
        pla
        sta rule
        pla
        sta rule+1
        jsr _incR
nextjmp:        
        jmp _next
immfail:
;;; TODO: doesn't seem to work correwctly
;;; TODO: isn't used...
        pla
        sta rule
        pla
        sta rule+1
        jmp _fail

.macro IMM_RET
        jsr immret
.endmacro

.macro IMM_FAIL
        jmp _fail
;;; TODO: doesn't work???
;        jsr immfail
.endmacro

;;; still % percent handling
noimm:

;;; TODO: remove case from char to test?
;;;   (still have original value in percentchar!)

        and #$7f

        ;; ? Skipper: A<' '
        ;; (TODO: potentially if hibit set could allow
        ;;  ..127 bytes skipped/copied, could conflict
        ;;  with hibit-'Rules if we want to make them
        ;;  "special" %'R == optional?)
        cmp #' '
        bcs :+

        ;; - SKIPPER
        ;; -- dos= address+1 (pointer to binary data!)
        ldy rule
        sty pos
        ldx rule+1
        stx pos+1

;;; TODO: why is it skipping?
;;;   maybe just get address?

        ;; -- Skip n bytes
        ;; C= 0
        jsr skipperPlusC

        ;; -- %* - dereference tos= *pos;
        ldy #1
        lda (pos),y
        sta tos+1
        dey
        lda (pos),y
        sta tos

;;; TODO: jmp _next ???

;;; TODO: old percent char not here!!!! 
        ;; -- %A tos=dos lol
        ;; (compat with old %A)
        lda whatvarpercentchar
        cmp #'A'
        bne @notA
        
        lda tos
        sta dos
        lda tos+1
        sta dos+1
@notA:


.ifdef DEBUGNAME
    php
    pha
    tya
    jsr _printh
    pla
    plp
.endif ; DEBUGNAME

        ;; -- Skip n bytes
        ;; C= 0
;        jsr skipperPlusC
        jmp _next

:       
        ;; Digits? (constants really)
        cmp #'d'                ; < 256
        beq :+
        cmp #'D'                ; any constant
        bne :++
:       
        jmp _digits
:       

        ;; String?
        cmp #'s'                ; means skip
        beq string
        cmp #'S'                ; means Copy
        beq string

        ;; ELSE assume it's %var..
jmpvar: 
        ;; - % anything...
        ;;   %V (or %A %N %...)
        jmp _var

        ;; - "constant string" inline!

        ;; -- save address in gos
        lda _out
        sta gos
        lda _out+1
        sta gos+1
        ;; -- keep counting size in dos
        lda #0
        sta dos
        sta dos+1

string: 
        ;; determine if to Copy (%S not %s)
        lda percentchar
        cmp #'s'                ; sets C= not copy
        bcs :+
        ;; Copy
        lda #128
        sta percentchar
;   putc '!'
:       
        ;; use "bit percentchar" to test bmi if to Copy

str:    
        ;; Y=0 still
        ;; get first char
;        ldy #0
        lda (inp),y
        bne :+
        jmp failjmp
:       
        ;; " - at end?
        cmp #'"'                ; "
        beq @zero

        ;; - quote (next char is raw)
        cmp #'\'
        bne @plain
        ;; -- quoted
        jsr _incI
        lda (inp),y
        ;; - \0 =>  0
        bne :+
        lda #0
:       
        ;; - \n => 10
        cmp #'n'
        bne :+
        lda #10
:       
        ;; - \r => 13
        cmp #'n'
        bne :+
        lda #10
:       
        ;; - \t => 9
        cmp #'t'
        bne :+
        lda #9
:       
        ;; TODO: - \xff

@plain:
        ;; skip to next char (keeps A)
        jsr _incI

        ;; - Copy (C=1)
        ;; 7bit set if to Copy
        bit percentchar
        bpl str

        ;; TODO: call jsr _outbyte?
        ;; 7 B
        ; ldy #0 
        sta (_out),y
        jsr _incD
        jsr _incO

        jmp str

@zero:
        ;; - Copy (C=1)
        ;; 7bit set if to Copy
        bit percentchar
        bpl @noout
        ;; zero-terminate if gen
        lda #0
        sta (_out),y
        jsr _incD
        jsr _incO
@noout:       
        ;; skip "
        jmp _nextI



;;; skipper: skip N=(A & 127) bytes of rule
skipperPlusC:
        and #127
        adc rule
        sta rule
        bcc :+
        inc rule+1
:       
        rts



FUNC _enterrule
.ifdef DEBUGNAME
PUTC '>'
.endif ; DEBUGNAME
.ifdef PRINTASM
        pha
        txa
        pha
        tya
        pha

;        jsr _iasm
        pla
        tay
        pla
        tax
        pla
.endif ;PRINTASM



.ifdef TRACERULE
        pha
;;; not totally correct
.ifdef TRACEDEL
        cmp #TAILREC
        beq :+
.endif
        putc '>'
        ldy #0
        lda (rule),y
        jsr _printchar
        cmp #TAILREC
        bne :+
        lda rulename
        jsr _printchar
;        jsr _printstack
:       
        pla
.endif ; TRACEFULE

;;; 34 B
        ;; enter rule
        ;; - save current rulepos
    DEBC '>'
.ifdef DEBUGKEY
        jsr getchar
        cmp #13
        bne :+
        ;; print state
        jsr nl
        putc '~'
        jsr putchar
        lda inp
        ldx inp+1
        jsr _printz
        jsr nl
:       
        ldy #0
        
.endif ; DEBUG

.ifdef xLINECOUNT
        ldx #nrules
        jsr _incRX
.endif ; LINECOUNT

        ;; TAILREC?
        cmp #TAILREC
        bne pushnewrule

        jmp _acceptrule

pushnewrule:
        ;; Hi-bit set, and it's not '*'

        ;; - load new rule pointer
        ldy #0
        lda (rule),y
enterrulebyname:
        sta savea

        ;; - save current rule
        lda rule+1
        pha
        lda rule
        pha
        lda rulename
        pha

        ;; save re-skipping!
;;; TODO: would like to get rid of this
;;;   but _next skips whitespace only (I think?)
;;; This skips // comments and #define #include...
        jsr nextInp

        ;; - push inp for retries
        lda inp+1
        pha
        lda inp
        pha
        lda #'i'
        pha

        ;; - set rule name
        lda savea
        sta rulename


.ifdef DEB3
    PUTC ' '
    jsr _printchar
    PUTC '>'
.endif

.ifdef DEBUGRULE
    PUTC ' '
    jsr putchar
    PUTC '>'
.endif

loadruleptr:
        and #31
        asl
        tay
        lda _rules,y
        sta rule
        lda _rules+1,y
        sta rule+1


.ifdef DEBUGRULE
;    jsr _printstack
.endif
        jmp _next
;;; TODO: use jsr, to know when to stop pop?
;;; (maybe don't need marker on stack?)


;;; We arrive here once a rule is matched
;;; successfully. We then cleanup 'i'nput and do
;;; any needed 'p'atching, until we reach another
;;; rule to continue parsing (or end).

FUNC _acceptrule
.ifdef xLINECOUNT
        ldx #naccepts
        jsr _incRX
.endif ; LINECOUNT

.ifdef DEBUGVARS
  PUTC '!'
.endif ; DEBUGVARS
;;; Theory:
;;;   program compile fail (unless error up-propagates)
;;;   is AFTER the last position of input that generated
;;;   code! lol

;;; seems this in _acceptrule is cheaper than _fail
.ifdef ERRPOS
        ;; update if inp>erp
        lda inp

        ldx inp+1
        cpx erp+1
        bcc @noupdate
        bne @update

        cmp erp
        bcc @noupdate
        beq @noupdate
@update:
        sta erp
        stx erp+1
@noupdate:       
.endif        

.ifdef PRINTASM
        putc MAGNENTA           ; magnenta RULE

        lda rulename
        jsr putchar

        putc GREEN              ; green code text

;        jsr _iasm
.endif ; PRINTASM

.ifdef TRACERULE

.ifdef TRACEDEL
        jsr bs
        jsr putchar

        jsr spc
        jsr putchar

        jsr bs
        jsr putchar
.else
        putc '<'
.endif ; TRACEDEL

.endif ; TRACERULE

;;; 19 B
    DEBC '<'
.ifdef DEBUGRULE
    putc '<'
.endif

@loop:
.ifdef DEB2
PUTC '.'
.endif
        ;; remove (all) re-tries
        pla

.ifdef DEBUGRULE2
    pha
    jsr _printchar
;    jsr _printstack

;;; Doesn't get here....?
        tsx
        bne :++
        PUTC 'X'
:       jmp :-
:       

    pla
.endif

        bmi uprule
        ;; - done?
        cmp #DONE
;;; TODO: what to do if have data left?
        bne :+
        ;; yes, done, no error
        jmp _donecompile
:       
        
        ;; 'p' - PATCH
        cmp #'p'
        bne @dropone
    DEBC 'P'
        pla
        sta pos
        pla
        sta pos+1

        ;; patch to here!
        ldy #0
        lda _out
        sta (pos),y
        iny
        lda _out+1
        sta (pos),y

        jmp @loop

;;; typically an 'i' but could be an '&'
@dropone:
.ifdef DEB2
PUTC '='
.endif

;        jsr putchar
    DEBC '.'
.ifdef DEBUGRULE
    putc '.'
.endif

        pla
        pla
        jmp @loop

;;; hibit - RULE
uprule:
        ;; put it back
        pha

        ;; is it TAILREC?
        ldy #0
        lda (rule),y
        cmp #TAILREC
        bne yesgoup
        
        ;; - commit inp so far
        lda inp+1
        pha
        lda inp
        pha
        lda #'i'
        pha
        ;; - reset current rule to beginning
        lda rulename
        jmp loadruleptr

yesgoup:
        pla

.ifdef DEB3
PUTC '^'
jsr _printchar
.endif

.ifdef DEB2
PUTC '^'
.endif

.ifdef DEB2
sta savea

tsx
stx tos
lda #0
sta tos+1
jsr putu
PUTC 10

lda savea
.endif

.ifdef DEBUGRULE
    PUTC '_'
.endif

    DEBC '_'

        ;; - restore partial parsed rule
        sta rulename
        pla
        sta rule
        pla
        sta rule+1

.ifdef DEBUGRULE
        putc '/'
        lda rule
        sta tos
        lda rule+1
        sta tos+1
        jsr puth
        jsr nl
        jsr _printstack
.endif

        ;; exit rule
        jsr _incR
        jmp _next



FUNC _fail

;;; TODO: seems to disturbe correct exec?
;.ifdef TRACERULE
;       PUTC '%'              
;.endif ; TRACERULE


;;; seems this in _acceptrule is cheaper than _fail
.ifdef xERRPOS
        ;; update if inp>erp
        lda inp
        ldx inp+1

        cpx erp+1
        bcc @noupdate
        bne @update

        cmp erp
        bcc @noupdate
        beq @noupdate
@update:
        sta erp
        stx erp+1
@noupdate:       
.endif ; ERRPOS


;;; 2159605 before FASTSKIP
;;; 1287228 with FASTSKIP! - half the time almost
;;; (/ 1287228 2159605.0) == 40.4% faster!
;;; 
;;; size 78 -> 87 Bytes (+ 9)

        ;; Y= inp.lo; // faster looping!
        ldy rule
        lda #0
        sta rule

;;; ca65: Can't have between @loop and usage??? LOL
;PRINTSKIP=1

.export loopfail
FUNC loopfail
        lda (rule),y
;
.ifdef PRINTSKIP
pha
PUTC '.'
jsr _printchar
iny
lda (rule),y
jsr _printchar
iny
lda (rule),y
jsr _printchar
jsr spc
dey
dey
pla
.endif ; PRINTSKIP
        beq endrule

        cmp #'|'
        beq nextalt

        cmp #'['
        beq skipgen

        ;; ? % operator?
        cmp #'%'
        bne @nopercent
        
        ;; - get char after %
        ;; (notice not jsr _incR as we're INY!)
        INY
        bne @noincinc
        inc rule+1
@noincinc:
        lda (rule),y

        ;; - skip 2 chars if "%L" ('L'= jmp!)
        cmp #'L'
        bne :+

        lda #2
        ;; fall-through and it'll skip 2!
:       

        ;; ? % len7 ... (skip ... of len7,hibit ignore)
        ;; 7bit < 32 skip bytes!
        and #$7f

        cmp #' '
        bne :+
        
        ;; skip JSR
        lda #2
        clc
        ;; fall-through and it'll skip 2!
:       

        bcs :+
        ;; SKIP A bytes!
        ;; C=0
        ;; more complicated than it should be
        sty rule
        jsr skipperPlusC
        ldy rule
        lda #0
        sta rule

        jmp loopfail
:       
@nopercent:
        ;; normal char: skip
FUNC nextskip
        ;; loop w Y
        INY
        bne loopfail
        inc rule+1
        ;; always!
        bne loopfail

        ;; skip [...0...] gen
FUNC skipgen
        iny
        bne :+
        inc rule+1
:       
        lda (rule),y
        cmp #']'
        bne skipgen
        beq nextskip
        
;;; we're done skipping! (standing at '|')
FUNC nextalt
.ifdef DEBUGNAME
   PUTC '|'
.endif ; DEBUGNAME
        ;; finally rule.lo (Y) write it back!
        sty rule

        ;; skip '|'
        jsr _incR

FUNC restoreinp
        ;; restore inp for alt

        ;; - peek stack
        pla
        pha
        ;; TODO: correct jump? is it error?
        ;;  (means? still have input?)
        ;        bmi gotendall
        bmi unexpectedrule
        cmp #DONE
        ; lda #0 ???? if no error
        beq _donecompile

        cmp #'i'
        beq gotretry

        ;; ignore... whatever is on the stack...
        pla
        pla
        pla

        jmp restoreinp

FUNC gotretry
.ifdef DEBUGRULE
    putc '!'
    jsr nl
.endif
    DEBC '!'

        ;; copy/restore inp and leave at stack
        tsx

        pla
        pla
        sta inp
        pla
        sta inp+1
        txs
        jmp _next

;;; we come here if FAIL find no '|' alt
endrule:
.ifdef DEBUGNAME
PUTC '/'
.endif ; DEBUGNAME

.ifdef DEB3
PUTC '/'
lda rulename
jsr _printchar
.endif

.ifdef DEBUGRULE
   putc 'E'
;   jsr _printstack
.endif

	;; END - rule
    DEBC 'E'

        ;; TODO: is this always like this?
        ;; (how about patch?)

        ;; nothing to backtrack

        ;; - get rid of 'i' retry ????
        pla


.ifdef DEB3
PUTC '&'
jsr _printchar
.endif

.ifdef DEBUGRULE2
pha
putc ' '
ldy #0
lda (rule),y
jsr _printchar
lda (inp),y
jsr _printchar
putc '\'

jsr _printstack

putc '/'
pla
:       
jsr _printchar
tsx
;;; TODO: hmmm
beq _donecompile                ; or %S TODO:
cmp #DONE
;;; TODO: hmmm
beq _donecompile                ; ???
;cmp #'i'
;beq :+

;;; not expected, try sync up...

putc '/'
pla
pla
jmp :-

:

.endif ; DEBUGRULE2

        pla
        pla

        ;; - get rid of _R current rule
        pla

.ifdef DEBUGRULE2
jsr _printchar
PUTC ' '
.endif

;.endif
        pla
        pla

        ;; need to prime uprule with one value
        ;; (this was mising -> unbalanced before)
:       
        pla
        bmi :+
;;; TODO: this fixes parse issue, ^i rule lol
;;;   but it probably drops a 'P' patch???

;;; NO, that's not the case....

;;;  TODO: loop instead, but why we got here?
        ;; not rule, go up!


;;; TODOTODOTODO:TTTOOODDDOOO fixme!
;;;    or not, what does it break?

        pla
        pla
        jmp :-
:       
        jmp uprule


FUNC _donecompile
        lda #0
        ;; A contains error code; 0 if no error
FUNC _errcompile

        TIMER

.ifdef TRACERULE
        jsr nl
.endif
.ifdef DEBUGRULE
        jsr _printstack
.endif
        ;; no errors - lol
        lda #0
        jmp _aftercompile


;;; --------------------------- ERRORS

FUNC _errors
;;; 25 B

;;; ? mismatch stack?
unexpectedrule:
.ifdef CHECKSTACK
        PRINTZ "%R"
        jmp stackerror
.else
        lda #'R'
        SKIPTWO
.endif
illegalvar:     
        lda #'I'
        SKIPTWO
;; Unexpected End of input
gotendall:
        lda #'E'
        SKIPTWO
;;; Unexpected char?
failed:
        lda #'F'
        ;; fall-through to error

;;; After error, it calls _aftercompile
;;; A register contains error
error:
        sta compilestatus
        pha
        PRINTZ {10,"%"}
        pla
        jsr putchar

        jmp _ERROR



FUNC _var
;;; 42 B
DEBC '$'

        lda percentchar

        ;; ? %* - dereference tos { tos= *(int*)tos; }
        cmp #'*'
        bne :+

        ldy #1
        lda (tos),y
        tax
        dey
        lda (tos),y
        sta tos
        stx tos+1

jmpnext:       
        jmp _next
:       

        ;; ? %Ident: match an long name ident
        cmp #'I'
        bne :+

        jmp _ident
:       
        ;; ? %New function/var
        cmp #'N'
        bne :+

;;; TODO: not working correctly?

        ;; add to env, default as 'w'ord
        ;; TODO: add char after "%Nw" w type?
        jmp _newvar_w

        ;; never returns! (jumps _next)

:       
        ;; %??? no match - ERROR
        jmp error

;;; TODO: can conflict w data
;;;   write .pl script look at .lst output?
FUNC _generate
;;; ??? 19 B
        jsr _incR
        ldy #0
        lda (rule),y

        ;; ']' - END GEN
        cmp #']'
        bne :+
        DEBC ']'
        ;; - done

        jsr _incR
        jmp _next
:       
        ;; Call substitute for $20 as it gets "quoted"
        cmp #'C'
        bne :+
        
        lda #$20                ; JSR
        jmp @skipjsr
:       
        ;; ' '- JSR skip 2 bytes (QUOTE THEM!)
        cmp #$20                ; JSR xx xx 
        ; ldx #1 ; ???
        bne :+
        ;; TODO: jmp?
        ;cmp #$4c                ;JMP xx xx
        ;; out JSR (' ')
;;; 28B
        sta (_out),y
        jsr _incO

        jsr _incR
        lda (rule),y
        sta (_out),y
        jsr _incO

        jsr _incR
        lda (rule),y
        sta (_out),y
        jsr _incO

        jmp _generate

;;; TODO: hmmm
;;; 21...?
        sta (_out),y
        jsr _incO

        ;; Y stil 0
        ;; lo: read next
        jsr _incR
        lda (rule),y

        ;; hi: read next (inc in genoutAX)
        pha

        jsr _incR            
        lda (rule),y
        tax

        pla
        jmp genoutAX

@skipjsr:
:       
;;; '<' LO %d
        cmp #'<'
        bne :+
DEBC '<'
        lda tos
        jmp doout
:       
;;; '>' HI %d
        cmp #'>'
        bne :+
DEBC '>'
        lda tos+1
        jmp doout
:       
;;; '?n' PICK n
        cmp #'?'
        bne :+
DEBC '?'
        jsr _incR
        lda (rule),y
        and #$0f
        ;; mul3
        sta savea
        asl a
        adc savea
        ;; add x
        tsx
        stx savex
        adc savex
        tax
        ;; PICK n:rd from stack
        lda $102,x
        sta tos
        lda $103,x
        sta tos+1
        jmp _generate
:       
;;; 'B' Branch patch TOS to here
        cmp #'B'
        bne :+
DEBC 'B'
        lda _out+1
        iny
        sta (tos),y

        lda _out
        dey                     ; Y back to 0 !
        sta (tos),y
        jmp _generate
:
;;; 'D' SET tos=dos
        cmp #'D'
        bne :+
DEBC 'D'
        lda dos
        sta tos
        lda dos+1
        sta tos+1
        jmp _generate
:  
;;; 25B
;;; 'd' pos=tos
        cmp #'d'
        bne :+
DEBC 'd'
        lda tos
        sta dos
        ldx tos+1
        stx dos+1
        jmp _generate
:       
;;; '#' push tos
        ;; dos=tos
        cmp #'#'
        bne :+
DEBC '#'
        lda tos+1
        pha
        lda tos
        pha
        lda #'p'
        pha
        jmp _generate
:       
;;; '{{' PATCH
        cmp #'{'
        bne :+
DEBC '{'
        lda _out+1
        pha
        lda _out
        pha
        lda #'p'
        pha
        jsr _incO
        jsr _incR
        jsr _incO
        jmp _generate
:       
;;; ":" PUSH HERE
        cmp #':'
        bne :+

        lda _out+1
        pha
        lda _out
        pha
        lda #'&'
        pha
        jmp _generate
:       
;;; ";" POP -> %D (tos)
        cmp #';'
        bne :+

        pla
.ifdef SANITY
        cmp #'&'
;;; TODO: ... bne error
.endif
        pla
        sta tos
        pla
        sta tos+1
        jmp _generate
:       
;;; "+" PUT %d+1
        cmp #'+'
        bne doout               ; raw byte - no special
DEBC '+'
        ldx tos+1
        ldy tos
        iny
        tya
        bne @noinc
        inx
@noinc:

genoutAX: 
        ;; put
        ldy #0
        sta (_out),y
        ;; - is second R char '>'?
.ifblank
        iny
        lda (rule),y
        cmp #'>'
        bne gendone
        dey
.endif
        ;; output '>' hibyte
        txa
        ;; these don't touch A
        ;; X changed, but that's ok!
        jsr _incR
        jsr _incO
        ;; fall-through doout
doout:
        sta (_out),y
gendone:
        jsr _incO
        jmp _generate


FUNC _ischar 
;;; 18 B
        ;; - get char
        jsr _incI
        ;; Y=0
        lda (inp),y
        sta tos
        sty tos+1
;;; TODO: quoted \n \r \0 \... ? \' \\
;        cmp #'\'
        ;; - skip char
        jsr _incI
        ;; - skip '
;;; TODO: jsr _incI!
        jsr _incI
        jmp _next



;;; TODO: this breaks BYTESIEVE.... eats one char too many sometimes?

.ifblank

;;; ChatGPT: 198 B several loops one per base (incl 'x')
;;;          145 B one loop unified, fixed C flag bug
;;; JSK: written before compare ShitGPT
;;;    (- #x763 #x6d2) = 145 + 18 B for _ischar
FUNC _digits

        ;; ++73 bytes compare to old DECIMAL


;;; savey = base, savex = minus

;;; 69 B

        ;; look at first char
        ;; Y=0
        lda (inp),y

        ;; 'c' : is char?
        cmp #'''
        beq _ischar

        ;; default base 10
        ldx #10
        stx savey

        ;; negative flag = 0 (Y)
        sty savex

        ;; start with 0 (Y)
        sty tos
        sty tos+1

        ;; ? - negative
;;; 12 B to consume one ?
        cmp #'-'
        bne :+

        sta savex
        jsr _incI
        lda (inp),y
:       
        ;; ? $ hex (hmmm - not standard)
        ;; (useful for inline ASM!)
;;; TODO: byte var problem....
        cmp #'$'
        beq @hex
      
        ;; ? '0'=>check 0x.. '1'..'9'=>isdigit, otherwise fail 
        sec
        sbc #'0'
        beq :+
        cmp #10
        bcs failjmp2
        bcc @isdigit
:       
        ;; - second char: x=hex b=binary otherwise=octal
        jsr _incI
        ldx #8                  ; default octal!
        lda (inp),y

        ;; lowercase
        ora #32
        ;; - ? 0x...
        cmp #'x'
        bne :+
@hex:
        ldx #16
:       
        ;; - ? 0b...
        cmp #'b'
        bne :+

        ldx #2
:
@start:
        stx savey
;;; TODO: little backwards logic (?)
        cpx #8
        beq @hasnext

;;; 74 B

@gonext:
        jsr _incI
        ;; TODO: maybe use Y to count?
        ldy #0
        lda (inp),y
        ;; map '0'..'9' -> 0..9, >=10 === END
;;; TODO: replace by xor???
;;; 7 B
@hasnext:
        sec
        sbc #'0'
        cmp #10
        bcc @isdigit
        ;; a-f/A-F -> 10-15
        ora #32
        sbc #'a'-'0'
        cmp #6
        bcs @done
        adc #10
@isdigit:
        ;; ? done (any other char breaks)
        cmp savey
        bcs @done

        ;; tos = tos*10 + digit
;;; 17
        ldy savey
        sta savea
        jsr _mulTOSyAX
        clc
        adc savea
        sta tos
        bcc :+
        inx
:       
        stx tos+1

        ;; check range:
        ;; ? "%d" and '> 256
        ;; TODO: bit percentchar? (if shl before/)
        lda percentchar
        cmp #'d'
        bne @gonext
        
        ;; %d
        lda tos+1
        beq @gonext
        bne failjmp2
        
@done:
        ;; DONE!
        ;; - negate?
        lda savex
        beq :+

        sec
        lda #0
        sbc tos
        sta tos
        lda #0
        sbc tos+1
        sta tos+1
:       
        jmp _next


.else

;FUNC _olddigits
FUNC _digits
;DEBC '#'
;;; 55 B + 18 B char
;;; (+ 19 22 23) = 64
        ;; 19 B
        ;; valid initial digit or fail?
        ;; Y=0
        lda (inp),y

        ;; 'c' : is char?
        cmp #'''
        beq _ischar
        ;; TODO: C=1 from cmp if digit
        ;; 0-9 : is digit?
        sec
        sbc #'0'
        cmp #10
        bcs failjmp2

        ;; start with 0
        lda #0
        sta tos
        sta tos+1

nextdigit:
        ;; 22 B
        ;; Y=0
        lda (inp),y

        ;; change '0'-> 0
        sec
        sbc #'0'
        cmp #10
        bcc digit
        ;; Done
        ;; > 9 : end == OK

        ;; test that it's allowed range D=word d=byte
        lda percentchar
        cmp #'D'
        beq @OK
        ;; we have 'd' lets see < 256
        lda tos+1
        bne failjmp2
@OK:       
        jmp _next

digit:  
        ;; 23 B
        sta savea
        ldy #10
        jsr _mulTOSyAX          ; AX = tos * 10
        ;; add digit from A to tos
        clc
        adc savea
        sta tos
        bcc :+
        inx
:       
        stx tos+1

        jsr _incI
        ldy #0
        jmp nextdigit
.endif ; FUNC olddigit

failjmp2:        
        jmp _fail



;;; TODO: cleanup!

;;; Consumes current input char, moves to next
;;; no-space character.
;;; 
;;; Any // comment is skipped till newline
;;; Same goes for #define or whatever (for now)
;;; TODO: maybe do simple macros, at least to treat
;;;       like constant INT/STRINGS






;;; TODO: cannot remove as this is the onlyi
;;;  place that skips // comments
;;;  and # defines....  lol

;.ifdef TODOREMOVE
.ifndef TODOREMOVE            

;; registers untouched
FUNC _incIspc
        jsr _incI

;;; skip white space
;;; TODO: better name?
;;; makes sure inp is pointing at relevant char
;;; - skips any char <= ' ' (incl attributes)
;;; - skips "// comment till nl"
;;; - skips "# anything till nl"
FUNC nextInp
.scope
;;; oops! this was actually important to save all regs!
        pha
        txa
        pha
        tya
        pha

nextc:
        ldy #0
        lda (inp),y
        bpl :+
        ;; hi-bit set => reset, lol (cursor?)
        and #$7f
        sta (inp),y
:       
        beq done

.ifdef PRINTDOTS
        ;; at each newline print a dot
        ;; cmp #10

        ;; trigger on end of statements
        ;; - foo();
        ;; - while () {
        cmp #';'
        beq :+
        cmp #'{'
        bne @nosemi
:       

;;; TODO: gives 44 "lines" when there is 32 stmts
.ifdef xLINECOUNT
        pha
        ldx #nlines
        jsr _incRX
        pla
.endif ; LINECOUNT

;;; TODO: move to subroutine
;;; TODO: keep track of last printed src
;;;       (and don't print again, lol)

        PUTC '.'
@nosemi:
.endif ;PRINTDOTS

        ;; CTRL characters/space skip
        cmp #' '+1
        bcc skipspc

;;; <------------Add more cases here!----------->

        ;; #include <...  - just ignore all #! .. NL!
        ;; CPP macros are complicated?
        ;; - https://en.cppreference.com/w/c/language/translation_phases.html
        cmp #'#'
        beq tillNL

        ;; // comment till NL
        cmp #'/'
        bne done

        ;; look-ahead 1 is '/'?
        iny
        lda (inp),y
        ;; second /
        cmp #'/'
        bne done

        ;; - is comment, skip till NL
tillNL:
        jsr _incI
        ldy #0
        lda (inp),y
        beq done
        cmp #10
        bne tillNL

skipspc:
        jsr _incI
        jmp nextc

done:
.ifnblank
ldy #0
lda (inp),y
putc '@'
jsr _printchar
.endif

.ifdef UPDATENOSPACE
.ifdef xERRPOS
;;; store max input position
;;; (indicative of error position)
        lda inp+1
        cmp erp+1
        bcc noupdate
        bne update
        ;; erp.hi == inp.hi
        lda inp
        cmp erp
        bcc noupdate
        beq noupdate
        ;; erp := inp
update:
.ifdef xPRINTREAD
        pha

        ldy #0
        lda (erp),y
        jsr putchar

.ifnblank
        sta tos
        lda #0
        sta tos+1
        putc '#'
        jsr putu
        putc ' '
.endif

        pla
.endif

        sta erp
        lda inp+1
        sta erp+1
noupdate:
.endif ; ERRPOS
.endif ; UPDATENOSPACE


        pla
        tay
        pla
        tax
        pla
.endscope
        rts

.endif ; TODOREMOVE






;;; written more to save bytes as each
;;; is only +3 B, but costs increase till 3x!
;;; 
;;; They are ordered so I is fastest, then
;;; R O P T which probably would relate to
;;; frequency of usage...

FUNC _incVARS
        ldx #_ruleVARS
        SKIPTWO
;;; TODO: is it worth it +3 B, used 2x 3 B=9 B, or 11 B
FUNC _incD
;;; 3  32c!
        ldx #dos
        SKIPTWO
FUNC _incT
;;; 3  32c!
        ldx #tos
        SKIPTWO
FUNC _incP
;;; 3  27c! (used for print?... TODO: optimize?)
        ldx #pos
        SKIPTWO
FUNC _incO
;;; 3  22c
        ldx #_out
        SKIPTWO
;;; TODO: how much faster if _incR and _incI specialized?
FUNC _incR
;;; 3  17c
        ldx #rule
        SKIPTWO
FUNC _incI      
;;; 2  12c
        ldx #inp
;;; Inc word Register X in zeropage
;;;   preserves A,Y
FUNC _incRX
;;; 6+1  10c (+ 4c seldomly) +12c for calling it!
        inc 0,x                 ; 6c
        bne :+
        inc 1,x
:
;;; State of flags at exit: Z=0 unless hi wrapped!
        rts
        


; 18 B

;;; put before (_ruleVARS), dec
;;;   Y must be 0
;;;   A value to be pushed
;;;   X modified (= _ruleVARS)
FUNC _stuffVARS
        sta (_ruleVARS),y
FUNC _decVARS
        ldx #_ruleVARS
        SKIPTWO
FUNC _decV
        ldx #vos
        SKIPTWO
;;; TODO: insert other DEC routines here

FUNC _decT
        ldx #tos
        ;; fall-through
;;; Dec word Register X in zeropage
;;;   preserves A,Y
FUNC _decRX
        pha
        lda 0,x
        bne :+
        dec 1,x
:       
        dec 0,x
        pla
        rts
        



.ifnblank
;;; TODO: consider

_addARX:        
;;; 10
        clc
        adc $0,x
        sta $0
        bcc :+
        inc $1,x
:       
        rts

_addARY:
;;; +2
        ldx #0
;;; add AX to register Y
;;; (result optionally (+2 B) in 
_addAXRY:        
;;; 15
        clc
        adc $0,y
        sta $0,y
        txa
        adc $1,y
        sta $1,y
        rts
;;; Note:  A=hi result, ($0,y)=lo


.endif



.ifdef CUT
cut:    
;;; OK this works! (but no benefit)
;        pla
;        pla
;        jmp _fail

        ;; save current char
;;; TODO: use the inpC stuff
        ldy #0
        lda (inp),y
        sta savea
;PUTC '@'
;jsr putchar
        ;; search from 
@next:
        iny
        lda breakchars-1,y
;PUTC '^'
;jsr putchar
        ;; @end FAIL - try all the rules
        ;; (ugh; NO use '|' - it cannot skip - lol)
        cmp #'|'+128
        bne :+

        pla
        pla
        jmp _fail
:       
        cmp savea
        bne @next

;;; should work, return and go to _accept?
;;; doesn't
;        rts

;;; OK, so far so good
;        pla
;        pla
;        jmp _fail


        pla
        pla

.ifnblank
        ;; should also work, but EXIT?
        lda #<nextrule-1
        sta rule
        ldx #>nextrule-1
        stx rule+1
        jmp _next
.endif
;        jmp _fail

        ;; should work... but?
        jmp _acceptrule

.endif ; CUT




;;; VAR ident list have following structure
;;;
;;; (no spaces, ' means hibit set)
;;;


;;;  NOTE: ++ value not encoded!


;;;                  ++ dos    
;;; | name %b %'N     1 ADDR   w  // word i;
;;; | NAME %b %'N     1 ADDR   c  // char b;

;;; Arrays are static (no dynamic on stack)
;;; and can from the compiler perspective be
;;; considered a constant (pointer).

;;; TODO: we need to store sizeof
;;;   crazy idea store before array?

;;; | NAME %b %'N     2 ADDR  'W  // word arrw[17];
;;; | NAME %b %'N     1 ADDR  'C  // char bytes[17];
;;;
 ;;; w=word W=word* c=char C=char* 'w=const word

;;; creates a newvar lexical binding
;;;   Y = w c W C 'w 'c 'W 'C (word/const, W/C=pointer, 'hibit)
;;;   A = ++ value (redundant from Y)

;;; parse identifier name
;;; pushes (address/word, len/byte) on stack
;;; (get's cleaned up correctly if _fail called!)
;;; 
;;; THis routine doesn't "fail"
;;; 
;;; NOTE: this requires inp to stand
;;;   on the first char and that it's a legal
;;;   ident first char.
FUNC _ident 
;;; 32 B

.ifdef DEBUGNAME
jsr nl
putc 'I'
.endif ; DEBUGNAME
; 18

        ;; push name pointer on stack (hi, lo)
        lda inp+1
        pha
        lda inp
        pha

        ;; parse name
        ;; Y=0
        lda #0
        sta savea
:       
        ldy #0
        lda (inp),y

.ifdef DEBUGNAME
PUTC ' '
jsr putchar
.endif ; DEBUGNAME
        jsr isident             
        beq :+                  ; not ident (AX=0), Y trashed
        jsr _incI
        inc savea
        ;; always
        bne :-
:       
        ;; push length
        ;; (this will "hopefully" be cleaned up by _fail)
        ;; (>30 might give misidentification, lol)
        ;; TODO: Y==0 should fail?
        lda savea
        pha
        jmp _next



;;; TODO: not here yet


;;; size not known
FUNC _newarr_c_unknown
        ;; set size 0
        lda #0
        sta tos
        sta tos+1
        ;; fall-through

;;; tos= size in bytes
FUNC _newarr_c
        ldy #'c'+128
        ;; fall-through

;;; tos= array size in bytes, Y = type of elements
FUNC _newarr
        sty savey

        ;; save address
        lda _out
        ldx _out+1
        sta gos
        stx gos+1

        ;; allocate tos bytes space (move _out)
        ;; (zero out tos bytes at _out; _out+= tos)
;;; 23
        ldx tos+1
        stx savex               ; hi counter
        
        lda #0
        tay
        ldx tos                 ; lo counter

        ;; Ysavex= size; result: _out+= size
        beq @page
        ;; partial page write first time
@loop:
        sta (_out),y
        jsr _incO
        dex
        bne @loop
@page:       
        ;; more page copy?
        dec savex
        bpl @loop

        ldy savey
        jmp _newname

;;; register a new funciton name (after %I)
FUNC _newfun
        lda #0
        sta nparam
        ;; TODO: return type?
        ldy #'F'
        ;; fall-through

FUNC _newname_Y_out
        ;; AX= _out address (inline array data)
        ;; push backwards (lo, hi)
        lda _out
        ldx _out+1
        
        jmp _newvar_Y_AX




FUNC _initparam
        ldx #255
        stx nparam
        jmp _next

FUNC _newparam_w
        ;; assign next fixed param position
        inc nparam
        lda nparam
        asl
        ;; C=0
        adc #params
        ldx #0
        
        jmp _newvar_Y_AX_w

;;; TODO: _newlocal_w

FUNC _newvar_w
        ;; V(ar)Alloc 2 bytes
        jsr _decV
        jsr _decV
        lda vos
        ldx vos+1

        ;; fall-through

FUNC _newvar_Y_AX_w
        pha
        lda #2
        sta tos
        lda #0
        sta tos+1
        pla
        
        ;; type
        ldy #'w'

;;; STACK: addrofname/w len/b JSR _newvar
;;; AX=addr, Y=typechar
FUNC _newvar_Y_AX
;;; ??? 70 B

        sta gos
        stx gos+1

;;; The way we keep environment/bindings of
;;; vars is by prefixing them to a rule and
;;; let our BNF parser to the matching!
;;; 
;;; In the end, not clear if save code memory
;;; as "stuffing" takes lots of bytes

;;; Register new name
;;;   (on stack %I result record pointing toname)
;;;   gos= address of variable/function/array
;;;   tos= sizeof
;;; 
;;; Result:
;;;   tos= points to %DATA
;;;   pos= points to "VARNAME" in source (unverified)
;;;   (these values used by _stuffarray_c/w)
;;;     gos= address of data
;;;     dos= 0
FUNC _newname
;;;             >>>  %b%'3<ADDRw><TYPEc>| <<<

;;; TODO: push 0, NAME..., 3+128, A, X, Y, '|'
;;; 
;;;           and then have loop "stuff it" till 0?
;;;           (A or X could be zero ... so minimal 3?)
;;; 
        sty savex
        ldy #0

        ;; store a '|' to end sub-match
        lda #'|'
        jsr _stuffVARS

;;; TODO: skipper wrong?
        ;; dummy 1 byte non-zero at end, LOL
        lda #255
        jsr _stuffVARS

        ;; push sizeof of var (other data func)
        lda tos+1
        jsr _stuffVARS
        lda tos
        jsr _stuffVARS
        
        ;; store type letter (last!)
        lda savex
        jsr _stuffVARS

        ;; store address of var
        lda gos+1               ; hi
        jsr _stuffVARS
        lda gos                 ; lo
        jsr _stuffVARS

        ;; store skip chars "%<3+128>"
        lda #6+128              ; 3 bytes to skip
        jsr _stuffVARS
        lda #'%'
        jsr _stuffVARS

        ;; save pointer to here in tos
        lda _ruleVARS
        sta tos
        lda _ruleVARS+1
        sta tos+1

        ;; store skip 'breakchar' "%b"
        lda #'b'            ; 3 bytes to skip
        jsr _stuffVARS
        lda #'%'
        jsr _stuffVARS

        ;; copy varname BACKWARDS from address on stack
        ;; - len
        pla
        tay
        ;; - address of name (lo, hi)
        pla
        sta pos
        pla
        sta pos+1

        dey
:       


        lda (pos),y

.ifdef DEBUGNAME
;;; prints reverse...
PUTC 'C'
jsr _printchar
.endif ; DEBUGNAME

        ;; TODO: clumsy?
        sty savey
        ldy #0
        jsr _stuffVARS          ; A preserved and => flags
        ldy savey

        dey
        bpl :-

.ifdef PRINTNAME
        ldy #1
:       
        ;; print name
        lda (_ruleVARS),y
        beq :+
        cmp #'%'
        beq :+
        jsr putchar
        iny
        jmp :-
:       
        jsr spc
.endif ; PRINTNAME

updatevars:     
        ;; update VARRRULEVEC
;;; TODO: too much work... save there waste here?
        lda _ruleVARS
        ldx _ruleVARS+1
;;; TODO: why are we adding one again?
        clc
        adc #1
        sta VARRRULEVEC
        txa
        adc #0
        sta VARRRULEVEC+1

storecurF:      
        ;; store "current function ptr"
        ;; TODO: minimize if can do earlier?
        lda savex               ; bit can test SV
        ;; ?array ???
        ;; ?function
        cmp #'F'
        bne @done
        ;; - is Function store in curF
        ;; (used for skipping over local)
        ldx _ruleVARS+1
        ldy _ruleVARS
        iny
        sty curF
        bne :+
        inx
:       
        stx curF+1
@done:       
        ;; needed to count array size
        lda #0
        sta dos
        sta dos+1

        jmp _next


;;; nparam*2 => tos (bytes)
FUNC _calcsubY
        lda nparam
        sta tos
        asl tos

        jmp _next


FUNC _hideargs
;        PUTC '?'
;        jmp _next
;        jmp updatevars
        
        ;; stuff %'N paramC paramB paramA >> funcF
        ;;           <----------N----------->
        ;; put new rule address
        ;; (have to put values from the BACK!)
;;; TODO: generalize?
        lda curF+1
        jsr _stuffVARS
        lda curF
        jsr _stuffVARS

        ;; "%R"
;;; TODO: generalize?
        lda #'R'
        jsr _stuffVARS
        lda #'%'
        jsr _stuffVARS

        jmp updatevars


;;; will FAIL if identifier isn't array
;;; (pointer give error too)
checkisarray:
        ;; array is not in zeropage
        cpx #0
        bne :+
        ;; not array (a-z)
        jmp _fail
:       
        jmp _next
        

;;; call with "%" jsr ...
_stuffarray_w:  
        jsr _stuffarray_c
        lda tos+1
        SKIPTWO
_stuffarray_c:  
        lda tos
        ldy #0
        sta (gos),y
        ldx #gos
        jsr _incRX
        jsr _incD               ; count of bytes
        rts

;;; pos= after array data
;;; dos= size in bytes of array data
;;; tos= ^ENV-array record to update size in
_newarr_updatesize:
        lda dos
        ldy #3
        sta (tos),y

        lda dos+1
        iny
        sta (tos),y
        
        rts
        


;;; will give ERROR! if tos address is local
disallowlocal:
.ifdef ZPVARS
.scope
        lda tos
        ldx tos+1
        bne isarray
        cmp #endparams
        bcs notstackedparameter
        ;; is a params address
        ;; (These can't be pointed to as they might be saved
        ;;  on the stack by other safe/recursive caller)
localerror:     
        lda #'L'
        jmp error
        
        
notstackedparameter:
isarray:
        jmp _next

.endscope
.else
        .assert("disallowlocal: for !ZPVARS")
.endif ; ZPVARS

negateLOVAL:
        lda #0
        sec
        sbc tos
        sta tos

        jmp _next


FUNC _dummy

        
;;;                  M A I N
;;; ========================================

endfirstpage:        
_endfirstpage:


FUNC _dummy4

;;; END CHEAT?

FUNC _bnfinterpend




;;; NO-need align...
;  .res 256-(* .mod 256)
secondpage:     

;;; TODO: still part of parse.bin
;;;    just not in screen display form firstpage/secondpage

;;; BEGIN CHEAT? - not count...



bytecodes:      

;;; ========================================
;;; START rules


.macro CHARCHECK addr,char
  .assert (<addr <> char),error,"%% XJSR addr - bad lo']'"
  .assert (>addr <> char),error,"%% XJSR addr - bad hi']'"
.endmacro

.macro CHECK addr
;;; can't give good error message...
;;        CHARCHECK(addr,']')

  .assert (<addr <> '<'),error,"%% RULE addr - bad lo'<'"
  .assert (>addr <> '<'),error,"%% RULE addr - bad hi'<'"

  .assert (<addr <> '>'),error,"%% RULE addr - bad lo'>'"
  .assert (>addr <> '>'),error,"%% RULE addr - bad hi'>'"

  .assert (<addr <> '+'),error,"%% RULE addr - bad lo'+'"
  .assert (>addr <> '+'),error,"%% RULE addr - bad hi'+'"

  .assert (<addr <> 'D'),error,"%% RULE addr - bad lo'D'"
  .assert (>addr <> 'D'),error,"%% RULE addr - bad hi'D'"

  .assert (<addr <> 'd'),error,"%% RULE addr - bad lo'd'"
  .assert (>addr <> 'd'),error,"%% RULE addr - bad hi'd'"

  .assert (<addr <> ':'),error,"%% RULE addr - bad lo':'"
  .assert (>addr <> ':'),error,"%% RULE addr - bad hi':'"

  .assert (<addr <> ';'),error,"%% RULE addr - bad lo';'"
  .assert (>addr <> ';'),error,"%% RULE addr - bad hi';'"

  .assert (<addr <> '#'),error,"%% RULE addr - bad lo'#'"
  .assert (>addr <> '#'),error,"%% RULE addr - bad hi'#'"

  .assert (<addr <> '{'),error,"%% RULE addr - bad lo'{'"
  .assert (>addr <> '{'),error,"%% RULE addr - bad hi'{'"

  .assert (<addr <> '?'),error,"%% RULE addr - bad lo'?'"
  .assert (>addr <> '?'),error,"%% RULE addr - bad hi'?'"

.endmacro

.macro XJSR addr
        CHECK(addr)
        jsr addr
.endmacro
        



;;; ------------------------------=


FUNC _rulesstart

;;; Rules 0,A-
_rules:  
        .word rule0             ; TODO: if we use &and?
        .word ruleA,ruleB,ruleC,ruleD,ruleE
        .word ruleF,ruleG,ruleH,ruleI,ruleJ
        .word ruleK,ruleL,ruleM,ruleN,ruleO
        .word ruleP,ruleQ,ruleR,ruleS,ruleT
        .word ruleU,ruleV,ruleW,ruleX,ruleY
        .word ruleZ
        .word ruleLeftBracket,ruleBackSlash,ruleRightBracket
        .word ruleCeiling,ruleUnderScore
.ifdef EXTRARULES
;;; TODO: currently rule indirect address is calculated
;;;   with AND #31... add code (EOR 31?)
        ;; ...a-z... 96-127
        .word ruleBackTick
        .word rule_a,rule_b,rule_c,rule_d,rule_e
        .word rule_f,rule_g,rule_h,rule_i,rule_j
        .word rule_k,rule_l,rule_m,rule_n,rule_o
        .word rule_p,rule_q,rule_r,rule_s,rule_t
        .word rule_u,rule_v,rule_w,rule_x,rule_y
        .word rule_z
        .word ruleLeftCurly,ruleBar,ruleRigthCurlt
        .word ruleTilde,ruleDel
.endif ; EXTRARULES
        .word 0                 ; TODO: needed?

;rule0: use ruleP
;ruleA: Aggregate statement
;ruleB: Block

;ruleC: start of expression
;ruleD: expr chain aDDons ... OP xxx TAILREC
;ruleE: Expression _C _D (or _U _V for bytes)

;ruleF: byte rule, keeps AX, get byte expr => Y
;ruleG: calling convention "(@tos,AX) like ruleC

;ruleH: printf parsing
;ruleI: "load byte expression" - opt
;ruleJ: "read byte expression, saving AX totos and sets Y=0"

;ruleK: list of var defined
;ruleL: one parmeter function call optimization
;ruleM: do ... while expressions (M is upside down W
;ruleN: - program var decl
;ruleO: - first rule in program/jmp main
;ruleP: - program
;ruleQ: - array data
;ruleR: - compile formal args list (calling convention)
;ruleU: - BYTERULES variant of "ruleC" (expression)
;ruleV: - BYTERULES variant of "ruleD" (expression)
;;; --- CALLING CONVENTIONS (all return in AX)
;ruleW: = hardware stack params (JSK CALLING: pha/txa/pha)
;ruleX: = cc65 parameter list (jsr pushax), last in AX
;ruleY: = ORIC parameters init (page 2)
;ruleZ: = ORIC list of parameters (page 2)
ruleLeftBracket:
ruleBackSlash:  
ruleRightBracket:       
ruleCeiling:    
ruleUnderScore:
        .byte 0

_A='A'+128
_B='B'+128
_C='C'+128
_D='D'+128
_E='E'+128
_F='F'+128
_G='G'+128
_H='H'+128
_I='I'+128
_J='J'+128
_K='K'+128
_L='L'+128
_M='M'+128
_N='N'+128
_O='O'+128
_P='P'+128
_Q='Q'+128
_R='R'+128
_S='S'+128
_T='T'+128
_U='U'+128
_V='V'+128
_W='W'+128
_X='X'+128
_Y='Y'+128
_Z='Z'+128
_LeftBracket='['+128
_ASM=_LeftBracket
_BackSlash='\'+128
_RightBracket=']'+128
_Ceiling='^'+128
_UnderScore='_'+128


;;; Zeroth-rule
;;; NOTE: can't backtrack here! do directly other rule!
rule0:  
        .byte _P,0

;;; PROBLEM is \0 in %{ code! can't skip when _fail!!
;;; 
;;; safer if done near end of of %{ area
        

;;; Aggregate statements, terminated by "}"
ruleA:

.ifdef CUT2
        ;; PEEK '}' marks end - CUT
      .byte "%{"
        ;; peek ahead
        ldy #0                  ; danger! 0 can't skip
        lda (inp),y
        cmp #'}'
        bne :+
        jmp _acceptrule
:       
        ;; put at end "past" any 0, lol
        lda #<@next
        ldx #>@next
        sta rule
        stx rule+1
;        IMM_FAIL
        jmp _fail
@next:   
        .byte '|'
.endif ; CUT2


        ;; store a marker to see if _S failed
      .byte "%{"
        lda inp+1
        pha
        lda inp
        pha
        lda #'s'
        pha
        IMM_RET

;;; TODO: %_S ??? lol   or  %?_S  ??? or %=_S ???
        .byte _S
      
        ;; if we didn't advance inp then _S failed
      .byte "%{"
        pla
        cmp #'s'
        pla
        tax
        pla
        cmp inp+1
        bne @ok
        cpx inp
        bne @ok
@fail:
        jmp _fail
@ok:       
        IMM_RET

        ;; otherwise we try yet another _S (tailrec on _A)
        .byte TAILREC,"|",0



;;; Block
ruleB:  
        .byte "{}"

        .byte "|{",_A
.ifdef PRINTASM
      .byte "%{"
        jsr _asmprintsrc
        IMM_RET
.endif ; PRINTASM
        .byte "}"

        .byte 0


;;; START of expression:
;;;   var/const/arrayelt/funcall()
ruleC:

;;; TODO: It seems it should be useful but not
.ifnblank
        .byte "%=;",$80

;      .byte "%{"
;        PUTC '/'
       ;jmp endrule
;        IMM_RET
        
;        .byte "%R"
;        .word endC

        .byte "|"
.endif

;        .byte "%{"
;          putc ':'
;          IMM_RET

;;; TODO: these are "more" statements...
FUNC _iorulesstart

        ;; TODO: fix
        ;; dummy rule to make | start - LOL
        .byte "d43fj3"

.ifdef STDIO
;;; TODO: these don't really return anything...

        ;;  potentially first so no "|"

        ;; "IO-lib" hack
        .byte "|putu(",_E,")"
      .byte '['
        jsr _printu
      .byte ']'

        ;; compatibility

        .byte "|printf(",34,"\%u",34,",",_E,")"
      .byte '['
        jsr _printu
      .byte ']'

        .byte "|printf(",34,"\%x",34,",",_E,")"
      .byte '['
        jsr _print4h
      .byte ']'

        ;; LOL: printf("%s", s); // safe...
        .byte "|printf(",34,"\%s",34,",",_E,")"
      .byte '['
        jsr _printz
      .byte ']'

.ifdef OPTRULES
.ifdef INLINEPUTZOPT
        .byte "|putz(",34
      .byte '['
        jsr iputz
      .byte ']'
        .byte "%S)"

        ;; fputs("foo",stdout); == putz !
        ;; NO newline!
        .byte "|fputs(",34
      .byte '['
        jsr iputs
      .byte ']'
        .byte "%S,stdout)"

        .byte "|puts(",34
      .byte '['
        jsr iputs
      .byte ']'
        .byte "%S)"
.endif ; INLINEPUTZOPT
.endif ; OPTRULES

        .byte "|fputs(",_E,",stdout)"
      .byte '['
        jsr _printz
      .byte ']'

.ifdef SIGNED
        .byte "|printf(",34,"\%d",34,",",_E,")"
      .byte '['
        jsr _printd
      .byte ']'

        ;; "IO-lib" hack
        .byte "|putd(",_E,")"
      .byte '['
;;; TODO: change printers to use AX
        jsr axputd
      .byte ']'
.endif ; SIGNED

        .byte "|puth(",_E,")"
      .byte '['
;;; TODO: change printers to use AX
        jsr _printh
      .byte ']'

        .byte "|putz(",_E,")"
      .byte '['
;;; TODO: fix, strings borken?
        jsr _printz
      .byte ']'

        .byte "|puts(",_E,")"
      .byte '['
.ifdef PRINTIT
;;; 20 B inline only...
        sta pos
        stx pos+1
        ldy #0
:       
        lda (pos),y
        beq :+
        jsr putchar
        iny
        bne :-
        inc pos+1
        bne :-
:       
.else
        jsr _prints
.endif ; PRINTIT
      .byte ']'

        .byte "|putcraw(",_E,")"
      .byte '['
        jsr putcraw
      .byte ']'

.else ; !STDIO

        ;;  potentially first so no "|"

        .byte "|putz(",_E,")"
      .byte '['
        ;; 19 B inline only...
        sta pos
        stx pos+1
        ldy #0
:       
        lda (pos),y
        beq :+

;;; TODO: cleanup
.ifndef NOBIOS ; BIOS
        jsr putchar
.else ; !BIOS

  .ifdef __ATMOS__
        ;; ORIC: print character
        jsr $CCD0
  .else
        ;; I guess it's here? (non oric)
        jsr _putchar
  .endif ; __ATMOS__

.endif ;

        iny
        bne :-
        inc pos+1
        bne :-
:       
.endif ; STDIO




.ifdef OPTRULES

.ifndef NOBIOS
        ;; putchar variable - saves 2 bytes!
;;; TODO: parser skips space, hahahaha!
        .byte "|putchar('')"    ; LOL!!!!
      .byte '['
        jsr spc
;;; TODO: about return value...
      .byte ']'

        ;; putchar variable - saves 2 bytes!
        .byte "|putchar('\\n')" ;      double \\???
      .byte '['
        jsr nl
;;; TODO: about return value...
      .byte ']'

        ;; putchar variable - saves 2 bytes!
        .byte "|putchar('\\t')" ;      double \\???
      .byte '['
        jsr tab
;;; TODO: about return value...
      .byte ']'

        ;; putchar constant - saves 2 bytes!
        .byte "|putchar(%D)"
      .byte '['
        lda #'<'
        jsr putchar
;;; TODO: about return value...
      .byte ']'

        ;; putchar variable - saves 2 bytes!
        .byte "|putchar(%V)"
      .byte '['
        lda VAR0
        jsr putchar
;;; TODO: about return value...
      .byte ']'

.else
        ;; LDA #0C 11 20 3F
        ;; 11= 17dec == ???

        .byte "|putchar('')"    ; LOL!!!!
        ;; (parser skips space...)
      .byte '['
        ;; ORIC: PRINT SPACE
        jsr $CCD4
      .byte ']'

        ;; putchar newline
        .byte "|putchar('\\n')" ;      double \\???
      .byte '['
        ;; ORIC: NEWLINE
        jsr $CBF0
      .byte ']'

.endif ; !NOBIOS

.endif ; OPTRULES


.ifndef NOBIOS
        ;; potentially first so no "|"

        .byte "|putchar(",_E,")"
      .byte '['
        jsr putchar
      .byte ']'

        .byte "|getchar()"
      .byte '['
        jsr getchar
        ldx #0
      .byte ']'
.else

.ifdef __ATMOS__
        ;; potentially first so no "|"

        .byte "clrscr()"
      .byte '['
        ;; ORIC: CLS command (LDA #$0C)
        jsr $CCCE
      .byte ']'

        .byte "|putchar(",_E,")"
      .byte '['
        ;; ORIC: print character...
        jsr $CCD0 
;;; $f77c output X !
      .byte ']'

        .byte "|getchar()"
      .byte '['
;;; from oric_advanced_user_guide_rom_disassembly.pdf
;;; WARNING: it messes with address ZEROPAGE $2e ???
        ;; ORIC: READ KEY FROM KEYBOARD
;;; $c5e9 ?
;;; $f523 poll keyboard
        jsr $C5E8
        ldx #0
      .byte ']'
.else
        
.endif ; __ATMOS__
        

.endif ; !NOBIOS


FUNC _iorulesend

.ifdef CTYPE
        .byte "|isxdigit(",_E,")"
      .byte '['
        jsr isxdigit
      .byte ']'

        .byte "|isdigit(",_E,")"
      .byte '['
        jsr isdigit
      .byte ']'

        .byte "|isalnum(",_E,")"
      .byte '['
        jsr isalnum
      .byte ']'

        .byte "|isalpha(",_E,")"
      .byte '['
        jsr isalpha
      .byte ']'

        .byte "|isspace(",_E,")"
      .byte '['
        jsr isspace
      .byte ']'

        .byte "|islower(",_E,")"
      .byte '['
        jsr islower
      .byte ']'

        .byte "|isupper(",_E,")"
      .byte '['
        jsr isupper
      .byte ']'

        .byte "|ispunct(",_E,")"
      .byte '['
        jsr ispunct
      .byte ']'

        .byte "|toupper(",_E,")"
      .byte '['
        jsr toupper
      .byte ']'

        .byte "|tolower(",_E,")"
      .byte '['
        jsr tolower
      .byte ']'
.else

;;; nah,it's compiletime
;FUNC _ctypestart 
;;; TODO: _byteexpr ??? X?
        .byte "|isdigit(",_E,")"
      .byte '['
;;; 11B
;;; TODO: make library? copy in on ref
        ldy #0
        sec
        sbc #'0'
        cmp #'9'-'0'+1
        bcs :+
        iny
:       
        tya
      .byte ']'

        .byte "|isalpha(",_E,")"
      .byte '['
        ldy #0
        ;; make all lower case
        ora #32
        sec
        sbc #'a'
        cmp #'z'-'a'+1
        bcs :+
        iny
:       
        tya
      .byte ']'

        ;; we take ourselves some freedom of interpreation!
        ;; (anything <= ' ' is space, lol)
        .byte "|isspace(",_E,")"
      .byte '['
        ldy #0
        cmp #' '+1
        bcs :+
        iny
:       
        tya
      .byte ']'
;FUNC _ctypeend
;;; nah,it's compiletime
.endif ; !CTYPE


FUNC _stringrulesstart
.ifdef STRING

        .byte "|strlen(",_E,")"
      .byte '['
        jsr strlen
      .byte ']'

        ;; all these takes 2 args
        ;; TODO: harmonize?
        .byte "|strchr(",_E,",",_F,")"
      .byte '['
        jsr strAXchrY
      .byte ']'

        .byte "|strcpy(",_E,",",_G
      .byte '['
        jsr strTOScpy
      .byte ']'

        .byte "|stpcpy(",_E,",",_G
      .byte '['
        jsr stpTOScpy
      .byte ']'

        .byte "|strcat(",_E,",",_G
      .byte '['
        jsr strTOScat
      .byte ']'

        .byte "|strcmp(",_E,",",_G
      .byte '['
        jsr strTOScmp
      .byte ']'

;;; TODO: not implemented yet!
        ;; 
;        .byte "|strstr(",_E,",",_G
;      .byte '['                 
;        jsr strTOSstr
;      .byte ']'



.endif ; STRING
FUNC _stringrulesend


FUNC _memoryrulesstart

;;; ORIC peek/poke deek/doke
.ifdef OPTRULES



;;; TODO: too many |POKE( rules!!!!

;;; OK
        .byte "|poke(%d,"
        .byte "[#]",_I
      .byte "[;"
        sta '<'
      .byte "]"

;;; OK
        .byte "|poke(%D,[#]",_I
      .byte "[;"
        sta VAL0
      .byte "]"


.ifdef ZPVARS
;;; OK
        .byte "|poke(%V,0)"
      .byte "["
        ;; save 1 B
        ldy #0
        tya
        sta (VAR0),y
      .byte "]"

;;; OK
        .byte "|poke(%V,[#]",_I
      .byte "[;"
        ldy #0
        sta (VAR0),y
      .byte "]"
.endif ; ZPVARS        


;;; TOTEST
        .byte "|doke(%D[#],",_E,")"
      .byte "[;"
;;; TODO: how about zero page addresses! save 2B
        sta VAL0
        stx VAL1
      .byte "]"

.endif ; OPTRULES


;;; OK
        .byte "|poke(",_E,",",_J
      .byte "["
        sta (tos),y
      .byte "]"

;;; TOTEST
        .byte "|doke(",_E,",",_G
      .byte "["
        ;; AX: value to doke
        ;; tos: addrss to put it
      .byte "["
        ldy #0
        sta (tos),y

        txa
        iny
        sta (tos),y
      .byte "]"


.ifdef OPTRULES
        .byte "|peek(%D)"
      .byte '['
        lda VAL0
        ldx #0
      .byte ']'

        .byte "|deek(%D)"
      .byte '['
        lda VAL0
        ldx VAL1
      .byte ']'
.endif ; OPTRULES

        .byte "|peek(",_E,")"
      .byte '['
        sta tos
        stx tos+1
        ldy #0
        lda (tos),y
        ldx #0
      .byte ']'

        .byte "|deek(",_E,")"
      .byte '['
        sta tos
        stx tos+1
        ldy #1
        lda (tos),y
        tax
        dey
        lda (tos),y 
      .byte ']'


;.ifdef NONO_cc65_STDLIB
.ifdef STDLIB

;;; TODO: cheating, using cc65 malloc/free :-(

        ;; gives error if run out of memory
        .byte "|xmalloc(",_E,")"
      .byte "["
        jsr _xmalloc
      .byte "]"

        ;; return NULL if failed...
        .byte "|malloc(",_E,")"
      .byte "["
        jsr _malloc
      .byte "]"

        .byte "|free(",_E,")"
      .byte "["
        .import _free
        jsr _free
      .byte "]"

        .byte "|realloc(",_E,")"
      .byte "["
        .import _realloc
        jsr _realloc
      .byte "]"

.else

        ;; Simple dummies
        ;; (just allocate directly after code, no free()) 

        .byte "|xmalloc(",_E,")"
;;; TODO: this is exactly the same as malloc
;;;   how to fix
      .byte "["
        ;; 21 B  33c - works!
        sta savea
        stx savex

        lda _out
        tay
        
        clc
        adc savea
        sta _out
        
        lda _out+1
        tax
        adc savex
        sta _out+1
        
        ;; TODO: test if run-out of memory
        tax
        tya     
      .byte "]"

        .byte "|malloc(",_E,")"
      .byte "["
SMALLER=1
.ifdef SMALLER
;;; 21 B  33c - works!
        sta savea
        stx savex

        lda _out
        tay
        
        clc
        adc savea
        sta _out
        
        lda _out+1
        tax
        adc savex
        sta _out+1
        
        ;; TODO: test if run-out of memory
        tax
        tya     
.else        
;;; 21 B   42c per call! ; - DOESN'T WORK????
        tay
        ;; save return pointer
        lda _out
        pha
        lda _out+1
        pha

        tya
        
        ;; move "heap" ahead
        clc
        adc _out
        sta _out
        txa
        adc _out+1
        sta _out+1
        
        ;; restore pointer
        pla
        tax
        pla
.endif
      .byte "]"

        .byte "|free(",_E,")"
      .byte "["
        ;; nothing to do, lol
      .byte "]"

        ;; NONO!
        ;.byte "|realloc",_X

.endif ; STDLIB


;;; TODO: fix?

.ifdef NOTDEFINEDIN_CC65 ; ???
.import _heapmemavail
        .byte "|heapmemavail",_X
      .byte "["
        jsr _heapmemavail
      .byte "]"

.import _heapmaxavail
        .byte "|heapmaxavail",_X
      .byte "["
        jsr _heapmaxavail
      .byte "]"
.endif

FUNC _memoryrulesend



FUNC _funcallstart

;.include "lib-runtime-funcall.asm"


;;; TODO: not fully correct, as if it's a
;;;   normal variable, it'd jump to that variable
;;;   address??? LOL

        ;; CALL fun() { ... }
        .byte "|%V()"
      .byte "["
        DOJSR VAL0
      .byte "]"

        .byte "|%V([#]",_E,_L,"[;]"

FUNC _funcallend


;;; TODO: a&!b .. hmmmm
        ;; ! - NOT
;;; TODO: "!%V" ...?
;;; TODO: !(...) more safe?
        .byte "|!",_E
      .byte "["
        ;; 12 B
        ldy #0
        cmp #0
        bne @false
        txa
        bne @false
@true:  
        dey
@false:
        tya
        tax
      .byte "]"

        ;; cast to char == &0xff !
        .byte "|(char)",_C
      .byte '['
        ldx #0
      .byte ']'

        ;; casting - ignore!
        ;; (we don't care legal, just accept if correct)
;;; TODO: lol funny way of skipping name/id/type
        .byte "|(%V\*)",_C

        
.ifdef OPTRULES
        ;; char array index [const]
        .byte "|%V[#]"
        IMMEDIATE checkisarray
        .byte "\[%d\]"
      .byte "["
        ;; 6 B
;;; TODO: can optimize, fold tos=LOVAL+VARRAY!
;;;   would save one byte, but youd allow for %D
        ldx #LOVAL
        .byte ";"
        lda VARRAY,x
        ldx #0
      .byte "]"

        ;; char array index [char var]
        .byte "|%V[#]"
        IMMEDIATE checkisarray
        .byte "\[(char)%V\]"
      .byte "["
        ;; 6 B
        ldx VAR0
        .byte ";"
        lda arr,x
        ldx #0
      .byte "]"

        ;; char array index [char]
        .byte "|%V[#]"
        IMMEDIATE checkisarray
        .byte "\[(char)",_E,"\]"
      .byte "[;"
        ;; 5 B
        tax
        lda VAR0,x
        ldx #0
      .byte "]"
.endif ; OPTRULES

;;; TODO: word[] - word array

        ;; char array index [word]
        ;; (most generic and expensive)
        .byte "|%V[#]"
        IMMEDIATE checkisarray
        .byte "\[",_E,"\]"
      .byte "[:"
        ;; 16 B
        ;; calculate address
        clc
        adc #LOVAL
        sta tos
        txa
        adc #HIVAL
        sta tos+1
        
        ;; load it
        ldy #0
        lda (tos),y
        ldx #0
      .byte "]"

        ;; ?pointer, as it wasn't array
        .byte "|%V[#]"
        ;; LOL: we will happily use any var as ponter!
        .byte "\[",_E,"\]"
      .byte "[:"
        ;; 16 B
        ;; calculate address
        clc
        adc VAR0
        sta tos
        txa
        adc VAR1
        sta tos+1
        
        ;; load it
        ldy #0
        lda (tos),y
        ldx #0
      .byte "]"




        ;; Surprisingly ++v and --v expression w value
        ;; arn't smalller or faster than v++ and v-- !
        .byte "|++%V"
      .byte '['
;;; 10B 14-18c
        inc VAR0
        bne :+
        inc VAR1
:       
        lda VAR0
        ldx VAR1
      .byte ']'

        .byte "|--%V"
      .byte '['
.ifblank
;;; 12B 17-21c
        lda VAR0
        bne :+
        dec VAR1
:       
        dec VAR0
        lda VAR0
        ldx VAR1
.else
;;; 13B 16-20c
        ldx VAR1
        ldy VAR0
        bne :+
        dex
        stx VAR1
:       
        dey
        tya
        sta VAR0
.endif
      .byte ']'

        .byte "|%V++"
      .byte '['
;;; 10B ! 14-18c ! - no extra cost!
        lda VAR0
        ldx VAR1
        inc VAR0
        bne :+
        inc VAR1
:       
      .byte ']'

        .byte "|%V--"
      .byte '['
.ifblank
;;; 10B ! 14-18c
        ldx VAR1
        lda VAR0
        bne :+
        dec VAR1
:       
        dec VAR0
.else
;;; 13B 16-20c
        ldx VAR1
        ldy VAR0
        dey
        tya
        bne :+
        dex
        stx VAR1
:       
        sta VAR0
.endif
      .byte ']'

;;; cc65: get parameter value from subroutine
;000055r 1  A0 01        	ldy     #$01
;000057r 1  B1 rr        	lda     (sp),y
;000059r 1  88           	dey
;00005Ar 1  11 rr        	ora     (sp),y
;;; probably have to turn it around

;;; TDOO: $ arr\[\] ... redundant?
;;; TODO: store addresss of arr in variable

        ;; variable
        .byte "|%V"
      .byte '['
        lda VAR0
        ldx VAR1
      .byte ']'

        .byte "|'\\n'"
;      .byte "%{"
;        putc '!'
;        IMM_RET

      .byte '['
        lda #10
        ldx #0
      .byte ']'

.ifnblank
        .byte "|"

      .byte "%{"
        putc '"'                ; "
        IMM_RET

        .byte "'"
      .byte "%{"
        putc '1'
        IMM_RET

        .byte "\\"               ; "
      .byte "%{"
        putc '2'
        IMM_RET

        .byte "n"
      .byte "%{"
        putc '3'
        IMM_RET

        .byte "'"
        
;      .byte "%{"
;        putc '!'
;        IMM_RET

      .byte '['
        lda #10
        ldx #0
      .byte ']'
.endif

.ifdef OPTRULES
        ;; load 0 saves 1 byte
        .byte "|0%b"
      .byte '['
        lda #0
        tax
      .byte ']'
.endif ; OPTRULES

        ;; digits
        .byte "|%D"
      .byte '['
        lda #'<'
        ldx #'>'
      .byte ']'
        


;;; TODO:       FAILS on sim65 !

;;; fine on ORIC - why?
;;; 
;;; It seems the address is 3 bytes too small,
;;; (if it was 2 it'd make sense as it's what PUSHLOC
;;;  is, but it ISN'T!)
;;; 
;;; possiblities:
;;;  a) addresses of vars are different?
;;;     (could interact w %{ but I tested
;;;      using subroutines, doesn't seem to bit it)
;;;  b) somebody is modifying DOS? (lo byte)
;;;  c) 


;;; Simpliest for now

;;; TODO: remove routines at endrules
POS=gos

.ifblank
        .byte "|",34            ; " character
parsestring:    
      .byte "["
        ;; jump over inline string
        jmp PUSHLOC             ; Branch ?1
        .byte ":"               ; start of string ?0
      .byte "]"               

        ;; copy string to out
        .byte "%S"
        
      .byte "[?1B"      ; patch Branch to after string
        .byte "?0"      ; load string address
        lda #LOVAL
        ldx #HIVAL
      .byte ";;]"
.else
;;; TODO: almost works, but 2 bytes too much
;;;   (pointing to path point!)
        .byte "|",34            ; " character
      .byte "["
        ;; jump over inline string
        jmp PUSHLOC
      .byte "]"               
        ;; copy string to out
        .byte "%S"
        ;; branch to after string!
      .byte "[;B"
        ;; load string address
        lda #LOVAL
        ldx #HIVAL
      .byte "]"
.endif



.ifdef STRING_DIDNTWORK_ON_EITHER
;.ifdef STRING
;;; TODO: remove routines at endrules
POS=gos

        .byte "|",34            ; " character
      .byte "["
        ;; jump over inline string
        jmp PUSHLOC
        .byte ":;d;"
      .byte "]"

        ;; TODO: make a "swap" code
      .byte "%{"
        lda tos
        ldy dos
        sta dos
        sty tos

        lda tos+1
        ldy dos+1
        sta dos+1
        sty tos+1

        IMM_RET

        ;; push str addr back on stack
        .byte "[#D]"

        ;; copy string to out
        .byte "%S"

        ;; TODO: make a patch routine
      .byte "%{"
        ;; patch jump to here
        lda _out+1
        ldy #1
        sta (tos),y

        lda _out
        dey
        sta (tos),y

        IMM_RET

      .byte "[;"
        lda #'<'
        ldx #'>'
      .byte "]"
.endif ; STRING




;;; TODO: only works on ORIC, sim65 fails... wtf?

.ifdef STRING_HMM
POS=gos ;works
;POS=pos ;workd
;POS=dos ; FAILS! who messes with dos?

        .byte "|",34            ; " character
      .byte "["
        ;; jump over inline string
        jmp PUSHLOC
        .byte ";"               ; TOS= PUSHLOC
      .byte "]"

      .byte "%{"                ; POS= addr of str
        jsr TOS2POS
        IMM_RET

        ;; copy string to out
        .byte "%S"

      .byte "%{"
        jsr TOSpatch
        jsr POS2TOS             ; TOS= POS
        IMM_RET

      .byte "["
        lda #'<'
        ldx #'>'
      .byte "]"
.endif ; STRING


;;; TODO: debug why dos get's changed value? (sometimes?)

.ifdef STRING_DEBUG
;.ifdef STRING
        .byte "|",34            ; " character
      .byte "["
        jmp PUSHLOC

;;; neither works on sim65... lol

POS=gos ;works
;POS=pos ;workd
;POS=dos ; FAILS! who messes with dos?

.ifndef POS
        .byte ":;d;"
      .byte "]"
.else
        .byte ";"               ; load PUSHLOC in tos
      .byte "]"

      .byte "%{"
        lda _out
        sta POS
        ldx _out+1
        stx POS+1
        IMM_RET
.endif ; POS

        .byte "%S"

      .byte "%{"
        ;; tos = PUSHLOC
        ;; dos = string address
        
        ;; patch jmp (over string) to here
        ldy #1                  ; void inline 0 !!! LOL
        lda _out+1
        sta (tos),y
        dey
        lda _out
        sta (tos),y
        
.ifdef POS
        lda POS
        sta tos
        lda POS+1
        sta tos+1
        IMM_RET
      .byte "["
.else
        IMM_RET
      .byte "[D"
.endif ; POS

        jsr nl
;        putc 'D' ;ugh!!!!
        putc '/'
        ;; load string address
        lda #'<'
        ldx #'>'
;;; print it just to see!
        sta tos
        stx tos+1
jsr puth
        ldy #0
:       
        lda (tos),y
        beq :+
        jsr putchar
        iny
        bne :-
:       
        jsr nl

        lda #'<'
        ldx #'>'
      .byte "]"

      .byte "%{"
        jsr nl
        jsr nl
        
      lda dos
      ldx dos+1
      jsr axputh
        IMM_RET

.endif ; STRING_DEBUG



;;; TODO: maybe no need this operator at all?
;;;   only case to allow pointer to variable
;;;   is only useful/safe for arrays!
;;; 
;;; pointer

;;; TODO: restrict pointer to "local"
;;;   variables (as they are copied and reused
;;;   in zeropage!)
        .byte "|&%V"
        IMMEDIATE disallowlocal
      .byte "["
        lda #LOVAL
        ldx #HIVAL
      .byte "]"


        .byte "|\*%V"
      .byte '['
.ifdef ZPVARS
        ldx #0
        ;; 1c more than (),y but sets X=0 for free!
        lda (VAR0,x)
.else
        lda VAR0
        sta tos
        lda VAR1
        sta tos+1

        ldx #0
        ;; 1c more than (),y but sets X=0 for free!
        lda (tos,x)
.endif
      .byte ']'


;;; last chance, try BYTERULES
;;; TODO: is this sane? doesn't seem to be triggerled?

.ifdef BYTERULES
        ;; BYTERULES
;;; TODO: if no match backtrack not propagated UP????
        .byte "|", _U
      .byte '['
;;; TODO: look into this...
;;; PRIMEBYTE: TODO: this adds 10bytes!!!! lol 313->323
;;; but sim: correct, and oric!
        ldx #0
      .byte ']'
.endif

endC:   

        .byte 0



;;; aDDons (::= op %d | op %V)
ruleD:

;;; TODO: generalize!

.ifdef CUT
        ;; "CUT" operator
        ;; if the next character is ,:;)]?
        ;; expression is ended
;;; BYTESIEVE:
;;;   3450146 before
;;;   2862018 cut only in ruleD
;;;   (/ 2862018 3430146.0)
;;; 
;;;   16.6% faster


      .byte "%{"
        jsr cut
        jmp _acceptrule

;;; TODO: use new %!

breakchars:
        ;; '|'+128 so not conflict with '|', not 0!
        .byte ",:;)]?",'|'+128

        .byte "|"
nextrule:       
.endif ; CUT

FUNC _oprulesstart
        ;; 7=>A; // Extention to C:
        ;; Forward assignment 3=>a; could work! lol
        ;; TODO: make it multiple 3=>a=>b+7=>c; ...
        .byte "=>%V"
      .byte "["
        sta VAR0
        stx VAR1
      .byte "]"
        .byte TAILREC


        ;; EXTENTION
        ;; .method call! - LOL
        .byte "|.%V"
      .byte '['
        ;; parameter already in AX
        DOJSR VAL0
      .byte ']'
        .byte TAILREC





        .byte "|+%V"
      .byte '['
        clc
        adc VAR0
        tay
        txa
        adc VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

.ifdef OPTRULES
        ;; +BYTE
        .byte "|+%d"
      .byte '['
;;; 6 B
        clc
        adc #'<'
        bcc :+
        inx
:
      .byte ']'
        .byte TAILREC
.endif ; OPTRULES

        .byte "|+%D"
      .byte '['
;;; 9 B
        clc
        adc #'<'
        tay
        txa
        adc #'>'
        tax
        tya
      .byte ']'
        .byte TAILREC

;;; 18 *2
        .byte "|-%V"
      .byte '['
        sec
        sbc VAR0
        tay
        txa
        sbc VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

.ifdef OPTRULES
        ;; -BYTE
        .byte "|-%d"
      .byte '['
;;; 6 B
        sec
        sbc #'<'
        bcs :+
        dex
:       
      .byte ']'
        .byte TAILREC
.endif ; OPTRULES

        .byte "|-%D"
      .byte '['
;;; 9 B
        sec
        sbc #'<'
        tay
        txa
        sbc #'>'
        tax
        tya
      .byte ']'
        .byte TAILREC

;;; 17 *2
        .byte "|&%V"
      .byte '['
        and VAR0
        tay
        txa
        and VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

.ifdef OPTRULES
        .byte "|&0xff00%b"
      .byte '['
        lda #0
      .byte ']'
        .byte TAILREC

        .byte "|&0xff%b"
      .byte '['
        ldx #0
      .byte ']'
        .byte TAILREC

        .byte "|&%d%b"
      .byte "["
        and #'<'
        ldx #0
      .byte "]"
        .byte TAILREC
.endif ; OPTRULES


.ifdef MATH

.ifdef OPTRULES
        ;; most common?
        .byte "|*%d"
      .byte "["
        ;; 5 B
        ldy #LOVAL
        jsr _mulAXyAX
      .byte "]"
        .byte TAILREC

        .byte "|*%D"
      .byte "["
        ;; 15 B
        sta tos
        stx tos+1
        lda #LOVAL
        ldx #HIVAL
        sta dos
        stx dos+1
        jsr _mul
      .byte "]"
        .byte TAILREC
.endif ; OPTRULES

        .byte "|*"
        ;; 16 B
      .byte "["
        pha
        txa
        pha
      .byte "]"
        .byte _E
      .byte "["
        sta dos
        stx dos+1
        pla
        sta tos+1
        pla
        sta tos
        jsr _mul
      .byte "]"
        .byte TAILREC

.endif ; MATH


        .byte "|&%D"
      .byte '['
        and #'<'
        tay
        txa
        and #'>'
        tax
        tya
      .byte ']'
;;; TODO: see FORDEBUG
;;;    if have this enabled then prase will loop >D>*>*>*...
;;;       why? we have and empty alt at end...
;        .byte TAILREC

.ifnblank
;;; TODO: \ quoting
;;; 17 *2
        .byte "|\|%V"
      .byte '['
        ora VAR0
        tay
        txa
        ora VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

        .byte "|\|%D"
      .byte '['
        ora #'<'
        tay
        txa
        ora #'>'
        tax
        tya
      .byte ']'
        .byte TAILREC
.endif ; NBLANK

;;; 17 *2
        .byte "|^%V"
      .byte '['
        eor VAR0
        tay
        txa
        eor VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

        .byte "|^%D"
      .byte '['
        eor #'<'
        tay
        txa
        eor #'>'
        tax
        tya
      .byte ']'
        .byte TAILREC

;;; 24
        
        .byte "|/2%b"
      .byte '['
;;; 6B 12c
        tay
        txa
        lsr
        tax
        tya
        ror
      .byte ']'
        .byte TAILREC

        .byte "|*2%b"
      .byte '['
;;; 6B 12c
        asl
        tay
        txa
        rol
        tax
        tya
      .byte ']'
        .byte TAILREC

.ifdef OPTRULES
        .byte "|>>8%b"
      .byte '['
        txa
        ldx #0
      .byte ']'
        .byte TAILREC

        .byte "|<<8%b"
      .byte '['
        tax
        lda #0
      .byte ']'
        .byte TAILREC
        
        .byte "|<<1%b"
      .byte '['
.ifblank
;;; 6B 12c
        asl
        tay
        txa
        rol
        tax
        tya
.else
;;; 7B 13c
        stx tos+1
        asl
        rol tos+1
        ldx tos+1
.endif
      .byte ']'
        .byte TAILREC

        .byte "|<<2%b"
      .byte '['
;;; 10B
        stx tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|<<3%b"
      .byte '['
;;; 13B= 4+3*n    15=4+3*n => n=11/3=4-
        stx tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|<<4%b"
      .byte '['
;;; 16B
        stx tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|>>1%b"
      .byte '['
.ifblank
;;; 6B 12c
        tay
        txa
        lsr
        tax
        tya
        ror
.else
;;; 7B 13c
        stx tos+1
        lsr tos+1
        ror
        ldx tos+1
.endif
      .byte ']'
        .byte TAILREC

        .byte "|>>2%b"
      .byte '['
;;; 10B
        stx tos+1
        lsr tos+1
        ror
        lsr tos+1
        ror
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|>>3%b"
      .byte '['
;;; 13B
        stx tos+1
        lsr tos+1
        ror
        lsr tos+1
        ror
        lsr tos+1
        ror
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|>>4%b"
      .byte '['
;;; 16B
        stx tos+1
        lsr tos+1
        ror
        lsr tos+1
        ror
        lsr tos+1
        ror
        lsr tos+1
        ror
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|<<%D"
      .byte '['
;;; 15B (breakeven: D=4-)
        stx tos+1
        ldy #'<'
:       
        dey
        bmi :+
        
        asl
        rol tos+1

        sec
        bcs :-
:       
        ldx tos+1
      .byte ']'
        .byte TAILREC

;;; TODO: so many duplicates...
;;;   can just do _C or _E ? priorities?
        .byte "|<<%V"
      .byte '['
;;; 15B (breakeven: D=4-)
        stx tos+1
;;; TODO: this is only difference...
;;;   IDEA: emit subroutine and remember;
;;;         incremental library buildup?
        ldy VAR0
:       
        dey
        bmi :+
        
        asl
        rol tos+1

        sec
        bcs :-
:       
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|>>%D"
      .byte '['
;PUTC '/'
;;; 15B (breakeven: D=4-)
        stx tos+1
        ldy #'<'
:       
        dey
        bmi :+
        
        lsr tos
        ror

        sec
        bcs :-
:       
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|>>%V"
      .byte '['
;;; 15B (breakeven: D=4-)
        stx tos+1
        ldy VAR0
:       
        dey
        bmi :+
        
        lsr tos
        ror

        sec
        bcs :-
:       
        ldx tos+1
      .byte ']'
        .byte TAILREC
.endif ; OPTRULES

;;; COMPARISIONS

;;; TODO: really shouldn't give -1 lol
        .byte "|==%V%=,;)?",$80
      .byte '['
        ;; 15
        ldy #0
        cmp VAR0
        bne :+
        cpx VAR1
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
        tax
      .byte ']'
        .byte TAILREC


;;; TODO: is one byte saved worth it?
        .byte "|==%d","%=,;)?",$80
      .byte '['
        ;; 12 (saves one byte...)
        ldy #0
        cmp #'<'
        bne :+
        txa
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
        tax
      .byte ']'
        .byte TAILREC

        .byte "|==%D","%=,;)?",$80 ; end of expression
;        .byte "|==%D"
      .byte '['
        ;; 13
        ldy #0
        cmp #'<'
        bne :+
        cpx #'>'
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
        tax
      .byte ']'
        .byte TAILREC

        ;; general
        .byte "|=="
      .byte '['
        pha
        txa
        pha
      .byte ']'
        .byte _E
      .byte '['
        ;; 7
        sta tos
        stx tos+1

        pla
        txa
        pla

.ifblank
        ;; 15
        cmp tos
        bne @false
        cpx tos+1
        bne @false
@true:
        lda #1
        SKIPTWO
@false:       
        lda #0
        ldx #0
.else

        ;; 23 no add 5
        tay
        txa

        tsx
        cpy $101,x
        bne @false
        cmp $100,x
        bne @false
@true:
        ;; C=1
        SKIPONE
@false:
        clc
        pla
        pla

        ldx #0
        txa
        ror                     ; A=C
        eor #1
        

;;; All these add 7
        

        ;; 12
        cmp tos
        bne @false
        cpx tos+1
        bne @false
@true:
        ;; C=1 !!!
        SKIPONE
@false:
        clc
        tax
        ror
        
  
        

        ;; 13
        ldy #0
        cmp tos
        bne :+
        cpx tos+1
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
        tax
      .byte ']'
        .byte TAILREC


;;; >=  7+ 9
        sta tos
        stx tos+1
        pla
        tax
        pla
        
        ;; 9 !!!
        cmp tos
        tax
        sbc tos+1
        ldx #0
        txa
        ror
.endif ; blank
        .byte "]"

;;; TODO: signed?
;;;    v < -42      => signed comparison
;;;    v < 32767    => SIGNED!
;;;    v < 40000    => UNSIGNED !
;;; 
;;;    v > 0        ?? impllies test for negative?
;;; 
;;; How to ipmlement signed comparison on 6502
;;; - just eor #$80 hi-byte of both values?
;;; 


;;; TODO: something messed up here? | ignored?

        .byte "|<%V%=,;)?",$80
      .byte '['
        ;; 11
        cmp VAR0
        tax
        sbc VAR1
        ;; A= !C, lol
        ldx #0
        txa
        ror
        eor #1
      .byte ']'


        .byte "|>=%V%=,;)?",$80
      .byte '['
        ;; 11
        cmp VAR0
        tax
        sbc VAR1
        ;; A= C, lol
        ldx #0
        txa
        ror
      .byte ']'


        ;; < constant
        ;; (42 -> 28 bytes) saves 34 bytes cmp general
        .byte "|<%D"
        ;; Restrict to only at end of expression
        ;; (correct but might miss some)
        .byte "%=,;)?",$80
      .byte '['
        ;; 11
        cmp #LOVAL
        tax
        sbc #HIVAL
        ;; A= !C, lol
        ldx #0
        txa
        ror
        eor #1
      .byte ']'

;;; TODO: is $80 safe, or gets interrpreted as 0 some time?
        .byte "|>=%D%=,;)?",$80
      .byte '['
        ;; 11
        cmp #LOVAL
        tax
        sbc #HIVAL
        ;; A= C, lol
        ldx #0
        txa
        ror
      .byte ']'

        ;; general
        ;; (21 B)
        .byte "|>="
      .byte '['
        ;; 3
        pha
        txa
        pha
      .byte ']'
        .byte _E
      .byte '['
        ;; 7
        sta tos
        stx tos+1
        
        pla
        tax
        pla

        ;; 11
        cmp tos
        tax
        sbc tos+1
        ;; A= C, lol
        ldx #0
        txa
        ror
      .byte ']'

        ;; general
        .byte "|<"
      .byte '['
        pha
        txa
        pha
      .byte ']'
        .byte _E
      .byte '['


.ifblank
.scope
;;; < 18 bytes!

        ;; 7 B
        sta tos
        stx tos+1

        pla
        tax
        pla

        ;; 11 B
        cmp tos
        txa
        sbc tos+1

        ldx #0
        txa
        rol
        eor #1
.endscope

.else
        

        ;;
        tay
        pla
        

        ;; 17 (but reverse?)
        stx tos
        tsx
        cmp $00fe,x
        lda tos
        sbc $00ff,x
        pla
        pla
        ldx #0
        txa
        rol


;;; minimalist computing - Alan Cashin
;;; 18 B
        stx tos
        tsx
        sec
        sbc $00fe,x
        lda tos
        sbc $00ff,x
        pla
        pla
        ldx #0
        txa
        rol
        ;; eor #1
        
        


;;; <= 17 bytes!!!
.scope
        ;; 7
        tay
        pla
        sta tos+1
        pla
1        sta tos
        
        ;; 10
        ;; reverse cmp
        cpx tos+1
        bne @done
        cpy tos
@done:
        ldx #0
        txa
        rol
        
.endscope


;;; < 19 bytes
        ;; 7
        sta tos
        stx tos+1
        
        pla
        tax
        pla

        ;; 12
        ;; hi
        cpx tos+1
        bne @done
        ;; equal or
        ;; lo
        cmp tos
@done:
        ldx #0
        txa
        rol
        eor #1


.scope
; ;; posted on minimalist computing

;;; < 22 bytes
        sta tos                         ; zero page
        stx tos+1

        pla
        tax
        pla

        sec
        sbc tos
        txa
        sbc tos+1
        bcs false
true:
        lda #1
        SKIPTWO
false:
        lda #0
        ldx #0
.endscope

;;; < 7+11=18 B  16c
        cmp tos
        txa
        sbc tos+1
        ldx #0
        ;; A= !C flag!
        txa
        rol
        eor #1
:       


;;; < 7+13=20 B  13-16c
        cmp tos
        txa
        sbc tos+1
        ldx #0
        bcc :+
        lda #1
        SKIPONE
:       
        txa
        

        


;;; 7+14=21 B  15-19==> 
        cmp tos
        txa
        sbc tos+1
        bcs :+
        lda #1
        SKIPTWO
:       
        lda #0
        ldx #0

        ;; 12 B  17-18c
        ldy #0
        cmp tos
        txa
;;; TODO: test - I think
        sbc tos+1
        bcs :+
        ;; <   => -1
        dey
:       
        ;; <=  => 0
        tya
        tax



;;; < 7+13=20 B  12c-18c
        ldy #$ff
        cpx tos+1
        bne :+
        cmp tos
:       
        bcc :+
        ;; !< => 0
        iny
:       
        ;;  < => -1
        tya
        tax

.endif
      .byte ']'


;
LOGIC=1
.ifdef LOGIC

;;; TODO: these should have very low priority
;;;   we should also have rules thhat tkaes
;;;   conditions and these things but out
;;;   generating only a C boolean result!

;;; TODO: use hibit!

ALT='|'+128
;       .byte ALT "foobar"

        ;; || OR operator


;;; TODO: trouble with | operator matching and skipping!
.ifdef xOPTRULES
        ;; || %V
        .byte "|\|\|","%V"
;;; TODO: & suspect, but how about |
        .byte "%=&,:;)]?",$80
      .byte "["
;;; 14 B vs 23 B saves 9 B
        stx savex
        ora savex
        ora VAR0
        ora VAR1
        ;; 0 false
        cmp #1                  ; C=1 if A>=1
        lda #0
        txa
        rol
      .byte "]"
        .byte TAILREC
.endif ; OPTRULES

;;; TODO: trouble with | operator matching and skipping!
.ifnblank
        .byte "|\|\|"
;;; 19 B
        .byte "%{"
;        jsr nl                 
        putc '?'
;        jsr nl
        IMM_RET

      .byte "["
        ;; 9 B
        stx savex
        ora savex
        ;; zero go _E, otheriwse skip!
        beq :+
        ;; - true: AX!=0
        jmp PUSHLOC
:       
        ;; - false = continue
      .byte "]"
        .byte _E
      .byte "["
        ;; 10 B
        ;; we need to make the value 0 or 1
        stx savex
        ora savex

        .byte ";B"              ; patch to branch here
        ;; 0 => 0, _ => 1
        cmp #1
        lda #0
        tax
        rol
      .byte "]"
.endif         

        ;; && AND operator

.ifdef OPTRULES
        .byte "|&&","%V"
;;; TODO: & suspect, but how about |
;        .byte "%=&,:;)]?",$80
      .byte "["
;;; 16 B vs 23 B saves 7 B
        stx savex
        ora savex
        ;; eq => false
        beq :+

        lda VAR0
        ora VAR1
:       
        ;; A=0 if false
        cmp #1
        lda #0
        tax
        rol
      .byte "]"
;;; TODO: messed up ordering...||| &&& | &||&
        .byte TAILREC
.endif ; OPTRULES

        .byte "|&&"
;;; 19 B
      .byte "["
        ;; 9 B
        stx savex
        ora savex
        ;; zero done, return 0
        bne :+
        ;; - false
        jmp PUSHLOC
:       
        ;; - true = continue 
      .byte "]"
        .byte _E
      .byte "["
        ;; 10 B  14c - STABLE! faster
        stx savex
        ora savex

        .byte ";B"            ; jumps here
        ;; we need to make the value 0 or 1
        cmp #1                  ; 0 => C=0, _ => C=1
        lda #0
        tax
        rol
      .byte "]"

.endif ; LOGIC

;;; DID we used to do fallthrough?

        .byte 0


FUNC _oprulesend




;;; BYTERULES variant of ruleC:
ruleU:  

.ifdef BYTERULES
.ifdef OPTRULES
        ;; arr[i]=constant;

;;; TODO: %A fix

        .byte "|$arr\[%A\]=%D;"
      .byte "[#D"               ; swap?
        ldx VAR0
        .byte ";"
        lda #'<'
;;; TODO: get address of array...
        sta arr,x
      .byte "]"
.endif ; OPTRULES

        ;; array index
;;; TODO: simulated
        .byte "|$arr\[",_E,"\]="
      .byte '['
        pha
      .byte ']'
        .byte _U,";"
      .byte '['
        tay
        pla
        tax
        tya
;;; TODO: get address of array...
        sta arr,x
      .byte ']'

        ;; array index
;;; TODO: simulated
;;; TODO: _E or _V ???
        .byte "$arr\[",_E,"\]"
      .byte '['
        tax
        lda arr,x
        ldx #0
      .byte ']'
        .byte _V

        ;; variable
        .byte "|$%V"
      .byte '['
        lda VAR0
        ldx #0
      .byte ']'
        .byte _V

        ;; constant
        .byte "|%D"
      .byte '['
        lda #'<'
        ldx #0
      .byte ']'
        .byte _V


        ;; byte
        .byte "|*(char*)%V"
      .byte "["
        ldy #LOVAL
        sty tos
        ldy #HIVAL
        sty tos+1
        ldy #0
        lda (tos),y
        ldx #0
      .byte "]"
        .byte _V
.endif ; BYTERULES

        .byte 0


;;; BYTERULES variant of ruleD:
FUNC _byterulesstart

ruleV:  
        ;; TODO:        // .byte "=>
        
.ifdef BYTERULES
        .byte "|+$%V"
      .byte '['
        clc
        adc VAR0
      .byte ']'
        .byte TAILREC

;;; TODO: HMMM, this gives full value? %d?
;;;   overflow semantics?
        .byte "|+%d"
      .byte '['
        clc
        adc #'<'
      .byte ']'
        .byte TAILREC

;;; 18 *2
        .byte "|-%d"
      .byte '['
        sec
        sbc VAR0
      .byte ']'
        .byte TAILREC

        .byte "|-%d"
      .byte '['
        sec
        sbc #'<'
      .byte ']'
        .byte TAILREC

;;; 17 *2
        .byte "|&$%V"
      .byte '['
        and VAR0
      .byte ']'
        .byte TAILREC

        .byte "|&%d"
      .byte '['
        and #'<'
      .byte ']'
        .byte TAILREC

.ifnblank
;;; TODO: \ quoting
;;; 17 *2
        .byte "|\|$%V"
      .byte '['
        ora VAR0
      .byte ']'
        .byte TAILREC

        .byte "|\|%d"
      .byte '['
        ora #'<'
      .byte ']'
        .byte TAILREC
.endif ; NBLANK

;;; 17 *2
        .byte "|^$%V"
      .byte '['
        eor VAR0
      .byte ']'
        .byte TAILREC

        .byte "|^%d"
      .byte '['
        eor #'<'
      .byte ']'
        .byte TAILREC

;;; 24
        
        .byte "|/2%b"
      .byte '['
        lsr
      .byte ']'
        .byte TAILREC

        .byte "|\*2%b"
      .byte '['
        asl
      .byte ']'
        .byte TAILREC

;;; ==

        .byte "|==$%V"
      .byte '['
        ldy #0
        cmp VAR0
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
;;; if isn't special for byte rules
        ldx #0
      .byte ']'
        .byte TAILREC

        .byte "|==%d"
      .byte '['
        ldy #0
        cmp #'<'
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
;;; if isn't special for byte rules
        ldx #0
      .byte ']'
        .byte TAILREC

        .byte "|<%d"
      .byte '['
        ldy #$ff
        cmp #'<'
        bcc :+
        ;; < => 0
        iny
:       
        ;; neq => 0
        tya
;;; if isn't special for byte rules
        ldx #0
      .byte ']'
        .byte TAILREC

       .byte "<<1%b"
      .byte '['
        asl
      .byte ']'                  

       .byte ">>1%b"
      .byte '['
        lsr
      .byte ']'                  

       .byte "<<2%b"
      .byte '['
        asl
        asl
      .byte ']'                  

       .byte ">>2%b"
      .byte '['
        lsr
        lsr
      .byte ']'                  

       .byte "<<3%b"
      .byte '['
        asl
        asl
        asl
      .byte ']'                  

       .byte ">>3%b"
      .byte '['
        lsr
        lsr
        lsr
      .byte ']'                  

       .byte "<<4%b"
      .byte '['
        asl
        asl
        asl
        asl
      .byte ']'                  

       .byte ">>4%b"
      .byte '['
        lsr
        lsr
        lsr
        lsr
      .byte ']'                  

       .byte "<<5%b"
      .byte '['
        asl
        asl
        asl
        asl
        asl
      .byte ']'                  

       .byte ">>5%b"
      .byte '['
        lsr
        lsr
        lsr
        lsr
        lsr
      .byte ']'                  

       .byte "<<6%b"
      .byte '['
.ifblank
;;; 5B 8c
        ror
        ror
        ror
        and #128+64
.else
;;; 6B 12c
        asl
        asl
        asl
        asl
        asl
        asl
.endif
      .byte ']'                  

       .byte ">>6%b"
      .byte '['
.ifblank
;;; 5B 8c
        rol
        rol
        rol
        and #1+2
.else
;;; 6B 12c
        lsr
        lsr
        lsr
        lsr
        lsr
        lsr
.endif
      .byte ']'                  

       .byte "<<7%b"
      .byte '['
        ror
        ror
        and #128
      .byte ']'

       .byte ">>7%b"
      .byte '['
        rol
        rol
        and #1
      .byte ']'


        .byte ">>%V"
      .byte '['
        ldy VAR0
:       
        dey
        bmi :+
        lsr
        jmp :-
:       
        .byte ">>%d"
      .byte '['
        ldy #'<'
:       
        dey
        bmi :+
        lsr
        jmp :-
:       
      .byte ']'


.endif ; BYTERULES
        
        .byte "|"

        .byte 0
FUNC _byterulesend



;;; printf handling
ruleH:  
;;; 111 B not finished,
;;; how big is an asm printf?
.ifdef rulePRINTF
        ;; TODO: only handles fixed formats!
        .byte "printf(",34,""
      .byte "%{"
        ;; save pointer for traversal
        lda inp 
        sta pos
        lda inp+1
        sta pos+1
        ;; skip parsing till end
        ldy #0
:       
        jsr _incI
        lda (inp),y
;;; TODO: \ and "foo""bar" ?
        cmp #'"'                ; "
        bne :-
        ;; standing at "
        jsr _incI
        ;; done
        IMM_RET

        .byte TAILREC

        ;; handle each argument
        .byte "|,"
      .byte "%{"
.scope
        ;; skip "str%..." till %
        ldy #0
:       
        lda (pos),y
        cmp #'%'
        beq :+
        cmp #'"'                ; "
        beq @done
        iny
        bne :-
:       
        jsr _incI
        ;; have string to print?
        tya
        pha

        beq @nah
        ;; string - put out JSR putherez
        lda #$20
        ldy #0
        sta (_out),y
        jsr _incO
        
        lda #<putherez
        sta (_out),y
        jsr _incO
        
        lda #>putherez
        sta (_out),y
        jsr _incO
        
        ;; string - put inline
        pla
        tax
        ;; Y=0 already
:       
        lda (pos),y
        sta (_out),y
        jsr _incO

        dex
        bne :-

        ;; string - zero terminate
        tya
        sta (_out),y
        jsr _incO
@done:  
        ;; jmp _acceptrule?
@nah:
.endscope
        IMM_RET
        ;; - process argument
        .byte _E
      .byte "%{"
        ;; pos standing char after %
        ldy #0
        lda (pos),y
        ;; 

        IMMRET
        ;; done with printf
        .byte "|);"
.endif ; rulePRINTF
        .byte 0

;;; load byte expression
ruleI:  
        .byte "%D)"
      .byte '['
        lda #'<'
      .byte ']'

        .byte "|%V)"
      .byte '['
        lda VAR0
      .byte ']'

        ;; Nothing else than Expression could come now
;;; TODO: possibly _byteexpreesion???
;;; TOOD: is this dupoicate of later stuff?
        .byte "|",_E,")"

        .byte 0



;;; read byte expression, saving AX to tos, and sets Y=0!
;;; LOL: only used by poke...

;;; TODO:   can we use all these for foo[...]= ....; ????
ruleJ:  
        .byte "0)"
      .byte '['
        ;; save 1 B
        sta tos
        stx tos+1
        lda #0
        ;; used by indirection
        tay
      .byte ']'

        .byte "|%D)"
      .byte '['
        sta tos
        stx tos+1
        lda #'<'
        ;; used by indirection
        ldy #0
      .byte ']'

        .byte "|%V)"
      .byte '['
        sta tos
        stx tos+1
        lda VAR0
        ;; used by indirection
        ldy #0
      .byte ']'

        ;; Nothing else than Expression could come now
        .byte "|"
      .byte '['
        pha
        txa
        pha
      .byte ']'
        .byte _E,")"
      .byte '['
        tay
        pla
        sta tos+1
        pla
        sta tos
        tya
        ;; used by indirection
        ldy #0
      .byte ']'

        .byte 0



;;; function call, optimize one arguemnt
ruleL:
        ;; single arguemnt call
        .byte ")"
      .byte "[?2"               ; ref up one rule level!
        DOJSR VAL0
      .byte "]"


        ;; CALL fun(a...) { ... }
        ;; 
        ;; JSK-calling convention!
        ;; (keeps the parameter directly pullable from stack!
        ;;  and ENDS with return address to be RTSed!)
        ;; (last param in AX, others pha/txa/pha)
        .byte "|,"
        ;; +3+3 = 6 B + 6c extra
      .byte "["
        ;; AX already contains first parameter
        jmp PUSHLOC             ;   jmp doFUN
        .byte ":"               ; paramsFUN:
        ;; push first parameter
        pha
        txa
        pha
      .byte "]"
        .byte _W                ;    pha/txa/pha (not last)
      .byte "["
        .byte "?4"              ; (get's FUN-address)
        jmp VAL0                ;    jmp FUN
      .byte "]"
      .byte "["
        .byte "?1B"             ; doFUN:  (patches Branch)
        .byte ";"
        DOJSR VAL0              ;    jsr paramsFUN
      .byte ";;]"               ; (drops 2 values)

        .byte 0



;;; TODO: bad routine, at least for poke(_E,byteexpr)
;;;    why bad?
;;; BYTESIEVE: saved 5 bytes using ruleF!
;;; 
;;; "keepAXsetY"
ruleF:  
;;; TODO: remove? only used by strchr?
        .byte "%D"
      .byte '['
        ldy #'<'
      .byte ']'

.ifdef ZPVARS
        .byte "|%V"
      .byte '['
        ldy VAR0
      .byte ']'
.endif ; ZPVARS

        ;; Nothing else than Expression could come now
        .byte "|"
      .byte "["
        ;; reverse save A,X
        pha
        txa
        pha
      .byte "]"
        .byte _E
      .byte "["
        ;; only need low byte
        tay
        ;; reverse pop X,A
        pla
        txa
        pla
      .byte "]"

        .byte 0


;;; same as ruleE/rule but protects AX (leaving it in tos, in the end)
;;; "saveTOSrule"

;;; Another calling convention!
;;; 
;;; "(",_E,",",_G:  two argument rule where:
;;;    - first arg is saved in TOS
;;;    - second arg is in AX
ruleG:

;;; When entering this code AX contains value to be 
;;; written to tos. In many cases we can do this without
;;; using the stack.

.ifdef OPTRULES
        .byte "0)"
      .byte "["
        sta tos
        stx tos+1

        lda #0
        tax
      .byte "]"

        ;; parse string - duplicate code (see parsestring:)
        .byte "|",34            ; " character
      .byte "["
        sta tos
        stx tos+1
        ;; jump over inline string
        jmp PUSHLOC
        .byte ":"               ; start of string ?0
      .byte "]"
        ;; copy string to out
        .byte "%S"
        ;; branch to after string!
      .byte "[?1B"
        ;; load string address
        .byte "?0"
        lda #LOVAL
        ldx #HIVAL
      .byte ";;]"
        .byte ")"

        .byte "|%D)"
      .byte "["
        sta tos
        stx tos+1

        lda #LOVAL
        ldx #HIVAL
      .byte "]"
        
        .byte "|%V)"
      .byte "["
        sta tos
        stx tos+1

        lda VAR0
        ldx VAR1
      .byte "]"

        .byte "|"
.endif ; OPTRULES

      .byte "["
        ;; save on stack (tos may be used in _E)
        pha
        txa
        pha
      .byte "]"
        .byte _E,")"
      .byte "["
        ;; copy from stack to tos
        tay
        pla
        sta tos+1
        pla
        sta tos
        tya
      .byte "]"

        .byte 0



;;; Exprssion:
ruleE:  
        
        .byte "%V=[#]",_E
      .byte "[;"
        sta VAR0
        stx VAR1
      .byte "]"

        .byte "|",_C,_D
        
.ifdef BYTERULES
        .byte "|"
        .byte _U,_V
.endif ; BYTERULES
        
        .byte 0


;;; Array constant data partsing
;;;
;;; prefix: array= {
;;;  ruleQ:  num,num,num }

;;; TODO:allow for expressions if have constant folding
ruleQ:
        ;; end
        .byte "};"

        ;; ',' - one more item, skip ','
        .byte "|,",TAILREC

        .byte "|%d"
        JSRIMMEDIATE _stuffarray_c
        .byte TAILREC

        .byte 0

        

;;; DEFS ::= TYPE %NAME() BLOCK TAILREC |
ruleN:

      .byte "%{"
;        putc 'a'
        IMM_RET

        ;; SPECIAL HACK!

        ;; CUT if positive match!
        ;; (ruleN parses var/func def and is called
        ;;  by ruleO, which function is to skip over
        ;;  everything before the main function!)
        ;; TODO: possibly replace all this with
        ;;   a lookup of main?
        .byte "word","main("
      .byte "%{"
        jmp gotmain_goendfail


.include "parse-fold.asm"


;;; DEFINING FUNCTIONS


        ;; TODO: _T never fails...
        ;;    need to propagate error? "%_T" ???
;        .byte _T,"%N()",_B


        ;; define function

        ;; DEFINE fun(){...} - ZERO argument function
        ;; (no overhead)
        .byte "|word","%I()"
        IMMEDIATE _newfun
        .byte _B
      .byte '['
        ;; TODO: This maybe be redundant if there is
        ;; a return just before...
        ;; 
        ;; Not easy to fix?
        ;; (Can't just check if last byte is rts,
        ;;  as there can be a jmp to the current pos,
        ;;  see example below)
        ;; 
        ;; if (3) ; else return 5;
        ;; (if no return inserted after then
        ;;  will fall through to next function...)
        rts
      .byte ']'
        ;; Not really needed
        ;; IMMEDIATE _hideargs
        .byte TAILREC


;;; TODO: need to use as ALLFUN (?)
;;;   can't handle Y=0 (for now),
;;;   it would require pretest in loop
;;; 
;;; - on the other hand this optimizes ONE arg function...
.ifblank
        ;; fun(Expr){...} - ONE argument function
        .byte "|word","%I(","word"
        IMMEDIATE _newfun
        ;; TODO: make part of newname_F?
        ;; TODO: how about other types?
        IMMEDIATE _initparam
        .byte "%I)"
        IMMEDIATE _newparam_w
;;; TODO: (too much?)
;;; (+ 11 6) = 17 B overhead/function
      .byte "["
        ;; save register used for param
;;; 11 B
        ;; - lo
        tay
        lda params
        pha
        sty params
        ;; - hi
        lda params+1
        pha
        stx params+1

        ;; "inject" a restore1 call
;;; 6 B  10c .... 10c+24c= 34c (+4c cmp inline!)
        lda #>(restore1-1)
        pha
        lda #<(restore1-1)
        pha
      .byte "]"
        .byte _B
      .byte "["
        ;; no easy way to determine if _B ends w return
        ;; (even if last ir rts might be if/loop)
        rts
      .byte "]"
        IMMEDIATE _hideargs
        .byte TAILREC
.endif

        ;; DEFINE fun(a,b...) - TWO or MORE args

        .byte "|word","%I("

;;; TODO: is this relevant still - cleanup?

;;; TODO: this is kindof messed up, lol
;;;   it relies on that ONE arg parse have
;;;   registred the name already, lol
;;;   make a way to detect how many args before?
;        IMMEDIATE _newfun

        IMMEDIATE _initparam
        .byte _R                ; reads f.arguments

        ;; TODO: local variables (?)
        IMMEDIATE _calcsubY
      .byte "["
        ldy #LOVAL
        jsr subparamY
      .byte "]"

        .byte _B
      .byte "["
        rts
      .byte "]"
        IMMEDIATE _hideargs
        .byte TAILREC



        ;; TODO: old stuff, remove? maybe contains
        ;;   timting tests and optideas?
        ;; 
        ;;.include "parse-func-def.asm"



        .byte "|void*","%N()",_B
      .byte '['
        rts
      .byte ']'
        .byte TAILREC


        .byte "|void","%N()",_B
      .byte '['
        rts
      .byte ']'
        .byte TAILREC


        .byte "|byte*","%N()",_B
      .byte '['
        ldx #0
        rts
      .byte ']'
        .byte TAILREC


        .byte "|byte","%N()",_B
      .byte '['
        ldx #0
        rts
      .byte ']'
        .byte TAILREC


        ;; DECLARE/DEFINE ARRAYS

        ;; -- char foo[4];
        .byte "|char","%I\[%D\];"
        ;; TODO change calling to JSRIMMEDIATE
        IMMEDIATE _newarr_c
        .byte TAILREC

        ;; -- char foo[4]= {0};
        .byte "|char","%I\[%D\]={0};"
        IMMEDIATE _newarr_c
        .byte TAILREC

        ;; -- char foo[]= "foo"; // 4
        .byte "|char","%I\[\]=",34
        IMMEDIATE _newarr_c
        .byte "%S;"
        JSRIMMEDIATE _newarr_updatesize
        .byte TAILREC

        ;; -- char foo[]= {102,'o',0x64,0};
        .byte "|char","%I\[\]={"
        IMMEDIATE _newarr_c_unknown
        .byte "[#]"             ; push ^ENV
        .byte _Q
        .byte "[;]"             ; pop ^ENV
        JSRIMMEDIATE _newarr_updatesize
        .byte TAILREC


.ifnblank
;;; TODO: is it needed?
;;; 
;;; TODO: &var is different from var!
        .byte "|char\*","%I=",34
;;; TODO: sizeof must be 2
        ;; "word" ops same as "char*", lol
        IMMEDIATE _newvar_w
        .byte "%S;"
        .byte TAILREC
.endif


;;; TODO:
;        .byte "|word\*","%I="...
;        IMMEDIATE _newarr_w
;        .byte TAILREC


;;; TODO: word array[] ...

;        .byte "|word","%I\[%D\];"
;        IMMEDATE _newarr_w_ptr
;        jsr _newarr
;        .byte TAILREC

;        .byte "|word","%I\[\]={"
;        IMMEDIATE _newarr_w
;        .byte _Q
;        .byte TAILREC





        ;; DEFINE VARIABLES

        ;; TODO: use %N in else branch
        .byte "|word",_K
        .byte TAILREC




        .byte "|"

      .byte "%{"
        ;; comes here if we got "word main(" ...
gotmain_goendfail:
        lda #<after
        ldx #>after
        sta rule
        stx rule+1
;;; TODO: make IMM_FAIL do similar to IMM_RET
        IMM_FAIL
after:  

        .byte "|"

        .byte 0


;;; define list of variables
ruleK:  

        ;; one more,,,
        .byte "%I,"
        IMMEDIATE _newvar_w
        .byte TAILREC

        ;; last
        .byte "|%I;"
        IMMEDIATE _newvar_w

        .byte 0


;;; This is the first rule applied on program.
;;; Generates a jmp to main(). If no functions/decl
;;; is wasting 3B. Bah.
ruleO:
      .byte '['
        jmp PUSHLOC
      .byte ']'
        .byte _N

.ifnblank
      .byte "%{"
        ;putc '_'
        jsr _printstack
        IMM_RET
.endif

        .byte 0
        ;; Autopatches skip over definitions in _N


ruleP:  
        ;; TODO: ?
        ; JSRIMMEDIATE _iasmstart

        ;; jump over definitions and arrive at main
        .byte _O

        ;; TODO: not to have special case for main()?
        ;;   just lookup and patch?
        ;; TODO: works with _S
        ;;   (_T error doesn't propagate up)

	;.byte _T,"main()",_B
        ;; TODO: allow "int" even if...
        .byte "word","main()"
        ;; TODO: allow { var w init ... }
        ;;   they can be global, at this point doesn't
        ;;   matter, not allow recursion on main(), LOL?
        .byte _B
      .byte '['
        ;; if main not return, return 0
        lda #0
        tax
        rts
      .byte ']'

.ifdef PRINTASM
        JSRIMMEDIATE _asmprintsrc
.endif ; PRINTASM

        ;; We also accept simple expressions...
        ;; TODO: have a look/test

        .byte "|"

        .byte _A
      .byte "["
        rts
      .byte "]"            

.ifdef PRINTASM
        JSRIMMEDIATE _asmprintsrc
.endif ; PRINTASM

;;; TODO: ???

;        .byte "|",_E,TAILREC
;        .byte "|;",TAILREC
;        .byte "|{",_A,"}",TAILREC
        
        .byte 0





;;; TODO: this isproblematic to use as error's
;;;   aren't currently propagated

;;; TODO: "%_T" - propagate error (one level)
;;; 
;;; Type
ruleT:  
.ifdef FROGMOVE
        .byte "static",TAILREC
        ;; we don't care
        .byte "|word|char*|char|void*|void|int*|int",0
.else
        .byte "word|char*|char|void|void*",0
;;; TODO: change word to int... lol
.endif





        ;; STATEMENTS

FUNC _stmtrulesstart
ruleS:

        ;; empty statement is legal
        .byte ";"
        

.ifdef PRINTASM
      .byte "%{"
        jsr _asmprintsrc
        IMM_RET
.endif ; PRINTASM

        ;; return from void function, no checks
        .byte "|return;"
      .byte '['
        rts
      .byte ']'
        


.ifdef OPTRULES
        ;; save for no args function!
        .byte "|return%V();"
      .byte '['
        ;; TAILCALL save 1 byte!
        jmp VAL0
      .byte ']'

;;; TODO: how to detect???
;        .byte "|return%V(...);"
;;; 
;;; Maybe second pass opt? use %O and %o flags...
;;;   TODO: implement %O and %o flags... LOL
;;;   


.endif ; OPTRULES



        ;; RETURN
        .byte "|return",_E,";"
      .byte '['
        rts
      .byte ']'

        ;; BlOCK!
;;; TODO: this gives inifinte loop! >S>B>* ...
;       .byte "|",_B

;;; TODO: this however works! 
;;;   which is just inline of _B ... HMMM :-(
        .byte "|{}"
        .byte "|{",_A,"}"


;;; TODO:
;;; -
;;; Turns out that adding a "hacky" (but correctly working) ELSE wasn't that difficult!
;;; Basically, I just made sure that the THEN branch always had the flag Z=0 (value not 0 i.e. true) and then since a false value would jump to after the THEN the ELSE can be implemented by just looking at the flag (so like an opposite THEN).
;;; Of course, this isn't very optimized: An IF comes out to 9 bytes ; ELSE support adds 2 + 5 more bytes, total 16.
;;; Currently, only patching long-JMP instructions, maybe just *define* that the if branches can't be too big(?) that is less than 127 bytes... That would make an IF THEN be 6 and ELSE 4 bytes, total 10.

;;; TODO: MINIMAL can limit to 10 bytes instead of 16
;;; 
;;; LONG could do fancy patching if >127
;;; replae BNE XX with JMP to here+3, add code
;;; 
.ifnblank
;;; LNG: 16B   (+ 9 2 5)   - all long
;;; 
;;; min: 10B   (+ 6 2 2)   - all short
;;; med: 18B   (+ 6 2 8 2) - IFF too long THEN
;;; max: 24B   (+ 6 2 8 8) - IFF also ELSE long

        ;; 6B 5-9c
        tay
        bne then
        txa
        beq PUSHREL
then:   
        ...
        ;; 2B (for else)
        lda #$ff
afterTHEN:      
        ;; + 8B to do long patch
        sec
        bcs 6
testhere:       
        beq 3
        jmp then
afterIF:        
elseTEST:       
        ;; 3B 4-5c
        bne PUSHREL
        nop                     ; ?
else:   
        ...
afterELSE:      
.endif


        ;; TODO: more like statement
        .byte "|SEI();"
      .byte '['
        sei
      .byte ']'

        .byte "|CLI();"
      .byte '['
        cli
      .byte ']'


        ;; LABEL moved to end of ruleS

        ;; goto
;;; TODO: %A can be %V ???
        .byte "|goto%V;"
      .byte "["                ; get aDdress
        jmp (VAL0)
      .byte "]"



.ifnblank
;;; TO: use as zero detector?
        ;; 11 B
        stx savex
        ora savex
;        cmp #0
        ;; C=1 if !0
;        bcs :+
        beq :+
        clc
        jmp PUSHLOC
:       

;;; good zero detector to set C opposite!
        ;; 10 B
        lda VAR0
        ora VAR1
        cmp #1
        ;; C=1 if !0
        bcs :+
;        beq :+
;        clc
        jmp PUSHLOC
:       


.endif ; TODO: use this? maybe when generic IF?
;;; TODO: TEST_EXPRESSION RULE




.ifdef OPTRULES

;;; TODO: add if(%V)
;;; TODO: add if(!%V)

        ;; IF( var == 0 ) ... saves 14 B !
        ;; (no need generate true/false)
        ;; note: this is safe as if it doesn't match,
        ;;   not code has been emitted! If use subrule... no
        .byte "|if(%V==0)"
      .byte "["
.scope
.ifnblank
        ;; 10 B
        lda VAR0
        ora VAR1
        beq :+
        clc
        jmp PUSHLOC
:       
.else
        ;; 12
        lda VAR0
        beq @eq1
@neq:
        ;; ELSE, C=0
        clc
        jmp PUSHLOC
@eq1:
        ldx VAR1
        bne @neq
.endif
.endscope
      .byte "]"
        ;; THEN
        .byte _S
      .byte "["
        ;; C=1 prohibits ELSE to run!
        sec
      .byte "]"
        ;; Autopatched ELSE jmp here
        ;; ELSE is optional and depends on C=0 to do ELSE clause!


.ifdef OPTRULES
        .byte "|if(%V==[#]%d)"
      .byte "["
        ;; 14
        lda #LOVAL
        .byte ";"
        cmp VAR0
        beq :++
:       
        clc
        jmp PUSHLOC
:       
        ldx VAR1
        bne :--
      .byte "]"
        ;; THEN
        .byte _S
      .byte "["
        sec
      .byte "]"
        ;; optional ELSE
        

.endif ; OPTRULES

        ;; IF( var == num ) ... saves 10 B ! (- 88 78)
        ;; (no need generate true/false)
        ;; note: this is safe as if it doesn't match,
        ;;   not code has been emitted! If use subrule... no
        .byte "|if(%V==[#]",_E,")"
      .byte "["
        ;; 12+1
        .byte ";"
        cmp VAR0
        beq @eq1
@neq:
        ;; ELSE, C=0
        clc
        jmp PUSHLOC
@eq1:
        cpx VAR1
        bne @neq
      .byte "]"
        ;; THEN
        .byte _S
      .byte "["
        ;; C=1 prohibits ELSE to run!
        sec
      .byte "]"
        ;; Autopatched ELSE jmp here
        ;; ELSE is optional and depends on C=0 to do ELSE clause!


;; TODO:

.ifnblank
;;; TODO: if(%V<[#]%d) should save (few bytes?)
        .byte "|if(%V<[#]%d[#])"
.scope        
;;; 15 B save 3 B
;;???
      .byte "["
        ldx VAL1
        beq @else
        lda VAR0                ; LOL, nono! VAR0==VAL0
        cmp #LOVAL
        bcc @then
@else:
        ;; Hmmm, reverse...
        clc
        jmp PUSHVAL
@then:
        _S
        sec
.endscope
.endif        
        

        ;; IF( var < num ) ... saves 6 B (- 63 57)
        ;; note: this is safe as if it doesn't match,
        ;;   not code has been emitted! If use subrule... no
        .byte "|if(%V<[#]%D)"
.scope        
;;; 18
      .byte "["
        ;; reverse cmp as <> NUM avail first
        lda #LOVAL
        ldx #HIVAL
        ;; cmp with VAR
        .byte ";"               ; get aDdress
        ;; test hi byte first
        cpx VAL1
        bne :+                  ; neq determine if <
        ;; equal: test lo byte; NUM>=VAR ... VAR<=NUM
        cmp VAR0
        beq @nah
:       
        bcs @ok                 ; NUM>=VAR
@nah:
        ;; set value for optional else...
        ;; C=0 ! (nothing to do)
        jmp PUSHLOC
@ok:        
        ;; C=1 !
        ;; THEN-branch
      .byte "]"
        .byte _S
.ifdef ELSE
        ;; for ELSE, keep C=1
      .byte '['
        sec
      .byte ']'
.endif ; ELSE
.endscope

        .byte "|if(%V&[#]%d)"
.scope        
      .byte "["
        lda #LOVAL
        ;; cmp with VAR
        .byte ';'               ; get aDdress
        and VAR0
        bne @ok
@nah:
        ;; set value for optional else...
.ifdef ELSE
        clc
.endif ;ELSE
        jmp PUSHLOC
@ok:        
        ;; THEN-branch
      .byte "]"
        .byte _S
.ifdef ELSE
        ;; for ELSE, keep C=1
      .byte '['
        sec
      .byte ']'
.endif ; ELSE
.endscope

.endif ; OPTRULES


        ;; IF(E)S; // no else
        .byte "|if(",_E,")"
      .byte '['
.ifnblank
        ;; 10B 9-13c
        ;; 111*111 => 859us
        stx savex
        ora savex
        bne :+
        clc
        jmp PUSHLOC
:       
.else
        ;; 10 B 5-9-13c
        ;; 111*111 => 859us same????
        ;; TODO: no savings for 111*111 ???
        ;;    609c if just make jmp PUSHLOC
        tay
        bne :+
        txa
        bne :+
        clc
        jmp PUSHLOC
:       
.endif
        ;; THEN-branch
      .byte ']'
;;; TODO: move these rules out to another rule
;;;    then don't need to repeat this one!
        .byte _S
.ifdef ELSE
        ;; for ELSE set C=1
      .byte '['
        sec
      .byte ']'
        ;; Auto-patches at exit!


        ;; ELSE as independent as it's optional! hack!
        ;; 13 B
        .byte "|else"
      .byte '['
        ;; either Z is from lda #$ff z=0 => !neq
        ;; or Z is from the if expression Z=1
        bcc :+
        jmp PUSHLOC
:
      .byte ']'
        .byte _S
        ;; Auto-patches at exit!
.endif ; ELSE

.ifdef BYTERULES
        ;; %D is ok as it get's "truncated" anyway.
        .byte "|$%V[#]=%D;"
      .byte "["
        lda #'<'
        .byte ";"
        sta VAR0
      .byte "]"

        .byte "|$%V=[#]",_E,";"
      .byte "[;"
        sta VAR0
      .byte "]"
.endif


.ifdef OPTRULES
        ;; arr[i]=constant;
        .byte "|arr\[%A\]=[#]%D;"
      .byte "["
        lda #'<'
        .byte ";"
        ldx VAR0
;;; TODO: get address of array...
        sta arr,x
      .byte "]"

;;; this makes it work, but isn't correct?
;        .byte TAILREC

.endif ; OPTRULES

        ;; array index
;;; TODO: simulated
        .byte "|arr\[",_E,"\]="
      .byte '['
        ;; save index
        pha
      .byte ']'
;;; TODO: _U in other rule???
        .byte _E,";"
      .byte '['
        ;; save value to store
        tay
        ;; get index
        pla
        tax
        tya
;;; TODO: get address of array...
        sta arr,x
      .byte ']'


.ifdef OPTRULES
        .byte "|$%V=0;"
      .byte "["
        sta VAR0
      .byte "]"
.endif ; OPTRULES


FUNC _stmtbyterulestart

.ifdef BYTERULES
        .byte "|++$%V;"
      .byte "["
        inc VAR0
      .byte "]"

        .byte "|--$%V;"
      .byte "["
        dec VAR0
      .byte "]"

        .byte "|$%V+=[#]",_U,";"
      .byte "[;"
        clc
        adc VAR0
        sta VAR0
      .byte "]"

        .byte "|%V-=[#]",_U,";"
      .byte "[;"
        sec
        eor #$ff
        adc VAR0
        sta VAR0
      .byte "]"

        .byte "|$%V&=[#]",_U,";"
      .byte "[;"
        and VAR0
        sta VAR0
      .byte "]"

        .byte "|$%V\|=[#]",_U,";"
      .byte "[;"
        ora VAR0
        sta VAR0
      .byte "]"

        .byte "|$%V^=[#]",_U,";"
      .byte "[;"
        eor VAR0
        sta VAR0
      .byte "]"

        .byte "|$%V>>=1;"
      .byte "["
        lsr VAR0
      .byte "]"

        .byte "|$%V<<=1;"
      .byte "["
        asl VAR0
      .byte "]"

        .byte "|$%V>>=2;"
      .byte "["
        lsr VAR0
        lsr VAR0
      .byte "]"

        .byte "|$%V<<=2;"
      .byte "["
        asl VAR0
        asl VAR0
      .byte "]"

        .byte "|$%V>>=3;"
      .byte "["
        lsr VAR0
        lsr VAR0
        lsr VAR0
      .byte "]"

        .byte "|$%V<<=3;"
      .byte "["
;;; 6B 15c
        asl VAR0
        asl VAR0
        asl VAR0
      .byte "]"

        .byte "|$%V>>=4;"
      .byte "["
;;; 8B 14c
.ifblank
        lda VAR0
        lsr
        lsr
        lsr
        lsr
        sta VAR0
.else
;;; 8B 20c
        lsr VAR0
        lsr VAR0
        lsr VAR0
        lsr VAR0
.endif
      .byte "]"

        .byte "|$%V<<=4;"
      .byte "["
        lda VAR0
        asl
        asl
        asl
        asl
        sta VAR0
      .byte "]"

        .byte "|$%V>>=5;"
      .byte "["
;;; 9B 16c
        lda VAR0
        lsr
        lsr
        lsr
        lsr
        lsr
        sta VAR0
      .byte "]"

        .byte "|$%V<<=5;"
      .byte "["
        lda VAR0
        asl
        asl
        asl
        asl
        asl
        sta VAR0
      .byte "]"

        .byte "|$%V>>=6;"
      .byte "["
;;; 10B 16c
        lda VAR0
        lsr
        lsr
        lsr
        lsr
        lsr
        lsr
        sta VAR0
      .byte "]"

        .byte "|$%V<<=6;"
      .byte "["
        lda VAR0
        asl
        asl
        asl
        asl
        asl
        asl
        sta VAR0
      .byte "]"

        .byte "|$%V>>=7;"
      .byte "["
;;; 8B 12c
        lda VAR0
        rol
        rol
        and #1
        sta VAR0
      .byte "]"

        .byte "|$%V<<=7;"
      .byte "["
        lda VAR0
        ror
        ror
        and #128
        sta VAR0
      .byte "]"

;;; TODO:: |<<9 >>9 ???

.ifnblank
        .byte "|$%V>>=[#]%D;"
      .byte "["
;;; 11B (tradeoff 
        ldy #'<'
        .byte ";"
:       
        dey
        bmi :+

        lsr VAR0

        sec
        bcs :-
:       
      .byte "]"
.endif

        .byte "|$%V>>=[#]%V;"
      .byte "["
        ldy VAR0
        .byte ";"
:       
        dey
        bmi :+

        lsr VAR0

        sec
        bcs :-
:       
      .byte "]"

.ifnblank
        .byte "|$%V<<=[#]%D;"
      .byte "["
;;; 11B
        ldy #'<'
        .byte ";"
:       
        dey
        bmi :+

        asl VAR0

        sec
        bcs :-
:       
      .byte "]"
.endif

        .byte "|$%V<<=[#]%V;"
      .byte "["
;;; 14B
        ldy VAR0
        .byte ";"
:       
        dey
        bmi :+

        asl VAR0
        rol VAR1

        sec
        bcs :-
:       
      .byte "]"
.endif ; BYTERULES
FUNC _stmtbyteruleend



;;; TODO: are these really "OPTRULES"
;;;   a+= is "extra syntax"?
;;;   ++a; is opt, yes

.ifdef OPTRULES
        .byte "|++%V;"
incinc:
      .byte "["
        inc VAR0
        bne :+
        inc VAR1
:       
      .byte "]"

        .byte "|%V++;"
        .byte "%R"
        .word incinc

        .byte "|--%V;"
decdec: 
      .byte "["
        lda VAR0
        bne :+
        dec VAR1
:       
        dec VAR0
      .byte "]"

        .byte "|%V--;"
        .byte "%R"
        .word decdec

.endif ; OPTRULES

        ;; assume it's char*
        .byte "|*%V=[#]",_E,";"
      .byte "[;"
.ifdef ZPVARS
        ldx #0
        sta (VAR0,x)
.else
        ldy VAR0
        sty tos
        ldy VAL1
        sty tos+1

        ldx #0
        sta (tos,x)
.endif
      .byte "]"

.ifdef BYTERULES
        ;; TODO: this is now limited to 256 index
        ;; bytes@[%D]= ... fixed address... hmmm
        .byte "|$%V\[[#]%D\]="
      .byte '['
        ;; prepare index
        lda '<'
        pha
      .byte ']'
        .byte _E,";"
      .byte "[;"
        ;; load index
        tax
        pla
        tay
        txa

        sta VAR0,y
      .byte "]"
.endif ; BYTERULES







.ifdef OPTRULES

;;; TODO: BYTERULES for $ i

;;; TODO: for expects empty statement to be "true"!

        .byte "|for(i=0;i<%d[d];++%V)"
      .byte "["
;;;  start not with 0 but with 
        lda #0
        sta VAR0
        sta VAR1
        ;; skip inc first time
.ifdef ZPVARS
        ;beq 2
        .byte $f0,2
.else
        ;beq 3
        .byte $f0,3
.endif

;;;  We moved inc here
        .byte ":"               ; note: this generates no byte
        inc VAR0

        lda VAR0
        .byte "D"
        cmp #'<'
        bcc :+
        jmp PUSHLOC
:              
      .byte "]"
        .byte _S
      .byte "["
        .byte ";d"
        .byte ";"
        ;;  jump to inc+test
        jmp VAL0
        .byte "D#"
      .byte "]"
;;;  autopatches jump to here if false (PUSHLOC)


;
FOROPT=1
.ifdef FOROPT
;;; TODO: doesn't match a[n]= b[n] ????
;;;  seems be tied to %V parsing???

        ;; Fastest small memcopy!
;;; TODO: check same var!
;;; TODO: check LIM < 256
;;; TODO: if "constants" generate no indirection!
        .byte "|for(%V[#]=0;%V<%D[#];++%V)"

;;; TODO []???
;        .byte   "%V[#]\[%V\]=%V[#]\[%V\];"

        .byte   "*%V[#]++=*%V[#]++;"

;;; TODO: syntax all wrong?
;;; 
;;; seems can't match to \[%V\] ... ? lol

        ;; vara ?3
        ;; lim  ?2
        ;; to   ?1
        ;; from ?0

.ifndef ZPVARS

;;; 29 B
       .byte "["
        ;; to
        .byte "?1"
        lda VAR0
        ldx VAR1
        sta tos
        stx tos+1
;;; TODO: works with tos+pos but not with dos???
        ;; from
        .byte "?0"
        lda VAR0
        ldx VAR1
        sta pos
        stx pos+1
        
        ;; get arg 2 (can't do inside loop!)
        .byte "?2"

        ldy #0
:       
        lda (pos),y
        sta (tos),y

        iny
        cpy #'<'
        bne :-

        ;; update loop variable
        ;; superfluos?
        .byte "?3"
        sty VAR0
        
     .byte ";;;;]"
.else ; ZPVARS

;;; 13 B
       .byte "["
        ldy #0
@nextc:
        .byte "?0"
        lda (VAR0),y

        .byte "?1"
        sta (VAR0),y

        iny

        .byte "?2"
        cpy #'<'

        ;bne :-
        bne @nextc+ 3 *2

        ;; update loop variable
        ;; superfluos?
        .byte "?3"
        sty VAR0

     .byte ";;;;]"

.endif ; ZEROPAGE


.endif ; FOROPT
        

        ;; i > 255
        ;; (saves 20B for PRIME for)
        .byte "|for(i=0;i<%D[d];++%V)"
;;; 40B (is less than while!!!
      .byte "["
        lda #0
        sta VAR0
        sta VAR1
        ;; skip inc first time
.ifdef ZPVARS
        ;beq 2+2+2
        .byte $f0,2+2+2
.else
        ;beq 3+2+3
        .byte $f0,3+2+3
.endif
        ;; We moved inc here
        .byte ":"               ; note this generates no byte
        inc VAR0
        bne :+
        inc VAR1
:       
.ifnblank
        putc 'i'
        lda VAR0
        sta tos
        lda VAR1
        sta tos+1
        jsr puth
.endif
        ;; test i<%D
        lda VAR0
        pha
        lda VAR1
        .byte "D"
        cmp #'>'
        beq @eq
        bcc @lt
        pla
@eqorgt:
        jmp PUSHLOC
@eq:       
        ;; hi equal
        pla
        cmp #'<'
        bcs @eqorgt
        bcc @ok
@lt:
        pla
@ok:
      .byte "]"
        .byte _S
      .byte "["
        .byte ";d"
        .byte ";"
        ;; jump to inc+test
        jmp VAL0
        .byte "D#"
      .byte "]"
        ;; autopatches jump to here if false (PUSHLOC)


.ifdef bug_BYTERULES

;;; TDOO: fix... %A

        .byte "|while([:]$%A<%d[#])"
      .byte "["
      .byte "]"
.scope        
      .byte "[D"
        lda VAR0
        .byte ";"
        cmp #'<'
        bcc @okwhile            ; NUM+1>=VAR === num>VAR
@nahwhile:
        ;; jmp to end if false
        jmp PUSHLOC
@okwhile:
.endscope
      .byte "]"
        .byte _S
      .byte "[;d;"              ; pop tos, dos=tos; pop tos
        ;; jump to beginning of loop (:)
        jmp VAL0
      .byte "D#]"               ; tos= dos, push tos (patch)
        ;; autopatches jump to here if false (PUSHLOC)
.endif ; BYTERULES

.ifdef OPTRULES
        ;; eternal loop
        ;; (saves (- 33 20) = 13 bytes!
        .byte "|while(1)[:]"
        .byte _S
      .byte "[;"
        jmp VAL0
      .byte "]"
.endif ; OPTRULES


;;; %A only used here!!!?

;;; todo: FIX
        .byte "|while(%A<"
        ;; similar to while(%A<%D)
      .byte "["
        ;; reverse cmp as <> NUM avail first
        .byte ":"               ; loop back location
        .byte "#"               ; push var address
      .byte "]"
.scope        
        .byte _E,")"
        ;; cmp with VAR
      .byte "["
        .byte ";"               ; pop address of var
        cpx VAR1
        bne @decide
        ;;  hi = equal
        cmp VAR0
        beq @nahwhile
@decide:
;;; TODO: seems longer than needed?
        bcs @okwhile            ; NUM>=VAR
@nahwhile:
        ;; jmp to end if false
        jmp PUSHLOC
@okwhile:
.endscope
      .byte "]"
        .byte _S
      .byte "[;d;"              ; pop tos, dos=tos; pop tos
        ;; jump to beginning of loop (:)
        jmp VAL0
      .byte "D#]"               ; tos= dos, push tos (patch)
        ;; autopatches jump to here if false (PUSHLOC)



;;; TODO: while(--a) ???


;;; TODO: cleanup using "?2" positional parameters


;;; OPT: WHILE(a)...
        .byte "|while(%V)"
        .byte "[:]"

      .byte "["
        lda VAR0
        ora VAR1
        ;; jmp to end if false
        bne :+
        jmp PUSHLOC
:       
      .byte "]"
        .byte _S
;;; 10B
;;; A kind of "complicated swap"
;;; TODO: maybe just a generic "pickN"???
;;;   'p' get's patched like normal and other manual
      .byte "[;d"               ; pop tos, dos=tos
        .byte ";"               ; pop tos
        ;; jump to beginning of loop (:)
;;; TODO: %j
        jmp VAL0
        .byte "D"               ; tos= dos
        .byte "#"               ; push tos (to patch)
      .byte "]"
        ;; autopatches jump to here if false (PUSHLOC)
.endif ; OPTRULES



;;; FOR( ; ; )
;        .byte "|for(",_E,";"

;;; TODO: _S just to do assignment.
;;;       but should be _E that allows _E,_E,_E
;;;       (like sequence)
        .byte "|for(",_S
      ;; INITIALIZER
      ;; CONDITION
      .byte "["
        .byte ":"               ; ?3jmp - fixed
        ;; test can be empty, but need to be true!
        lda #$ff
      .byte "]"
        .byte _E,";"
        ;; TEST
      .byte "["
        ;; not zero?
        tay
        bne @true
        txa
        bne @true
@fail:
        jmp PUSHLOC             ; ?2B - fixed
@true:
        ;; skip over INC (do first!)
        jmp PUSHLOC             ; ?1B - fixed

       ;; STEP (inc)
        .byte ":"               ; ?0jmp - fixed
      .byte "]"
        ;; TODO: need to make distinction beteen
        ;;    argument statements and _E,
        ;;    latter can take a,b,c; not in args!
        .byte _E,")"

      .byte "[?3"
        jmp VAL0
      .byte "]"

      ;; BODY 
        ;; come here after CONDITION
      .byte "[?1B]"

        .byte _S

      .byte "[?0"
        jmp VAL0
      .byte "]"
        
        ;; FAIL go here
      .byte "[?2B]"

        ;; cleanup, lol - big one!
        .byte "[;;;;]"



;;; WHILE()...
        .byte "|while("
        .byte "[:]"
        .byte _E,")"

      .byte "["
        stx savex
        ora savex
        ;; jmp to end if false
        bne :+
        jmp PUSHLOC
:       
      .byte "]"
        .byte _S

;;; 10B
;;; A kind of "complicated swap"
;;; TODO: maybe just a generic "pickN"???
;;;   'p' get's patched like normal and other manual
      .byte "[;d"               ; pop tos, dos=tos
        .byte ";"               ; pop tos
        ;; jump to beginning of loop (:)
;;; TODO: %j
        jmp VAL0
        .byte "D"               ; tos= dos
        .byte "#"               ; push tos (to patch)
      .byte "]"
        ;; autopatches jump to here if false (PUSHLOC)


;;; TODO: remove?
.ifnblank
        ;; - swap the two locs!
;;; 28B
      .byte "%{"
        ;; TODO: this may not be easily skippable
        pla
        pla
        sta pos
        pla
        sta pos+1
        
        pla
        pla
        sta tos
        pla
        sta tos+1
        
        lda pos+1
        pha
        lda pos
        pha
        lda #'p'                ; patch and end
        pha
        
        IMM_RET

        ;; TOS is now before condition
      .byte "["
        jmp VAL0
      .byte "]"
.endif
        
        ;; autopatch 'p' at end to go condition

        

;;; TODO: wrong1!! will break
;;; ;;; TODO: make special ZEROTESTEXPR parse rule?


.ifdef xOPTRULES
;;; OPT: DO ... WHILE(a);
        .byte "|do"
      .byte "[:]"
        .byte _S

        .byte "while(%V);"
      .byte "["
        lda VAR0              
        ora VAR1
        .byte ";"               ; pop tos
        ;; don't loop if not true
;;; TODO: potentially "b" to generate relative jmp
        beq :+
        jmp VAL0
:        
      .byte "]"
.endif

.ifdef BYTERULES
;;; OPT: DO ... WHILE(a);
        .byte "|DO"
      .byte "[:]"
        .byte _S

        .byte "WHILE($%V);"
      .byte "["
        lda VAR0
        .byte ";"
        ;; don't loop if not true
;;; TODO: potentially "b" to generate relative jmp?
        beq :+
        jmp VAL0
:        
      .byte "]"
.endif ; BYTERULES


        ;; Generic optimized do...while
        ;; (clever specialization in _M
        .byte "|do[:]",_S,"while(",_M,"[;]"


;;; ========================================
;;; TODO: move out to oric-cmd.rules.

FUNC _oricstart

.ifdef __ATMOS__
        .include "atmos-cmd-ruleS.asm"
.endif ; __ATMOS__

FUNC _oricend

;;; TODO: furk!
;;;   thsi worked, when it shouldn't have!
;;;   HAHA: 5555555
;;; 
;;; void gotoxy(unsigned char, unsigned char);
;;;    somehow by pure "Luck" it worked...
;;;   but datastack is messed up!

;;; todo:
;        .BYTE "|gotoxy(",_BYTEPARM,",",_BYTEPARAM,");"

;;; void gotoxy(unsigned char, unsigned char);
.import _gotoxy

        .byte "|gotoxy",_X
      .byte "["
        jsr _gotoxy
      .byte "]"



;;; TODO: bzero(char*, len); // legacy unix

.ifdef OPTRULES
        ;; Feature (BUG): 0=>256 bytes set!
        .byte "|memset(%D[#],%d[#],%d);"
      .byte "["
        ;; 10 B !
        ldy #'<'
        .byte ";"
        lda #'<'
        .byte ";"
:       
        sta VAL0,y
        dey
        bne :-
      .byte "]"


.ifdef CANT_UNGEN_EXPRESSION
        ;; (once _E is parsed and code generated
        ;;           can't backtrack!           )
        ;; typical usage? (varying address, fixed fill & len)
 	.byte "|memset(",_E,",%D[d],%D[#]);"
      .byte "["
        ;; 22 B
        sta tos
        stx tos+1
        ;; fill value
        .byte "D"
        lda #'<'
        ;; YX= count
        .byte ";"
        ldx #'>'
        ldy #'<'
        bne :++
:       
        dey
        sta (tos),y
        bne :-
        inc tos+1
        dex
        bpl :-
:       
        .byte "]"
.endif ; CANT_UNGEN_EXPRESSION
        
.endif ; OPTRULES


        ;; LIMIT: can only set max 32KB
        .byte "|memset(",_E,","
        ;; 29 B - too big!
;;; TODO: include a subroutine (call overhead 4+3 B)
      .byte "["
        ;; push address
        pha
        txa
        pha
      .byte "]"
        .byte _E,","
      .byte "["
        ;; only one byte value to set
        pha
      .byte "]"
        .byte _E,");"
      .byte "["
        sta savey
        ;; get value to set
        pla
        tay
        ;; get address
        pla
        sta tos+1
        pla
        sta tos
        ;; restore A fill value
        tya
        ;; YX is count
        ldy savey
        beq :++
:       
        dey
        sta (tos),y
        bne :-
        inc tos+1
        dex
        bpl :-                  ; bpl limits to 32K!
:       
      .byte "]"



;;; memcpy len<=256
;;; Function call with 3 constants:
;;;   cost:   23 B (3x lda/ldx, 2x sta/stx, 1x jsr)
;;;   inline: 16 B !

        .byte "|memcpy(%D[d],%D,"
      .byte "["
;;; 8B
        ldy #0

        .byte ":"

        lda VAL0,y
        .byte "D"
        sta VAL1,y

      .byte "]"
        .byte "%d);"
      .byte "["
;;; 8B
        iny
        cpy #'<'
        .byte ";"
        bcs :+
        jmp VAL0
:       
      .byte "]"
        
        .byte "|memcpy("
;;; (8+) 15B =(23B params+) copy
        .byte _E,","
      .byte "["
        sta dos
        stx dos+1
      .byte "]"

        .byte _E,","
      .byte "["
        sta tos
        stx tos+1
      .byte "]"
        
        .byte _E,");"
      .byte "["

;;; TODO: WTF?


;;; 8
        tay
:       
        lda (tos),y
        sta (dos),y
        iny
        bne :-

;;; TODO: not generate this part if X=0!!!
        ;; next page
;;; 7B
        inc tos+1
        inc dos+1
        dex
        bpl :-
      .byte "]"

endcmdrules:    

;;; END: hardcoded differnt "cmd("
;;; ========================================







;;; ========================================
;;; START: optimize parsing of   "|%V..."

;;; TODO: not working, seems to loop!

;;; TODO: maybe can optimize if %V name
;;;   isn't a defined variable?

;;; Moving them just here made parsing 1.27s=>1.53s
;;; 

;STARTVAROPT=1

;;; TODO: ??????

.ifdef STARTVAROPT
        .byte "|"

        ;; store current parsing location
      .byte "%{"
        lda inp 
        sta pos
        lda inp+1
        sta pos+1
        IMM_RET

        ;; check that we have a VAR
        .byte "%V"
        ;; OK - we got it!
      .byte "%{"
        ;; reset parsing and go do the rules
        lda pos
        sta inp
        lda pos+1
        sta inp+1
;putc '!'        
        clc
;;; TODO: potential zero or | ? (safer)
        bcc startparsevarfirst

        ;; we didn't match, skip all!
        .byte "|"
      .byte "%{"
;putc '%'
;;; TODO: potential zero or | ?
        jmp endparsevarfirst

;;; --- after here are ONLY rules that start with %A!
        .byte "%{"
startparsevarfirst:
;putc '<'
        IMM_RET

.endif ; STARTVAROPT


.ifdef OPTRULES
        ;; "|%A=%V;" (or even %A=%V _E)
        ;; TODO: if keep track of AX= var/value
        ;;   (and reset whenver we have : PUSHLOC etc)
        ;;   we may be able to save 4 bytes!

        .byte "|%V=0;"
      .byte "["
        lda #0
        sta VAR0
        sta VAR1
      .byte "]"

.endif ; OPTRULES

        ;; A=7; // simple assignement
;;; TODO: is E eating up an ";" ???

        .byte "|%V=[#]",_E,";"


;;; This isin't correct!!!! breaks BYTESIEVE!!!!

; BUG _E eats ';' !!!
;        .byte "|%V=[#]",_E

      .byte "[;"
        sta VAR0
        stx VAR1
      .byte "]"

.ifdef OPTRULES
        .byte "|%V>>=1;"
      .byte "["
;;; 6B
        lsr VAR1
        ror VAR0
      .byte "]"

        .byte "|%V<<=1;"
      .byte "["
;;; 6B
        asl VAR0
        rol VAR1
      .byte "]"

        .byte "|%V>>=2;"
      .byte "["
;;; 12B
        lsr VAR1
        ror VAR0
        lsr VAR1
        ror VAR0
      .byte "]"

        .byte "|%V<<=2;"
      .byte "["
;;; 12B (zp: 8B)
        asl VAR0
        rol VAR1
        asl VAR0
        rol VAR1
      .byte "]"

        .byte "|%V>>=3;"
      .byte "["
;;; 8B
        lsr VAR1
        ror VAR0
        lsr VAR1
        ror VAR0
        lsr VAR1
        ror VAR0
      .byte "]"

        .byte "|%V<<=3;"
      .byte "["
;;; 8B
        asl VAR0
        rol VAR1
        asl VAR0
        rol VAR1
        asl VAR0
        rol VAR1
      .byte "]"

        .byte "|%V+=[#]%d;"
      .byte "["
        ;; 11 B
        lda #LOVAL
        clc
        .byte ";"
        adc VAR0
        sta VAR0
        bcc :+
        inc VAR1
:       
      .byte "]"

        .byte "|%V-=[#]%d;"
        IMMEDIATE negateLOVAL
      .byte "["
        ;; 11 B
        lda #LOVAL
        clc
        .byte ";"
        adc VAR0
        sta VAR0
        bcs :+
        dec VAR1
:       
      .byte "]"
.endif ; OPTRULES


        .byte "|%V+=[#]",_E,";"
      .byte "[;"
        ;; 10 B
        clc
        adc VAR0
        sta VAR0
        txa
        adc VAR1
        sta VAR1
      .byte "]"

        .byte "|%V-=[#]",_E,";"
      .byte "[;"
        sec
        eor #$ff
        adc VAR0
        sta VAR0
        txa
        eor #$ff
        adc VAR1
        sta VAR1
      .byte "]"

        .byte "|%V&=[#]",_E,";"
      .byte "[;"               
        and VAR0
        sta VAR0
        txa
        and VAR1
        sta VAR1
      .byte "]"

        .byte "|%V\|=[#]",_E,";"
      .byte "[;"
        ora VAR0
        sta VAR0
        txa
        ora VAR1
        sta VAR1
      .byte "]"

        .byte "|%V^=[#]",_E,";"
      .byte "[;"
        eor VAR0
        sta VAR0
        txa
        eor VAR1
        sta VAR1
      .byte "]"




        .byte "|%V>>=[#]%D;"
      .byte "["
;;; 14B (tradeoff 14=6*d => d=2+)
;;; (zp: 12B)
        ldy #LOVAL
        .byte ";"
:       
        dey
        bmi :+

        lsr VAR1
        ror VAR0

        sec
        bcs :-
:       
      .byte "]"

        .byte "|%V>>=[#]%V;"
      .byte "["
;;; 14B (tradeoff 14=6*d => d=2+)
        ldy VAR0
        .byte ";"
:       
        dey
        bmi :+

        lsr VAR1
        ror VAR0

        sec
        bcs :-
:       
      .byte "]"

        .byte "|%V<<=[#]%D;"
      .byte "["
;;; 14B
        ldy #'<'
        .byte ";"
:       
        dey
        bmi :+

        asl VAR0
        rol VAR1

        sec
        bcs :-
:       
      .byte "]"

        .byte "|%V<<=[#]%V;"
      .byte "["
;;; 14B
        ldy VAR0
        .byte ";"
:       
        dey
        bmi :+

        asl VAR0
        rol VAR1

        sec
        bcs :-
:       
      .byte "]"

        ;; TODO: this is now limited to 128 index
        ;; word[%D]= ... fixed address... hmmm
        .byte "|%V\[[#]%D\]="
;;; TODO: similar to poke?
      .byte '['
        ;; prepare index (*2)
        lda '<'
        asl
        pha
      .byte ']'
        .byte _E,";"
      .byte "[;"
        ;; load index
        sta savea
        pla
        tay
        lda savea

        sta VAR0,y
        txa
        sta VAL1,y
      .byte "]"

.ifdef STARTVAROPT
        .byte "%{"
;putc '.'
clc
bcc parsevarcont
;putc '>'
endparsevarfirst:
;;; TODO: ?
        jmp _fail
;;; TODO: or??
        ;; this moves rule parsing to here!
parsevarcont:
        IMM_RET
.endif ; STARTVAROPT


.ifdef ASM
        ;; inline ASM!
        ;; (must be inline as we don't fail on subrule)
        .include "rules-asm.asm"
.endif ; ASM


;;; END: optimize parsing of   "|%V..."
;;; ========================================

        ;; Expression; // throw away result
        .byte "|",_E,";"

        ;; MUST BE LAST!
        ;; (%N sidoeffects are large, lol)

        ;; label
        .byte "|%N:",_S
        ;; set's variable/name to that address!

;;; DON'T PUT ANYTHING HERE!

        .byte 0




FUNC _stmtrulesend


;;; Common code patterns in large-scale C repositories:
;;; Condition  Est. Frequency    Typical Expr Pattern
;;; =========  ==============    ===========================
;;; Input/Validation     ~45%   `while (val < 0)
;;; ;Menu/Event Loops    ~25%    while (choice != EXIT_CODE)
;;; Iterative Calc       ~15%    while (error > threshold)
;;; Resource/Flag Wait   ~10%    while (!is_ready)
;;; Digit/Buffer process  ~5%    while (num > 0)

ruleM:  
;;; Hackey rule we need to lookUP wards many step!

        ;; do it once
        .byte "0);"
        
        ;; do it forever
        .byte "|1);"
      .byte "[?2"
        jmp VAL0
      .byte "]"

;;; TOOD: add %V==0 too? (same)
        .byte "|!%V);"
      .byte "["
.ifblank
        ;; 9B
        lda VAR0
        ora VAR1
        .byte "?2"
        bne :+
        jmp VAL0
:       
.else
        ;; 12 B
        ldx VAR1
        lda VAR0
        .byte "?2"              ; can't be inside bXX
        bne :+
        txa                     ; +1 B because can't mix ??
        bne :+
        jmp VAL0
:       
.endif
      .byte "]"

        .byte "|%V);"
      .byte "["
.ifblank
        ;; 9 B
        lda VAR0
        ora VAR1
        .byte "?2"
        beq :+
        jmp VAL0
:       
.else
        ;; 12 B
        ldx VAR1
        lda VAR0
        .byte "?2"        
        beq :++
:       
        jmp VAL0
:       
        txa                 
        bne :--
.endif
      .byte "]"

        ;; would only save one byte, not worth it!
        ;.byte "|%V[#]<%d[#]);"

        .byte "|%V<[#]%D[#]);"
      .byte "["
        ;; 14 B - optimal!
        .byte "?1"
        lda VAR0
        ldx VAR1
        .byte "?0"
        cmp #LOVAL              ; saves 1 byte (sec/sbc)
        txa
        sbc #HIVAL
        .byte "?4"              ; ???
        bcs :+
        jmp VAL0
:       
;;; TODO: [;;] cleanup?
      .byte "]"

        .byte "|%V<[#]%V[#]);"
        ;;      ?1    ?0
      .byte "["
        ;; 14 B - optimal!
        .byte "?1"
        lda VAR0
        ldx VAR1
        .byte "?0"
        cmp VAR0                ;lrt7 ???
        txa
        sbc VAR1
        .byte "?4"              ; access jump from caller
        bcs :+
        jmp VAL0
:       
;;; TODO: [;;] cleanup?
      .byte ";;]"

        ;; Generic rule
        .byte "|",_E,");"
      .byte "["
        .byte "?2"              ; ???? 2 ????
        tay
        beq :++
:       
        jmp VAL0
:       
        txa
        bne :--
      .byte "]"
        
        .byte 0
        
        

.ifnblank


LESSTHAN=1
.ifdef LESSTHAN
        ;; saves 1 byte!!!
        .byte "%V<[#]%D[#]"
      .byte "[?1"
.scope
        ldy #$ff
        lda VAR0
        ldx VAR1
        .byte "?0"
        cmp #LOVAL
        txa
        sbc #HIVAL
        bcc @true
@false:
        iny
@true:
        tya
        tax
.endscope
      .byte ";;]"


        .byte "|"
.endif ; LESSTHAN
        .byte _E
        .byte 0

.endif ; ruleL

FUNC _parametersstart

;;; - formal JSK-calling parameters
ruleR:  
        
        ;; lol, just "eat" the commas
        .byte ","
        .byte TAILREC

        ;; end
        .byte "|)"

        ;; parse one argument
        .byte "|word","%I"
        IMMEDIATE _newparam_w
        .byte TAILREC

        .byte 0


;;; - oric paramters
ruleY:  
        .byte "("
;;; Don't care?
.ifnblank
      .byte "["
        ;; store 0 for no error
        lda #0
        sta $02e0
      .byte "]"
.endif
      .byte "%{"
;PUTC 'C'        
        ;; oric parameters start
        lda #$02
        sta pos+1
        lda #$e1
        sta pos
        IMM_RET

        .byte _Z
        .byte 0

ruleZ:  
        .byte ",",TAILREC

        ;; end
        .byte "|)"
;        .byte "%{"
;PUTC 'F'
;        IMM_RET

        ;; parse next paramter
        .byte "|",_E
      .byte "%{"
;PUTC 'D'        
        lda pos
        sta tos
        lda pos+1
        sta tos+1
        IMM_RET
      .byte "["
        sta VAL0
        stx VAL1
      .byte "]"
      .byte "%{"
;PUTC 'E'        
        ;; move to next paramter addr
        jsr _incP
        jsr _incP
        IMM_RET
        ;; get next param
        .byte TAILREC
        
        .byte 0




;;; ----------------------------------------
;;             C   C   6   5

;;; cc65 AX _fastcall_ calling convention
.import pushax, popax, pusha0, pusha, popa

.ifnblank ;.ifdef __CC65__
ruleX:
        .byte 0
.else
;;; TODO: think hard, does it handle nesting correctly?
ruleX:  
        .byte "("
;      .byte "%{"
;        PUTC 'B'
;        IMM_RET
        .byte TAILREC

        .byte "|)"
;      .byte "%{"
;        PUTC 'E'
;        IMM_RET

        .byte "|,"
      .byte "["
        jsr pushax
;;; problem here, depend on address???
      .byte "]"
;      .byte "%{"
;        PUTC 'P'
;        IMM_RET
        .byte TAILREC

        ;; one byte constant paramter 0-255
        .byte "|%D,"
      .byte "%{"
        ;; TODO: this may not be easily skippable
;;;  make sure %D <256
        lda tos+1
        beq :+
        jmp _fail
:              
        jsr immret
      .byte "["
        ;; saves 2 bytes!
        lda  #'<'
        jsr pusha0
      .byte "]"
        .byte TAILREC

        .byte "|",_E
        ;; TODO: can we optimize if same constant twice? (10,10)??
 ;      .byte "%{"
;        PUTC 'E'
;        IMM_RET
        .byte TAILREC
        
        .byte 0



;;; TODO: fails on foo(42,(93),35) ???
        .byte "("
       .byte "%{"
;PUTC 'B'
        ;; counter for args
        lda #0
        jsr pusha
        IMM_RET

        .byte TAILREC


        .byte "|,"
      .byte "%{"
;PUTC 'P'
        putc '?'
        IMM_RET

      .byte "["
        jsr pushax
      .byte "]"
        .byte TAILREC
        
        .byte "|)"
      .byte "%{"
;PUTC 'E'
        jsr popa
        sta tos
        IMM_RET
      .byte "["
        ;; vararg always generated, lol
        ;; (however vararg f needs call jsr pushax
        ;;  for the last argument before jsr FUN)
        ldy #'<'
      .byte "]"


        .byte "|",_E
        ;; parse E leaves value in AX
.ifnblank
      .byte "%{"
PUTC 'A'
        ;; +2 for each arg
        jsr popa
        clc
        adc #02
        jsr pusha
        putc 'B'
        IMM_RET
.endif
        .byte TAILREC


        .byte 0
.endif ; __CC65__






;;; ========================================
;;;         P H A  /  T X A  /  P H A 

;;; Use the hardward stack for parameters
;;; 
;;; TODO: cleanup!!! LOL (or just function copy)
;;; (see Play/calling-conventions.asm )



;;; TODO: think hard, does it handle nesting correctly?


ruleW:  

        ;; End
        .byte ")"
.ifnblank
        ;; TODO: for now all parameters are put
        ;;   on stack!
      .byte "["
        pha
        txa
        pha
      .byte "]"
.endif

        ;; Comma pushes!
        .byte "|,"
      .byte "["
        pha
        txa
        pha
      .byte "]"
        .byte TAILREC


        ;; 0 value argument
        ;; TODO: handle 0,0,0.... ?
        .byte "|0,"
      .byte "["
        ;; 4 B (saves 3)
        lda #0
        pha
        pha
      .byte "]"
        .byte TAILREC

        ;; one byte constant paramter 0-255
        .byte "|%d,"
      .byte "["
        ;; saves 1 byte, hmmm
        lda #'<'
        pha
        lda #0
        pha
      .byte "]"
        .byte TAILREC


        ;; Generic expression 2 B value
        .byte "|",_E
        ;; TODO: can we optimize if same constant twice? (10,10)??
        .byte TAILREC
        

        .byte 0




FUNC _parametersend

;;; TODO: remove
.ifnblank

;;; TODO: what was this for?

;;; TODO: find better place...
TOS2POS:
        lda _out
        sta POS
        ldx _out+1
        stx POS+1
        rts

POS2TOS:        
        lda POS
        sta tos
        lda POS+1
        sta tos+1
        rts

TOSpatch:       
        ldy #1                  ; void inline 0 !!! LOL
        lda _out+1
        sta (tos),y
        dey
        lda _out
        sta (tos),y
        rts
.endif

endrules:       
        .byte "|",$ff

;;; END rules
;;; ========================================


FUNC _rulesend


.export __ZPIDE__
.zeropage
__ZPIDE__:        .res 0
.code

FUNC _idestart

FUNC _editorstart
.ifndef __ATMOS__
        ;; ironic, as this is not editor for
        ;; generic...

        ;; outdated (no cursor anymore)
        .include "edit-atmos-screen.asm"
.else
        ;; EMACS buffer RAW REDRAW
        .include "edit.asm"
.endif
FUNC _editorend


FUNC _aftercompile
        ;; failed?
        ;; (not stand at end of source \0)
        ldy #0
        lda (inp),y
        and #127
        ;; stores 0 if no compile error, lol
        sta compilestatus
        ;; fall-through

FUNC _reportcompilestatus

;;; TODO: reset S stackpointer! (editaction C-C goes here)
;;; doesn't set A!=0 if no match/fail just errors!
;        sta err

;;; TODO: print earlier before first compile?

.macro aschi str
  .repeat .strlen (str), c
    .byte .strat (str, c) | $80
  .endrep
.endmacro


        ;; TOP screen banner
.ifdef __ATMOS__

.data
status: 
        .word $bb80-2
        ;;     ////////////////////////////////////////
        ;;     YMeteoriC v0.60G`2025 yescoY^HelpWWCAPS
        ;; 
  ;;; BEGIN: INVERTED
        .byte YELLOW            ; => BLUE
        aschi "MeteoriC"
        .byte GREEN             ; => MAGNENTA
        aschi             VERSION
        .byte WHITE             ; => BLACK
        aschi                  "`2025 yesco"
  ;;; END: INVERTED
        .byte YELLOW 
        .byte                                 " ^Help"
        .byte 0
.code

        ;; - from
        lda #<status
        ldx #>status
        ;; - copy to status line of screen
        jsr _memcpyz
.endif ; __ATMOS__

        ;; check if error (== letter)
        ;; 0 means "OK"
        ;; 1(--31) means "unknown" (need compile)
        lda compilestatus
        bne :+

        jmp _OK
:       
        ;; unknown
        cmp #' '+1
        bcs :+

        jmp _eventloop
:       
        ;; error letter (A-Z or >' ')

;;;     fall-through
;;; ------------ ERROR ----------

FUNC _ERROR

.ifdef __ATMOS__
        ;; update color status
        lda #(RED+BG)&127
        sta SCREEN+35
.endif ; __ATMOS__

        ;; replace "jmp main" with "jmp _hell"
        ;; TODO: assuming it's not been optimized away?
        ;; lda #$4c
        ;; sta _output+0
        lda #<_hell
        ldx #>_hell
        sta _output+1
        stx _output+2
        
.ifdef ERRPOS
        ;; set hibit near error!
        ;; (approximated by as far as we "read")
        ;; TODO: or as far as we _fail (or _acccept?)
        ldy #0
        lda (erp),y
        ora #128
        sta (erp),y

.endif ; ERRPOS


        PRINTZ {10,YELLOW+BG,BLACK,"ERROR",10,10}


.scope
.ifdef PRINTINPUT
        ;; print it
        lda originp
        sta pos
        lda originp+1
        sta pos+1

        ;; jumps into middle of loop!
        jmp print

loop:
.ifdef ERRPOS
        ;; hi bit on char is indicator of how far it
        ;; is ok; next char, it's assumed to be near
        ;; near the error; thus hilite red background
        ;; and white text.
        bpl nohi

        ;; - remove hibit from src
        and #127
        sta (pos),y

        ;; - print ERROR location source
        pha
        ; TODO: doesn't work, messes with y and x ? doesn't mttr?
        ; PRINTZ {BG+RED, WHITE}
        putc BG+RED
        putc WHITE
        pla

        ;; - print MORE chars after HILITE for context
        ldy #1
        ldx #0
printmore:
        jsr putchar
        lda (pos),y
        beq done
        ;; limit lines printed to 7
        cmp #10
        bne :+
        inx
        cpx #8
        bcs done
:       
        ;; limit chars printed
        iny
        cpy #128
        bcc printmore
done:   
        PRINTZ {10,"...",10}

        jmp done2
        
nohi:
.endif ; ERRPOS

        ;; print source char
        jsr putchar

        jsr _incP
print:
        ldy #0
        lda (pos),y
        bne loop
;;; TODO: came here with no errors? 
;;;    or none to display?

done2:  
        jsr nl
.endif ; PRINTINPUT
.endscope

        ;; print next char (code) input+rule
.ifdef PRINTRULES
        PRINTZ {10,WHITE,"inp  @ "}
        lda inp
        ldx inp+1
        jsr _printh

        putc ' '
        ldy #0
:       
        lda (inp),y
        jsr _printchar
        iny
        cpy #20
        bne :-

        PRINTZ {10,WHITE,"rule @ "}
        lda rule
        ldx rule+1
        jsr _printh

        putc ' '
        ldy #0
:       
        lda (rule),y
        jsr _printchar
        iny
        cpy #20
        bne :-

        PRINTZ {10,WHITE,"rule @ "}
        lda _ruleVARS
        ldx _ruleVARS+1
        jsr _printh

        putc ' '
        ldy #0
:       
        lda (_ruleVARS),y
        jsr _printchar
        iny
        cpy #20
        bne :-
.endif ; PRINTRULES

        PRINTZ {10,10,YELLOW,"goto e)rror  ?) help",10,10}

        jmp _forcecommandmode



FUNC _OK

.ifdef INTRO
        ;; if first time (during init)
        bit mode
        bvc :+
        ;; then
        jsr waitesc
:       
.endif ; INTRO


.ifdef TESTING

.endif
        ;; reset erp(os)
        lda inp
        sta erp
        ldx inp+1
        stx erp+1

;;; TODO: detect if overrun OUTPUTSIZE
;;;    _out >= _outputend


 .ifdef __ATMOS__
;;; TODO: make function?
        lda #(GREEN+BG)&127
        sta SCREEN+35
.endif ; __ATMOS__


        jsr _eosnormal

        ;; size of text
        jsr nl
        lda originp
        ldx originp+1
        jsr strlen
        jsr _printu
        
        PRINTZ {" bytes source",10,10,"OK "}

        ;; print size in bytes
        ;; (save in gos, too)
;;; TODO: gos gets overwritten by dasm(?)
;;; TODO: optimize byte usage, subroutines?
        sec
        lda _out
        sbc #<_output
        sta tos
        sta gos
        lda _out+1
        sbc #>_output
        sta tos+1
        sta gos+1
        
        lda tos
        ldx tos+1

        jsr _printu
        PRINTZ {" Bytes (libs +"}

        sec
        lda #<_libraryend
        sbc #<_librarystart
        pha
        tay
        lda #>_libraryend
        sbc #>_librarystart
        pha
        tax
        tya

        jsr _printu
        PRINTZ {" bios +"}

        sec
        lda #<_biosend
        sbc #<_biosstart
        pha
        tay
        lda #>_biosend
        sbc #>_biosstart
        pha
        tax
        tya
        jsr _printu
        PRINTZ {")",10,10}

;;; TODO: make another variant of _OK that compiles in the background...

        ;; if first time (during init)
        bit mode
        bvc :+
        ;; - first time => go editor
        jmp _eventloop
:       
        ;; if invoked with CTRL-C go command mode
        jmp _forcecommandmode





.export _runs

.zeropage
_runs:   .res 1
.code

FUNC _run
        lda #1
        ldx #0
FUNC _runN
        ;; 0 => 1
        sta _runs
        txa
        ora _runs
        beq _run

        stx _runs+1

        ;; make sure have succesful compilation
        lda compilestatus
        beq :+
        ;; can't run; have error (?)
        PRINTZ {10,10,YELLOW,"Compile first...",10}
        lda #128
        sta mode
.ifdef __ATMOS__
        jmp _idecompile
.else
        ;; rts
        jsr _processnextarg
.endif
:       

        ;; TODO: print something if run from edit mode?
        jsr nl

        ;; set "BAR" TERMINAL program output colors 
        lda #BLACK+16           ; paper "WHITE BAR"
        ldx #WHITE&127          ; ink
        jsr _eoscolors

        ;; RUN PROGRAM _runs TIMES

.ifdef TIM
        ;; initiate CYCLE EXACT MEASUREMENT!
        lda #$ff
        sta READTIMER
        sta READTIMER+1
.endif ; TIM

again:
        jsr _output

        dec _runs
        bne again
        dec _runs+1
        bpl again

        ;; save result "reverse"
        pha
        txa
        pha

        jsr _eosnormal

.ifdef TIM
        ;; 13617
        lda READTIMER
        ldx READTIMER+1

        ;; adjust, one time overhead 10c, each loop 8
        ;; (may depend on code-location/page boundary?)
TIMONCE=10
TIMPER=8

;;; TODO: RUNTIMES ... was in run, not gone.... lol

        TIMCOST=$ffff - TIMONCE - TIMPER*RUNTIMES
        ;; saved lo, hi
        sec
        eor #$ff
        adc #<TIMCOST
        pha
        txa
        eor #$ff
        adc #>TIMCOST
        pha

        ;; make sure we're in textmode
.ifdef __ATMOS__
;        jsr $ec21
.endif

        ;; print "[47B 100x: 4711us]"
        PRINTZ {10,WHITE,"["}

        ;; print "47B "
;;; TODO: gos gets overwritten by dasm(?)
        lda gos
        sta tos
        ldx gos+1
        stx tos+1
        jsr putu
        PRINTZ {10,"B "}

        ;; print "100x: "
        lda #<RUNTIMES
        sta tos
        ldx #>RUNTIMES
        stx tos+1
        jsr putu
        PRINTZ {"x: "}

        ;; restore timing
        pla
        sta tos+1
        pla
        sta tos

        jsr putu

        PRINTZ {" us]",10}
.endif ; TIM

        ;; print return code
        PRINTZ {10,"=> "}

        ;; get it "reverse"
        pla
        tax
        pla

        ;; store it in runs! lol
        sta _runs
        stx _runs+1

        jsr _printu
        ;; (run finished)

        ;; fall-through
FUNC _forcecommandmode
        ;; - turn on command mode unconditionally
        lda mode
        ora #128
        sta mode

        jsr _processnextarg

        ;; fall-through

.ifdef __ATMOS__
;;; eventloop
;;; 
;;; Depending on "mode", you're either in
;;; edit mode (BPL) or command mode (BMI).
;;; 

;;; TODO: this is more like "entereditor(again)"
FUNC _eventloop
        ;; this is like a continuation;
        jsr _processnextarg

        ;; init if first time
        bit mode
        bvc :+
        ;; init + "load"
        jsr _loadfirst
        ;; remove init bit (V)
        lda mode
        eor #64
        sta mode
        ;; compiled ok?
        lda compilestatus
        beq :+
        ;; not
        jmp _ERROR
:       
        jmp editstart


;;; TODO: seems a bit roudabout the flow
;;;   works but...
command:
;        jsr _eosnormal

        ;; 'Q' to temporary turn on cursor!
.ifdef __ATMOS__
        PRINTZ {10,">",'Q'-'@'}
.else
        PRINTZ {10,">"}
        CURSOR_ON
.endif
        jsr getchar
        CURSOR_OFF

        ;; ignore return
        cmp #13
        beq command
        ;; ?help
        cmp #'?'
        bne :+
@minihelp:
        ;; 82 B
        PRINTZ {"?",10,"Command",10,YELLOW,"e)rror c)ompile r)un h)elp v)info",10,YELLOW,"q)asm  x)tras ESC-edit"}
        jmp command
:       

        ;; lowercase whatever to print!
        ora #64+32           
        jsr putchar

        ;; then convert any char to CTRL to run it!
        and #31


editing:
        jsr _editaction

editstart:
        bit mode
        bmi command

        ;; don't redraw if key waiting!'
        jsr KBHIT
        bmi :+
        ;; redraw
        jsr _redraw
:       
        jsr getchar
        jmp editing
.else 

FUNC _eventloop
        ;; this is like a continuation;
        jsr _processnextarg

        ;; TODO: hmmm...
        jmp _ide

.endif ; __ATMOS__





.ifdef __ATMOS__

FUNC _idecompile
        ;; We need to make sure no hibit (cursor)
        ;; is set in the code we compile, either
        ;; save a copy to compile in the background
        ;; or wait...

.ifdef __ATMOS__
        ;; update color status
        lda #(YELLOW+BG)&127    ; YELLOW = wait, lol
        sta SCREEN+35
.endif ; __ATMOS__
        jsr nl
        jsr _eosinfo
        PRINTZ {10,YELLOW,"compiling...",10,10}
        
        ;; Compile directly from editor!
;;; TODO: take snapshot? so can compile in background...
        lda #<EDITSTART
        ldx #>EDITSTART
        ;; There is no return, stack is (potentially) wiped
        ;; and when done goes to _ERROR or _OK!
        jmp _compileAX


FUNC _togglecommand
;;; 7
        lda mode
        eor #128
        sta mode

	;; actions
        ;; TODO: feels like lots of duplications?
;;; 11
        bpl @ed
        ;; re-sshow compilation result
        jsr _eosnormal
        jmp _reportcompilestatus

@ed:
        jmp _redraw

.endif ;  __ATMOS__






;;; when compiation goes bad, we replace
;;; _output code with jmp hell!
;;; 
;;; only used in the IDE

FUNC _hell
        lda #<666
        ldx #>666
        rts


;;; Print generated code info
;;; TODO: bad name
FUNC _outkey
        jsr _eosinfo
        .import _printvariables ; from C
        jsr _printvariables
        jmp _forcecommandmode


;;; PRINTASM uses this function
;;; it prints source code from here till next ';'
FUNC _asmprintsrc
;;; 47 !
        ;; print next statement fully
        ;; from inp,y
        ;; 
        ;; (limit 256 chars)

;        jsr _printstack

        jsr _iasm
        
        PRINTZ {";",WHITE," "}

        ldy #0
;        iny
@nextc:       
        lda (inp),y
        beq @end
        cmp #10
        beq :+
        cmp #' '
        beq :+
        jsr putchar
:       
        cmp #';'
        beq @end
        cmp #'{'
        beq @end
        cmp #'}'
        beq @end

        iny
        bne @nextc
@end:
        putc GREEN

        rts



;.include "Play/byte-sieve-gen.asm"
;.include "Play/byte-sieve-gen-opt.asm"


;;; TODO: move to... ?

;;; Go back to prompt
FUNC _NMI_catcher
;;; 24
        ;; report current PC
        jsr nl
        plp
        pla
        tay
        pla
        tax
        tya
        jsr _printh
        
        ;; reset stack pointer
        ldx #$ff
        txs

        ;; Reset colors
        jsr _eosnormal
        PRINTZ {10,RED+BG,"RESET",10}

;;; TODO: keyboard disabled if NMI during "loading..."

        jmp _forcecommandmode


;;; TODO: move somewhere else?

;;; This doesn't work at all!?!??!

origint:        .res 2
        
.ifdef INTERRUPT
FUNC _interrupt
; nah
;        rti
; nah
;        jmp (origint)

; better - LOL - WTF? how is this not equivalent?
;;; getting %R means somethingon stack messed up!!!
;        jmp $ee22

;;; doesn't get back to main code...

;;; copy of $ee22 routine...
        pha
        lda $0300
        and #$40
        beq :+
        sta $0300
        jsr $ee34
:       

;;; doesn't help much more
;        pla
;        rti

;;; gets called but no normal work done
;        PUTC '*'
        pla
        ;; basically jump to an changable rti!
        jmp $024a

;;
        
        pha
        txa
        pha
        tya
        pha

        PUTC '*'

        pla
        tay
        pla
        tax
        pla

        rti

        jmp (origint)
;        rti

        pha
        txa
        pha
        tya
        pha

;;; even this doesn't work...
        pha

        ;; count till hundred
        inc centis
;;; 85s if nothing
;;; (/ 85 34.45) = 2.46 ... 

;;; 34.4s
;        lda centis              ; if reversecount save 2c
;        cmp #100
        bne @done
        ;; update seconds
        inc seconds
        bne @next
        bne :+
        inc seconds+1
:       
PUTC '*'
.ifdef DOIT
        ;; print
        lda tos
        pha
        lda tos+1
        pha

        putc 'M'-'@'
        lda seconds
        sta tos
        lda seconds+1
        sta tos+1
        jsr putu
        jsr spc

        pla
        sta tos+1
        pla
        sta tos

.endif ; DOIT
@next:
        ;; reset centis
        lda #0
        sta centis

@done:
        pla
        tay
        pla
        tax
        pla
;;; lol?
;        rts

;;; no effect?
;        cli

        rti

.endif ; INTERRUPT



;;; set colors for COMMAND menu/hints (yellow)
FUNC _eoscommand
        ldx #YELLOW&127
        SKIPTWO
        ;; fall-through

;;; set colors for INFO by IDE
FUNC _eosinfo
        ldx #WHITE&127
        SKIPTWO
        ;; fall-through

;;; reset to EDITOR normal/default/user input
FUNC _eosnormal
        ldx #GREEN&127          ; ink
@skipshere:
        lda #BLACK&127+BG       ; paper
        ;; fall-through

;;; Change default print colors:
;;;   A= paper
;;;   X= ink
FUNC _eoscolors
.ifdef __ATMOS__
        sta PAPER
        stx INK
        GOTOXY 2,27
.else
        ;; LOL, ./oric-terminal changes to ANSI
        jsr putchar
        txa
        jsr putchar
.endif ; __ATMOS__        

        jsr nl
        jmp nl



FUNC _listfiles
        jsr clrscr
        ;; search for nothing
        lda #0

;;; lda #'p'
;;; jsr _searechfileA
;;; beq @notfound

FUNC _searchfileA
        sta savex

        ;; init
        lda #<input
        ldx #>input
        sta tos
        stx tos+1

        lda #'a'
        sta savea
@nextfile:       
        ;; no more files? (0,0)
        ldy #0
        lda (tos),y
        beq @done

        ;; target file?
        lda savex               ; target
        ;; ? target==0 => listing
        beq @listing
        ;; ? target==current match!
        cmp savea
        bne @goendfile          ; no print
        
        ;; match found!
        lda tos
        ldx tos+1
        rts

@listing:
        ;; print 'letter'
        putc WHITE
        lda savea
        jsr putchar
        putc GREEN

        ;; print first line
:       
        lda (tos),y
        beq @donefile
        cmp #10
        beq @donefile
        jsr putchar
        jsr _incT
        jmp :-

@donefile:
        jsr nl

@goendfile:
        ;; skip till end of file
:       
        lda (tos),y
        beq :+
        jsr _incT
        jmp :-
:       
        ;; go next file
@endfile:
        jsr _incT
        inc savea
        jmp @nextfile

@done:
        ;; no file
        lda #0
        tax
        rts





FUNC _help
        lda #<_helptext
        ldx #>_helptext
        jsr _printz

        jsr waitesc

FUNC _listsymbols
        ;; display names from ruleS
        PRINTZ {12,10, DOUBLE,YELLOW,"Symbols found",10, DOUBLE,YELLOW,"Symbols found",10, 10}
        
        lda #<_rules
        sta pos
        lda #>_rules
        sta pos+1
@nextbar:
        ldy #0
        lda (pos),y
        jsr _incP
        cmp #'|'
        bne @nextbar
        ;; next char
        lda (pos),y
        ;; end of rules ( endrules!)
        cmp #$ff
        beq @donelist
        ;; standing at name (maybe)
        ;; - print space if no have
        pha
        ldy CURCOL
        dey
        lda (ROWADDR),y
        cmp #' '+1
        bcc :+
        jsr spc
:       
        pla
@nextchar:       
        cmp #'a'
        bcc @nextbar
        cmp #'z'+1
        bcs @nextbar
        jsr putchar
        jsr _incP
        ldy #0
        lda (pos),y

        jmp @nextchar
        
@donelist:
        ;; fall-through
waitesc:
        PRINTZ {CYAN,"    ESC>"}
        jsr getchar
        jmp _eosnormal
FUNC _helpend

FUNC _helptext

;;; 10. If a print line starts with control characters
;;;     – e.g., ESC N, etc. – then the protected columns
;;;     0 and 1 are used, overwriting any PAPER and INK
;;;     attributes. Always start the line with a
;;;     non-attribute character, such as space.

MEAN=WHITE
KEY=GREEN
CODE=GREEN
GROUP=YELLOW

.byte 'A'
.byte 12,10
;.byte 12,128+'A',128+'B',128+'C',10
.byte DOUBLE,"ORIC",YELLOW,"CC02",NORMAL,MEAN,"alpha",GREEN,DOUBLE,"minimal C-compiler",10
.byte DOUBLE,"ORIC",YELLOW,"CC02",NORMAL,' ',"     ",' ',DOUBLE,"minimal C-compiler",10
;.byte 128+'D',128+'E'
.byte "",10
.byte KEY,"ESC",MEAN,"cmd/edit",KEY," ^V",MEAN,"info",10
.byte KEY," ^C",MEAN,"ompile  ",KEY," ^X",MEAN,"tras",10
.byte KEY," ^R",MEAN,"un      ",KEY," ^Z",MEAN,"ource",10
.byte KEY," ^Q",MEAN,"asm    - shows compiled code",10
;.byte KEY,"(^W",MEAN,"rite   - save source)",10
;.byte KEY,"(^L",MEAN,"oad    - load source)",10
.byte KEY,"NMI",MEAN,"stop program",10
.byte 10
.byte KEY,"DEL",MEAN,"bs",KEY,"^D",MEAN,"del",KEY,"^A",MEAN,"|<-",KEY,"^I",MEAN,"ndent",KEY,"^E",MEAN,"->|",10
.byte GROUP,"Line:",KEY," ^P",MEAN,"rev",KEY,"^N",MEAN,"ext",KEY,"RET",MEAN,"next indent",10
.byte "      ",KEY," ^K",MEAN,"ill",KEY,"^Y",MEAN,"ank",KEY,"^G",MEAN,"quit/clear",10
.byte "",10
.byte WHITE,"#include <foo.c> // # line ignored",10
;.byte GROUP,"V :",CODE,"v",CODE,"  v[byte]",MEAN,"==",CODE,"*(char*)v",MEAN,"==",CODE,"$ v",10
.byte GROUP,"V :",CODE,"word v, abba, x_y, x3;",10
.byte GROUP,"S :",CODE,"v 17 0x2a 0b1011 'c'",WHITE,34,"simple",34,10
.byte GROUP,"= :",GROUP,"V",CODE,"=",GROUP,"V",MEAN,"[",GROUP,"OP S",MEAN,"]...",CODE,";",MEAN,"   or",CODE,"a+=",GROUP,"S;",10
.byte GROUP,"OP:",CODE,"+ - & | ^ *2 /2 << >> == <",10
.byte GROUP,"FN:",CODE,"word A(...) {... return ...; }",10
.byte "  ",CODE,"if (...)...",MEAN,"OPT:",CODE,"else ...",10
.byte "  ",CODE,"while(...)...",MEAN,"test",CODE,"!v v<",GROUP,"S",CODE," v==",GROUP,"S",10
.byte "  ",CODE,"do...while(...);",MEAN,"most efficient!",10
.byte "  ",CODE,"for(...; ...; ...)...",MEAN,"least",10
;;; TODO:
;.byte "  ",CODE,"L: ... goto L;"
.byte 0



.ifdef INTRO
;;; TODO: put where heap will grow? - then overwrite?
FUNC _introtext
.byte 10
.byte DOUBLE,YELLOW,"MeteoriC",NORMAL,MEAN,"alpha",GREEN,DOUBLE,"minimal C-compiler",10
.byte DOUBLE,YELLOW,"MeteoriC",NORMAL,' ',"     ",' ',DOUBLE,"minimal C-compiler",10
.byte 10
.byte WHITE,"`2026 Jonas S Karlsson jsk@yesco.org",10
;;;          ----------------------------------------
.byte 10
.byte GREEN,"This is an",CYAN,"early alpha demo",GREEN,"version",10
.byte GREEN,"of a",YELLOW,"minimal",GREEN,"C-language compiler",10
.byte GREEN,"that runs on 6502:",10
.byte YELLOW," - a",CYAN,"minimal",YELLOW,"subset of C",10
.byte YELLOW," - an IDE:",CYAN,"editing & examples",10
.byte YELLOW," - only",GREEN,"word",YELLOW,"datatype",10
.byte YELLOW," - functions (recursive <= 8 args)",10
.byte YELLOW," - no local variables (coming)",10
.byte YELLOW," -",GREEN,"if for while do-while",WHITE,"< == !",10
.byte YELLOW," - ops:",CODE,"+-*&|^ *2 /2 << >> ! ++ --",10
.byte YELLOW," - no op precedence:",GREEN,"1+2*4  =>7!",10
.byte YELLOW," -",CYAN,"std libraries",YELLOW,"or",CYAN,"libraryless!",10
.byte YELLOW," -",CYAN,"ATMOS",YELLOW,"API for graphics/sound routines",10
.byte MAGNENTA,"...more features coming...",10
.byte 10
.byte 0

.endif ; INTRO


;;; TODO: sim65 interact with files?

.ifdef __ATMOS__

;;; ORIC tape max length 16
FILENAMESIZE=17

;filename:       .res FILENAMESIZE+1
;;; TODO: dummy for now
filename:              
        .byte "userfile.c",0
        .res FILENAMESIZE-.strlen("userfile.c")-1


copyfilename:
;;; this code is stupid, just copies 15 bytes
;;; from CC65 store_filename, doesn't care about length?
        ldy #$0f
        lda #<filename
        ldx #>filename
        sta tos
        stx tos+1
@nextc:
        lda (tos),y
        sta $027f,y
        dey
        bpl @nextc
        
        rts


FUNC _writefileas
        jsr _eosnormal
        
        PRINTZ {10,YELLOW,"Write to file as:",WHITE}

        ;; fgets(char*,int len,stdio) => ptr
        lda #<filename
        ldx #>filename
        sta tos
        stx tos+1

        lda #FILENAMESIZE
        ldx #0

        jsr _fgets_edit

        ;; 0 bytes => abort, otherwise save!
        stx savex
        ora savex
        beq :+

putc 'c'

FUNC _savefile

PUTC 'd'
;;; crashes during save? HMMM, WHY?
        PRINTZ {10,"Writing..."}
        lda #<filename
        ldx #>filename
        jsr _printz
        jsr nl
putc 'e'

.ifblank
        ;; _atmos_save see cc65
        ;; CC65 calling convention

        sei
        ;; store file start address
        lda #<EDITSTART
        ldx #>EDITEND
        sta $02a9               ; file start lo
        stx $02aa               ; file start hi
        ;; store file end address
        lda editend
        ldx editend+1
        sta $02ab               ; file end lo
        stx $02ac               ; file end hi

        jsr copyfilename

        ;; what data is this?
        lda #$00
        sta AUTORUN

        ;; mark as "machinecode", otherwise pops to basic?
        lda #$80
        sta LANGFLAG

        ;; calling interrupt subroutine?
        jsr csave_bit
        cli

        jmp _eventloop

csave_bit:      
        php
        jmp $e92c

.endif

:       
        jmp _eventloop



FUNC _loadbuffer
        jsr _eoscommand
        PRINTZ {"? - list preloaded examples",10}

        ;; get user selection
        jsr _eosnormal
        jsr getchar

        ;; or ?
        cmp #'?'
        bne :+
listbuffers:
        jsr _listfiles
        ;; let user choose buffer
        jsr getchar
:       

        ;; save it (isupper destroys)
        pha

        ;; ? check if 'a-z' (A-Z) or abort
        jsr isalpha
        beq :+
        ;; => save current buffer/copy buffer
        ;; TODO: save current letter buffer (if edited?)

        ;; lowercase
        pla
        ora #32

        jsr _searchfileA
        beq @notfound
@found:
        jsr _loadfromAX
        ;; TODO: compile first?
        
        jmp _eventloop

@notfound:       
        PRINTZ "% Not found!"
        jmp _forcecommandmode

:      
        pla

        ;; load tape file?
        pha
        jsr isalpha
        beq :+

        pla

;;; load file (ask for name)
openfile:
        jsr _eosnormal
        
        PRINTZ {10,YELLOW,"Open file:",WHITE}

        ;; fgets(char*,int len,stdio) => ptr
        lda #<filename
        ldx #>filename
        sta tos
        stx tos+1

        lda #FILENAMESIZE
        ldx #0

        jsr _fgets_edit

        ;; 0 bytes => abort, otherwise save!
        stx savex
        ora savex
        beq :+

        jsr _clearedit

        ;;; _atmos_load cc65
        sei
        jsr     copyfilename
        ldx     #$00
        stx     AUTORUN       ; $00 = only load, $C& = run
        stx     JOINFLAG      ; don't join it to another BASIC program
        stx     VERIFYFLAG    ; load the file

        ldx     #$80          ; machinecode
        stx     LANGFLAG      ; BASIC

        jsr     cload_bit
        cli
        jmp loadedfile
cload_bit:
        pha
        jmp     $e874
loadedfile:

        ;; update editend (search \0!)
        lda #<EDITSTART
        ldx #>EDITSTART
        sta editend
        stx editend+1
        
        ;; TODO: use strlen, fewer bytes?
;;; 13 B
        ldy #0
@loop:       
        lda (editend),y
        beq :+

        ldx #editend
        jsr _incRX
        ;; Z=1
        bne @loop

        ;; force edit mode
        lda #0
        sta mode

        jmp _eventloop

:       
        ;; get key back
        pla

        ;;  more commands

        jmp _forcecommandmode

.else
FUNC _writefileas
FUNC _savefile       
FUNC _loadfile
openfile:       
        ;; TODO: not amos buffer
        PRINTZ {10,"% Not implemented"}

        rts
.endif ; __ATMOS__




;;; CTRL-X: extras
FUNC _extend
;;; 16 
        jsr _eoscommand

        lda #<_extendinfo
        ldx #>_extendinfo
        jsr _printz
      
        jsr _eosnormal
        jsr getchar
        ;; everything becomes CTRL-A .. CTRL-Z !
        ;; (a-z, A-Z)
        and #31

.ifdef __ATMOS__
        ;; ^X^B - emacs list buffers!
        cmp #CTRL('B')
        bne :+
        jmp listbuffers
:       
        ;; ^X^F - open file from tape/disk
        cmp #CTRL('F')
        bne :+
        jmp openfile
:       
        ;; ^X^S - save current file
        cmp #CTRL('S')
        bne :+
        jmp _savefile
:       
        ;; ^X^W - write/save file as
        cmp #CTRL('W')
        bne :+
        jmp _writefileas

.endif ; __ATMOS__

        ;; CTRL-C : compile "input" (unmodified)
        cmp #CTRL('C')
        bne :+

        PRINTZ {"Compile Input",10}
        jmp _compileInput
:       

.ifdef bytesieve
        cmp #'J'
        bne :+
        jmp bytesieve
:       
.endif
        rts



;;; TODO: sedoric loads file save file
;;; -  https://github.com/iss000/oricOpenLibrary/blob/main/lib-sedoric%2Flibsedoric.s

FUNC _extendinfo
.byte 10
.byte "b - ^Buffers: show examples",10
.byte "f - ^Files open from tape/disk",10
.byte "s - ^Save current file",10
.byte "w - ^Write/save new file as (new name)",10
;.byte "^Crash/exit",10
;.byte "^Zleep",10

.byte 0

FUNC _helptextend

.include "memcpy.asm"


.export lastcs

.zeropage
  lastcs:  .res 2
.code

FUNC timer
.ifdef TIM
        lda READTIMER
        ;; TODO: could just see a flip!
        ldx READTIMER+1
        
        ;; $ffff-AX
        eor #$ff
        tay
        txa
        eor #$ff
        tax
        tya

        ;; print it
        jsr nl
        putc WHITE
        putc '['
;        putc 'T'

TODO:    this will not work, A destroyed

        sta tos
        stx tos+1
        jsr putu

        PRINTZ {"us"}
;        jsr nl
        
        ;; CLEAR TIMER
        lda #$ff
;        sta READTIMER
        ;; this write triggers reset
;        sta READTIMER+1
.else

        ;; software interrupt ORIC timer
        ;; 100 ticks/s
        lda CSTIMER
        ldx CSTIMER+1
        
        ;; $ffff-AX
CSRESET=1

.ifdef CSRESET
        eor #$ff
        tay
        txa
        eor #$ff
        tax
        tya
.else
.ifnblank
        sec
        eor #$ff
        adc lastcs
        tay
        txa
        eor #$ff
        adc lastcs+1
        tax
        tya
.endif ; BLANK
.endif ; CSRESET

.endif ; TIM

        ;; print it
.ifdef TIM
;        jsr spc
.else
        jsr nl
        jsr _printu
        PRINTZ {"cs"}

.endif
        PRINTZ {"]",GREEN,10}

.ifdef CSRESET
        lda #$ff
        sta CSTIMER
        sta CSTIMER+1
.else
        sta lastcs
        stx lastcs+1
.endif

.ifdef TIM
        lda #$ff
        ;; writing hibyte triggers
        sta READTIMER
        sta READTIMER+1
.endif
        rts


FUNC _ideend



FUNC _debugstart
;;; print "$4711@$34 "
FUNC _printvar
;;; 32
        jsr spc

        lda 0,y
        ldx 1,y

        jsr _printh

        tya
        PUTC '@'
        PUTC '$'
        jsr _print2h

        jmp nl

;;; TODO: not used remove
.ifdef PRINTADDRESS
FUNC printaddress
        sta tos
        stx tos+1
        PUTC '@'
        jsr _printh
        putc '='
        ldy #1
        lda (tos),y
        tax
        dey
        lda (tos),y
        jsr _printu
        jsr spc
        rts     
.endif


FUNC _printinp
        lda inp 
        ldx inp+1
        jmp _printz

;;; prints readable otherwise:
;;; (newline is printed)
;;; _c means hibit-set for 'c'
;;; [NUM] is the charcode of 'c' (c&127 < 32)
;;; $ = \0
;;; _$ means \0 with hibit === 128
FUNC _printchar
;;; 96 !!!
        pha
        tya
        pha
        txa
        pha
        
        tsx
        lda $103,x

        ;; ? hi-bit set '
        bpl :+
        ;; - remove hi-bit
        and #127
        PUTC '_'
:       
        bne :+
        ;; ? zero - print $ and newline
        putc '$'
        SKIPTWO
:       
        ;; ? newline
        cmp #10
        bne :+
        pha
        jsr putchar
        lda #13
        jsr putchar
        pla
:       
        ;; print [CODE] or plain (c < 128)
        cmp #' '
        bcs @printplain
@printcode:
        PUTC '['
        ldx #0
        jsr _printu
        putc ']'

        jmp @done
@printplain:
        jsr putchar
@done:

        pla
        tax
        pla
        tay
        pla
        rts


;;; TODO: ridiculus long!!! shorten?

;;; prints vars
;;; FORMAT: foo    $varaddr typechar   @value
FUNC _printvars

        PRINTZ {10,"=== VARS ==="}
        lda _ruleVARS
        sta tos
        lda _ruleVARS+1
        sta tos+1
        jsr _incT
        
        ldy #0
        sty savex               ; indent indicator

@nextline:
        jsr nl
@next:
        lda (tos),y
        bne :+
@done:
        PUTC '<'
        rts
:       
        cmp #'%'
        beq @percent
        jmp @normal
@percent:        
        jsr _incT
        lda (tos),y

        ;; new function hiding?
        cmp #'R'
        bne :+
        
        PRINTZ {"-- params & F"}
;;; Have some problem here???
        inc savex
        jsr _incT
        jsr _incT
        jsr _incT
        jmp @nextline
:       
        cmp #'b'
        bne :+
        jsr _incT
        jmp @next
:       
        cmp #0
        bpl @normal

@skipperORrule:
        and #127
        cmp #' '+1
        bcs @normal

        ;; store how bytes to skip
        sta savey

        ;; print varaddr
.ifdef __ATMOS__
:       
;;; TODO: gotox ?
        lda CURCOL
        cmp #20
        beq :+
        jsr spc
        jmp :-
:       
.else
        jsr tab
.endif
        iny
        iny
        ;; get typechar
        iny
        lda (tos),y
        sta savea
        dey
        ;; print address
        ;; - get hi
        lda (tos),y
        tax
        ;; - get lo
        dey
        lda (tos),y
        dey

        sta pos
        stx pos+1
        jsr _printh

        ;; print value
        jsr spc
        ldy #1
        lda (pos),y
        tax
        dey
        lda (pos),y
        
        ;; jsr _printn prints garbage???
        jsr _printu
        ;; print type
        jsr tab
        lda savea
        jsr _printchar
        ;; Fun extra newline
        lda savea
        cmp #'F'
        bne :+
        jsr nl
:       

        ;; skip bytes
        jsr _incT
        lda (tos),y
;        jsr _printchar
        dec savey
        bne :-
        
        jsr _incT
        jmp @next

@normal:
        jsr _incT
        cmp #'|'
        bne :+
        jmp @nextline
:       
        jsr _printchar
        jmp @next



;;; prints current variable envioronment structure
;;; FORMAT: $addr foo%b%_[3] [$varaddr] varaddrbytes F |
FUNC _printenv

        PRINTZ {10,"---ENV---"}
        lda _ruleVARS
        sta tos
        lda _ruleVARS+1
        sta tos+1
        jsr _incT
        
        ldy #0

@nextline:
        jsr nl
        lda tos
        ldx tos+1
        jsr _printh
        jsr spc
@next:       
        lda (tos),y
        beq @done
        cmp #'%'
        bne :+
        PUTC 9                  ; TAB (not oric)
:       
        jsr _printchar

        cmp #'%'
        bne @normal
        jsr _incT
        lda (tos),y
        jsr _printchar

        ;; print skipjumper address
        cmp #'R'
        bne :+
        
        jsr _incT
        putc '['
        iny
        lda (tos),y
        tax
        dey
        lda (tos),y
        jsr _printh
        putc ']'
        
        jsr _incT
        jmp @nextline
:       
        cmp #0
        bpl @normal

@skipperORrule:
        and #127
        cmp #' '+1
        bcs @normal

        sta savey

        ;; print [varaddr]
        putc '['
        iny
        iny
        lda (tos),y
        tax
        dey
        lda (tos),y
        dey
        jsr _printh
        putc ']'

        ;; print skipped bytes
:       
        jsr _incT
        lda (tos),y
        jsr _printchar
        dec savey
        bne :-

@normal:
        jsr _incT
        cmp #'|'
        bne @next
        jmp @nextline

@done:       
        PUTC '<'
        rts


FUNC _printstack
;;; 119  !!!!!
        pha
        tya
        pha
        txa
        pha

        tsx
        inx
        inx
        inx                     
        inx                    
        inx

        lda tos+1
        pha
        lda tos
        pha
        ;; we can use the stack for print

        jsr nl
        putc '#'
        lda rulename
        jsr _printchar
        jsr spc
        putc 's'

        ;; print s
        stx tos
        txa
        jsr _print1h

@loop:
        jsr spc
        ;; print first byte

        lda $101,x

        jsr _printchar
        inx
        beq @err

        ;; end marker?
.ifnblank
        lda tos
        cmp #DONE
        beq @done
.endif        

.ifdef DEBUGRULE2ADDR
        putc '-'
        ;; print 1 word
        lda $101,x
        sta tos
        inx
        beq @err

        lda $101,x
        inx
        beq @err
        sta tos+1
        jsr puth
.else
        inx
        beq @err
        inx
        beq @err
.endif ; DEBUGRULE2ADDR

        jmp @loop

@err:
        PRINTZ {"  oo"}
@done:
        putc '>'
;;; TODO: 
.ifndef TIM
        jsr getchar
.endif
        sta savea
        jsr nl

        pla
        sta tos
        pla
        sta tos+1

        pla
        tax
        pla
        tay
        pla

        lda savea
        cmp #';'
        bne @ret
        ;; drop one - for debug when messed up
        pla
        sta savex
        pla
        sta savey

        ;; drop one
        pla

        lda savey
        pha
        lda savex
        pha

        jmp _printstack
@ret:
        rts
FUNC _debugend



;;; TODO: make it point at screen,
;;;   make a OricAtmosTurboC w fullscreen edit!

;;; Pretend to be prefixed by:
;;; 
;;;   typedef unsigned uint16_t word;
;;; 

;;; TODO: remove "word" and make "int" default.
;;;   all ops except < don't care! (2 complement)


;;; OK, not fully true, but try not put 
;;; any code after here!

FUNC _asmend

;;; TODO: move to beginning of _init/_compiler
;;;   we want to able to NUKE it from memory!

FUNC _inputstart

;;; TODO: remove
;;; This is just to keep input safe, lol
;;; _incIspc may mark prev as read, and or 
;;; it could be used by memcpyz that need prefix?
.byte 0,0


.FEATURE STRING_ESCAPES
input:

;ANDOR=1
.ifdef ANDOR
        .byte "word o,z;",10
        .byte "word main(){",10
        .byte "  o=1; z=0;",10
        .byte "  putu(0);",10
        .byte "  putu(1);",10

.ifnblank
;;; 384 B
        .byte "  putu(0&&0);",10
        .byte "  putu(0&&1);",10
        .byte "  putu(1&&0);",10
        .byte "  putu(1&&1);",10
        .byte "  putu(1&&1);",10
        .byte "  putu(1&&1&&1);",10
        .byte "  putu(1&&1&&1&&1);",10
        .byte "  putu(1&&1&&1&&0);",10
.else
;;; 419 B - no opt
;;; 321 B - opt (/ (- 419 321) 14) = ~7 saved/&&
        .byte "  putu(z&&z);",10
        .byte "  putu(z&&o);",10
        .byte "  putu(z&&o);",10
        .byte "  putu(o&&z);",10
        .byte "  putu(o&&o);",10
        .byte "  putu(o&&o);",10
        .byte "  putu(o&&o&&o);",10
        .byte "  putu(o&&o&&o&&o);",10
        .byte "  putu(o&&o&&o&&z);",10
.endif ; !vars

;        .byte "  putu(0||0);",10
;        .byte "  putu(0||1);",10
;        .byte "  putu(1||0);",10
;        .byte "  putu(1||1);",10
        .byte "}",10
        .byte 0
.endif ; ANDOR

;ETERNAL=1
.ifdef ETERNAL
        .byte "word main(){",10
        .byte "  while(1) putchar('.');",10
        .byte "  return 666;",10
        .byte "}",10
        .byte 0
.endif ; ETERNAL

;ARRAY=1
.ifdef ARRAY
        .byte "char array[]={70,111,111,66,65,,0};",10
        .byte "char gurka[]={'f','o','o','b','a','r',0};",10
        .byte "char bytes[7];",10
        .byte "char string[]=\"FOOBAR\";",10
        .byte "",10
        .byte "word p(word s){",10
        .byte "  putu(strlen(s)); putchar('>'); puts(s); putchar('<'); putchar('\\n');",10
        .byte "}",10
        .byte "word ph(word a){",10
        .byte "  puth(a); putchar(' ');",10
        .byte "}",10
        .byte "word main(){",10
        .byte "  ph(array); ph(gurka); ph(string); ph(bytes); putchar('\\n');"
        .byte "  ph(&array); ph(&gurka); ph(&string); ph(&bytes); putchar('\\n');"
        .byte "  p(bytes);",10
        .byte "  p(gurka);",10
        .byte "  p(array);",10
        .byte "  p(string);",10
.ifdef DODO
        .byte "  strcpy(bytes,\"FOOBAR\");",10
        .byte "  putchar(bytes[0]);",10
        .byte "  putchar(bytes[(char)i]);",10
        .byte "  putchar(bytes[(char)1-1]);",10
        .byte "  putchar(bytes[i]);",10
        .byte "  putchar(bytes[1-1]);",10
.endif
        .byte "}",10
        .byte 0

.endif ; ARRAY


;POINTERLOCAL=1
.ifdef POINTERLOCAL
        .byte "word global;",10
        ;; .byte "_regcall" then it's ok
        .byte "word fun(word local) {",10
        .byte "  return &global;",10
        .byte "  return &local;",10
        .byte "}",10
        .byte "word main(){}",10
        .byte 0
.endif ; POINTERLOCAL

;;; LinesPerSecond - 300 x "++i;\n"
;;; to test "maximum" lines/s ~ 31 on 1 MHz!
;;; 
;        .incbin "Input/lps-300.c"
;        .byte 0

;        .byte 0

;LESSTHAN=1
.ifdef LESSTHAN
        .byte "word a;",10
        .byte "word main(){",10
        ;; 7 bytes til here

;;; TODO: 
;        .byte "  a=3<4;",10

;;; TODO: bug - error! lol
;;;   TODO: lookahead wrong... lol (what's next input..)
        .byte "  a=3<4 ;",10

        ;; 37 B
;        .byte "  a= 3<4+1;",10
        ;; 33 B ! (- 33 5 7 3 3) = 15 for cmp?
;        .byte "  putu(3<4); putchar('\\n');",10 
        ;; 39 B (+ 6)
;        .byte "  putu(2+1<4); putchar('\\n');",10
	;; 45 B (+ 6 + 6)
;        .byte "  putu(2+1<3+1); putchar('\\n');",10
;        .byte "  putu(3+1<3+1); putchar('\\n');",10
;        .byte "  putu(3+1<2+1); putchar('\\n');",10

        .byte "  return a;",10
        .byte "}",10
        .byte 0
.endif ; LESSTHAN

; IFTEST=1
.ifdef IFTEST
        .byte "word v;",10
        .byte "word main(){",10
        .byte "  v=3;",10

        ;; 44 B
;        .byte "  if(v==3) return 1; else return 0;",10
        ;; 57 B   (= + 13)
;        .byte "  if(3==v) return 1; else return 0;",10

        ;; 52
;        .byte "  if(v==2+1) return 1; else return 0;",10

        ;; 63     (= + 11)
;        .byte "  if(2+1==v) return 1; else return 0;",10

        ;; 63
;        .byte "  if(v+1==4711) return 1; else return 0;",10
        ;; 63
;        .byte "  if(4711==v+1) return 1; else return 0;",10

        

        .byte "}",10
        .byte 0
.endif ; IFTEST

;DODEBUG=1
.ifdef DODEBUG
        .incbin "Input/plusplus.c"
;        .incbin "Input/music.c"
;        .incbin "Input/noel-retro.c"
        .byte 0
.endif ; DODEBUG


;;; TODO: %V variables... %v for 1 byte address? lol
;;; TODO: $name (byte) var and constant $a4,, lol ambigious!

;TESTASM=1
.ifdef TESTASM
        .byte "word main(){",10
        .byte "  LDA #41;",10
        .byte "  LDA #')';",10
        .byte "  LDA #0x29;",10
        .byte "  LDA #$29;",10
        .byte "  LDX #0;",10
        .byte "  NOP;",10      
        .byte "  NOP;",10
        .byte "  NOP;",10
        .byte "  CLC;",10
        .byte "  ADC #1;",10
        .byte "  RTS;",10
        .byte "}",10
        .byte 0
.endif ; TESTASM



;MUSIC=1
.ifdef MUSIC
        .incbin "Input/music.c"
;        .incbin "Input/noel-retro.c"
        .byte 0
.endif ; MUSIC


;;; TODO: PARSERING ERROR
;;;   should say "Expected: 'while'"
;;;   how difficult (longest parse rule match?)
;DOPARSE=1
.ifdef DOPARSE
        .byte "// foobar fie fum",10
        .byte "word i;",10
        .byte "word main() {",10
        .byte "  for(i=10; --i; ) do {",10
        .byte "    putchar('x');",10
        .byte "  }",10
        .byte "  printz(\"end\\n\");",10
        .byte "}",10
        .byte 0
.endif ; DOPARSE

;;;  for some reason this gives compile errrorr...
;WAIT=1
.ifdef WAIT
        .byte "// foobar fie fum",10
        .byte "word z;",10
        .byte "word wait(word cs) {",10
        .byte "  while(cs--) {",10
        .byte "  z= 1000; do {;} while(z--);",10
        .byte "}",10
        .byte "word main() {",10
        .byte "  putchar('>');",10
        .byte "  return wait(1000);",10
        .byte "  putchar('<');",10
        .byte "}",10
        .byte 0
.endif ; WAIT


;SPACEBUG=1
.ifdef SPACEBUG
        .byte "word a, b, c, line;",10
        .byte "word main() {",10
        .byte "  a= 47; b= a;",10
;;; TODO: space before + error!
        .byte "  a>>= 2; c= b*100 +a;",10
        .byte "  return c;",10
        .byte "}",10
        .byte 0
.endif ; SPACEBUG

;STRPARAM=1
.ifdef STRPARAM
        .byte "word s,bar;",10
        .byte "word main() {",10
        .byte "  s= \"foo456\";",10
.ifnblank
        ;; 68 B
        .byte "  bar= \"bar\";",10
        .byte "  strcpy(s+3, bar);",10
.else
        ;; 60 B saves 8 B!
        .byte "  strcpy(s+3, \"bar\");",10
.endif 
        .byte "  puts(s);",10
        .byte "}",10
        .byte 0
.endif ; STRPARAM


.ifdef TUTORIAL
        .incbin "Input/tutorial.txt"
        .byte 0

.else 

;;; Multi Assignment
;MASSIGN=1
.ifdef MASSIGN
        .byte "word a,b,c;",10
        .byte "word main(){",10
        .byte "  a=b=c=14;",10

;;; more difficult
;       a=1+(b=1+(c=13));
;;; actually not legal:
;        .byte "  a=b=1+c=13;",10

        .byte "  return a+b+c;",10
        .byte "}",10
        .byte 0
.endif ; MASSIGN


;;; 53 bytes - optimize one param function call -6 B
;;;    -> 47 B
;ONEPARAM=1
.ifdef ONEPARAM
        .byte "word double(word one) {",10
        .byte "  return one+one;",10
        .byte "}",10
        .byte "word main() {",10
        .byte "  return double(7);",10
        .byte "}",10
        .byte 0
.endif ; STRPARAM

;IFLT=1
.ifdef IFLT
        .byte "word i;",10
        .byte "word main(){",10
;        .byte "  i=4; return i<4;",10  ; fine
        .byte "  i=4; if (i<4) return 1; else return 0;",10
        .byte "}",10
        .byte 0
.endif ; IFLT


;        .incbin "Input/fib-list.c"
;        .byte 0

;;; BUG: requires var to compile empty stmt in do-whie!
;BUGVAR=1
.ifdef BUGVAR
        ;; if remove this line files compile while???
        .byte "word x;",10

        .byte "word main(){",10
        .byte "  do ; while(1);",10
        .byte "}",10
        .byte 0
.endif ; BUGVAR

;WHILE=1
.ifdef WHILE
        .byte "word n,x;",10
        .byte "word main(){",10
        .byte "  n= 0; x= 10;",10
        ;; 21 B till here

        ;; 60 - more expensive (extrea jump)
;        .byte "  while(n<10) putchar(n++ + '0');",10

        ;; 54 B (dowhile<) - CHEAPEST!!! special rule
;        .byte "  do putchar(n++ + '0'); while(n<10);",10

        ;; 54 B special rule (65 generic) (+ x=10 => + 8B)
;        .byte "do putchar(n++ + '0'); while(n<x);",10

;;;  LOL because current TRUE == -1 +1 == 0!!! lol
        ;; 72 B
;        .byte "do putchar(n++ + '0'); while(n-1<x);",10
;;; cant' do
;        .byte "do putchar(n++ + '0'); while(n<x+1);",10
;        .byte "return n<x-1;",10

        ;; 43 B eternal (53 B) special rule
        .byte "do putchar(n++ + '0'); while(1);",10
        ;; 40 B
;        .byte "do putchar(n++ + '0'); while(0);",10 

        ;; 60 B
;        .byte "x=10;while(n<x) putchar(n++ + '0');",10

.ifnblank
        ;; 75 w special rule
        .byte "  do {",10
        .byte "    putchar(n++ + '0');",10
        .byte "    if (n==10) x=1; else x=0;",10;
        .byte "  } while(!x);",10
.endif

.ifnblank
        ;; 75 w special rule
        .byte "  do {",10
        .byte "    putchar(n++ + '0');",10
        .byte "    if (n==10) x=0; else x=1;",10;
        .byte "  } while(x);",10
.endif
        .byte "}",10
        .byte 0
.endif ;WHILE


;EQTEST=1
.ifdef EQTEST
        ;; ==0   => 61-63 B   59-61 B  if(%V==0) improvement
        ;; ==3+4 => 82-84 B   71-73 B  if(%V==_E general
        ;; ==7   => 65-67 B   63-65 B  if(%V==%d) specific
        .byte "word x;",10
        .byte "word main(){",10
;        .byte "  x= 7;",10
        .byte "  x= 0;",10
;        .byte "  if (x==0) puts(\"zero!\");",10
        .byte "  if (x==7) puts(\"seven\");",10
;        .byte "  if (x==3+4) puts(\"seven\");",10
        .byte "  else puts(\"NOT\");",10
        .byte "}",10
        .byte 0
.endif ; EQTEST        

        ;; MINIMAL PROGRAM
        ;; 7B 19c
;        .byte "word main(){}",0

;        .byte "word main(){ return 4711; }",0

;        .byte "word abc;",10,"word main(){ return 4710+1; }",0

;        .byte "word abc,def,ghi,jkl;",10
;        .byte "word main(){ abc=4711; return abc; }",10
;        .byte "{return 42;};",10
;        .byte 0


;OPTINCBYTE=1
.ifdef OPTINCBYTE
        .byte "word p;",10
        .byte "word main(){",10
;        .byte "  p= 40; p+= 2;",10
        .byte "  p= 64; p-= 22;",10
        .byte "  return p;",10
        .byte "}",0
.endif ; OPTINCBYTE


;MUL=1
.ifdef MUL
        .byte "word main(){",10
;        .byte "  return 42*101;",10
        .byte "  return 42*1010;",10
        .byte "}",0
.endif ; MUL

;FUN4=1
.ifdef FUN4
        .byte "word four(word a, word b, word c, word d) {",10
        .byte "  return a+b+c+d;",10
        .byte "}",10
        .byte "word main() { return four(1,2,3,four(4,5,6,four(7,8,9,10))); }",10
        .byte 0
.endif ; FUN4



;;; cc65:   1     1929
;;;         2:    3682
;;;      1000:    1700/1     (/ 1700409 1000) = 1700
;;; => 386 B (341 if no loop)
;;; 
;;;    0: 2900153
;;;    1: 2915942
;;;    2: 2916714  (- 2916714 2915942)         =   772
;;;  100: 3089096  (- 3089096 2900153)         =  1889.43
;;;  255: 3361741  (/ (- 3361741 2915942) 255) =  1748
;;; => 147 bytes + 125 (+ 147 125) = 272

;MUL2=1
.ifdef MUL2
        .byte "word z;",10
        .byte "word mul(word a, word b) {",10
;        .byte "  putchar(' '); putu(a); putchar(' '); putu(b); putchar('\\n') ;",10
        .byte "  if (!a) return 0;",10
.ifnblank                        
        ;; 2x f calls => more code
        .byte "  if (a&1) return mul(a/2, b*2)+b;",10
        .byte "  return mul(a/2, b*2);",10
.else
        ;; careful, global variable...
        .byte "  z= mul(a/2, b*2);",10 
;;; To debug if right value are restored...
;        .byte "  putchar('='); putu(a); putchar(' '); putu(b); putchar(' '); putu(z); putchar('\\n');",10
        .byte "  if (a&1) return z+b;",10
        .byte "  return z;",10
.endif
        .byte "}",10

        .byte "word main() {",10
;        .byte "  return mul(3,4);",10
        .byte "  return mul(40,40);",10
        .byte "}",10
        .byte 0
.endif ; MUL2



;ARGSHADOW=1
.ifdef ARGSHADOW
        .byte "word a;",10
        .byte "word three(word a, word b, word c){ return a+b+c; }",10
        .byte "word two(word a, word b){ return a+b; }",10
        .byte "word seta(word v){ a= v; return a; }",10
        .byte "word geta(){ return a; }",10
        .byte "word shadow(word a){",10
        .byte "  putu(a); putchar(' ');",10
        .byte "  return geta();",10
        .byte "}",10
        .byte "word main() {",10
        .byte "  putu(a); putchar('\\n');",10
        .byte "  seta(42); putu(a); putchar('\\n');",10
        .byte "  putu(geta()); putchar('\\n');",10
        .byte "  putu(shadow(666)); putchar('\\n');",10
        .byte "  putu(shadow(17)); putchar('\\n');",10
        .byte "  putu(a); putchar('\\n');",10
        .byte "  putu(geta()); putchar('\\n');",10
        .byte "}",10
        .byte 0
.endif ; ARGSHADOW



;;; cc65:                             3110 c !!!
;;;       (/ 3322               1) =  3320 c ???
;;;       (/ 2893432         1000) =  2893 c ???
;;; -O    (/ 1849420         1000) =  1849 c
;;; -Oi   (/ 1693408         1000) =  1693 c  371 B
;;; progsz                                    363 B

;;; MC:   (- 2862398 2849291)      = 13107 (ide overhead)
;;;  2x-1 (- 2864211 2862398)         1813
;;;    (/ (- 2878715 2849291)  10) =  2942
;;;    (/ (- 3042871 2849291) 100) =  1935
;;;    (/ (- 3323886 2849291) 255) =  1861
;;; => 167 B (+ 26 B bios + 99 B runtime/misc)
;;;    292 B (+ 167 26 99)
;;; 
;;; Conclusion: we're using full/recursive param passing
;;;    also, BIOS+NOLIBRARY == 125 B 
;FUN2=1
.ifdef FUN2
        .byte "word plus(word a, word b) {",10
;        .byte "   putu(17);",10
;        .byte "  putu(a); putchar(' '); putu(b); putchar('\\n') ;",10
        .byte "  return a+b;",10
        .byte "}",10
        .byte "word main() {",10
.ifnblank
        .byte "  return plus(3,4);",10
.else
        .byte "  return plus(plus(1,",10
        .byte "                   plus(2, plus(3,4)) ),",10
        .byte "              plus(plus(5,plus(6,7)),",10
        .byte "                   plus(8,plus(9,10)) ) );",10
.endif
        .byte "}",10
        .byte 0
.endif ; FUN2

;;; Just testing sanity of no arg fun
;NEWFUN=1
.ifdef NEWFUN
        .byte "word foo(){ return 4700; }",10 
;        .byte "word main(){ return foo(); }",10
;        .byte "word main(){ return foo()+11; }",10
;        .byte "word main(){ return foo()+11; }",10

        .byte "word zzz;",10
        .byte "word main(){ zzz=foo()+11; return zzz; }",10

;        .byte "word main(){ return 11+foo(); }",10 ; can't!
;        .byte "word main(){ return 4711; }",10
        .byte 0
.endif ; NEWFUN



;EDITORTEST=1
;;; (* 200 35) = 7000 B, 3 chars/second

.ifdef EDITORTEST

;.repeat 200, I

;;; (* 50 35) = 1750 B, 7 chars/second (?)
.repeat 50, I

  .byte .sprintf("%d: ",I)
  .res 30,'A'
  .byte 10
.endrep

.byte 0

.endif ; EDITORTEST



;;; TEST size of WHILE loops
;WHILESIZE=1

.ifdef WHILE


;;; Measure size impact on OPTRULES and BYTERULES
;DOWHILE=1
.ifdef DOWHILE

        ;; 31 B optrules, wihtout 41 B
.ifdef BYTERULES
        ;; 20 B with BYTERULES and CAPital DO ... WHILE
        .byte "word main(){",10
        .byte "  $a=42;",10
;;; TODO: BUG, cant' match on "while($a)" after generating
;;;    "--$a;" so it gets generated twice!!!
;;; TODO: "$do" lol!!!
        .byte "  DO --$a; WHILE($a);",10
        .byte "}",0
.else
        .byte "word main(){",10
        .byte "  a=42;",10
        .byte "  do --a; while(a);",10
        .byte "}",0
.endif

.else

        ;; 33 B with OPTRULES, otherwise 46 B
.ifdef BYTERULES
        ;; 26 B with BYTERULES
        .byte "word main(){",10
        .byte "  $a=0;",10
        .byte "  while($a<42) ++$a;",10
        .byte "}",0
.else
        .byte "word main(){",10
        .byte "  a=0;",10
        .byte "  while(a<42) putu(++a);",10
        .byte "}",0
.endif

.endif ; !DOWHILE


.endif ; WHILESIZE




;;; TODO: memory corruption???
;;; ;;; def hEll0 changes to hAll0?
;;; CTRL-Z gives hAll0 too, indicating input
;;; corruption?
;;; (Also happens to BYTESIEVE=1 only it's in
;;;  the comment, so not detected)
;;; DOESN'T happen (there) on ./rrasm ...
;DEF=1
.ifdef DEF
        .byte "word a;",10
        .byte "word hEll0;",10
        .byte "word gurka33;",10
        .byte "word fish_666;",10
        .byte "word fish_42;",10
        .byte "word main(){",10
;;; TODO: don't use/allow &var - not safe for local!
        .byte "  puth(&a); putchar('\\n');",10
        .byte "  puth(&fish_42); putchar('\\n');",10
        .byte "  puth(&fish_42); putchar('\\n');",10
        .byte "  puth(&fish_666); putchar('\\n');",10
        .byte "  puth(&gurka33); putchar('\\n');",10
        .byte "  puth(&hEll0); putchar('\\n');",10
;        .byte "  puth(&not_find); putchar('\\n');",10

        .byte "  a=0;",10
        .byte "  fish_42=21;",10
        .byte "  a=a+fish_42*2;",10
        .byte "  putu(fish_42);",10
        .byte "return 4711; }",0
.endif ; DEF


;;; Experiments in estimating and prototyping
;;; function calls, using JSK_CALLING !

;PARAM4=1
.ifdef PARAM4

;
CANT=1
.ifndef CANT
        .byte "word F(word a, word b, word c, word d) {",10
        .byte "  if (a) return a+b+c+d;",10
        .byte "  return F(a-1, b+1, d*2, c/2);",10
        .byte "}",10
        .byte "",10
        .byte "word main() {",10
        .byte "  return F(22, 0, 1, 65535);",10
        .byte "}",10
        .byte 0
.else ; CANT
;        .byte "word F(word a, word b, word c, word d) {",10


.ifdef NOTHING
        .byte "word main() {",10
        .byte "}",10
        .byte 0
.endif ; NOTHING

.ifdef MINISUB
        .byte "word P(){",10
        .byte "  putchar(' '); puth(a);",10
        .byte "}",10
        .byte "word main() {",10
        .byte "  a=4660; P();",10
        .byte "}",10
        .byte 0
.endif ; MINISUB

;;; PRINT vars in calls
;P4PR=1
.ifdef P4PR
        .byte "word P(){",10
        .byte "  putchar(' '); puth(a);",10
        .byte "  putchar(' '); puth(b);",10
        .byte "  putchar(' '); puth(c);",10
        .byte "  putchar(' '); puth(d);",10
        .byte "  putchar(' '); puth(e);",10
        .byte "  putchar(' '); puth(r);",10
        .byte "  putchar('\\n');",10
        .byte "}",10
.endif ; P4PR
        .byte "word F(word a,word b,word c,word d) {",10
.ifdef P4PR
        .byte "  putchar('>'); P();",10
.endif
        .byte "  if (a) return F(a-1, b+1, d*2, c/2);",10
        .byte "  else return a+b+c+d;",10
;        .byte "  r= a+b+c+d;",10
.ifdef P4PR
        .byte "  putchar('<'); P();",10
.endif

;;; need to run postlude...
;        .byte "  return r;",10
;;; set AX
;        .byte "  r;",10

        .byte "}",10
        .byte "word i,r;",10
        .byte "word main() {",10
.ifdef P4PR
        .byte "  putchar('+'); P();",10
.endif
        .byte "i=1000;while(i--){",10
;.byte "i=1;while(i--){",10
;        .byte "  r= F(22, 0, 1, 65535);",10
;;; (/ 256 (+ 8 2 1 3)) 
;        .byte "  r= F(18, 0, 1, 65535);",10
        .byte "  r= F(17, 9, 1, 65535);",10
;        .byte "  r= F(0, 9, 1, 65535);",10
;;; I think value comes out wrong???
.byte "}",10


.ifdef P4PR
        .byte "  putchar('-'); P();",10
.endif

        .byte "  return r;",10
        .byte "}",10
        .byte 0
.endif ; CANT

.endif ; PARAM4


;STRBYTES=1
;;; 28 bytes (inline str, jmp over, lda/x)
;;; 21 bytes (inline after jsr inlinePuts)
.ifdef STRBYTES
        .byte "word main(){",1
;        .byte "  fputs(",34,"0123456789",34,",stdout);",10
        .byte " puts(",34,"0123456789",34,");",10
        ;; make sure newline for puts...
;        .byte " putchar('<');",10
        .byte "}",10
        .byte 0
.endif ; STRBYTES

;FORSMALL=1
.ifdef FORSMALL
        .byte "word main(){",10
        .byte "  for(i=0;i<100;++i)",10
        .byte "    putu(i);",10
        .byte "}",10
        .byte 0
.endif ; FORSMALL


;FORCOPY=1
.ifdef FORCOPY
        .byte "word main(){",10
;        .byte "  a= 48000; b= a+1;",10
        ;; #xbb80
        .byte "  s= 48000; t= s+1;",10
        .byte "  for(n=0;n<39;++n)",10

;;; TODO: fix
;        .byte "    a[n;=b[n];",10
;;; It's a lie, s and t not updated!
        .byte "    *s++=*t++;",10
;        .byte "    *(char*)s++=*(char*)t++;",10

        .byte "}",10
        .byte 0
.endif ; FOR

;FOR=1
.ifdef FOR
        .byte "word main(){",10
        .byte "  for(n=10;n--;) {",10
        .byte "    putu(n); putchar(' ');",10
        .byte "  }",10
        .byte "}",10
        .byte 0
.endif ; FOR

;WHILECOUNT=1
.ifdef WHILECOUNT
        .byte "word main(){",10
        .byte "  s= 0; e= 8000;",10
        .byte "  while(s<e) {",10
        .byte "    putu(s); putchar(' ');",10
        .byte "    s+= 40;",10
        .byte "  }",10
        .byte "}",10
        .byte 0
.endif ; WHILECOUNT

;TEMPLATE=1
.ifdef TEMPLATE
        .byte "word main(){",10
        .byte "  putu(6502);",10
        .byte "  return 42;",10
        .res 23,10
        .byte "}"
        .byte 0
.endif ; TEMPLATE

;;; return without argument, lol (AX)
;        .byte "word main(){ 666; return; }",0


;POKEGEN=1
.ifdef POKEGEN
;;; Used to debug codegen for POKE
;;; TODO: add way to do regression testsing on
;;;       code gen sizes etc...
        .byte "word main() {",10
        .byte "  poke(7, 0);",10 ; 4 B
        .byte "  poke(4711, 0);",10 ; 5 B
        .byte "  poke(a, 0);",10 ; 5 B
        .byte "  poke(a, 3);",10 ; 6 B
        .byte "  poke(7, 17+4);",10
        .byte "  poke(a, 17+4);",10
        .byte "  poke(a, b);",10

        .byte "  poke(3+4, 0);",10 ; 9 B
        .byte "  poke(4711+4, 0);",10 ; 9 B
        .byte "  poke(4711+4, 9);",10 ; 10 B
        .byte "  poke(3+4, a);",10 ; 10 B
        .byte "  poke(3+4, 17+4);",10
        .byte "}",10
        .byte 0
.endif ; POKEGEN



;STR=1
.ifdef STR

        .byte "word main(){",10
        .byte "  s= ",34,"foobar        fiefum",34,";",10
        .byte "  puts(s);",10
        .byte "  puts(",34,"gurka",34,");",10
        .byte "  puts(",34,"foobar        fiefum",34,");",10
        .byte "  puts(s+3);",10
        .byte "  x= ",34,"smurk pa burk smakar urk",34,";",10
        .byte "  puts(x);",10

;;; on sim65 somebody is eating up 1234!!!

        .byte "  n= ",34,"1234567890",34,";",10
        .byte "  puts(n);",10
        .byte "  puts(",34,"1234567890",34,");",10
        .byte "}",10
        .byte 0


        .byte "word main(){",10
        .byte "  puth(s);",10
        .byte "  putchar(' ');",10
        ;; TODO: fix this goes wrong
        ;.byte "  puth(&s);",10



;;; space dissapear?
        .byte "  s= ",34,"foobar        fiefum",34,";",10
;;; spaces are retained!
;        .byte "  s= ",34
 ;       .byte "foobar","     ","fiefum"
;        .byte 34,";",10

;        .byte "  s= ",34,"foobar fiefum",34,";",10
;        .byte "  s= ",34,"foobar fish-fiefum",34,";",10


;;; exists according to manual... but gives error ca64
;        .literal "  s= ",34,"foobar           fiefum",34,";",10

;;; foobar works with +3 on oric but this gives nothing!
;;; doesn't work on sim, lol
;;; garbage on oric
;        .byte "  s= ",34,"0123456789",34,";",10
;        .byte "  putz(s+3);",10

       .byte "  putchar('\\n');",10
;;; works now, but with extra hibit char first? hmmm
;;; must e some memory corruption...
;        .byte "  putz(s-2);",10
;        .byte "  putchar('\\n');",10

;        .byte "  putchar('\\n');",10

.ifnblank                       
;;; d=0 doesn't give same result...
        .byte "  d=0;",10
        .byte "  putu(strlen(s-d));",10
        .byte "  putchar('>');",10
        .byte "  putz(strlen(s-d));",10
        .byte "  putchar('<');",10
        .byte "  putchar('\\n');",10

        .byte "  putu(strlen(s));",10
        .byte "  putchar('>');",10
        .byte "  putz(s);",10
        .byte "  putchar('<');",10
        .byte "  putchar('\\n');",10
.endif
        .byte "  putu(s);",10
        .byte "  putchar(':');",10
        .byte "  putu(strlen(s));",10
        .byte "  putchar('\\n');",10
        .byte "  putchar('>');",10

;;; correct on SIM! (sometimes...)
        .byte "  putz(s);",10
        .byte "  putchar('<');",10
        .byte "  putchar('\\n');",10

.ifdef __ATMOS__
;        .byte "putz(20278);",10
        .byte "putz(20310);",10
        .byte "putchar('\\n');",10
        .byte "putz(20310);",10
;        .byte "putz(20278);",10
.else
;;; 7 chars missing, lol
        .byte "putz(19524);",10
        .byte "putchar('\\n');",10
        .byte "putz(19642+3);",10
.endif
;;; Add these two lines and SIM no longer happyy
        .byte "putchar('\\n');",10
        .byte "  putu(s);",10   ; should be same?

;        .byte "  puth(s);",10
        .byte "}",10
        .byte 0
.endif ; STR


;;; fixed!
;;; TODO: move to bugtest verify module?
;BUGS=1
.ifdef BUGS
        .byte "word main() {",10
        .byte "  return 1<<10;",10
        .byte "}",10
        .byte 0
.endif


.ifdef PRINTF
        .byte "word main(){printf(",34,"%u",34,",6502);}"
        .byte 0
        .byte 0
.endif ; PRINTF


;WHILEVLTV=1
.ifdef WHILEVLTV

.ifdef OPUTD
        .byte "word main(){",10
        .byte "  x=0; y=300;",10 ; a screenful
        .byte "  while(x<y) {",10

;;; ORIC, totally crap!
;;;   clash of vars?
        .byte "    oputd(x);",10

        .byte "    ++x;",10
        .byte "  }",10
        .byte "}",10
        .byte 0
.endif

        .byte "word main(){",10
;        .byte "  i=0; m=10;",10
        .byte "  i=0; m=300;",10 ; a screenful
        .byte "  while(i<m) {",10
        .byte "    putu(i); putchar(' ');",10
        .byte "    ++i;",10
        .byte "  }",10
        .byte "}",10
        .byte 0
.endif

.ifdef CHARNL
        .byte "word main(){",10
        .byte "putchar('a');",10
        .byte "a=10;",10
        .byte "b='q';",10
        .byte "a='\\n';",10
        .byte "putchar(a);putchar(b);putchar('\\n');putchar('b');",10
        .byte "}",10
        .byte 0
.endif ; CHARNL



.ifdef FOLDx
;;;  TODO: provide an EVAL(expr) or CONST(expr) macro!
;;;    fold/run it during compilation!

;; // from GAI:

;; #define IS_CONSTANT(exp) (sizeof(char[ (exp) || 1 ? 1 : -1 ]))
;; #define ENSURE_CONST(exp) ((void)sizeof(char[ ( (exp) || 1 ) ? 1 : -1 ]), (exp))

;; // Usage
;; int a = 10                      ;
;; int b = 5                       ;

;; // This works:
;; int x = ENSURE_CONST(10 + 5)    ; 

;; // This will cause a compilation error (variable-sized object):
;; // int y = ENSURE_CONST(a + b); 


        .byte "// Folding constants",10
        .byte "const word a=40+2;",10
        .byte "word main(){",10
        .byte "  putu(a);",10
        .byte "}",10
        .byte 0



;;; WOW! (108)
;        .byte "3+4+100+1;",0

;; fail
;        .byte "3+4+100+1<<3>>1>>1>>1;",0
; ok
;        .byte "3+4+100+1<<1>>1;",0;

; 300?
;        .byte "return 3+4+100+1<<2>>1>>1;",0
;;; wrong?
;        .byte "3+4+100+1<<2>>1>>1;",0 
        .byte "putu(3+4+100+1<<1<<1>>1);",0 

        .byte "putu(3+4+100+1<<1<<1);",0 
        .byte "putu(3+4+100+1<<1<<1>>1>>1);",0 

;;; loops forever! lol
        .byte "r=17;"
;        .byte "n=r<<2+r<<3;"
        .byte 0
.endif ;FOLD

        ;; single expression!
;        .byte "4+3;",0
;        .byte "a=4+3;putu(a);putchar('0'+a);",0

;        .byte "word main(){a=r;}",0

;        .byte "word main(){ for(i=0; i<26; ++i) { gotoxy(i/2,i); putchar('A'+i); } }",0
;        .byte "word main(){ putchar('a'); }",0

;        .byte "word main(){ ;;; }",0
;        .byte "word main(){ gotoxy(4711,666); putchar('a'); putchar('b'); }",0
;        .byte "word main(){ gotoxy(10,10); putchar('a'); putchar('b'); }",0

;        .byte "word main(){ gotoxy(10,10); putu(4711); }",0


;;; x3  =  n=r*2+r;
;;; x5  =  n=r<<2+r;
;;; x7  =  n=r<<3-r;
;;; x9  =  n=r*2+r;n=r*2+r;   or n=r<<2+r*2-r;
;;; x10 =  n=r<<2+r*2;     n=((r<<2)+r)*2;


;        .byte "word main(){z=0; ++i; ++i; z=arr[i]; ++j; ++j; }",0
;        .byte "word main(){arr[i]=42; ++i;}",0


;        .byte "word main(){",10
;        .byte "  i=0; while(i<256) { arr[i]=255; ++i; }",10
;        .byte "}",0



;        .byte "word main(){ i=0;while(i<8){putchar(i+65);++i;}}",0
;;; TODO: can optimized more as we know %D != 0 (check)
;        .byte "word main(){ for(i=0; i<8; ++i) putchar(i+65);}",0


;FUN=1
.ifdef FUN
        .byte "// Functions",10
        .byte "word F() { return 4700; }",10
;        .byte "word G() { return F()+11; }",10
;        .byte "word main(){ return G(); }",0
        .byte "word main(){",10
        .byte "  puth(&F); putchar('\\n');",10
        .byte "  puth(&G); putchar('\\n');",10
        .byte "}",0
.endif



;        .byte "word main(){a=b+c;return a;}",0

;        .byte "word main(){b=1; if (b&1) putchar(65); }",0

;;; 101B      80B: cc65 -Oirs
;;;           83B: oscar64 no opt
;;;           64B: oscal64 -Oz -Os main+M in one! (62?)
;;;          118B: oscar64 -O3 haha or -Os
;;;        
;;;  63B         : asm simple expected
;;;  47B         : asm optimal zp

;;;           33B: 16x16->16 MUL (plain algo)

;;;           57B: cc65 Mul(a,b) recursive 11 calls
;;;          126B: oscar64 Mul(a,b)  no opt

;;; .tap M()  M.size
;;; 133B 849c 99B: naive, c=0+a+c;
;;; 131B 849c 86B: opt: 0 -1B
;;; 120B 603c 85B: c+= a; works (+ etc) again
;;; 119B         : c=0; // optimized (-1B)
;;; 118B         : return M(); // tail calls -1B
;;; 117B         : removed extra rts after main -1B
;;; 113B         : 111=>a=>b; // lol, -5B
;;; 109B 603c 82B: &byte; // %{ made it possible! -5B!
;;; 101B 603c 74B: if(%A & byte) - 8B!
;;;  80B 603c 58B: ZPVARS=1 -16B!

;;; TODO: ZPVARS saves bytes but no CYCLES ??? WTF?


;;;    TODO:   b&1 oscar64: lsr+bcc cheaper! (-1B)

;;; 80B

;FMUL=1
.ifdef FMUL
        .byte "// FMUL",10
        .byte "word c,b,a;",10
        .byte "word M() {",10
        .byte "  c= 0;",10
        .byte "  while(b) {",10
        .byte "    putu(a); putchar(' '); putu(b); putchar(' '); putu(c); putchar('\\n');",10
        .byte "    if (b&1) c+= a;",10
        .byte "    a<<= 1;",10
        .byte "    b>>= 1;",10
        .byte "  }",10
        .byte "  return c;",10
        .byte "}",10
        .byte "",10
        .byte "word main(){",10
.ifdef FFFF
        .byte "  a= 111; b= 111; M();",10
        .byte "  a= 111; b= 111; M();",10
        .byte "  a= 111; b= 111; M();",10
        .byte "  a= 111; b= 111; M();",10
        .byte "  a= 111; b= 111; M();",10
        .byte "  a= 111; b= 111; M();",10
        .byte "  a= 111; b= 111; M();",10
        .byte "  a= 111; b= 111; M();",10
.endif
;;; TODO: somehow this here crashes? LOL
;        .byte "  a= 111; b= 111; M();",10
;        .byte "  a= 111; b= 111;",10

;        .byte "  a= 111; b= 111;",10
;;; TODO:
;       .byte "  a=b=111;",10 ;; save 4 bytes
        .byte "  111=>a=>b;",10 ; 603us
;        .byte "  1=>a=>b;",10   ;  91us
;        .byte "  200=>a=>b;",10   ; 347us (603us !zp)

        .byte "  return M();",10
        .byte "}",10
        .byte 0
.endif ; FMUL





;        .byte "word main(){ }",0

;;; TAILREC
;        .byte "word main(){ return 4700+11; }",0


;;; TODO: not working because TAILREC ruleD?
;        .byte "word main(){a=1;return a<<1;}",0
;        .byte "word main(){a=65535;a>>=8;return a;}",0

;;; MINIMAL
;        .byte "word main(){}",0

        ;; cc65:  36B !
        ;; parse: 40B 33108c          30x faster than basic
        ;; OPT:   36B 26964c 27c loop 37x faster ...
;;; OPTRULES works, --a not in other and TAILREC bug
;        .byte "word main() { a=1000; while(a) { --a; } }",0

        ;; cc65:  a=100; => 23B !!!
        ;; cc65 : 33B        25c loop
        ;; parse: 37B 32804c 30c loop (while end 15B)
        ;; OPT:   33B 15956  26c 
;;; OPTRULES works
;        .byte "word main() { a=1000; do { --a; } while(a); }",0

;        .byte "word main() { }",0

;;; TAILREC broken for ruleD ????? (loops forever)
;        .byte "word main() { a= 4700; a= a+11; return a; }",0
;;; WORKS
;        .byte "word main() { a= 4700; a+= 11; return a; }",0


;        .byte "word main() { if (a&1) ++b; }",0

;;; WORKS (w inline _B)
;        .byte "word main() { if(a&1) {--a;;--a;--a;} else {++a;++a;++a;++a;++a;} return a;}",0

;;; TODO: can't handle TAILREC, parser goes there but loops forefer!
;        .byte "word main() { if (a&1&2) ; }",0
;        .byte "word main() { if (a&1) ; }",0

; fails with TAILREC
;        .byte "word main(){ return b+1+2+3+4+5+6; }",0

;        .byte "word main() { if (a&1&2) putchar(65); else putchar(66); }",0

;        .byte "word main() { if (a&1) putchar(65); else putchar(66); }",0


;;; Fine, loops
;FOUR=1

.ifdef FOUR
        .byte "// FOUR",10
        .byte "word main() {",10
        .byte "  a= 470; b= 11;",10
        .byte "A:",10
        .byte "  if (a&1) { ++b;++b;++b;++b;b+=6; }",10
        .byte "  else { b+=8; ++b; ++b; }",10
        .byte "  --a;",10
        .byte "  if (a) goto A;",10
        .byte "  putu(b);",10
        .byte "}",10
        .byte 0
.endif ; FOUR

;;; prints A-Z.
;;; 
;ATOZ=1

.ifdef ATOZ
        .byte "// A-Z.",10
        .byte "word main() {",10
        .byte "  a='A';",10
        .byte "A:",10
        .byte "  putchar(a);",10
.ifdef OPTRULES
        .byte "  ++a;",10
.else
;;; TODO: 
        .byte "  a=a+1;",10
.endif
        .byte "  if (a<'[') goto A;",10
        .byte "  putchar('.');",10
;    .byte "  ++a;",10
        .byte "  return 42;",10
        .byte "}",10
        .byte 0
.endif ; ATOZ

;        .byte "word main(){++a;++a;return a;}",0
;        .byte "word main(){return 4711;}",0

;;; IF sanity
;        .byte "word main(){a=42;if(a==3)a+=4;putu(a);}",0

.ifdef BB
;;; ???
;;; TODO: it would seem that inp points wrong here!
;;;   then that causes error
        .byte "{}{}{}",0
        .byte "{}{b=7;}",0


;;; error from (7;)}{}
        .byte "{}{b=7;}{}",0
;;; crash (not gen end rule)
        .byte "{}{b=7;}",0
;;; ok

        .byte "{}{}{}",0
        .byte "{}{}",0
        .byte "{}",0
;;; error
        .byte "{a=3;}{b=7;}",0
        .byte "{a=3;}{}",0

;;; ok need space before putu? lol
;        .byte "{a=4;a+=3; putu(a);}",0

;;; FAIL - no space?   "putu" fails if first rule!
;;; ... and now it works....?
        .byte "{a=4;a+=3;putu(a);}{b=7;}",0
        .byte "{a=4;a+=3;putu(a);}",0
.endif ; BB

.ifdef ALTTEST
        .byte "bbb"
        .byte "aaa"
        .byte "aaa"
        .byte "aaa"
        .byte "bbb"
        .byte "aaa"
;;; ok, gives error %E - end of input...
;        .byte "b"
;        .byte "bb"
;;; ok, stop compile
;        .byte "bbx"
;;; stop compile and detect as error
;        .byte "xlxkjflksjdflkasdjf"
        .byte 0
        .byte 0
        ;; TODO: BUG: if not here get's corruption1
        ;; and getting next bytes and "word main"!
;        .byte 0

        .byte "ccc"
        .byte "ccc"
.endif ; ALTTEST


.ifdef FFF
        .byte "word main(){return 4711;}",0

;;; FAIL - both as input, in any order...
        .byte "word F(){return 4711;}"
        .byte "word main(){return 4711;}"
        .byte 0

;;; ok - either as input, but not both
        .byte "word main(){return 4711;}",0
        .byte "word F(){return 4711;}",0



;;; WTF, a space after '}' makes stack explode?
;;; TODO: could it be that empty match "...|" gives
;;;    too much recursion?
        .byte "word main(){return 4711     ;        } "
        .byte 0
.endif ; FFF

;FUNTEST=1
.ifdef FUNTEST

;;; TODO:  doesn't like 10 newline!!! lol (or space...)
        .byte "word F(){ putchar(65); return 4711; }",32
;        .byte "word F(){ putchar(65); return 4711; }"
;        .byte "word main(){ putchar(65); return 4711; }"

        .byte 0
.endif


.ifdef GOTOtest
;;; MINIMAL SANITY CHECK
;;        .byte "word main(){return 4711;}",0
;;; minimal error
;        .byte "word main(){return 47x11;}",0

;;; TODO: not found name need better error...
;;;      .byte "void main(){xyz(65);}",0

        ;; Speed of Turbo Pascal on z80 (4 MHz)
        ;; 2000 lines/less than 60s
        ;; (/ 2000 55) = 36 lines/s

        ;; GOTO !
        ;; 
        ;;      (/ 7 0.052) = 134 op compiles/s
        ;; 
        ;;                             7 "ops"/gen
        ;;                        no PRINTREAD vvv
        ;; = CC02: 57 bytes 10580c compile: 51796c=0.052s
       ;; = CC02: 57 bytes 10580c compile:  9044c
        ;; = CC02: 57 bytes 2.79cs compile:   24cs
        ;;            100x / 100
        ;; 
        ;;     putchar(%D|%V) => 63 (- 5 B)
        ;;     if(%V<%D)      => 57 (- 6 B)
        ;; 
        ;;     TODO: byte            -17 B
        ;;     TODO: zp vars          -7 B
        ;;     jsr .. ; rts           -1 B
        ;;     if no ELSE support     -5 B
        ;; 
        ;; = cc65: 50 bytes 12613c compile: 112ms
        ;;          (-20 using byte) = 30 B
        ;;        
        ;; = asm:  15 bytes! (using register only)

;;; ok - AAAAAA
;        .byte "void main(){A:putchar(65);goto A;}",0
;;;; ok
;        .byte "void main(){A:putchar(65);goto A;putchar(66);}",0
;        .byte "void main(){putchar(64);A:putchar(65);goto A;putchar(66);}",0

;        .byte "void main(){ putchar(65); putchar(66); putchar(67); }",0

;;; ok
        .byte "// GOTO test A-Z.",10
        .byte "void main()",10
        .byte "  a=65;",10
        .byte "A:putchar(a);",10
        .byte "  ++a;",10
        .byte "  if (a<91) goto A;",10
        .byte "  putchar(46);",10
        .byte "}",10
        .byte 0
;;; TODO: remove spaces crash in parse!!!!
;        .byte "void main(){ a=65; A: putchar(a); ++a; if (a<91) goto A; putchar(46); }",0
.endif ; GOOTTEST


;;; sim65: 40020 bytes allocatable
;;;  oric: 12704 bytes allocatable

;;; SIM65: (- 65536 (* 2 256) 17348 4096)
;;;           64K   0-1 pages .sim  output
;;;        (- 43580 40020) = 3560 bytes "cc65 stack"?

;;; ORIC:
;;; (- 65536 (* 5 256) 16384 17421 4096   8000  2000)
;;;    64KB  0-4 page  ROM   .tap  output hires charset
;;; (- 16355 12704) = 3651 bytes "cc65 stack"?
;;; 
;;; TEXT:  (- 37631 (* 5 256) 17421 2000 1000) = 15930
;;; HIRES: (- 37631 (* 5 256) 17421 8000 2000) =  8930
;;; -- cc65 



;;; TODO: doesn't compile, z get's lost???




;MALLOC=1
.ifdef MALLOC
        .byte "// malloc() test",10
        .byte "word z,a,p;",10
        .byte "word main() {",10
;        .byte "  putu(heapmemavail()); putchar(10);",10
;       .byte "  putu(heapmaxavail()); putchar(10);",10
        .byte "  z= 32768;",10
        .byte "  a= 0;",10

        .byte "  while(1) {",10
;        .byte "X:",10

        .byte "    p= malloc(z);",10
        .byte "    if (p) {",10
        .byte "      a+= z;",10
        .byte "      putu(a); putchar(' '); puth(p); putchar(' '); putu(z); putchar(10);",10
        .byte "      // try same size again till fail!",10
        .byte "    } else {",10


;;; TODO: seems it "forgot" z, doesn't matter if change to s
;;;     hint: ? look at screen strange debug output?
;        .byte "      z>>=1;",10


        .byte "    }",10
;        .byte "    if (z==0) return a;",10
        .byte "    if (!z) return a;",10

;;; crash! errror "1" lol
;        .byte "  } while(1);",10
;;; NOT TRUE????
;        .byte "  goto X;",10
        .byte "  }",10

        .byte "}",10
        .byte 0
.endif
;


;;; Byte Sieve Benchmark! (OLD)
;;; ===========================
;;; Normalized: 1MHz onthe6502.pdf (1M cycles/s)
;;; 
;;;   202 B     1.16s asm  onthe6502.pdf
;;;   819 B     5.82s CC65 onthe6502.pdf
;;; 
;;;   326 B     4.17s CC65 -O Play/byte-sieve-prime.c
;;;                   (-Cl static locaL) (-Or 5.37s)
;;; (1045 B     -"- in the byte-sieve-prime.out sim65)

;;;      (normalixed)
;;;             1.8s  action (see below)
;;;           228s    BASIC (according to action)
;;;             3.6s  Tigger C
;;;            16.s   "BASIC" says Tigger C video
;;; 
;;;      10 X
;;;             
;;;            10s asm (according to Action! doing 10x!)
;;;            18s Action! (algo/src from there)
;;;            38m BASIC - 126 times slower
;;; 
;;;   ????      36s   Tigger C, 4.5s 8 MHz (* 4.5 8)
;;;           "160s"  "BASIC" according to Tigger C
;;; 
;;; BN16 (use dec mode, no print? store only odd)
;;;   150ms asm (2023: super opt years later) - 1K ram

;;; Byte sieve from Byte magaxine:
;;; ==============================
;;; char prime[8192]={0}; // simplier code: no bitshift


;;;    bytes
;;; FILE   MAIN seconds  WHAT
;;; ----   ---- ----.--  ------------------------

;;; === Byte magazine (10x run, 8192) ===
;;;   287s          UCSD PASCAL, APPLE II, 6502
;;;   390s (!)      interpreted (?)
;;; 
;;;   425s          hopperBasic (53s @ 8 MHz) f video

;;; - https://github.com/soegaard/minipascal/blob/master/minipascal/tests-real/primes.rkt

;;; === BCPL (bytecode) === ( https:projects.drogon.net/retro-basic-and-bcpl-benchmarks/ )
;;; 
;;;     NOTE: this is size=4095 (half of BYTE BENCHMARK!)
;;;     NOTE: this is 1x run!!
;;; 
;;;               96.96  BBC BASIC 1-3 (6.06s on 16Mhz)
;;;               81.12  BBC BASIC 4   (5.07s)
;;;              134.4   CBM2 (* 8.40 16)
;;;              135.86  EhBASIC (* 8.48 16)
;;;               10.352 BCPL (INT) (* 0.647 16)
;;; 
;;; === jsk: 1x = 4096 = (don't compare with 8192...) BYTESIEVE
;;;         363    2.104s CC02    my compiler
;;;         336    1.630s CC02    my compiler better WHILE
;;;         336    1.551s CC02    1000x loop
;;;            (/ 10.352 1.551) = 6.67
;;;         319    1.327s CC02    poke optimized
;;;            (/ 10.352 1.327) = 7.80
;;;              1% BEAT cc65 default! SMALLER! (- 3 bytes



;;; === jsk tests === (1x run, 8192)
;;; FILE,  MAIN bytes 
;;;   2627  322    5.196  CC65   ./r Play/byte-sieve-prime
;;;         287    9.510  CC65   -DPROGSIZE
;;;         322    2.8323 CC65   -Cl
;;; === my compiler === ("no library!")
;;;         363    3.63   sim65  ./rrasm parse BYTESIEVE
;;;         363    4.8s   CC02   ./rasm parse  BYTESIEVE
;;;         336    3.185s CC02   ./rrams WHILE(a<_E)
;;;             12% faster than before
;;;             12% slower than cc65 -Cl
;;;         319    2.665s CC02   ./rrasm 100x (- 17B!)
;;;              6% FASTER than cc65 -Cl
;;;             11% bigger than smallest (slowest) cc65 (287)
;;;         315    2.665s  CC02   axputu

;;; Published results from
;;; - https://thred.github.io/c-bench-64/
;;; (I haven't been able to reproduce the cc65 result)
;;;  4.3K          2.12s  Calpyso (21.4s size opt, 4.3K)
;;;  3.2K          2.05s  cc65 (2.10s, 3.2K))
;;;  7.1K          1.90s  LLVM-mos (21.8s, 6.4K))
;;;  2.5K   240j   0.94s  Oscar64 (10.3s, 1.6K)
;;;  2.4K          2.13s  SDCC (21.3s, 2.4K)
;;;  5.8K          1.33s  VBCC (15.9s, 3.4K)
;;;        (240j means jsk extracted main from .asm)
;;; 
;;; 
;;; MeteoriC:
;;;         315    2.60s  CC02 10K runs ^X * 100
;;;         307    2.53s  CC02 while-speed,++i(;),+BYTE
;;;         302    2.43s  CC02 rule _F byte rule for poke!
;;;         304       +2 B ??? investigate, poke changed, wrong?
;;;                    - 1a45336b30cc787f668c83dd4e4c7dff4baa7a99
;;;         303         -1 B !!! better poke (?)
;;; 
;;;         303    2.458s - opt still stable: rules: 3610
;;;  NOOPT! 366    3.082s - noopt             rules: 2425
;;;  BYTES  303                               rules: 4505
;;;         302    same   - save one byte on if/clc
;;;         301    2.6484 - (.sim/10 20250120)
;;;         284    2.6806 - (/ 6835663562 255) do-while-opts

;
BYTESIEVE=1
;
NOPRINT=1

;;; 2026-01-31 Compilation 2.000s!
;;;   32 "lines", 40 ops, 15 dots, 63 commas
;;; (/ 32 2.000) = 16 ... (* 16 60) = 960 lines/minute!

; https://thechipletter.substack.com/p/once-again-through-eratosthenes-sieve
;;; = 10x == 10x == 10x == 10x == 10x == 10x == 10x =
;;; 1899 primes:
;;;   cy,cles      bytes
;;;  -----------   -----
;;;   51,962,632    2627    - cc65    ./r Play/byte-sieve-prime
;;;   95,097,713     287           -DPROGSIZE
;;;   28,322,714     322           -Cl

;;; === my compiler ===
;;;   36.3           363    - sim65   ./rrasm parse  
;;;   43s            363    - ORIC    ./rasm parse   

;;;  #x142 322 
;;;  #x11f 287

.ifdef BYTESIEVE
;;; BC: (+ 11 9 3 16 9 6 7 3 14 5 5 1 2 1 2 1 2 2 1 2 2) = 104
;;; so 104 bytecodes is substantially lower than MC: 365...
        .byte "// BYTE SIEVE PRIME benchmark",10
        .byte "#include <stdio.h>",10

        .byte "word a, c, i, k, m, n, p;",10

        .byte "word main(){",10
       ;; BYTE MAGAZINE 8192 => 1899
        .byte "  m=8192;",10
        ;; used by Bench/Byte Sieve - BCPL/BBC
;        .byte "  m=4096;",10

;;; Also gives error... hmmm something wrong in _digits
;        .byte " m=47;",10

        .byte "  a=xmalloc(m);",10
;.byte "x"
        .byte "  n=0; do {",10
;        .byte "  n=0; while(47n<10) {",10

;        .byte " xwhile(47n<10) {",10

        .byte "    c=0;",10
        .byte "    i=0; do {",10
        .byte "      poke(a+i, 1); ++i;",10
        .byte "    } while(i<m);",10
;;; NOPE
;        .byte "    i=0; do { poke(a+i, 1); ++i; } while(i<m);",10
        .byte "    i=0; do {",10
        .byte "      if (peek(a+i)) {",10
        .byte "        p= i*2+3;",10
.ifndef NOPRINT
        .byte "        putu(p);",10
        .byte "        putchar(32);",10
.endif
        .byte "        k=i+p; while(k<m) {",10
        .byte "          poke(a+k, 0);",10
        .byte "          k+=p;",10
        .byte "        }",10
        .byte "        ++c;",10
        .byte "      }",10
        .byte "      ++i;",10
        .byte "    } while(i<m);",10
.ifndef NOLIBRARY
        .byte "    printf(",34,"%u",34,", c);",10
.endif
        .byte "    ++n;",10
        .byte "  } while(n<10);",10
        .byte "  free(a);" ;;,10
        .byte "  return c;",10
        .byte "}"
        .byte 0
.endif ; BYTESIEVE
;


;PRIME=1
;;; TODO: this crashes in ORIC ????
;PRIMBYTE=1

;NOPRINT=1

;;; From: onthe6502.pdf - by 
;;;  jsk: modified for single letter var, putchar

;;; also in Play/prime.c

.ifdef PRIME
;;;   313B      3.337s BYTERULES PRIMBYTE
;;;               2.5% smaller
;;;              20% faster than cc65 
;;;  (305B)     1.9s NOPRINT! (putu(),putchar())
;;;   321B      3.426 moved i=n;
;;;               SMALLER! than cc65!!!
;;;   329B            while not long-for (256) init arr
;;;               close to 326B cc65
;;;   335B      3.432 ^65535 (-5B)
;;;   340B      3.461 j=i>>3; (-10B)
;;;               17% faster than cc65
;;;                4% faster than Tigger C
;;;   350B      3.543 while(%A<%D) (- 14B)
;;;               15% FASTER than cc65!
;;;                1.6% faster than Tigger C
;;;   364B      4.445 measure wrong? ( arr[i]=const; )
;;;   377B      4.414s PRIME (for, init, save bytes)
;;;                5.9% slower than cc65
;;;   397B      4.477s PRIME (correct result)
;;;                7% slower than cc65

;;; (+ 397 33 10)=440 B ; estimate: main + putu + putchar
;;;  (/ 4.477 4.17) 7%

;;; TODO: need more features:
;;;   x label A:
;;;   x goto A;
;;;   x do while
;;;   - array declaration
;;;   - array access/set
;;;   - parenthesis
;;; 
;;;  (- hex numbers)
;;;  (- char constants 'c')
;;;  (- t++)
;;;  (- --t)
;;;  (- // comments)
;;;  (- variable declaration)
;;;  (- %10 hmmm???)
;;;  (- for)
;;;  (- to ~ reverse bits)

;;; TODO: there might be hi-bit chars here???
        .byte "// PRIME test; char arr+bitshift",10
        .byte "char arr[256];",10
;        .byte "char b[4];",10
;        .byte 10
        .byte "word main(){",10
;       .byte "  word n,i;",10
;       .byte "  char t;",10
;       .byte "  arr[0]=0xff;",10
;;; TODO: for!
;        .byte "  arr[0]=255;",10
;       .byte "  for(t=1; t; ++t) arr[t]=0xff;",10

;
;;; 335B for loop has overhead >255
;        .byte "  for(i=0; i<256; ++i) arr[i]=255;",10
;;; 329B !!! closer to cc65... (326B)

;.ifndef PRIMEBYTE
        .byte "  i=0; while(i<256) { arr[i]=255; ++i; }",10
;.else
;        .byte "  i=0; while(i<256) { $ arr[i]=255; ++i; }",10
;.endif

;;; 338B ???
;        .byte "  i=0; while(i<256) { arr[i++]=255; }",10

;        .byte "  for(n=2; n<2048; ++n) {",10
        .byte "  n=2; while(n<2048) {",10
;        .byte "  n=1; while(++n<2048) {",10 ; worse!

;;; TODO: no paren
;        .byte "    if (arr[n>>3] & (1<<(n&7))) {",10
.ifndef PRIMBYTE
        .byte "    z=n&7; z=1<<z;",10
        .byte "    if (arr[n>>3] & z) {",10
.else
        .byte "    $ z= n&7; $ z=1<<z;",10 ;
        .byte "    if (arr[n>>3] & z) {",10
;        .byte "    if ($ arr[n>>3] & $ z) {",10
.endif

        ;;           // simulates putu?
.ifndef NOPRINT
.ifblank
        .byte "      putu(n);",10
.else
        .byte "      i=n;",10
        .byte "      t=0;",10
        .byte "      do {",10
        .byte "        b[t++]= (i%10)+'0';",10
        .byte "        i/=10;",10
        .byte "      } while(i);",10
        .byte "      do {",10
        .byte "        putchar(b[--t]);",10
        .byte "      } while(t);",10
.endif
;; TODO: LOL loops forever, WTF!
;        .byte "      putchar(' ');",10
        .byte "      putchar(32);",10
.endif
;        .byte "      for(i=n+n; i<2048; i+= n) {",10
        .byte "      i=n*2; while(i<2048) {",10

;       .byte "        a[i>>3]&= ~(1<<(i&7));",10

.ifndef PRIMBYTE
        .byte "        z=i&7; z=1<<z ^65535;",10
        .byte "        j=i>>3;",10
        .byte "        arr[j]= arr[j] & z;",10
.else
        .byte "        $ z= i&7; $ z=1<<z ^255;",10
        .byte "        j=i>>3;",10
;        .byte "        $ arr[j]= $ arr[j] & $ z;",10
        .byte "        arr[j]= arr[j] & z;",10
.endif
        ;; for the while
        .byte "        i+=n;",10

        .byte "      }",10
        .byte "    }",10
        ;; for the while
        .byte "    ++n;",10
        .byte "  }",10
        .byte "}"
        .byte 0

.endif ; PRIME


.ifdef TESTARRAY
        ;; char arrays
        .byte "// char array",10
        .byte "char a[42];",10
        .byte "word main(){ a@[3]=20; a@[7]=22;",10
        .byte "  return a@[3]+a@[3];",10
        .byte "}",0
.endif

.ifdef TWEN
        .byte "// many ++a;",10
        .byte "word main(){"
        .byte "++a;++a;++a;++a;++a;"
        .byte "++a;++a;++a;++a;++a;"
        .byte "++a;++a;++a;++a;++a;"
        .byte "++a;++a;++a;++a;++a;"
        .byte "return a;}",0
.byte "word main(){a=4700;return a+11;}",0
.byte "word main(){return 4711;}",0
.endif ; TWEN

;;; HOW is this NOT the SAME?
;        .byte "word main(){++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;++a;return a;}",0

;REP=2000
.ifdef REP
        .byte "// MANY statements test: repeat ++a",10
        .byte "word a;",10
        .byte "word main(){"
        ;; 48 => 15s lol - error
        ;; 40 =>  8s LOL
;        .repeat 32+8

        ;; 25 statements takes ~2.5s to compile
        ;; 526 bytes!
        ;; 
        ;; 25 is ok: (* 25 6) = 150 recursions (inp,rule)
        ;; I think two rules deep... not helping...
        ;; (/ 256 6 2) = 21 ...
;;; TODO: need *S clenex operator for repeats!
;        .repeat 16+8+1

        ;; OPTRULES:
        ;;   a=a+1; // 16 => 3s  337 bytes (/ 337 16) = 21
        ;;   ++a;   // 16 => 1s  136 bytes 
        ;;   ++a;   // 32 => 1s  264 bytes (/ 264 32) =  8
;        .byte "a=0;"

;;; TOO high value triggers CHECKSTACK error!
        ;; run: T340 compile: T6484
;        .repeat 25           
        ;; run: T 84          T26964
        ;.repeat 12

        ;; run: T 84          T55892
        ;.repeat 0               ;  6cs
        ;.repeat 10              ; 15cs
;        .repeat 20              ; 27cs
;.byte "++a;return a;}",0

;        .repeat 20              ; 27cs
;        .repeat 2000 ; MAX!

        .byte "a=0;"

        .repeat REP
        ;; ~~~~~~~~~~~~~~~~~~~~ 1cs/op == 100ops/s
        ;; (* 60 100)= 6000 ops ~ 2000 lines? lol?
        ;; w print  24s (/ 2000 24) =  83 ops/s
        ;; NO print 15s (/ 2000 15) = 133 ops/s
        ;; "an if is maybe 7 ops => (/ 133 7) = 19l/s
        ;; (* 60 19) = 1140 lines/60s nonoptimized!

;          .byte "a=a+1;"
;          .byte "++a;"
           .byte "++a;"
        .endrep
        .byte "return a;}",0
.endif ; REP

.ifdef FOO
;;; OOO, what comes after here matter???? LOL

;        .byte 0,0,0,0
        .byte "return a;"
        .byte "}",0


        ;; quoted test
        .byte "[]",0

        .byte "word main(){ return 3<3; }",0
        .byte "word main(){ if(1) a=42; return a;}",0

        .byte "word main(){ if(1) a=42; else a=4711; return a;}",0

        ;; tests for self-modifying v op= const;
        .byte "word main(){ a=4141; ++a; return a; }",0
        .byte "word main(){ a=4343; --a; return a; }",0
        .byte "word main(){ a=512+42+1; a&=42; return a; }",0
        .byte "word main(){ a=84; a>>=1; return a; }",0
        .byte "word main(){ a=21; a<<=1; return a; }",0
        .byte "word main(){ e-=10*2+6; return e; }",0
        .byte "word main(){ e+=2; return e; }",0

        ;; ELSE 101 or 11
        ;; BUG: TODO: if else because MINIMAL and have LONGNAME
        ;; elsea=10; might be assigned, lol
        .byte "word main(){ if(0) a=100; else a=10; return a+1; }",0


;;; 101/1
        .byte "word main(){if(1)a=100;return a+1;}",0
;;; 40
        .byte "word main(){return e;}",0


        .byte "void A(){putchar(102);}",0

        .byte "word main(){putchar(102);}",0

        .byte "word main(){putu(4711);return getchar();}",0

        .byte "word main(){return 65535>>3;}",0
;;; => 2???
        .byte "word main(){return 1<<2;}",0

        .byte "word main(){return 517&0xff+42;}",0

        .byte "word main(){3+4=>a+3=>b;return a+b;}",0


;;; TODO: LOOP shit - same issue on "MINIMAL - lol"
        .byte "word main(){return a;}",0

;;; works 1477
        .byte "word main(){if(1){a=77;a=1400+a;}return a;}",0
;;; works 0 or "magix"
        .byte "word main(){if(0){a=77;a=1400+a;}return a;}",0

;;; WORKS (but can't do three as limited {SS} ...
        .byte "word main(){a=10;if(1){a=a*2;a=a*2;} a=a+1; return a;}",0

;;; FAIL
;        .byte "word main(){ if(1) { a=e+50; return a; } a=a+1; return a;}",0

;        .byte "word main(){a=10; if(1){a=a*2;} a=a+1; return a;}",0
;;; WRONG
        .byte "word main(){ return a; if(0){a=10;} a=a+1; return a;}",0

;;; OK, fixed var.... lol
        .byte "word main(){ if(1) a=10; a=a+1; return a;}",0

.ifdef INCTESTS
        .byte "word main(){ return 4711 ; }",0
        .byte "word main(){ return e ; }",0
        .byte "word main(){ return &e ; }",0
        .byte "word main(){ return a ; }",0
        .byte "word main(){ return e; }",0
        .byte "word main(){ if(0) a=10; a=a+1; return a;}",0
;;; OK 11
        .byte "word main(){ return 4710+1; }",0
        .byte "word main(){ if(1) a=10; a=a+1; return a;}",0

;;; OK 
        .byte "word main(){return 4711;}",0

;;; ERROR
        .byte "word main(){ if(1) { return 33; } a=a+1; return a;}",0

;;; syntax error highlight!
;        .byte "word main(){ if(1) a=10x; a=a+1; return a;}",0


;;; OK (w S not = B | )
        .byte "word main(){ if(0) return 33; return 22; }",0
        .byte "word main(){ if(1) return 33; return 22; }",0



;;; FAIL
        .byte "word main(){ if(0) { a=e+50; return a; } a=a+1; return a;}",0
;;; FAIL
        .byte "word main(){ if(1) { a=89; return a; } a=a+1; return a;}",0


        .byte "word main(){ if(1) return 99; a=a+1; return a;}",0
        .byte "word main(){ if(1) a=10; a=a+1; return a;}",0
        .byte "word main(){ if(0) a=10; a=a+1; return a;}",0



        .byte "word main(){ a=2005*2; a=a+700; return a+1; }",0

;;; WRONG
        .byte "word main(){ a=2005*2; b=84; a=a+700; a=b/2+a; return a+1; }",0

;;; OK
        .byte "word main(){ a=99; a=a+1; a=a+100; return a+1; }",0

;;; TODO: somehow this gives garbage and jumps wrong!
;;;  (stack messed up?)

;;; FAILS
        .byte "wordmain(){return e==40;}",0
;;; FAILS
        .byte "wordmain(){return 42==42;}",0


;;; OKAY:
        .byte "wordmain(){a=42;return a+a;}",0
        .byte "wordmain(){42=>a;return a+a;}",0
        .byte "wordmain(){return 40==e;}",0
        .byte "wordmain(){return e==e;}",0
        .byte "wordmain(){return e+e;}",0
        .byte "wordmain(){a=99;a=a+1;return a+1;}",0
        .byte "wordmain(){a=99;return 77;}",0
        .byte "wordmain(){return 4711;}",0
        .byte "wordmain(){a=99;return a+1;}",0
        .byte "voidmain(){a=99;}",0
        .byte "wordmain(){return 1+2+3+4+5;}",0
;        .byte "wordmain(){return 42==e;}",0
        .byte "wordmain(){return e+12305;}",0
        .byte "wordmain(){return e;}",0
        .byte "wordmain(){return 4010+701;}",0
        .byte "wordmain(){return 8421*2;}",0
        .byte "wordmain(){return 8421/2;}",0
        .byte "wordmain(){return 4711;}",0
;;; garbage (OK)
        .byte "voidmain(){}",0
        .byte 0
.endif ; FOO

.endif ; INCTESTS

        ;; Input include example library

.endif ; TUTORIAL

;;; adds about 3-4 KB
.ifdef EXAMPLEFILES

;;; a - ^^^^^^^^^^^^^^^^^^^^ - current prog for testing...
;;; b - Byte sieve
.ifdef DEMO







;;;  BYTESIEVE crashes on ORIC ATMOS...

;;; it's good at:
;;; 
;;; commit 704fae71e47a4ea6fe5bc3b52bb503ede56e3989

;;; this DEMO: OUTPUTSIZE = 1 K still crash...

;;; but any later gives crash... ??? hmmmm


        .incbin "Input/byte-sieve-2K.c"


.else
        .incbin "Input/byte-sieve.c"
.endif
        .byte 0

;;; c - color chart
        .incbin "Input/color-chart.c"
        .byte 0

;;; d - rainbow drop
        .byte "// d -"
;        .incbin "Input/rainbow-drop.c"
        .byte 0

;;; e - expr
        .incbin "Input/expressions.c"
        .byte 0

;;; f - fib recursion

;;; - fib(24) (sim)
;;; cc65:  336 B 33311024 - add, fib(24) no print
;;; (tap)  518 B          (oric atmos .tap file)
;;;        319 B 28807992 - no add
;;;       (105 B  only fib!)
;;; mc02:  136+B 37270319 - add, fib(24) no print
;;;        227+tap overhead  (runtime +91)

;;; - fib(0..24)
;;; cc65: 2607 B  75731440 - no add
;;; cc65: 2605 B  91050216 - with add     
;;; 
;;; mc02:  187+B  98224959 - with add (runt+91 stdio+114)
;;;        171+B   ...
;;;        153+B  95318098 - opt one param calls

        .incbin "Input/fib-list.c"
        .byte 0


.ifdef FROGMOVE
        ;; TODO: not working
        .byte "// frogmove-simple.c",10
        .incbin "Play/frogmove-simple.c"
        .byte 0
.endif ; FROGMOVE

;;; g - graphics
        .byte "// graphics - circle/line (ORIC)",10
        .byte "",10
        .byte "// note: it looses program after run!",10
        .byte "",10
        .byte "word main(){",10
        .byte "  hires();",10
        .byte "  curset(120,100,0);",10
        .byte "  circle(75,2);",10
        .byte "  curset(0, 0, 3);",10
        .byte "  draw(239, 199, 2);",10
        .byte "  getchar();",10
        .byte "  text();",10
        .byte "}",10
        .byte 0

;;; h - hello
        .byte "// Hello World! - loops",10
        .byte "",10
        .byte "word spaces(word n) {",10
        .byte "  while(n--) putchar(' ');",10
        .byte "}",10
        .byte "",10
        .byte "word i;",10
        .byte "",10
        .byte "word main(){",10
        .byte "  for(i=0; i<150; ++i) {",10
        .byte "    spaces(i);",10
        .byte "    printf(\"%s\",\"Hello World!\");",10
        .byte "  }",10
        .byte "}"
        .byte 0

;;; i - isalph etc..
        .incbin "Input/test-ctype.c"
        .byte 0

;;; j - inc ++ dec -- 
        .incbin "Input/plusplus.c"
        .byte 0

;;; k - 
        .byte "// k -",10
        .byte 0

;;; l - line bench
.ifblank
        .incbin "Input/music.c"
;        .byte "// l -",10
        .byte 0
.else
        .byte "// LINEBENCH - for borken?",10
        .byte "word i;",10
        .byte "word main(){",10
        .byte "  hires();",10
        .byte "  for(i=0; i<239; ++i) {",10
.byte "putu(i); putchar(' ');",10
        .byte "    curset(239-i, 199, 3);",10
;        .byte "    draw(i*2-239, 0-199, 2);",10
        .byte "    draw(i+i-239, 0-199, 2);",10
        .byte "  }",10
        .byte "  for(i=0; i<199; ++i) {",10
.byte "putu(i); putchar(' ');",10
        .byte "    curset(0, i, 3);",10
        .byte "    draw(239, 199-i-i, 2);",10
        .byte "  }",10
        .byte "  curset(120, 100, 3);",10
        .byte "  for(i=0; i<99; ++i) {",10
.byte "putu(i); putchar(' ');",10
        .byte "    circle(i, 0);",10
        .byte "  }",10
        .byte "  getchar();",10
        .byte "  text();",10
        .byte "}",10
        .byte 0
.endif ; LINEBENCH

;;; m - music
        .incbin "Input/music.c"
        .byte 0

;;; n - numeric constants different bases
        .byte "// numeric C constants",10
        .byte "word nl(){ putchar('\\n'); }",10
        .byte "",10
        .byte "word p(word n){",10
        .byte "  putu(n);",10
        .byte "  putchar(' ');",10
        .byte "}",10
        .byte "",10
        .byte "word main(){",10
;;; BUG: basically lda/ldx lda/ldx as two parameters w no push!
;;;    (because no comman, lol!)
;        .byte "  p(0b111666); nl();",10
        .byte "  p(17); p(42); p(55555); nl();",10
        .byte "  p(0x11); p(0x2a); p(0xd903); nl();",10
        .byte "  p(0x11); p(0X2A); p(0XD903); nl();",10
        .byte "  p(0x11); p('*'); p(0XD903); nl();",10
        .byte "  p(0b10001); p(0B101010); p(0b1101100100000011); nl();",10
        .byte "  p(021); p(052); p(0154403); nl();",10
        .byte "}",0

;;; o -
;
LOOP=1
.ifdef LOOP
        .byte "// optimize size: for vs while",10
        .byte "word i;",10
        ;; TODO: tail recursion?
        .byte "word nl(){ return putchar('\\n'); }",10
        .byte "word p(word n){putu(n);putchar(' ');}",10
        .byte "word main(){",10
        .byte "  // 43 Bytes - cheapest!",10
        .byte "  i=9; do p(i); while(i--); nl();",10
        .byte "  // 46 Bytes - ok",10
        .byte "  i=10; while(i--) p(i); nl();",10
        .byte "  // 58 Bytes - ugh!",10
        .byte "  for(i=10; i--; ) p(i); nl();",10
        .byte "  // 59 Bytes - hmmm",10
        .byte "  for(i=10; i; ) p(--i); nl();",10
        .byte "}",10
        .byte 0
.endif ; LOOP

;;; p - printing
        .byte "// print functions",10
        .byte "word main() {",10
        .byte "  putchar('H');   putchar('@'+5);",10
        .byte "  putchar('m'-1); putchar('6'<<1);",10
        .byte "  putchar(111);   putchar('\\n');",10
        .byte "",10
        .byte "  // strings",10
        .byte "  puts(\"World\") ; // adds newline",10
        .byte "",10
        .byte "  // no newline",10
        .byte "  putz(\"print \");",10
        .byte "  fputs(\"nums:\",stdout); putchar(' ');",10
        .byte "",10
        .byte "  puth(488879); putchar(' ');",10
        .byte "  putu(0x1148); putchar(10);",10
        .byte "",10
        .byte "  // SIMPLE printf (ONLY these)",10
        .byte "  printf(\"%s\", \"fish\");",10
        .byte "  printf(\"%u\", 0x29a);",10
        .byte "  printf(\"%x\", -1);",10
        .byte "  putchar('\\n');",10
        .byte "  // NO: printf(\"foo%s\\n\", \"bar\");",10
        .byte "",10
        .byte "  putz(\"a\\nb\\nc\\n\");",10
        .byte "}",10
        .byte 0
;;; q -
        .byte "// q -",10
        .byte 0
;;; r - 
        .byte "// recursive summer",10
        ;; cc65: 13768c (41)
        ;; MC:   16915c (41=>861)
        .byte "word summer(word a) {",10
;        .byte "  putu(a); putchar(' ');",10
        .byte "  if (a==0) return 0;",10
        ;; tail recursion???
        .byte "  return summer(a-1)+a;",10
        .byte "}",10
        ;; 41 is maximum recursion (/ 256 41.0) = 6.24 (2param+2restore1+2rts) ok
        .byte "word main() {",10
        .byte "  // return summer(41);",10
        .byte " return summer(10);",10
        .byte "}",10
        .byte 0

;;; s - strings
        ;; 647 B -> 621 B 
        ;; 565 B - fixed _G rule
        ;; 533 B - inline strings!
        .incbin "Input/strlib.c"
        .byte 0

;;; t - 
        .byte "// Template empty program",10
        .byte "word num,xyz;",10
        .byte "",10
        .byte "word main() {",10
        .byte "  return 4711;",10
        .byte "}",10
        .byte 0
;;; u -
        .byte "// u -",10
        .byte 0
;;; v -
        .byte "// v -",10
        .byte 0
;;; w -
        .byte "// w -",10
        .byte 0
;;; x -
        .byte "// x -",10
        .byte 0
;;; y -
        .byte "// y -",10
        .byte 0
;;; z -
        .byte "// z -",10
        .byte 0


;;; TOOD: not working...
;BIGSCROLL=1
.ifdef BIGSCROLL
        .incbin "Input/bigscroll.c"
        .byte 0
.endif ; BIGSCROLL


.endif ; EXAMPLEFILES

endinput:       

FUNC _inputend

        ;; two zeroes ends input sequence of files
        .byte 0,0


;;; END INPUT
;;; ----------------------------------------
;;; GLOBAL DATA


;;; TODO: move to earlier, or beginning of compiler?

;;; TODO: simulated arr, only one! lol
.ifdef FROGMOVE
arr:    .res 1200
.else
;PRIME
arr:    .res 256
.endif


.code

;;; variable defs
;;; TODO: rework to generate BNF parse rules!
FUNC _defs

defs:

;;; TODO: change with new rules?

;;; test example
;;; TODO: remove?
.ifdef TESTING
.ifdef LONGNAMESx
vfoo:   
        .word 0                 ; linked-list end
        .word 4711
        .byte "foo",0
.ifnblank
vmain:  
        .word vfoo
        .word 0
        .byte "main",0
vbar:
        .word vmain
.else
vbar:
        .word vfoo
.endif
imain:  .word 42
        .byte "bar",0
vnext:  
        .word vbar
        .word 0
        .byte 0

.endif ; LONGNAMESx
.endif ; TESTING


;;; ORIC MEMORY free
;;; - retro8bitcomputers.co.uk/Content/downloads/manuals/oric-graphics-and-machine-code-techniques.pdf

;;; From #400 to #4FF, 256 bytes are available.
;;; Be warned, however, that the Oric disk system
;;; makes use of this area.
;;; 
;;; 3. The first 256 bytes of each character set
;;; are unused, so programs can be put at
;;; #B400 to #B4FF and #B800 to #B8FF
;;; (or in HIRES mode at #9800 to #98FF
;;; and #9C00 to #9CFF).
;;; 
;;; Although the Reset button on the Oric causes
;;; the character set to be regenerated these
;;; areas are not affected.
;;;
;;; 4. Since the alternate character set is rarely
;;; used the entire area between #B800 and #BB7F
;;; is available for a machine code program.
;;; This area of RAM is ideal for facilities like
;;; Renumber.
;;; 
;;; 5. Another ‘hidden’ area lies between
;;; #BFEO and #BFFF. This area will only be overwritten
;;; if HIMEM is incorrectly set, and survives the
;;; commands ‘HIRES’, ‘TEXT’, and the Reset button.


.bss
;;; Generated program memory layout:
;;; 
;;;   _start:  jmp _output              TODO:
;;;            ...bios...               TODO:
;;;            ...library...            TODO:
;;;   _output: jmp main               GEN CODE
;;;            ...gen machine code... GEN CODE
;;;            rts
;;;    out->
;;; 
;;;            ...free...
;;;
;;;            TODO:concstants/vars ???
;;;   _outend: 

FUNC _outputstart
;;; ideally this should be *overlapping* the
;;; compiler, and memmove compiler to end of mem
;;; Probably can do by explicit .org (and then memmove)

_output:
.bss
;;; not physicaly allocated in binary
;;; ++a; x 2000
;;;  free tap inp output
;;; (- 37 11    8   16  ) = 2K left

        .res OUTPUTSIZE

FUNC _outputend





;;; Some variants save on codegen by using a library

;;; LIBRARY

.code

.export __ZPEND__
.zeropage
__ZPEND__:        .res 0
.code

.end
