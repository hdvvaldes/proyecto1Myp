#pragma once

#include "Connection.hpp"
#include "Lexer.hpp"
#include "Model.hpp"
#include "View.hpp"
#include <mutex>
#include <string>
#include <vector>

/*
 * Controller
 *
 * The orchestrator. Its responsibilities are:
 *  1. Read user input lines from stdin.
 *  2. Feed each line to the Lexer and drive token extraction.
 *  3. Validate arguments and build protocol messages via MessageCodec.
 *  4. Send messages through Connection.
 *  5. Receive server messages (via Connection callback -> handleServerMessage).
 *  6. Update the Model.
 *  7. Notify the View.
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

    // ---- Server message handling
    void handleServerMessage(const std::string& jsonLine);
    void dispatchServerEvent(const ModelEventData& data);

    // ---- Helpers
    bool requireArgs(Lexer& lx, std::vector<std::string>& out, int n, const std::string& usage);
    bool requireIdentified();
    bool requireConnected();
};