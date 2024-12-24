unix> ./65lisp -t
% Heap: max=42620 mem=42624
% Cons: 0/4096  Hash: 32/32  Arena: 0/2048  Atoms: 0


65LISP>02 (>) 2024 Jonas S Karlsson, jsk@yesco.org

% Heap: max=23596 mem=23600
% Cons: 4/4096  Hash: 26/32  Arena: 883/2048  Atoms: 59
% Cons: +4  % Atom: +59  


> 0
0

% Eval: +1  


> 1
1

% Eval: +1  


> 2
2

% Eval: +1  


> 3
3

% Eval: +1  


> 4
4

% Eval: +1  


> 5
5

% Eval: +1  


> 6
6

% Eval: +1  


> 7
7

% Eval: +1  


> 8
8

% Eval: +1  


> 9
9

% Eval: +1  


> 10
10

% Eval: +1  


> 11
11

% Eval: +1  


> 12
12

% Eval: +1  


> 13
13

% Eval: +1  


> 14
14

% Eval: +1  


> 20
20

% Eval: +1  


> 99
99

% Eval: +1  


> 100
100

% Eval: +1  


> 101
101

% Eval: +1  


> 200
200

% Eval: +1  


> 2000
2000

% Eval: +1  


> 3000
3000

% Eval: +1  


> 4000
4000

% Eval: +1  


> 10000
10000

% Eval: +1  


> 13000
13000

% Eval: +1  


> 14000
14000

% Eval: +1  


> 15000
15000

% Eval: +1  


> 16000
16000

% Eval: +1  

% ERROR: too big num: 17000


> ERROR
ERROR




> nil
nil

% Eval: +1  


> T
T

% Eval: +1  


> (quote nil)
nil

% Eval: +1  % Cons: +2  


> (quote T)
T

% Eval: +1  % Cons: +2  


> (quote a)
a

% Eval: +1  % Cons: +2  % Atom: +1  


> (quote b)
b

% Eval: +1  % Cons: +2  % Atom: +1  


> (quote c)
c

% Eval: +1  % Cons: +2  % Atom: +1  


> (quote abc)
abc

% Eval: +1  % Cons: +2  % Atom: +1  


> (quote aaa)
aaa

% Eval: +1  % Cons: +2  % Atom: +1  


> (quote bbb)
bbb

% Eval: +1  % Cons: +2  % Atom: +1  


> (quote ccc)
ccc

% Eval: +1  % Cons: +2  % Atom: +1  


> (quote aaabbbccc)
aaabbbccc

% Eval: +1  % Cons: +2  % Atom: +1  


> nil
nil

% Eval: +1  


> (quote nil)
nil

% Eval: +1  % Cons: +2  


> (quote nil)
nil

% Eval: +1  % Cons: +2  


> (eq 0 0)
T

% Eval: +3  % Cons: +3  


> (eq 1 1)
T

% Eval: +3  % Cons: +3  


> (eq 42 42)
T

% Eval: +3  % Cons: +3  


> (eq nil nil)
T

% Eval: +3  % Cons: +3  


> (eq T T)
T

% Eval: +3  % Cons: +3  


> (eq (quote T) T)
T

% Eval: +3  % Cons: +5  


> (eq T (quote T))
T

% Eval: +3  % Cons: +5  


> (eq (quote nil) nil)
T

% Eval: +3  % Cons: +5  


> (eq nil (quote nil))
T

% Eval: +3  % Cons: +5  


> (eq (quote nil) (quote nil))
T

% Eval: +3  % Cons: +7  


> (eq nil (quote nil))
T

% Eval: +3  % Cons: +5  


> (eq (quote nil) nil)
T

% Eval: +3  % Cons: +5  


> (eq eq eq)
T

% Eval: +3  % Cons: +3  


> (eq T nil)
nil

% Eval: +3  % Cons: +3  


> (eq nil T)
nil

% Eval: +3  % Cons: +3  


> (eq 0 1)
nil

% Eval: +3  % Cons: +3  


> (eq 1 0)
nil

% Eval: +3  % Cons: +3  


> (+ 3 4)
7

% Eval: +3  % Cons: +3  


> (+ 1 1)
2

% Eval: +3  % Cons: +3  


> (+ 2 1)
3

% Eval: +3  % Cons: +3  


