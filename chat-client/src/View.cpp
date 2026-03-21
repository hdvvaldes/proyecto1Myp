#include "View.hpp"
#include <iomanip>
#include <iostream>

// --- Constructor ----
View::View() = default;

// -- Line Flush ---
void View::clearCurrentLine() {
    std::cout << "\r\033[K";
}

void View::printLine(const std::string& prefix, const std::string& colorCode, const std::string& message) {
    clearCurrentLine();
    std::cout << colorCode << prefix << Color::RESET << " " << message << "\n";
    showPrompt();
}

std::string View::statusBadge(UserStatus status) {
    switch (status) {
        case UserStatus::ACTIVE:  
          return std::string(Color::BRIGHT_GREEN) + 
            "●" + Color::RESET;
        case UserStatus::AWAY:    
          return std::string(Color::BRIGHT_YELLOW) + 
            "●" + Color::RESET;
        case UserStatus::BUSY:    
          return std::string(Color::BRIGHT_RED)    + 
            "●" + Color::RESET;
        default:                  
          return std::string(Color::DIM)           + 
            "●" + Color::RESET;
    }
}

std::string View::statusBadge(const std::string& status) {
    return statusBadge(Model::statusFromString(status));
}

// ------------------------
// --- Lifecycle ----------
// ------------------------

void View::showWelcome() {
    std::cout << "\n";
    std::cout << Color::BRIGHT_CYAN << Color::BOLD;
    std::cout << "  ╔═══════════════════════════════════════╗\n";
    std::cout << "  ║          C H A T  C L I E N T         ║\n";
    std::cout << "  ╚═══════════════════════════════════════╝\n";
    std::cout << Color::RESET << "\n";
    std::cout << Color::DIM << "  Type " << Color::RESET
              << Color::BRIGHT_WHITE << "/help" << Color::RESET
              << Color::DIM << " for a list of commands.\n\n" << Color::RESET;
}

void View::showHelp() {
    clearCurrentLine();
    std::cout << "\n";
    std::cout << Color::BOLD << Color::BRIGHT_WHITE
              << "  ─── Commands ───────────────────────────────────\n"
              << Color::RESET;
  /* Format Row */
  auto row = 
    [](const std::string& cmd, const std::string& desc) {
      std::cout << "  " 
        << Color::BRIGHT_CYAN 
        << std::left << std::setw(32) << cmd 
        << Color::RESET 
        << Color::DIM 
        << desc 
        << Color::RESET << "\n";
    };
  std::cout << "\n  " 
    << Color::YELLOW 
    << "Connection\n" << Color::RESET;

  row("/connect <host> <port>",    
      "Connect to a chat server");
  row("/identify <username>",
      "Identify yourself (max 8 chars)");
  row("/disconnect",
      "Disconnect from the server");
  row("/quit",
      "Exit the client");

  std::cout << "\n  " 
    << Color::YELLOW 
    << "Users\n" << Color::RESET;

  row("/status <ACTIVE|AWAY|BUSY>",
      "Change your status");
  row("/users",
      "List all online users");
  row("/msg <username> <text>",
      "Send a private message");
  row("/pub <text>",
      "Send a public message to everyone");

    std::cout << "\n  " << Color::YELLOW << "Rooms\n" << Color::RESET;
  row("/newroom <roomname>",
      "Create a new room (max 16 chars)");
  row("/invite <room> <u1> [u2]…",
      "Invite users to a room");
  row("/join <roomname>",
      "Join a room you were invited to");
  row("/roomusers <roomname>",
      "List users in a room");
  row("/roomtext <room> <text>",
      "Send a message to a room");
  row("/leave <roomname>",
      "Leave a room");
  std::cout << "\n  " << Color::YELLOW << 
    "Other\n" << Color::RESET;
  row("/help",
    "Show this help");
    std::cout << "\n";
    showPrompt();
}

void View::showPrompt() {
  std::cout <<
    Color::BRIGHT_BLUE << "> " << Color::RESET <<
    std::flush;
}

//--------------------------------------------------
// --- Connection -------------------------
// --------------------------------------------------

void View::showConnected(const std::string& host, int port) {
    clearCurrentLine();
  std::cout << Color::BRIGHT_GREEN 
    << "✔ Connected" << Color::RESET 
    << " to " 
    << Color::BRIGHT_WHITE 
    << host << ":" << port << Color::RESET 
    << "  (use " 
    << Color::BRIGHT_WHITE 
    << "/identify <name>" << Color::RESET 
    << " to log in)\n";
    showPrompt();
}

