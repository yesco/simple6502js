# simple6502js

This is just a simple 6502 generated as simple as possible as proof of concept. It's intent was to be a "single-page" readable, without any complications.

WHY? it's been done before. Sure! I just wanted that "one page". Turns out it's pretty small...

Features:
- simple one-file "one-page" "readable"
- no abstractions that get in the way
- experiment with instruction de/coding for on-board 6502
- instrution tracer
- memory dumper (0000  00 00 00 41  ...A)
- hackable

## How to use

   ./run

Runs gen.pl generating file fil.js and runs node on it. If you haven't changed the gen.pl it'll generated the same as simple6502.js.

The program generates code for some useful inspections.

There are functions exported by the CPU6502 function that generates an CPU simulator.

# TODO

Possible TODO:s
- [ ] make it a real node module
- [ ] add cycle count
- [ ] optimize for performance (no switch)
- [ ] write a STXZX style dis/assembler
- [ ] utility file to read a binary program with location either from filename or as arguemnt
- [ ] generate a C variant?
- [ ] ... please add

## speed

It's not fast! Switch on javascript is terrible choice for large options, it becomes a list of if:s. For speed, it's better to use function calls and array lookups.

tiny6502.js is a handedited proof of concept for compact code, it's actually not smaller, but for JS have benefits that reflection provides the names of the functions which simplifies tracing. I'm not happy with it, as it's pretty ugly and NOTreadable.

WARNING: It doesn't generate the correct instructions yet!

