// Compatiblity layer for MeteoriC compiler
// 
// This file allows to share C code with
// other compilers and get "similar" results
// but getting ALL THE OPTIMIZATIONS on MeteoriC.
//
// Include this file in your project.
// The include will be ignored by MeteoriC.

#ifndef METEORIC_COMPAT

  #define METEORIC_COMPAT
 
  #include <stdint.h>
  typedef uint16_t word;

  #define BFILL(arr,val) memset(arr,val,sizeof(arr))
  #define BZERO(arr)     BFILL(arr,0)

  #define putu(v)        printf("%u", v)
  #define putd(v)        printf("%d", v)
  #define puth(v)        printf("$%4x", v) 
  #define putz(s)        fputs(stdout, s)

  // These won't capture the leading zero encoding
  #define putfu(v,w,p,spost)  printf("%*.*u%s",w,p,v,spost)
  #define putfd(v,w,p,spost)  printf("%*.*d%s",w,p,v,spost)
  #define putfx(v,w,p,spost)  printf("%*.*x%s",w,p,v,spost)
  #define putfs(v,w,p,spost)  printf("%*.*x%s",w,p,v,spost)

#endif
