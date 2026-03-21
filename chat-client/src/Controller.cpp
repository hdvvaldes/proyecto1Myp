#include "Controller.hpp"
#include "MessageCodec.hpp"
#include <iostream>

Controller::Controller() {
    // Wire up the Connection callbacks
    connection_.setMessageCallback([this](const std::string& json) {
        handleServerMessage(json);
    });
    connection_.setErrorCallback([this](const std::string& reason) {
        std::lock_guard<std::mutex> lock(mutex_);
        model_.setConnectionState(ConnectionState::DISCONNECTED);
        view_.showConnectionError(reason);
    });
}

void Controller::run() {
    view_.showWelcome();
    view_.showPrompt();

    std::string line;
    while (!quit_ && std::getline(std::cin, line)) {
        std::lock_guard<std::mutex> lock(mutex_);
        processLine(line);
    }
}

void Controller::processLine(const std::string& line) {
    if (line.empty()) {
        view_.showPrompt();
        return;
    }

    lexer_.setInput(line);
    Token tok = lexer_.nextToken();

    switch (tok) {
        case Token::CMD_HELP:       view_.showHelp();         break;
        case Token::CMD_QUIT:       handleQuit();             break;
        case Token::CMD_DISCONNECT: handleDisconnect();       break;
        case Token::CMD_USERS:      handleUsers();            break;
        case Token::CMD_CONNECT:    handleConnect(lexer_);    break;
        case Token::CMD_IDENTIFY:   handleIdentify(lexer_);   break;
        case Token::CMD_STATUS:     handleStatus(lexer_);     break;
        case Token::CMD_MSG:        handleMsg(lexer_);        break;
        case Token::CMD_PUB:        handlePub(lexer_);        break;
        case Token::CMD_NEWROOM:    handleNewRoom(lexer_);    break;
        case Token::CMD_INVITE:     handleInvite(lexer_);     break;
        case Token::CMD_JOIN:       handleJoin(lexer_);       break;
        case Token::CMD_ROOMUSERS:  handleRoomUsers(lexer_);  break;
        case Token::CMD_ROOMTEXT:   handleRoomText(lexer_);   break;
        case Token::CMD_LEAVE:      handleLeave(lexer_);      break;

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

// ═════════════════════════════════════════════
//  Command handlers
// ═════════════════════════════════════════════

void Controller::handleConnect(Lexer& lx) {
    std::vector<std::string> args;
    if (!requireArgs(lx, args, 2, "/connect <host> <port>")) return;

    const std::string& host = args[0];
    int port = 0;
    try {
        port = std::stoi(args[1]);
    } catch (...) {
        view_.showError("Invalid port: " + args[1]);
        return;
    }

    if (connection_.isConnected())
        connection_.disconnect();

    model_.setConnectionState(ConnectionState::CONNECTED);
    if (connection_.connect(host, port)) {
        view_.showConnected(host, port);
    } else {
        model_.setConnectionState(ConnectionState::DISCONNECTED);
    }
}

void Controller::handleIdentify(Lexer& lx) {
    if (!requireConnected()) return;

    std::vector<std::string> args;
    if (!requireArgs(lx, args, 1, "/identify <username>")) return;

    const std::string& username = args[0];
    if (username.size() > 8) {
        view_.showError("Username must be at most 8 characters.");
        return;
    }

    connection_.send(MessageCodec::buildIdentify(username));
}

void Controller::handleStatus(Lexer& lx) {
    if (!requireIdentified()) return;

    std::vector<std::string> args;
    if (!requireArgs(lx, args, 1, "/status <ACTIVE|AWAY|BUSY>")) return;

    const std::string& s = args[0];
    if (s != "ACTIVE" && s != "AWAY" && s != "BUSY") {
        view_.showError("Status must be ACTIVE, AWAY, or BUSY.");
        return;
    }
    connection_.send(MessageCodec::buildStatus(s));
    
    // We update locally to provide immediate feedback, although the server will broadcast it back.
    model_.setUserStatus(Model::statusFromString(s));
    view_.showStatusChanged(s);
}

void Controller::handleUsers() {
    if (!requireIdentified()) return;
    connection_.send(MessageCodec::buildUsers());
}

void Controller::handleMsg(Lexer& lx) {
    if (!requireIdentified()) return;

    std::vector<std::string> nameVec;
    if (!requireArgs(lx, nameVec, 1, "/msg <username> <text>")) return;

    Token tk = lx.nextToken();
    if (tk != Token::ARG && tk != Token::TEXT_BODY) {
        view_.showError("Usage: /msg <username> <text>");
        return;
    }
    std::string text = lx.lexeme();

    // Gather remaining tokens
    if (tk == Token::ARG) {
        Token t2 = lx.nextToken();
        while (t2 == Token::ARG || t2 == Token::TEXT_BODY) {
            text += " " + lx.lexeme();
            t2 = lx.nextToken();
        }
    }

    if (text.empty()) {
        view_.showError("Usage: /msg <username> <text>");
        return;
    }

    connection_.send(MessageCodec::buildText(nameVec[0], text));
}

void Controller::handlePub(Lexer& lx) {
    if (!requireIdentified()) return;

    Token tk = lx.nextToken();
    if (tk != Token::TEXT_BODY && tk != Token::ARG) {
        view_.showError("Usage: /pub <text>");
        return;
    }
    std::string text = lx.lexeme();
    // Gather remaining if it was just one word
    if (tk == Token::ARG) {
        Token t2 = lx.nextToken();
        while (t2 == Token::ARG || t2 == Token::TEXT_BODY) {
            text += " " + lx.lexeme();
            t2 = lx.nextToken();
        }
    }

    connection_.send(MessageCodec::buildPublicText(text));
}

void Controller::handleNewRoom(Lexer& lx) {
    if (!requireIdentified()) return;

    std::vector<std::string> args;
    if (!requireArgs(lx, args, 1, "/newroom <roomname>")) return;

    if (args[0].size() > 16) {
        view_.showError("Room name must be at most 16 characters.");
        return;
    }
    connection_.send(MessageCodec::buildNewRoom(args[0]));
}

void Controller::handleInvite(Lexer& lx) {
    if (!requireIdentified()) return;

    std::vector<std::string> roomArg;
    if (!requireArgs(lx, roomArg, 1, "/invite <roomname> <user1> [user2 …]")) return;

    std::vector<std::string> users;
    Token tk = lx.nextToken();
    while (tk == Token::ARG) {
        users.push_back(lx.lexeme());
        tk = lx.nextToken();
    }

    if (users.empty()) {
        view_.showError("Usage: /invite <roomname> <user1> [user2 …]");
        return;
    }
    connection_.send(MessageCodec::buildInvite(roomArg[0], users));
}

void Controller::handleJoin(Lexer& lx) {
    if (!requireIdentified()) return;

    std::vector<std::string> args;
    if (!requireArgs(lx, args, 1, "/join <roomname>")) return;

    connection_.send(MessageCodec::buildJoinRoom(args[0]));
}

void Controller::handleRoomUsers(Lexer& lx) {
    if (!requireIdentified()) return;

    std::vector<std::string> args;
    if (!requireArgs(lx, args, 1, "/roomusers <roomname>")) return;

    connection_.send(MessageCodec::buildRoomUsers(args[0]));
}

void Controller::handleRoomText(Lexer& lx) {
    if (!requireIdentified()) return;

    std::vector<std::string> roomArg;
    if (!requireArgs(lx, roomArg, 1, "/roomtext <roomname> <text>")) return;

    std::string text;
    Token tk = lx.nextToken();
    bool first = true;
    while (tk == Token::ARG || tk == Token::TEXT_BODY) {
        if (!first) text += " ";
        text += lx.lexeme();
        first = false;
        tk = lx.nextToken();
    }

    if (text.empty()) {
        view_.showError("Usage: /roomtext <roomname> <text>");
        return;
    }

    connection_.send(MessageCodec::buildRoomText(roomArg[0], text));
}

void Controller::handleLeave(Lexer& lx) {
    if (!requireIdentified()) return;

    std::vector<std::string> args;
    if (!requireArgs(lx, args, 1, "/leave <roomname>")) return;

    connection_.send(MessageCodec::buildLeaveRoom(args[0]));
}

void Controller::handleDisconnect() {
    if (!connection_.isConnected()) {
        view_.showError("Not connected.");
        return;
    }
    connection_.send(MessageCodec::buildDisconnect());
    connection_.disconnect();
    model_.setConnectionState(ConnectionState::DISCONNECTED);
    view_.showDisconnected();
}

void Controller::handleQuit() {
    if (connection_.isConnected()) {
        connection_.send(MessageCodec::buildDisconnect());
        connection_.disconnect();
    }
    quit_ = true;
    std::cout << "\nGoodbye!\n";
}

// ═════════════════════════════════════════════
//  Server message handling
// ═════════════════════════════════════════════

void Controller::handleServerMessage(const std::string& jsonLine) {
    std::lock_guard<std::mutex> lock(mutex_);
    ModelEventData data = MessageCodec::parse(jsonLine);
    dispatchServerEvent(data);
}

void Controller::dispatchServerEvent(const ModelEventData& data) {
    switch (data.event) {
        case ModelEvent::NEW_USER:
            model_.addUser(data.username);
            view_.showNewUser(data.username);
            break;

        case ModelEvent::USER_DISCONNECTED:
            model_.removeUser(data.username);
            view_.showUserDisconnected(data.username);
            break;

        case ModelEvent::STATUS_CHANGED:
            model_.updateUserStatus(data.username, data.status);
            view_.showUserStatusChanged(data.username, Model::statusToString(data.status));
            break;

        case ModelEvent::USER_LIST_UPDATED:
            model_.setUserList(data.users);
            view_.showUserList(data.users);
            break;

        case ModelEvent::TEXT_RECEIVED:
            view_.showPrivateMessage(data.username, data.text);
            break;

        case ModelEvent::PUBLIC_TEXT_RECEIVED:
            view_.showPublicMessage(data.username, data.text);
            break;

        case ModelEvent::INVITED_TO_ROOM:
            model_.addInvitation(data.roomname);
            view_.showInvitation(data.username, data.roomname);
            break;

        case ModelEvent::USER_JOINED_ROOM:
            if (model_.isInRoom(data.roomname))
                model_.userJoinedRoom(data.roomname, data.username);
            view_.showUserJoinedRoom(data.roomname, data.username);
            break;

        case ModelEvent::ROOM_USER_LIST_UPDATED:
            model_.setRoomUserList(data.roomname, data.users);
            view_.showRoomUserList(data.roomname, data.users);
            break;

        case ModelEvent::ROOM_TEXT_RECEIVED:
            view_.showRoomMessage(data.roomname, data.username, data.text);
            break;

        case ModelEvent::USER_LEFT_ROOM:
            if (model_.isInRoom(data.roomname))
                model_.userLeftRoom(data.roomname, data.username);
            if (data.username != model_.getUsername())
                view_.showUserLeftRoom(data.roomname, data.username);
            break;

        case ModelEvent::SUCCESS_RESPONSE:
        case ModelEvent::ERROR_RESPONSE: {
            const std::string& op  = data.operation;
            const std::string& res = data.result;

            if (op == "IDENTIFY") {
                if (res == "SUCCESS") {
                    model_.setConnectionState(ConnectionState::IDENTIFIED);
                    model_.setUsername(data.extra);
                    model_.addUser(data.extra, UserStatus::ACTIVE);
                    view_.showIdentified(data.extra);
                } else {
                    view_.showIdentifyFailed(data.extra);
                }
            } else if (op == "NEW_ROOM") {
                if (res == "SUCCESS") {
                    model_.addRoom(data.extra);
                    model_.joinRoom(data.extra);
                    view_.showRoomCreated(data.extra);
                } else {
                    view_.showRoomCreateFailed(data.extra, res);
                }
            } else if (op == "INVITE") {
                if (res != "SUCCESS")
                    view_.showInviteFailed(data.extra, res, data.extra);
            } else if (op == "JOIN_ROOM") {
                if (res == "SUCCESS") {
                    model_.joinRoom(data.extra);
                    view_.showJoinedRoom(data.extra);
                } else {
                    view_.showJoinFailed(data.extra, res);
                }
            } else if (op == "ROOM_USERS") {
                if (res != "SUCCESS")
                    view_.showError("ROOM_USERS failed: " + res);
            } else if (op == "ROOM_TEXT") {
                if (res != "SUCCESS")
                    view_.showError("ROOM_TEXT failed: " + res);
            } else if (op == "LEAVE_ROOM") {
                if (res == "SUCCESS") {
                    model_.leaveRoom(data.extra);
                    view_.showLeftRoom(data.extra);
                } else {
                    view_.showLeaveRoomFailed(data.extra, res);
                }
            } else if (op == "TEXT") {
                if (res == "NO_SUCH_USER")
                    view_.showPrivateSentError(data.extra);
            } else if (op == "INVALID") {
                view_.showError("Server rejected message: " + res);
                model_.setConnectionState(ConnectionState::DISCONNECTED);
            } else {
                if (res != "SUCCESS")
                    view_.showError("Server error [" + op + "]: " + res);
            }
            break;
        }

        default:
            view_.showError("Unhandled server event.");
            break;
    }
}

// ═════════════════════════════════════════════
//  Helpers
// ═════════════════════════════════════════════

bool Controller::requireArgs(Lexer& lx, std::vector<std::string>& out, int n, const std::string& usage) {
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
        view_.showNotIdentified();
        return false;
    }
    return true;
}

bool Controller::requireConnected() {
    if (!connection_.isConnected()) {
        view_.showError("Not connected. Use /connect <host> <port> first.");
        return false;
    }
    return true;
}
