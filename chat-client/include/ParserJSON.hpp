#pragma once

#include "Model.hpp"

class MessageCodec {
public:
    static std::string buildIdentify(
        const std::string& username);
    static std::string buildStatus(
        const std::string& status);
    static std::string buildUsers();
    static std::string buildText(
        const std::string& username, 
        const std::string& text);
    static std::string buildPublicText(
        const std::string& text);
    static std::string buildNewRoom(
        const std::string& roomname);
    static std::string buildInvite(
        const std::string& roomname, 
        const std::vector<std::string>& usernames);
    static std::string buildJoinRoom(
        const std::string& roomname);
    static std::string buildRoomUsers(
        const std::string& roomname);
    static std::string buildRoomText(
        const std::string& roomname, 
        const std::string& text);
    static std::string buildLeaveRoom(
        const std::string& roomname);
    static std::string buildDisconnect();

  // Parse a JSON line and return a 
  // populated ModelEventData.
  // Returns an event == 
  // ModelEvent::ERROR_RESPONSE with 
  // result == "PARSE_ERROR"
  // if the line cannot be decoded.
  static ModelEventData parse(const std::string& jsonLine);

private: 



};
