// Functions - no parameters (yet)
typedef unsigned int word;
word F() { return 4700; }
word G() { return F()+11; }
word main() {
  return G(); // tail call
}
