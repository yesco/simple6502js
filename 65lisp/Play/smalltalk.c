#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

// Simple environment for variables
typedef struct Env {
  const char *name;
  int val;
  struct Env *next;
} Env;

int eval(const char **p, Env *env);

// Smalltalk Logic for Fibonacci: 
// If self <= 2, result is 1. Else, calculate recursively.
const char* FIB_BODY = "self <= 2 ifTrue: [ 1 ]. self > 2 ifTrue: [ (self - 1) fib + (self - 2) fib ]";

int lookup(Env *e, const char *name) {
  while (e) {
    if (strcmp(e->name, name) == 0) return e->val;
    e = e->next;
  }
  return 0;
}

const char* skip(const char *p) {
  while (*p && (isspace(*p) || *p == '.')) p++;
  return p;
}

// Method Dispatch
int send(int receiver, const char *msg) {
  if (strcmp(msg, "fib") == 0) {
    Env method_env = { "self", receiver, NULL };
    const char *p = FIB_BODY;
    return eval(&p, &method_env);
  }
  return 0;
}

int eval(const char **p, Env *env) {
  int res = 0;
  *p = skip(*p);

  while (**p && **p != ']') {
    // 1. Parse Primary (Literal, Variable, or Parenthesized Expression)
    if (isdigit(**p)) {
      res = (int)strtol(*p, (char**)p, 10);
    } else if (**p == '(') {
      (*p)++; // Skip (
      res = eval(p, env);
      if (**p == ')') (*p)++; // Skip )
    } else if (isalpha(**p)) {
      char name[32] = {0};
      int i = 0;
      while (isalnum(**p)) name[i++] = *(*p)++;
      res = lookup(env, name);
    }

    *p = skip(*p);

    // 2. Message Loop (Binary, Keyword, or Unary)
    while (**p && **p != ']' && **p != '.' && **p != ')') {
      if (**p == '+' || **p == '-' || **p == '>' || **p == '<') {
        char op[3] = {0};
        op[0] = *(*p)++;
        if (**p == '=') op[1] = *(*p)++;
        int arg = eval(p, env);
        if (op[0] == '+') res += arg;
        if (op[0] == '-') res -= arg;
        if (op[0] == '>') res = (res > arg);
        if (op[0] == '<') res = (res <= arg);
      } else if (strncmp(*p, "ifTrue:", 7) == 0) {
        *p += 7;
        *p = skip(*p);
        if (**p == '[') {
          const char *block_start = ++(*p); // Move inside [
          if (res) {
            const char *tmp = block_start;
            res = eval(&tmp, env);
          }
          // Advance caller's pointer past the block
          int depth = 1;
          while (depth > 0 && **p) {
            if (**p == '[') depth++;
            if (**p == ']') depth--;
            (*p)++;
          }
        }
      } else if (isalpha(**p)) { // Unary message (e.g., fib)
        char msg[32] = {0};
        int i = 0;
        while (isalnum(**p)) msg[i++] = *(*p)++;
        res = send(res, msg);
      } else break;
      *p = skip(*p);
    }
    if (**p == '.') *p = skip(*p); // Handle statement separator
  }
  return res;
}

int main() {
  const char *code = "10 fib";
  const char *p = code;
  printf("Result: %d\n", eval(&p, NULL));
  return 0;
}
