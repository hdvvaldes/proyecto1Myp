#pragma once

enum class Token {
  // -- Commands (no argument) ----
  CMD_HELP,
  CMD_QUIT,
  CMD_DISCONNECT,
  CMD_USERS,
  // -- Commands (with arguments) -------------
  CMD_CONNECT,    // <host> <port>
  CMD_IDENTIFY,   // <username>
  CMD_STATUS,     // <ACTIVE|AWAY|BUSY>
  CMD_MSG,        // <username> <text…>
  CMD_PUB,        // <text…>
  CMD_NEWROOM,    // <roomname>
  CMD_INVITE,     // <roomname> <user1> [user2 …]
  CMD_JOIN,       // <roomname>
  CMD_ROOMUSERS,  // <roomname>
  CMD_ROOMTEXT,   // <roomname> <text…>
  CMD_LEAVE,      // <roomname>

  // -- Data tokens ---------------------------
  ARG,            // one space-delimited word
  TEXT_BODY,      // rest-of-line free text
  RAW_TEXT,       // line did not start with '/'

  // -- Control -------------------------------
  UNKNOWN_CMD,
  END_OF_LINE,
  END_OF_INPUT,
  NONE
};
