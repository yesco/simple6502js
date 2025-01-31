// LOGO alphabetical language

// random reference
// - https://www.calormen.com/jslogo/language.html#sec6
#include "hires-raw.c"

// right:
//  dx  dy
//   0  +1
//  +1   0
//   0  -1
//  -1   0
//   0  +1

#define NSTACK 32
int stack[NSTACK], nstack= 0;

#define push(v) (stack[++nstack]= (v))
#define pop() (nstack[nstack--])

void logo(char* s) {
  char* r= NULL;
  int n, i;

  // do we need to keep sub integer resolution?
  // i.e. scaling factor, 2^n 
  int dx=0,dy=-1,dz=1;
  --s;
#define Z goto next; case
 next:
  switch(*++s) {
  case 0: return NULL;

  // 90d turn - simple!
  Z 'r': i= dx; dx= dy; dy= i;
  Z 'l': i= dx; dx= -dy; dy= i;

  // movement
  Z 'h': gcurx= 240/2; gcury= 200/2;
  Z 'x': gcurx= pop();
  Z 'y': gcury= pop();
  Z 'f': { int n= pop();
      int zx= i*dx/dz, zy= i*dy/dz;
      if (down) draw(zx, zy);
      else { gcurx+= zx, gcury+= zy; }
    }

  // modes
  Z 'd': down= 1;
  Z 'u': down= 0;
  Z 'M': mode= pop(); 

  // draw
  Z 'C': gclear();

  Z 'c': circle(n, mode);


  Z 'L': // oric: plot // draw label/text
  case 'A': // TODO: arc not moving "arc 180 100" dest
  case 'F': // TODO: fill
    goto fail:

  // repeat 3[...] v[...]==IFTHEN
  Z ']': return s;
  Z '[':
    while(--n>0) r= logo(s+1);
    if (s= r) return NULL;

  // turtle - maybe only when waiting user input?
  // TODO: show
  // TODO: hide

  Z '$': switch(*++s) {
    Z 'X': push(gcurx);
    Z 'Y': push(gcury);
    Z 'A': push(angle);
    Z 'S': push(scale);
    Z 'B': // TODO: bounds?
    default:
      if (islower(*s)) {
        push(var[*s-'a']); goto next;
      }
      --s; goto fail;

    //Z '!w': // TODO: wrap, window, fence
    //case 't': // TODO: turn, towards xy => angle
    default:
      if (isdigit(*s)) {
        stack[nstack]= stack[nstack]*10 + *s-'0';
        goto next;
      }
      // fail
    }

  fail:
    printf("\n%% Not implemented yet: %s", s);
}

void main() {
  logo("h10f");
}
