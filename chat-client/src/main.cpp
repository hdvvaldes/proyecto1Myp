#include "Controller.hpp"
#include <stdio.h>

int main() {
  printf("%s\n","-----------");
  printf("%s\n", "Starting Controller");
  printf("%s\n","-----------");
  Controller controller;
  controller.run();
}
