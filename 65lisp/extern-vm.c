extern L return0(L);
extern L retnil(L);
extern L rettrue(L);

extern L istrue(L);
extern L isfalse(L);
extern L iscarry(L);

extern L callax(L);

extern void ffmul();

extern L ffffcar(L);
extern L ffffcdr(L);

extern L fffcar(L);
extern L fffcdr(L);

extern L ffcar(L);
extern L ffcdr(L);

extern L ffnull(L);
extern L ffisnum(L);
extern L ffiscons(L);
extern L ffisatom(L);
extern L fftype(L);

extern L ldaxi(L);
extern L ldaxidx(L);
extern L ldax0sp(L);
extern L ldaxysp(L);

extern void push0();
extern void push2();
extern void push4();
extern void pushax(); 
extern void popax(); 

extern void incsp2(); // JSR=drop, JMP=return!
extern void incsp4();
extern void incsp6();
extern void incsp8();

extern void negax();

extern void tosaddax();
extern void tossubax();
extern void tosmulax();
extern void tosdivax();
extern void tosadda0();
extern void tossuba0();
extern void tosmula0();
extern void tosdiva0();


extern void mulax3();
extern void mulax5();
extern void mulax6();
extern void mulax7();
extern void mulax9();
extern void mulax10();
extern void mulaxy();

extern void asrax1();
extern void asrax2();
extern void asrax3();
extern void asrax4();
//extern void asrax7();

extern void asraxy();


extern void aslax1();
extern void aslax2();
extern void aslax3();
extern void aslax4();
//extern void aslax7();

extern void aslaxy();


extern void shrax1();
extern void shrax2();
extern void shrax3();
extern void shrax4();
//extern void shrax7();

extern void shraxy();


extern void shlax1();
extern void shlax2();
extern void shlax3();
extern void shlax4();
//extern void shlax7();

extern void shlaxy();



extern void decax1();
extern void decax2();
extern void decax3();
extern void decax4();
extern void decax5();
extern void decax6();
extern void decax7();
extern void decax8();
extern void decaxy();

extern void incax1();
extern void incax2();
extern void incax3();
extern void incax4();
extern void incax5();
extern void incax6();
extern void incax7();
extern void incax8();
extern void incaxy();


extern void toseq00();
extern void toseqa0();
extern void toseqax();

extern void addysp();

extern void staxspidx();
