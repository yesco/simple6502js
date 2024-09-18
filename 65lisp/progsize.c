#ifdef PROGSIZE

  void startprogram() {}
  char firstbss;

  #undef PROGSIZE
  #define PROGSIZE printf("Program size: %u bytes(ish)\n", ((unsigned int)&firstbss)-((unsigned int)startprogram))

  //char firstvar= 0;
  //#define PROGRAMSIZE printf("Program size: %u bytes(ish) %04x-%04x %04x %04x\n", ((uint)&firstbss)-((uint)startprogram), (uint)startprogram, (uint)main, (uint)&firstvar, (uint)&firstbss)

#else
  #define PROGSIZE 
#endif