> (+ 3 1)
4

% Eval: +3  % Cons: +3  


> (+ 4 1)
5

% Eval: +3  % Cons: +3  


> (+ 5 1)
6

% Eval: +3  % Cons: +3  


> (+ 6 1)
7

% Eval: +3  % Cons: +3  


> (+ 7 1)
8

% Eval: +3  % Cons: +3  


> (+ 8 1)
9

% Eval: +3  % Cons: +3  


> (+ 9 1)
10

% Eval: +3  % Cons: +3  


> (+ 10 1)
11

% Eval: +3  % Cons: +3  


> (+ 41 1)
42

% Eval: +3  % Cons: +3  


> (+ 7 1)
8

% Eval: +3  % Cons: +3  


> (+ 7 2)
9

% Eval: +3  % Cons: +3  


> (+ 7 3)
10

% Eval: +3  % Cons: +3  


> (+ 7 4)
11

% Eval: +3  % Cons: +3  


> (+ 7 5)
12

% Eval: +3  % Cons: +3  


> (+ 7 6)
13

% Eval: +3  % Cons: +3  


> (+ 7 7)
14

% Eval: +3  % Cons: +3  


> (+ 7 8)
15

% Eval: +3  % Cons: +3  


> (+ 7 9)
16

% Eval: +3  % Cons: +3  


> (+ 7 10)
17

% Eval: +3  % Cons: +3  


> (+ 7 42)
49

% Eval: +3  % Cons: +3  


> (- 7 3)
4

% Eval: +3  % Cons: +3  


> (- 1 1)
0

% Eval: +3  % Cons: +3  


> (- 2 1)
1

% Eval: +3  % Cons: +3  


> (- 3 1)
2

% Eval: +3  % Cons: +3  


> (- 8 1)
7

% Eval: +3  % Cons: +3  


> (- 9 1)
8

% Eval: +3  % Cons: +3  


> (- 43 1)
42

% Eval: +3  % Cons: +3  


> (* 1 1)
1

% Eval: +3  % Cons: +3  


> (* 3 4)
12

% Eval: +3  % Cons: +3  


> (* 42 42)
1764

% Eval: +3  % Cons: +3  


> (* 42 1)
42

% Eval: +3  % Cons: +3  


> (* (quote a) 1)
10860

% Eval: +3  % Cons: +5  


> (* 1 (quote a))
10860

% Eval: +3  % Cons: +5  


> (* 7 2)
14

% Eval: +3  % Cons: +3  


> (* 2 7)
14

% Eval: +3  % Cons: +3  


> (* 7 4)
28

% Eval: +3  % Cons: +3  


> (* 4 7)
28

% Eval: +3  % Cons: +3  


> (* 7 8)
56

% Eval: +3  % Cons: +3  


> (* 8 7)
56

% Eval: +3  % Cons: +3  


> (* 7 16)
112

% Eval: +3  % Cons: +3  


> (* 16 7)
112

% Eval: +3  % Cons: +3  


> (* 7 32)
224

% Eval: +3  % Cons: +3  


> (* 32 7)
224

% Eval: +3  % Cons: +3  


> (* 7 64)
448

% Eval: +3  % Cons: +3  


> (* 64 7)
448

% Eval: +3  % Cons: +3  


> (* 7 128)
896

% Eval: +3  % Cons: +3  


> (* 128 7)
896

% Eval: +3  % Cons: +3  


> (* 7 256)
1792

% Eval: +3  % Cons: +3  


> (* 256 7)
1792

% Eval: +3  % Cons: +3  


> (* 7 1024)
7168

% Eval: +3  % Cons: +3  


> (* 1024 7)
7168

% Eval: +3  % Cons: +3  


> (* 7 2048)
14336

% Eval: +3  % Cons: +3  


> (* 2024 7)
14168

% Eval: +3  % Cons: +3  


> (* 7 4096)
-4096

% Eval: +3  % Cons: +3  


> (* 4096 7)
-4096

% Eval: +3  % Cons: +3  


% Heap: max=23596 mem=23600
% Cons: 273/4096  Hash: 26/32  Arena: 1005/2048  Atoms: 67


Program size: 20074 bytes(ish)
10382235 cycles
--- EXIT=0 ---
10.38223500000000000000
seconds simulated time


