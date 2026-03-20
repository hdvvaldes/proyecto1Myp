#pragma once 

#include <functional>
#include <string>
#include <thread>

/*
 * Connection
 *
 * Thin TCP socket wrapper that:
 *   - connects to host:port
 *   - sends newline-terminated JSON messages
 *   - receives messages in a background thread and invokes a callback
 */
class Connection {
public:
    using MessageCallback = std::function<void(
        const std::string& jsonLine)>;
    using ErrorCallback = std::function<void(
        const std::string& reason)>;

    Connection();
    ~Connection();

    bool connect(const std::string& host, int port);
    void disconnect();

    // Send a JSON string followed by '\n'
    bool send(const std::string& json);

    bool isConnected() const {
      return fd_ >= 0;
    }

    void setMessageCallback(MessageCallback cb) { 
      onMessage_ = std::move(cb); 
    }
    void setErrorCallback(ErrorCallback cb) { 
      onError_   = std::move(cb); 
    }

private:
    void recvLoop();
    
    /* socket */
    int fd_ = -1;
    std::thread recvThread_;
    bool running_ = false;

    MessageCallback  onMessage_;
    ErrorCallback    onError_;

};
