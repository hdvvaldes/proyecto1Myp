#include "Connection.hpp"
#include <netdb.h>
#include <sys/socket.h>
#include <unistd.h>

Connection::Connection() = default;

Connection::~Connection() {
    disconnect();
}

bool Connection::connect(const std::string& host, int port){
  if (fd_ >= 0) disconnect();

  struct addrinfo hints{}, *res = nullptr;
  hints.ai_family   = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;

  std::string portStr = std::to_string(port);
  int err = 
    ::getaddrinfo(host.c_str(), portStr.c_str(), &hints, &res);
  if (err != 0) {
    if (onError_) 
      onError_(std::string("getaddrinfo: ") + 
          gai_strerror(err));
    return false;
  }
  int sock = -1;
  for (auto* p = res; p != nullptr; p = p->ai_next) {
    sock = 
      ::socket(p->ai_family, p->ai_socktype, p->ai_protocol);
    if (sock < 0) continue;
    if (::connect(sock, p->ai_addr, p->ai_addrlen) == 0) 
      break;
    ::close(sock);
    sock = -1;
  }
  ::freeaddrinfo(res);

  if (sock < 0) {
    if (onError_) onError_("Could not connect to " + host + ":" + portStr);
    return false;
  }

  fd_ = sock;
  running_ = true;
  recvThread_ = std::thread(&Connection::recvLoop, this);
  return true;
}

void Connection::disconnect() {
  running_ = false;
  if (fd_ >= 0) {
    ::shutdown(fd_, SHUT_RDWR);
    ::close(fd_);
    fd_ = -1;
  }
  if (recvThread_.joinable())
    recvThread_.join();
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



