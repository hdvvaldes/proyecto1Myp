#include "Connection.hpp"
#include <sys/socket.h>

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

bool Connection::send(const std::string& json) {
  if (fd_ < 0) return false;
  std::string msg = json + "\n";
  ssize_t sent =
    ::send(fd_, msg.c_str(), msg.size(), MSG_NOSIGNAL);
  return sent == static_cast<ssize_t>(msg.size());
}

/*
 * Manages server responses
 * Running in background thread
 */
void Connection::recvLoop() {
  std::string buffer;
  char        chunk[4096];

  while (running_ && fd_ >= 0) {
    ssize_t n = 
      ::recv(fd_, chunk, sizeof(chunk) -1, 0);
    if (n <= 0) {
      // Server closed connection or error
      if (running_ && onError_)
        onError_("Server closed the connection.");
      running_ = false;
      break;
    }
    chunk[n] = '\0';
    buffer  += chunk;

    // Deliver complete newline-delimited messages
    std::size_t pos;
    while ((pos = buffer.find('\n')) != std::string::npos) {
      std::string line = buffer.substr(0, pos);
      buffer.erase(0, pos + 1);
      if (!line.empty() && onMessage_)
        onMessage_(line);
    }
  }
}



