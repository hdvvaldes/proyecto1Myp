#include "Connection.hpp"

Connection::Connection() = default;

Connection::~Connection() {
    disconnect();
}

bool Connection::connect(const std::string& host, int port){
  return true;
}

void Connection::disconnect() {
    running_ = false;
}

bool Connection::send(const std::string& json){
  return true;
}

bool Connection::isConnected(){
  return running_;
}

