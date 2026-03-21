#include "Controller.hpp"
#include <stdio.h>

int main() {
  printf("%s\n","-----------");
  printf("%s\n", "Starting Controller");
  printf("%s\n","-----------");
  // TODO manage exceptions, or idk dude
  Controller controller;
  controller.run();
}
