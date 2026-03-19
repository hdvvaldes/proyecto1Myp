#pragma once 

/*
 * Connection
 *
 * Thin TCP socket wrapper that:
 *   - connects to host:port
 *   - sends newline-terminated JSON messages
 *   - receives messages in a background thread and invokes a callback
 *   - is NOT thread-safe for send() calls (caller must serialise if needed)
 */
class Connection {
public:
    Connection();
    ~Connection();
};
