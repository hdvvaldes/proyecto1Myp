# serverdd — File Relations (Haskell)

> A Haskell TCP server for a chat.

## Project Layout

```
server/
├── server.cabal          ← Build config, declares modules & dependencies
├── server/
│   ├── app/
│   │   └── Main.hs         ← Entry point
│   └── src/
│       └── Server/
│           ├── App.hs      ← Core application logic & server lifecycle
│           ├── ConnectionHandler.hs  ← Per-connection I/O and request handling
│           ├── ServerState.hs ← Global server state and STM actions
│           ├── ServerTypes.hs ← Shared data types (Client, Room, etc.)
│           └── Parser/
│               ├── Interface.hs   ← Request parsing entry point
│               └── ParserTypes.hs ← Request and Response types
```

## File Dependency Graph

```mermaid
graph TD
    CABAL["server.cabal"]
    MAIN["app/Main.hs"]
    APP["src/Server/App.hs"]
    CONN["src/Server/ConnectionHandler.hs"]
    STATE["src/Server/ServerState.hs"]
    TYPES["src/Server/ServerTypes.hs"]
    PARSER["src/Server/Parser/Interface.hs"]

    CABAL -->|"declares modules"| APP
    CABAL -->|"declares modules"| CONN
    CABAL -->|"declares modules"| STATE
    
    MAIN -->|"import Server.App"| APP
    APP  -->|"import Server.ConnectionHandler"| CONN
    APP  -->|"import Server.ServerState"| STATE
    CONN -->|"import Server.ServerState"| STATE
    CONN -->|"import Server.Parser.Interface"| PARSER
    STATE -->|"import Server.ServerTypes"| TYPES
    CONN -->|"import Server.ServerTypes"| TYPES
```

## File-by-File Breakdown

### `server.cabal`

| Role | Build manifest |
|------|---------------|
| **Declares** | `Main.hs` (entry), `Server.App`, `Server.ConnectionHandler`, `Server.ServerState`, `Server.ServerTypes` |
| **Dependencies** | `base`, `network`, `stm`, `transformers`, `text`, `bytestring`, `containers` |

---

### `src/Server/App.hs`

| Role | Server lifecycle and accept loop |
|------|---------------------------------------------|
| **Module** | `Server.App` |
| **Exports** | `runServer`, `defaultSocket` |
| **Key functions:** | `runServer` (setup socket, bind, listen), `acceptLoop` (forks `runConn`) |

---

### `src/Server/ConnectionHandler.hs`

| Role | Handles a single client connection with dual-thread I/O |
|------|------------------------------------|
| **Module** | `Server.ConnectionHandler` |
| **Concurrency Model:** | **Reader Thread (`connLoop`)**: Reads input, parses requests, and executes actions. |
|                       | **Writer Thread (`deliveryLoop`)**: Waits for messages in `TChan` and writes to `Handle`. |
| **Key functions:** | `runConn` (init), `handshake` (ID creation), `handleRequest` (dispatch), `broadcast` |

---

### `src/Server/ServerState.hs`

| Role | Global state management using STM |
|------|----------------------------------|
| **Module** | `Server.ServerState` |
| **Key functions:** | `newServerState`, `addUser`, `broadcast` (to all), `getClientCount` |

---

### `src/Server/ServerTypes.hs`

| Role | Shared server data types |
|------|--------------------------|
| **Key Types** | `Client` (name, handle, chan), `Room`, `Status` |

---

## High-Level Data Flow

```mermaid
sequenceDiagram
    participant App as Server.App
    participant Conn as ConnectionHandler
    participant State as Server.ServerState
    participant Net as Network.Socket / Handle

    App->>Conn: runConn (socket, addr)
    Conn->>Net: socketToHandle
    Conn->>State: getClientCount
    Conn->>Conn: handshake (Guest-N)
    Conn->>State: addUser
    par Writer Thread
        loop Wait for Messages
            State-->>Conn: readTChan
            Conn->>Net: hPutStrLn
        end
    and Reader Thread
        loop Handle Input
            Net-->>Conn: hGetLine
            Conn->>Conn: handleRequest
            opt Public Text
                Conn->>State: broadcast
            end
        end
    end
```
