.import tosaslax, tosshlax, aslaxy, shlaxy
.import __CALLIRQ__
.import __argc, __argv

.import _abs

.import addeq0sp, addeqysp
.import addysp1, addysp

.import aslax1, shlax1
.import aslax2, shlax2
.import aslax3, shlax3
.import aslax4, shlax4
.import aslax7

.import asleax1, shleax1
.import asleax2, shleax2
.import asleax3, shleax3
.import asleax4, shleax4

.import asrax1
.import asrax2
.import asrax3
.import asrax4
.import asrax7

.import asreax1
.import asreax2
.import asreax3
.import asreax4

.import aulong, along
.import axulong, axlong

.import bcasta, bcastax
.import bcasteax

.import bnega, bnegax
.import bnegeax

.import boolne, booleq, boollt, boolle, boolgt, boolge
.import boolult, boolule, boolugt, booluge

.import bpushbsp, bpushbysp

.import callax
.import callirq
.import callirq_y       ; Same but with Y preloaded
.import callmain
.import callptr4

.import complax
.import compleax

.import decax1
.import decax2
.import decax3
.import decax4
.import decax5
.import decax6
.import decax7
.import decax8

.import decaxy
.import deceaxy

.import decsp1
.import decsp2
.import decsp3
.import decsp4
.import decsp5
.import decsp6
.import decsp7
.import decsp8

.import enter

.import idiv32by16r16
.import imul16x16r32
.import imul8x8r16, imul8x8r16m

.import incax1
.import incax2
.import incax3
.import incax4
.import incax5
.import incax6
.import incax7
.import incax8

.import incaxy
.import inceaxy

.import incsp1
.import incsp3
.import incsp4
.import incsp5
.import incsp6
.import incsp7
.import incsp8

.import laddeq0sp, laddeqysp
.import laddeq1, laddeqa, laddeq

.import ldaxi, ldaxidx

.import ldau00sp, ldau0ysp
.import ldaui0sp, ldauiysp
.import ldauidx

.import ldax0sp, ldaxysp
.import ldeax0sp, ldeaxysp

.import ldeaxidx, ldeaxi
.import leaaxsp, leaa0sp

.import leave
.import leave00, leave0, leavey00, leavey0, leavey

.import lsubeq0sp, lsubeqysp
.import lsubeq1, lsubeqa, lsubeq

.import mul8x16, mul8x16a
.import mulax3
.import mulax5
.import mulax6
.import mulax7
.import mulax9
.import mulax10

.import negax
.import negeax

.import popa
.import popax

.import popeax
.import poplsargs

.import popptr1

.import popsargsudiv16

.import popsreg

.import pusha
.import pushax

.import pusha0
.import push0ax
.import pusheax

.import push0
.import push1
.import push2
.import push3
.import push4
.import push5
.import push6
.import push7

.import pushaFF

.import pusha0sp, pushaysp, pusha

.import pushb, pushbidx
.import pushbsp, pushbysp

.import pushc0
.import pushc1
.import pushc2

.import pushl0
.import pushlysp
.import pushptr1

.import pushw, pushwidx, pushptr1idx
.import pushwysp, pushw0sp

.import regswap
.import regswap1
.import regswap2

.import return0
.import return1
.import returnFFFF

.import saveeax, resteax

.import shrax1
.import shrax2
.import shrax3
.import shrax4
.import shrax7

.import shlax7

.import shreax1
.import shreax2
.import shreax3
.import shreax4

.import staspidx
.import staxspidx

.import staxysp, stax0sp

.import steaxspidx
.import steaxysp, steax0sp
.import stkchk, cstkchk

.import subeq0sp, subeqysp
.import subysp

.import swapstk

.import tosadd0ax, tosaddeax
.import tosadda0, tosadd
.import tosand0ax, tosandeax
.import tosanda0, tosandax

.import tosasleax, tosshleax
.import tosasrax, asraxy
.import tosasreax

.import tosdiv0ax, tosdiveax
.import tosdiva0, tosdivax

.import toseq00, toseqa0, toseqax
.import toseqeax

.import tosge00, tosgea0, tosgeax
.import tosgeeax
.import tosgt00, tosgta0, tosgtax
.import tosgteax

.import tosicmp, tosicmp0

import tosint

.import toslcmp
.import tosle00, toslea0, tosleax
.import tosleeax
.import toslt00, toslta0, tosltax
.import toslteax

.import tosmod0ax, tosmodeax
.import tosmoda0, tosmodax

.import tosne00, tosnea0, tosneax
.import tosneeax

.import tosor0ax, tosoreax
.import tosora0, tosorax

.import tosrsub0ax, tosrsubeax
.import tosrsuba0, tosrsubax

.import tosshrax, shraxy
.import tosshreax

.import tossub0ax, tossubeax
.import tossuba0, tossubax
.import tosudiv0ax, tosudiveax, getlop, udiv32
.import tosudiva0, tosudivax, udiv16
.import tosuge00, tosugea0, tosugeax
.import tosugeeax
.import tosugt00, tosugta0, tosugtax
.import tosugteax
.import tosule00, tosulea0, tosuleax
.import tosuleeax
.import tosulong, toslong
.import tosult00, tosulta0, tosultax

.import tosulteax

.import tosumod0ax, tosumodeax
.import tosumoda0, tosumodax

.import tosumul0ax, tosumuleax, tosmul0ax, tosmuleax
.import tosumula0, tosmula0
.import tosumulax, tosmulax

.import tosxor0ax, tosxoreax
.import tosxora0, tosxorax

.import udiv32by16r16, udiv32by16r16m
.import umul16x16r16, umul16x16r16m
.import umul16x16r32, umul16x16r32m
.import umul8x16r16, umul8x16r16m
.import umul8x16r24, umul8x16r24m
.import umul8x8r16, umul8x8r16m

.import utsteax, tsteax

.import	initlib, donelib, condes

.import jmpvec
