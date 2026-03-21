# Chat Client

A modular C++ terminal chat client that implements the JSON-over-TCP chat
protocol.

## Future Architecture

```
┌──────────────────────────────────────────────────────────┐
│                        main.cpp                          │
│                    (entry point)                         │
└───────────────────────────┬──────────────────────────────┘
                            │ owns
                            ▼
┌──────────────────────────────────────────────────────────┐
│                      Controller                          │
│                   (orchestrator)                         │
│                                                          │
│  ┌─────────────┐  ┌────────────┐  ┌──────────────────┐  │
│  │    Lexer    │  │   Model    │  │       View        │  │
│  │  (flex++)   │  │  (state)   │  │  (terminal UI)    │  │
│  └─────────────┘  └────────────┘  └──────────────────┘  │
│                                                          │
│  ┌──────────────────┐   ┌─────────────────────────────┐  │
│  │   Connection     │   │      MessageCodec            │  │
│  │  (TCP socket)    │   │  (JSON encode / decode)      │  │
│  └──────────────────┘   └─────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

### Layer responsibilities

| Component | Responsibility |
|-----------|---------------|
| **Model** | Holds all client-side state: connection status, our username, online users, joined rooms, pending invitations. Emits typed events via a callback. |
| **View** | Owns *all* terminal output. Accepts high-level method calls (`showPrivateMessage`, `showRoomCreated`, …) and formats them with ANSI colours. Never reads state directly. |
| **Controller** | The orchestrator. Reads stdin, drives the Lexer, calls MessageCodec to build JSON, sends it via Connection, receives server events and updates Model + View. |
| **Lexer** | flex++-generated (or hand-written fallback) scanner. Tokenises user input into a stream of `Token` values: command keywords, arguments, and free-form text bodies. |
| **Connection** | Thin POSIX TCP wrapper. Sends newline-terminated messages and delivers complete incoming lines to a callback on a background thread. |
| **MessageCodec** | Stateless utility. Builds outbound JSON strings and parses inbound ones into `ModelEventData` structs. No external JSON library required. |

## Lexer

The following are conditions to move the lexer between states and identify what type of argumnt to be expected after a command.

| Condition | Purpose |
|-----------|---------|
| `INITIAL` | Dispatches `/command` keywords or flags unknown input |
| `SC_ARGS` | Tokenises space-delimited word arguments |
| `SC_TEXT` | Captures everything to end-of-line as a single `TEXT_BODY` token |

## Commands

| Command | Description |
|---------|-------------|
| `/connect <host> <port>` | Connect to server |
| `/identify <username>` | Log in (max 8 chars) |
| `/status <ACTIVE\|AWAY\|BUSY>` | Change status |
| `/users` | List online users |
| `/msg <username> <text>` | Private message |
| `/pub <text>` | Public message |
| `/newroom <name>` | Create room (max 16 chars) |
| `/invite <room> <u1> [u2…]` | Invite users to room |
| `/join <room>` | Join an invited room |
| `/roomusers <room>` | List room members |
| `/roomtext <room> <text>` | Send message to room |
| `/leave <room>` | Leave a room |
| `/disconnect` | Disconnect from server |
| `/quit` | Exit the client |
