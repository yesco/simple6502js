
function subADC(oper)
{
	if (FlagD==1)
	{
		var t1=(A&0xF)+(oper&0xF)+FlagC;
		if (t1>9) t1+=6;
		t1+=(A&0xF0)+(oper&0xF0);
		if (t1>=0xA0) t1+=0x60;
		cycle_count++;
	} 
	else var t1=A+oper+FlagC;
	if (t1>=0x100){t1&=0xFF;FlagC=1;}else FlagC=0;
	if ((A<0x80)&&(oper<0x80)&&(t1>=0x80)) FlagV=1;
	else if ((A>=0x80)&&(oper>=0x80)&&(t1<0x80)) FlagV=1;
	else FlagV=0;
	A=t1;
	if (A==0) FlagZ=1;else FlagZ=0;
	if (A>=0x80) FlagN=1;else FlagN=0;
}
function subAND(oper)
{
	A&=oper;
	if (A==0) FlagZ=1;else FlagZ=0;
	if (A>=0x80) FlagN=1;else FlagN=0;
}

https://github.com/JoeyShepard/65C02_Emulator/blob/master/emu6502.js

function subSBC(oper)
{
	if (FlagD==1) 
	{
		if ((oper==0)&&(FlagC==0))
		{
			oper=1;
			FlagC=1;
		}
		var t1=(A&0xF)+(9-(oper&0xF)+FlagC);
		if (t1>9) t1+=6;
		t1+=(A&0xF0)+(0x90-(oper&0xF0));
		if (t1>0x99) t1+=0x60;
		if (t1>=0x100) 
		{
			t1-=0x100;
			FlagC=1;
		}
		else FlagC=0;
		//May happen if oper is not valid BCD
		if (t1<0) t1=0;
		cycle_count++;
	}
	else
	{
		var t1=A-oper-1+FlagC;
		if (t1<0){t1+=0x100;FlagC=0;}else FlagC=1;
	}
	if ((A<0x80)&&(oper>=0x80)&&(t1>=0x80)) FlagV=1;
	else if ((A>=0x80)&&(oper<0x80)&&(t1<0x80)) FlagV=1;
	else FlagV=0;
	A=t1;
	if (A==0) FlagZ=1;else FlagZ=0;
	if (A>=0x80) FlagN=1;else FlagN=0;
}

