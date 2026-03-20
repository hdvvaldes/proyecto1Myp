#pragma once 

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
    // TODO investigate callback hehe
    // TODO investigate socket
    Connection();
    ~Connection();
    bool connect(const std::string& host, int port);
    void disconnect();

    // Send a JSON string followed by '\n'
    bool send(const std::string& json);

    bool isConnected();

private:
    void recvLoop();
    std::thread recvThread_;
    bool running_ = false;

};
