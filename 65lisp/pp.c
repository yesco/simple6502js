#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <ctype.h>
#include <assert.h>
#include <unistd.h>
#include <math.h>

// --- CONFIG

// show all paths
int displayfail= 0;

// set to desired screen size
//int h= 24, w= 38;
int h= 55, w= 80;


// --- MEAT

size_t len= 0;

void out(char** pr, char c) {
  *(*pr)++= c;
  //putchar(c);
  //putchar('.');
}

void newline(char** pr, int o) {
  out(pr, '\n'); for(int i=0; i<o; ++i) out(pr, ' ');
}

void skipspace(char** ps) {
  while(isspace(**ps)) (*ps)++;
}

void processatom(char** pr, char** ps, int* pc) {
  // TDOO: string and |foo bar|
  while(!isspace(**ps) && **ps!='(' && **ps!=')') {
    out(pr, *((*ps)++)); ++(*pc);
  }
}

float leastarea;

float area(int h, int w, int wsum) {
  return powf(2,h)*powf(1.3,w)*powf(10.1,wsum?wsum:1); // great for code.lisp
  return powf(2,h)*powf(1.3,w)*powf(10.1,wsum?wsum:1); // great for code.lisp
  return powf(2,h)*powf(1.3,w)*powf(10.1,wsum?wsum:1); // great for code.lisp
  return powf(100.0*w/h, h) * powf(7, w) * powf(100, wsum?wsum:1);
  return powf(35.0*w/h, h) * powf(7, w);
  return powf(30, h) * powf(10, w) * powf(1.1, wsum?wsum:1);
  return h * powf(10, w) * pow(1.1, wsum?wsum:1);
  return h * powf(10, w); // seems goood
  return h * powf(1.5, w); // seems goood
  //return h * powf(1.1, w); // seems goood
  //return h * powf(1.01, w); // not soo good
  //return h * w; // too long lines
}

void line(int w) {
  printf("\n");
  for(int i=0; i<w; ++i) putchar('-');
  printf("\n");
}

void printer(char* s, int r, int c, int o, int* stack, char* prev, int deep, int maxw, float sumarea) {
  char res[h*w+w], *p= res+strlen(prev);
  int ostack[256]= {0};
  if (stack) memcpy(ostack, stack, sizeof(ostack));

  memset(res, 0, sizeof(res));
  strcat(res, prev);

  int norecurse= 0;
  float wsum= 0;

  // newline
  if (c==0) {
    //float rowcost= 10*r*c;
    float rowcost= r*c;
    wsum+= rowcost;
    r++; c= o; newline(&p, o);
    norecurse++;
    skipspace(&s);
    // line cannot start with ')'
    if (*s==')') return;

  }

  while(*s) {

    float a= area(r, maxw, wsum);
    if (a > leastarea) return;

    switch(*s) {
    case ' ': case '\n': case '\r': case '\t': // ignore all but first
      out(&p, ' '); c++;
      skipspace(&s);
      break;
    case '(':
      //out(&p, 'A'+o);

      // before every '(' choise of newline!
      // TODO: this may be a never ending choice... delay others
      if (!norecurse)
        printer(s, r, 0, o, ostack, res, deep, maxw, sumarea);

      //out(&p, '0'+deep); // c++;
      ostack[deep]= o;

      ++deep;
      out(&p, *s++); c++;
      skipspace(&s);
      int newo= c+2;

      // process first word, if list, hmmm?
      processatom(&p, &s, &c);

      // 1. choose to continue line
      // TODO: not recurse
      printer(s, r, c, newo, ostack, res, deep, maxw, sumarea); 

      // 2. choose newline, 
      if (norecurse) --norecurse; // set as will see
      else printer(s, r, 0, newo, ostack, res, deep, maxw, sumarea);

      return;
    case ')':
      // TODO: pop old offset? or at least at newline?
      deep--;
      if (deep<0) assert(!"^^^^^^^^^^ ONE TO MANY ')\n");
      out(&p, *s++); c++;

      //out(&p, '0'+deep); // c++;

      o= ostack[deep];

      // start of new function in same file
      // each optimized independeintly
      if (!deep) { 
        sumarea+= area(r, maxw, wsum);
        maxw= 0; wsum= 0; o= 0;
        printer(s, r, 0, o, ostack, res, deep, maxw, sumarea);
        //r++; o= 0; newline(&p, o); c= 1; skipspace(&s);
      }
      // 1. continue line
      printer(s, r, c, o, ostack, res, deep, maxw, sumarea);
      //if (!deep) { r++; o= c= 0; newline(&p, o); skipspace(&s); }
      // 1. newline
      printer(s, r, 0, o, ostack, res, deep, maxw, sumarea);

      return;

      break;
    case ';': // comment - ignore for now
      while(*++s!='\n'){}; s++;
      //newline(&p, 0);
      //r++; c= o; break;
      break;
    default:
      if (*s <= ' ') { skipspace(&s); break; }
      //out(&p, *s++); c++; break;
      processatom(&p, &s, &c);
    }

    // can't get better...
    if (sumarea > leastarea) {
      fprintf(stderr, "%% PRUNED %f                       \r", sumarea);
      return;
    }

    if (c > maxw) maxw= c;

    if (c > w || r > h) {
      if (displayfail) {
        usleep(1000);
        printf("[H[2J[3J");
        line(w);
        printf("%s", res);
        printf("\nxxxxxxxxxxxxxxxx FAIL(r=%d c=%d)\n", r, c);
      }
      return;
    }

  }

  //usleep(10*1000);
  //usleep(1000);

  // TODO: should be sum of area of each "function"

  //float a= area(r, maxw?maxw:1000);
  //printf("%f\t%f\t%f\n", a, leastarea, 1e38);

  if (sumarea < leastarea) {
    usleep(10*1000);
    printf("[H[2J[3J");
    line(w);
    printf("%s", res);
    line(w);
    printf("SUCESSS (r=%d mw=%d area=%f)\n\n", r, maxw, sumarea);
    leastarea= sumarea;
  }
}

int main(int argc, char** argv) {

  // read all of stdin
  char* in= NULL;
  printf("READ: %zd bytes\n\n", getdelim(&in, &len, 0, stdin));

  printf("%s", in);

  printf("\n========= ^^^^^^^__________ INPUT\n");

  //leastarea= area(h, w, );
  leastarea= 3e38;

  printer(in, 1, 1, 0, NULL, "", 0, 0, 0);
  printf("\n\n");

  free(in);
  return 0;
}
