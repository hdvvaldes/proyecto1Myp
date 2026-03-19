#pragma once

#include "Model.hpp"
#include "View.hpp"
#include "Connection.hpp"
#include "Lexer.hpp"


/*
 * Controller
 *
 * The orchestrator.  Its responsibilities are:
 *
 *  1. Read user input lines from stdin.
 *  2. Feed each line to the Lexer and drive token extraction 
 * TODO Change doc to class name
 *  3. Validate arguments and build protocol messages via a factory of jsons.
 *  4. Send messages through Connection.
 *  5. Receive server messages (via Connection callback -> handleServerMessage).
 *  6. Update the Model. If necessary.
 *  7. Notify the View.
 *
 * The main event loop runs on the main thread; server messages arrive on a
 * TODO Find TChan to communicate between threads securely
 * background thread owned by Connection.
 */

class Controller {
public:
    Controller();
    ~Controller() = default;

    // Starts the interactive loop; returns when the user types /quit.
    void run();

private: 
    Model      model_;
    View       view_;
    Connection connection_;
    Lexer      lexer_;




};
