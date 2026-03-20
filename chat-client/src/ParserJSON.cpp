#include "ParserJSON.hpp"
#include "json.hpp"

using json = nlohmann::json;

std::string MessageCodec::buildIdentify(const std::string& username) {
  json j;
  j["type"] = "IDENTIFY";
  j["username"] = username;
  return j.dump();
}

std::string MessageCodec::buildStatus(const std::string& status) {
  json j;

  j["type"] = "STATUS";
  j["status"] = status;
  return j.dump();
}

std::string MessageCodec::buildUsers() {
  json j;
  j["type"] = "USERS";
  return j.dump();
}

std::string MessageCodec::buildText(const std::string& username, const std::string& text) {
  json j;
  j["type"] = "MESSAGE";
  j["username"] = username;
  j["text"] = text;
  return j.dump();
}

std::string MessageCodec::buildPublicText(const std::string& text) {
  json j;
  j["type"] = "PUBLIC_MESSAGE";
  j["text"] = text;
  return j.dump();
}

std::string MessageCodec::buildNewRoom(const std::string& roomname) {
  json j;
  j["type"] = "NEW_ROOM";
  j["roomname"] = roomname;
  return j.dump();
}

std::string MessageCodec::buildInvite(const std::string& roomname, const std::vector<std::string>& usernames) {
  json j;
  j["type"] = "INVITE";
  j["roomname"] = roomname;
  j["usernames"] = usernames;
  return j.dump();
}

std::string MessageCodec::buildJoinRoom(const std::string& roomname) {
  json j;
  j["type"] = "JOIN_ROOM";
  j["roomname"] = roomname;
  return j.dump();
}

std::string MessageCodec::buildRoomUsers(const std::string& roomname) {
  json j;
  j["type"] = "ROOM_USERS";
  j["roomname"] = roomname;
  return j.dump();
}

std::string MessageCodec::buildRoomText(const std::string& roomname, const std::string& text) {
  json j;
  j["type"] = "ROOM_MESSAGE";
  j["roomname"] = roomname;
  j["text"] = text;
  return j.dump();
}

std::string MessageCodec::buildLeaveRoom(const std::string& roomname) {
  json j;
  j["type"] = "LEAVE_ROOM";
  j["roomname"] = roomname;
  return j.dump();
}

std::string MessageCodec::buildDisconnect() {
  json j;
  j["type"] = "DISCONNECT";
  return j.dump();
}

ModelEventData MessageCodec::parse(const std::string& jsonLine) {
  ModelEventData data;
  try {
    auto j = json::parse(jsonLine);
    std::string type = j.value("type", "");

    if (type == "CONNECTED") 
      data.event = ModelEvent::CONNECTED;
    else if (type == "DISCONNECTED") 
      data.event = ModelEvent::DISCONNECTED;
    else if (type == "IDENTIFIED") 
      data.event = ModelEvent::IDENTIFIED;
    else if (type == "NEW_USER") 
      data.event = ModelEvent::NEW_USER;
    else if (type == "USER_DISCONNECTED") 
      data.event = ModelEvent::USER_DISCONNECTED;
    else if (type == "STATUS_CHANGED") 
      data.event = ModelEvent::STATUS_CHANGED;
    else if (type == "USER_LIST_UPDATED") 
      data.event = ModelEvent::USER_LIST_UPDATED;
    else if (type == "TEXT_RECEIVED") 
      data.event = ModelEvent::TEXT_RECEIVED;
    else if (type == "PUBLIC_TEXT_RECEIVED") 
      data.event = ModelEvent::PUBLIC_TEXT_RECEIVED;
    else if (type == "ROOM_CREATED") 
      data.event = ModelEvent::ROOM_CREATED;
    else if (type == "INVITED_TO_ROOM") 
      data.event = ModelEvent::INVITED_TO_ROOM;
    else if (type == "JOINED_ROOM") 
      data.event = ModelEvent::JOINED_ROOM;
    else if (type == "USER_JOINED_ROOM") 
      data.event = ModelEvent::USER_JOINED_ROOM;
    else if (type == "USER_LEFT_ROOM") 
      data.event = ModelEvent::USER_LEFT_ROOM;
    else if (type == "ROOM_USER_LIST_UPDATED") 
      data.event = ModelEvent::ROOM_USER_LIST_UPDATED;
    else if (type == "ROOM_TEXT_RECEIVED") 
      data.event = ModelEvent::ROOM_TEXT_RECEIVED;
    else if (type == "LEFT_ROOM") 
      data.event = ModelEvent::LEFT_ROOM;
    else if (type == "SUCCESS") 
      data.event = ModelEvent::SUCCESS_RESPONSE;
    else if (type == "ERROR") 
      data.event = ModelEvent::ERROR_RESPONSE;
    else {
      data.event = ModelEvent::ERROR_RESPONSE;
      data.result = "UNKNOWN_TYPE";
      return data;
    }

    // Fill common fields
    data.username = j.value("username", "");
    data.roomname = j.value("roomname", "");
    data.text     = j.value("text", "");
    data.operation = j.value("operation", "");
    data.result   = j.value("result", "");
    data.extra    = j.value("extra", "");

    if (j.contains("status")) {
      data.status = Model::statusFromString(j["status"]);
    }

    if (j.contains("users") && j["users"].is_object()) {
      for (auto& [name, statusStr] : j["users"].items()) {
        data.users[name] = Model::statusFromString(statusStr);
      }
    }

  } catch (const std::exception& e) {
    data.event = ModelEvent::ERROR_RESPONSE;
    data.result = "PARSE_ERROR";
    data.extra = e.what();
  }
  return data;
}
