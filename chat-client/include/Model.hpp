#pragma once

#include <functional>

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

class Model {
public:
  // TODO Replace **const Model** for the correct data type
  using EventCallback = std::function<void(const Model)>;
  Model();

private:
    ConnectionState connectionState_ = ConnectionState::DISCONNECTED;

};

