#pragma once

#include <functional>
#include <string>
#include <map>
#include <set>

enum class UserStatus {
  ACTIVE,
  AWAY,
  BUSY
};

enum class ConnectionState {
    DISCONNECTED,
    CONNECTED,       // TCP connected, not yet identified
    IDENTIFIED       // Identified with a username
};

struct RoomInfo {
    std::string roomname;
    // username → status
    std::map<std::string, UserStatus> users;  
};

class Model {
public:
  // TODO Replace **const Model** for the correct data type
  // TODO Investigate how to use callback
  using EventCallback = std::function<void(const Model)>;
  Model();

  // -- State Modifiers -----
  void setConnectionState(ConnectionState state);
  void setUsername(const std::string& username);
  void setUserStatus(UserStatus status);

  // Users
  void addUser(const std::string& username, UserStatus status = UserStatus::ACTIVE);
  void removeUser(const std::string& username);
  void updateUserStatus(const std::string& username, UserStatus status);
  void setUserList(const std::map<std::string, UserStatus>& users);

  // Rooms
  void addRoom(const std::string& roomname);
  void removeRoom(const std::string& roomname);
  void addInvitation(const std::string& roomname);
  void joinRoom(const std::string& roomname);
  void leaveRoom(const std::string& roomname);
  void setRoomUserList(const std::string& roomname,
      const std::map<std::string, UserStatus>& users);
  void userJoinedRoom(const std::string& roomname, const std::string& username);
  void userLeftRoom(const std::string& roomname, const std::string& username);

  // -- Getters ---------
  // Const bc model is not being modified
  ConnectionState getConnectionState() const 
    { return connectionState_; }

  const std::string& getUsername() const 
    { return username_; }

  UserStatus getMyStatus() const 
    { return myStatus_; }

  const std::map<std::string, UserStatus>& getUsers() const
    { return users_; }

  const std::map<std::string, RoomInfo>& getRooms() const
    { return rooms_; }

  bool isIdentified() const 
    { return connectionState_ == ConnectionState::IDENTIFIED; }

  bool isInRoom(const std::string& roomname) const;
  bool isInvitedToRoom(const std::string& roomname) const;
private:
  ConnectionState connectionState_ = ConnectionState::DISCONNECTED;
  std::string username_;
  UserStatus myStatus_ = UserStatus::ACTIVE;
   // All online users
  std::map<std::string, UserStatus> users_;
  // Rooms we have joined
  std::map<std::string, RoomInfo> rooms_; 
  // TODO Overkill set?
  // Pending invitations
  std::set<std::string> invitations_; 
};

