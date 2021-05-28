let jasm = require('./jasm.js');

global.ORG(0x0501);
        global.LDAN(3);
        LDAN(3, (v)=>v*v);
        LDAN(3);

L('foo');
        LDAN('foo', lo);
        LDAN('foo', hi);
        LDAN('bar', hi); // forward!
        LDAN('bar', (v)=>hi(v)*hi(v)); // delaye

L('bar');
        LDAN(0xbe);
        LDAN(0xef);

L('fish');
        LDAN(0xff);

L('string');
        string("ABC");

L('sverige');
        string("Svörigä");

L('char');
        char('j');
        char('ö');
L('copy');
        char('©');

L('here');
	BNE('here');
	LDAN(0x42);
	BNE('there');
	RTS()
L('there');
	RTS()
L('end');

console.log(jasm.getChunks());
console.log(jasm.getHex(1,1,1));
console.log(jasm.getHex(0,0,0));

