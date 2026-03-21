#include "Model.hpp"
#include <algorithm>

Model::Model() = default;

//---------------------------
// -- State setters ----------
//---------------------------

void Model::setConnectionState(ConnectionState state) {
    connectionState_ = state;
}

void Model::setUsername(const std::string& username) {
    username_ = username;
}

void Model::setUserStatus(UserStatus status) {
    myStatus_ = status;
    auto it = users_.find(username_);
    if (it != users_.end())
        it->second = status;
}

//---------------------------
// Users
//---------------------------

void Model::addUser(const std::string& username, UserStatus status) {
    users_[username] = status;
}

void Model::removeUser(const std::string& username) {
    users_.erase(username);
    // Also remove from all rooms
    for (auto& [rname, rinfo] : rooms_)
        rinfo.users.erase(username);
}

void Model::updateUserStatus(const std::string& username, UserStatus status) {
    users_[username] = status;
    // Propagate to rooms
    for (auto& [rname, rinfo] : rooms_) {
        auto it = rinfo.users.find(username);
        if (it != rinfo.users.end())
            it->second = status;
    }
}

void Model::setUserList(const std::map<std::string, UserStatus>& users) {
    users_ = users;
}

// ----------------
// Rooms
// ----------------

void Model::addRoom(const std::string& roomname) {
    rooms_[roomname] = RoomInfo{ roomname, {} };
}

void Model::removeRoom(const std::string& roomname) {
    rooms_.erase(roomname);
    invitations_.erase(roomname);
}

void Model::addInvitation(const std::string& roomname) {
    invitations_.insert(roomname);
}

void Model::joinRoom(const std::string& roomname) {
    invitations_.erase(roomname);
    if (rooms_.find(roomname) == rooms_.end())
        rooms_[roomname] = RoomInfo{ roomname, {} };
    rooms_[roomname].users[username_] = myStatus_;
}

void Model::leaveRoom(const std::string& roomname) {
    rooms_.erase(roomname);
    invitations_.erase(roomname);
}

void Model::setRoomUserList(const std::string& roomname,
                             const std::map<std::string, UserStatus>& users) {
    rooms_[roomname].users = users;
}

void Model::userJoinedRoom(const std::string& roomname, const std::string& username) {
    auto status = UserStatus::ACTIVE;
    auto it = users_.find(username);
    if (it != users_.end()) status = it->second;
    rooms_[roomname].users[username] = status;
}

void Model::userLeftRoom(const std::string& roomname, const std::string& username) {
    auto rit = rooms_.find(roomname);
    if (rit != rooms_.end())
        rit->second.users.erase(username);
}


// -- Queries ------------

bool Model::isInRoom(const std::string& roomname) const {
    return rooms_.find(roomname) != rooms_.end();
}

bool Model::isInvitedToRoom(const std::string& roomname) const {
    return invitations_.find(roomname) != invitations_.end();
}

// -------------------------------------
// -- Utility  -----------------------
// -------------------------------------

std::string Model::statusToString(UserStatus status) {
    switch (status) {
        case UserStatus::ACTIVE:  return "ACTIVE";
        case UserStatus::AWAY:    return "AWAY";
        case UserStatus::BUSY:    return "BUSY";
        default:                  return "UNKNOWN";
    }
}

UserStatus Model::statusFromString(const std::string& s) {
    if (s == "ACTIVE") return UserStatus::ACTIVE;
    if (s == "AWAY")   return UserStatus::AWAY;
    if (s == "BUSY")   return UserStatus::BUSY;
    return UserStatus::UNKNOWN;
}