void View::showDisconnected() {
    clearCurrentLine();
  std::cout << Color::BRIGHT_YELLOW << 
    "⚡ Disconnected from server.\n" << Color::RESET;
    showPrompt();
}

void View::showConnectionError(const std::string& reason) {
    clearCurrentLine();
  std::cout 
    << Color::BRIGHT_RED 
    << "✖ Connection error: " 
    << Color::RESET << reason << "\n";
    showPrompt();
}

// ----------------------------
// --- Indetify --------------
// ----------------------------

void View::showIdentified(const std::string& username) {
    clearCurrentLine();
  std::cout << Color::BRIGHT_GREEN << 
    "✔ Identified as " << Color::RESET << 
    Color::BOLD << username << Color::RESET << "\n";
    showPrompt();
}

void View::showIdentifyFailed(const std::string& username) {
    clearCurrentLine();
  std::cout << Color::BRIGHT_RED << 
    "✖ Username '" << username << 
    "' is already taken.\n" << Color::RESET;
    showPrompt();
}

void View::showStatusChanged(const std::string& status) {
    clearCurrentLine();
  std::cout << statusBadge(status) << 
    " Your status is now " << Color::BOLD << 
    status << Color::RESET << "\n";
    showPrompt();
}

void View::showNotIdentified() {
    clearCurrentLine();
    std::cout << Color::BRIGHT_RED << "✖ You must identify yourself first using /identify <username>\n"
              << Color::RESET;
    showPrompt();
}

/* --------------------------------
 * ---- Presenting Users
 * --------------------------------
 */

void View::showNewUser(const std::string& username) {
    printLine("→", Color::GREEN, Color::BOLD + std::string(username) + Color::RESET + " joined the chat.");
}

void View::showUserDisconnected(const std::string& username) {
    printLine("←", Color::YELLOW, Color::BOLD + std::string(username) + Color::RESET + " left the chat.");
}

void View::showUserStatusChanged(const std::string& username, const std::string& status) {
    clearCurrentLine();
    std::cout << statusBadge(status) << " " << Color::BOLD << username << Color::RESET
              << " is now " << Color::BOLD << status << Color::RESET << "\n";
    showPrompt();
}

void View::showUserList(const std::map<std::string, 
    UserStatus>& users) {
    clearCurrentLine();
    std::cout << "\n  " 
      << Color::BOLD << Color::BRIGHT_WHITE 
      << "Online users (" << users.size() << ")\n" 
              << Color::RESET;
    showPrompt();
}

void View::showRoomUserList(const std::string& roomname,
    const std::map<std::string, UserStatus>& users) {
    clearCurrentLine();
    std::cout << "\n  " 
      << Color::BOLD << Color::BRIGHT_WHITE 
      << "Users in " << Color::BRIGHT_CYAN 
      << "#" << roomname << Color::BRIGHT_WHITE 
      << " (" << users.size() << ")\n" << Color::RESET;
    for (auto& [name, status] : users) {
        std::cout << "    " << statusBadge(status) << "  "
                  << std::left << std::setw(12) << name
                  << Color::DIM << Model::statusToString(status) << Color::RESET << "\n";
    }
    std::cout << "\n";
    showPrompt();
}

/* --------------------------------
 * ---- Messages ---------
 * --------------------------------
 */


void View::showPrivateMessage(const std::string& from, const std::string& text) {
    clearCurrentLine();
    std::cout << Color::BRIGHT_MAGENTA << "(private) " 
              << Color::BOLD << from << Color::RESET 
              << ": " << text << "\n";
    showPrompt();
}

void View::showPrivateSentError(const std::string& toUser) {
    clearCurrentLine();
    std::cout << Color::BRIGHT_RED << "✖ User '" << toUser << "' does not exist.\n"
              << Color::RESET;
    showPrompt();
}

void View::showPublicMessage(const std::string& from, 
    const std::string& text) {
    clearCurrentLine();
  std::cout 
    << Color::BRIGHT_WHITE << Color::BOLD 
    << from << Color::RESET 
    << Color::WHITE 
    << " (public): " << Color::RESET 
              << text << "\n";
    showPrompt();
}

void View::showRoomMessage(const std::string& roomname, const std::string& from, const std::string& text) {
    clearCurrentLine();
    std::cout << Color::BRIGHT_CYAN << "#" << roomname << " " << Color::RESET
              << Color::BRIGHT_WHITE << Color::BOLD << from << Color::RESET
              << ": " << text << "\n";
    showPrompt();
}

void View::showRoomCreated(const std::string& roomname) {
    clearCurrentLine();
    std::cout << Color::BRIGHT_GREEN << "✔ Room created: " << Color::RESET
              << Color::BRIGHT_CYAN << "#" << roomname << Color::RESET << "\n";
    showPrompt();
}

