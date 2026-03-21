# Chat System Project

A TCP-based chat system consisting of a Haskell server and a C++ client, communicating via a JSON protocol.

## Project Structure

- `server/`: Haskell chat server implementation.
  - `serverChat/`: Main server codebase.
- `chat-client/`: C++ chat client implementation.
  - `src/`: Source files.
  - `include/`: Header files.
  - `lexer/`: Flex++ lexer definition.
- `Dockerfile`: Unified Docker configuration to run both components.
- `run_all.sh`: Helper script for Docker.

## Getting Started

### Prerequisites

- **Server**: GHC and Cabal.
- **Client**: G++ (supporting C++17), Make, and Flex++.

---

### Manual Setup

#### 1. Build and Run the Server

```bash
cd server
cabal update
cabal run
```

#### 2. Build and Run the Client

```bash
cd chat-client
make
./chat-client
```

Once the client starts, use the following commands:
- `/connect 127.0.0.1 8080` to connect to the server.
- `/identify <username>` to log in.
- `/help` to see all available commands.

---

### Docker Setup

```bash
# Build the image
docker build -t chat-system .

# Run the system (interactive mode is required for the client)
docker run -it chat-system
```

---

## Testing

### Haskell Server Smoke Tests
```bash
cd server
cabal exec runghc -- -iserverChat/src -iserverChat/app serverChat/app/ProtocolSmoke.hs
```
## Protocol Overview

The system uses a JSON protocol over TCP. Key features include:
- **Identification**: Users must identify with a unique name.
- **Messaging**: Private and public (broadcast) messaging.
- **Rooms**: Creation, invitation, and joining of chat rooms.
- **Status**: Custom user statuses (ACTIVE, AWAY, BUSY).
