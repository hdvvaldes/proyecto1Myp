#pragma once

#include "Model.hpp"
#include "View.hpp"
#include "Connection.hpp"
#include "Lexer.hpp"
#include <mutex>


/*
 * Controller
 *
 * The orchestrator.  Its responsibilities are:
 *
 *  1. Read user input lines from stdin.
 *  2. Feed each line to the Lexer and drive token extraction 
 * TODO Change doc to class name parser ? 
 *  3. Validate arguments and build protocol messages via a factory of jsons.
 *  4. Send messages through Connection.
 *  5. Receive server messages (via Connection callback -> handleServerMessage).
 *  6. Update the Model. If necessary.
 *  7. Notify the View.
 *
 * The main event loop runs on the main thread; 
 * server messages arrive on a different thread using 
 * callbacks to communicate with main thread.
 */

class Controller {
public:
  Controller();
  ~Controller() = default;

  // Starts the interactive loop; returns when the user types /quit.
  void run();

private: 
  Model model_;
  View view_;
  Connection connection_;
  Lexer lexer_;

  std::mutex mutex_;
  
  /* Flag to indicate user qutting entirely */
  bool quit_ = false;

  // ---- Input handling
  void processLine(const std::string& line);

  /* 
   * Command handlers 
   * (called after the lexer identifies the command)
   * args : lexer reading input entry
   * 
   */ 
  void handleConnect(Lexer& lx);
  void handleIdentify(Lexer& lx);
  void handleStatus(Lexer& lx);
  void handleUsers();
  void handleMsg(Lexer& lx);
  void handlePub(Lexer& lx);
  void handleNewRoom(Lexer& lx);
  void handleInvite(Lexer& lx);
  void handleJoin(Lexer& lx);
  void handleRoomUsers(Lexer& lx);
  void handleRoomText(Lexer& lx);
  void handleLeave(Lexer& lx);
  void handleDisconnect();
  void handleQuit();

  /* Sends json to server 
   * MUST BE called under mutex_
   */
  void handleServerMessage(const std::string& jsonLine);

  /* Manages state changes in the model 
   * MUST BE called under mutex_
   * TODO I might move this function to other class due this one having to many handlers
   * */
  void dispatchServerEvent(const std::string& data);

  // -- Utility --------
  
  /* Gets exactly N following ARG tokens,
   * returns false and shows error if not found
   */ 
  bool requireArgs(Lexer& lx, 
      std::vector<std::string>& out, int n, 
      const std::string& usage);
  
  /* Guard to ensure client being identified,
   * already connected
   */
  bool requireIdentified();

  /*Guard to ensure client being connected*/
  bool requireConnected();
  
};
