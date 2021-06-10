#include <stdio.h>

int main() {
  auto fn = [&]() {
    return 5;
  };

  printf("Goodbye world! %d\n", fn());
}
