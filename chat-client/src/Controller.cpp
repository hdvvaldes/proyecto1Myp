#include "Controller.hpp"
#include <iostream>

// ---------------------------------------------
//  Constructor
// ---------------------------------------------

Controller::Controller()
{

}


// ---------------------------------------------
//  run – main loop
// ---------------------------------------------

void Controller::run() {
  view_.showWelcome();
  view_.showPrompt();
}