void View::showRoomCreateFailed(const std::string& roomname, const std::string& /*reason*/) {
    clearCurrentLine();
    std::cout << Color::BRIGHT_RED << "✖ Room '" << roomname << "' already exists.\n"
              << Color::RESET;
    showPrompt();
}

void View::showInvitation(const std::string& from, const std::string& roomname) {
    clearCurrentLine();
    std::cout << Color::BRIGHT_YELLOW << "✉ " << Color::BOLD << from << Color::RESET
              << Color::YELLOW << " invited you to " << Color::RESET
              << Color::BRIGHT_CYAN << "#" << roomname << Color::RESET
              << Color::DIM << "  (use /join " << roomname << ")" << Color::RESET << "\n";
    showPrompt();
}

void View::showInviteFailed(const std::string& roomname, const std::string& reason, const std::string& extra) {
    clearCurrentLine();
    if (reason == "NO_SUCH_ROOM")
        std::cout << Color::BRIGHT_RED << "✖ Room '" << roomname << "' does not exist.\n";
    else if (reason == "NO_SUCH_USER")
        std::cout << Color::BRIGHT_RED << "✖ User '" << extra << "' does not exist.\n";
    else
        std::cout << Color::BRIGHT_RED << "✖ Invite failed: " << reason << "\n";
    std::cout << Color::RESET;
    showPrompt();
}

void View::showJoinedRoom(const std::string& roomname) {
    clearCurrentLine();
    std::cout << Color::BRIGHT_GREEN << "✔ Joined room " << Color::RESET
              << Color::BRIGHT_CYAN << "#" << roomname << Color::RESET << "\n";
    showPrompt();
}

void View::showJoinFailed(const std::string& roomname, const std::string& reason) {
    clearCurrentLine();
    if (reason == "NO_SUCH_ROOM")
        std::cout << Color::BRIGHT_RED << "✖ Room '" << roomname << "' does not exist.\n";
    else if (reason == "NOT_INVITED")
        std::cout << Color::BRIGHT_RED << "✖ You were not invited to '" << roomname << "'.\n";
    else
        std::cout << Color::BRIGHT_RED << "✖ Could not join '" << roomname << "': " << reason << "\n";
    std::cout << Color::RESET;
    showPrompt();
}

void View::showUserJoinedRoom(const std::string& roomname, const std::string& username) {
    clearCurrentLine();
    std::cout << Color::GREEN << "→ " << Color::BOLD << username << Color::RESET
              << Color::GREEN << " joined " << Color::RESET
              << Color::BRIGHT_CYAN << "#" << roomname << Color::RESET << "\n";
    showPrompt();
}

void View::showUserLeftRoom(const std::string& roomname, const std::string& username) {
    clearCurrentLine();
    std::cout << Color::YELLOW << "← " << Color::BOLD << username << Color::RESET
              << Color::YELLOW << " left " << Color::RESET
              << Color::BRIGHT_CYAN << "#" << roomname << Color::RESET << "\n";
    showPrompt();
}

void View::showLeftRoom(const std::string& roomname) {
    clearCurrentLine();
    std::cout << Color::BRIGHT_YELLOW << "⚡ You left " << Color::RESET
              << Color::BRIGHT_CYAN << "#" << roomname << Color::RESET << "\n";
    showPrompt();
}

void View::showLeaveRoomFailed(const std::string& roomname, const std::string& reason) {
    clearCurrentLine();
    if (reason == "NO_SUCH_ROOM")
        std::cout << Color::BRIGHT_RED << "✖ Room '" << roomname << "' does not exist.\n";
    else if (reason == "NOT_JOINED")
        std::cout << Color::BRIGHT_RED << "✖ You are not in room '" << roomname << "'.\n";
    else
        std::cout << Color::BRIGHT_RED << "✖ Could not leave '" << roomname << "': " << reason << "\n";
    std::cout << Color::RESET;
    showPrompt();
}

void View::showError(const std::string& message) {
    clearCurrentLine();
    std::cout << Color::BRIGHT_RED << "✖ " << message << Color::RESET << "\n";
    showPrompt();
}

void View::showUnknownCommand(const std::string& input) {
    clearCurrentLine();
    std::cout << Color::BRIGHT_RED << "✖ Unknown command: " << Color::RESET
              << Color::DIM << input << Color::RESET
              << "  (type " << Color::BRIGHT_WHITE << "/help" << Color::RESET << " for help)\n";
    showPrompt();
}
