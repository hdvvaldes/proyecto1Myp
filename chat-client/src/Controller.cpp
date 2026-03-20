#include "Controller.hpp"
#include <iostream>
#include <mutex>

// ---------------------------------------------
//  Constructor
// ---------------------------------------------

Controller::Controller()
{
  // Wire up the Connection callbacks
  connection_.setMessageCallback(
      [this](const std::string& json) {
      handleServerMessage(json);
      });
  connection_.setErrorCallback(
      [this](const std::string& reason) {
      std::lock_guard<std::mutex> lock(mutex_);
      model_.setConnectionState(ConnectionState::DISCONNECTED);
      view_.showConnectionError(reason);
      });
}

/* Infinite cycle reading user input */
void Controller::run() {
  view_.showWelcome();
  view_.showPrompt();
  std::string line;

  while (!quit_ && std::getline(std::cin, line)) {
    std::lock_guard<std::mutex> lock(mutex_);
    processLine(line);
  }
}

/*
 * Runs a command handler based on the lexer
 * first token
 */
void Controller::processLine(const std::string& line) {
  if (line.empty()) {
    view_.showPrompt();
    return;
  }

  lexer_.setInput(line);
  Token tok = lexer_.nextToken();

  switch (tok) {
    case Token::CMD_HELP:
      view_.showHelp();
      break;
    case Token::CMD_QUIT:
      handleQuit();
      break;
    case Token::CMD_DISCONNECT:
      handleDisconnect();
      break;
    case Token::CMD_USERS:
      handleUsers();
      break;
    case Token::CMD_CONNECT:
      handleConnect(lexer_);
      break;
    case Token::CMD_IDENTIFY:
      handleIdentify(lexer_);
      break;
    case Token::CMD_STATUS:
      handleStatus(lexer_);
      break;
    case Token::CMD_MSG:
      handleMsg(lexer_);
      break;
    case Token::CMD_PUB:
      handlePub(lexer_);
      break;
    case Token::CMD_NEWROOM:
      handleNewRoom(lexer_);
      break;
    case Token::CMD_INVITE:
      handleInvite(lexer_);
      break;
    case Token::CMD_JOIN:
      handleJoin(lexer_);
      break;
    case Token::CMD_ROOMUSERS:
      handleRoomUsers(lexer_);
      break;
    case Token::CMD_ROOMTEXT:
      handleRoomText(lexer_);
      break;
    case Token::CMD_LEAVE:
      handleLeave(lexer_);
      break;
    // Unrecognized commands
    case Token::UNKNOWN_CMD:
      view_.showUnknownCommand(lexer_.lexeme());
      break;
    case Token::RAW_TEXT:
      view_.showUnknownCommand(line);
      break;
    default:
      view_.showPrompt();
      break;
  }
}

// --------------------------------
// ------ Command Handlers --------
// --------------------------------

/*
 * Handler for
 * /connect <host> <port>
 */
void Controller::handleConnect(Lexer& lx) {
    std::vector<std::string> args;
    if (!requireArgs(lx, args, 2,
          "/connect <host> <port>")) return;
    const std::string& host = args[0];
    int port = 0;
    try {
      port = std::stoi(args[1]);
    } catch (...) {
      view_.showError("Invalid port: " + args[1]);
      return;
    }
    // TODO this might cause problems in future
    // TODO manage being identified and running /connect
    if (connection_.isConnected())
      connection_.disconnect();
    model_.setConnectionState(ConnectionState::CONNECTED);
    if (connection_.connect(host, port)) {
        view_.showConnected(host, port);
    } else {
        model_.setConnectionState(ConnectionState::DISCONNECTED);
    }
}

void Controller::handleIdentify(Lexer& lx){
}

void Controller::handleStatus(Lexer& lx){

}

void Controller::handleUsers(){

}

void Controller::handleMsg(Lexer& lx){

}

/*
 * Handler to manage
 * /pub <message>
 */
void Controller::handlePub(Lexer& lx) {
  // TODO manage not being identified
  Token tk = lx.nextToken();
  if (tk != Token::TEXT_BODY && tk != Token::ARG) {
    view_.showError("Usage: /pub <text>");
    return;
  }
  std::string text = lx.lexeme();
  // TODO manage json parsing here
  connection_.send(text);
}

void Controller::handleNewRoom(Lexer& lx){

}

void Controller::handleInvite(Lexer& lx){

}

void Controller::handleJoin(Lexer& lx){

}

void Controller::handleRoomUsers(Lexer& lx){

}

void Controller::handleRoomText(Lexer& lx){

}

void Controller::handleLeave(Lexer& lx){

}

void Controller::handleDisconnect(){

}

void Controller::handleQuit(){

}

// -- Server message handling -----

void Controller::handleServerMessage(
    const std::string& jsonLine) {
    std::lock_guard<std::mutex> lock(mutex_);
  // TODO auto data = Parser::parse(jsonLine);
  // TODO dispatchServerEvent(data);
}

void Controller::dispatchServerEvent(
    const std::string& data){
  // TODO manage dispatcher
}

/*
 * Utility Functions
 */

bool Controller::requireArgs(Lexer& lx,
    std::vector<std::string>& out, int n,
    const std::string& usage) {
  out.clear();
  for (int i = 0; i < n; ++i) {
    Token tk = lx.nextToken();
    if (tk != Token::ARG) {
      view_.showError("Usage: " + usage);
      return false;
    }
    out.push_back(lx.lexeme());
  }
  return true;
}

bool Controller::requireIdentified() {
  if (!model_.isIdentified()) {
    // TODO view_.showNotIdentified();
    return false;
  }
  return true;
}

bool Controller::requireConnected() {
  if (!connection_.isConnected()) {
    view_.showError(
        "Not connected. \
        Use /connect <host> <port> first.");
    return false;
  }
  return true;
}

