#pragma once

#include "Model.hpp"

// ---------------------------------------------
//  ANSI color helpers
// ---------------------------------------------


#include <string>
namespace Color {
    constexpr const char* RESET   = "\033[0m";
    constexpr const char* BOLD    = "\033[1m";
    constexpr const char* DIM     = "\033[2m";

    constexpr const char* RED     = "\033[31m";
    constexpr const char* GREEN   = "\033[32m";
    constexpr const char* YELLOW  = "\033[33m";
    constexpr const char* BLUE    = "\033[34m";
    constexpr const char* MAGENTA = "\033[35m";
    constexpr const char* CYAN    = "\033[36m";
    constexpr const char* WHITE   = "\033[37m";

    constexpr const char* BRIGHT_RED     = "\033[91m";
    constexpr const char* BRIGHT_GREEN   = "\033[92m";
    constexpr const char* BRIGHT_YELLOW  = "\033[93m";
    constexpr const char* BRIGHT_BLUE    = "\033[94m";
    constexpr const char* BRIGHT_MAGENTA = "\033[95m";
    constexpr const char* BRIGHT_CYAN    = "\033[96m";
    constexpr const char* BRIGHT_WHITE   = "\033[97m";
}

class View {
public: 
  View();

  // -- Lifecycle -------------
  void showWelcome();
  void showHelp();
  void showPrompt();

  // -- Conection Logging --------
  void showConnected(const std::string& host, int port);
  void showDisconnected();
  void showConnectionError(const std::string& reason);

  // -- Identify Logging --------
  void showIdentified(const std::string& username);
  void showIdentifyFailed(const std::string& username);

  // -- Status Logging ----------
  void showStatusChanged(const std::string& status);

  // -- Global user events ------
  void showNewUser(const std::string& username);
  void showUserDisconnected(const std::string& username);
  void showUserStatusChanged(const std::string& username, 
      const std::string& status);

  // -- Presenting Users ------
  void showUserList(const std::map<std::string, UserStatus>& users);
  void showRoomUserList(const std::string& roomname, const std::map<std::string, UserStatus>& users);

  // -- Messages -----------------
  void showPublicMessage(const std::string& from, 
      const std::string& text);

  // -- Error Logging --------------
  void showError(const std::string& message);
  void showUnknownCommand(const std::string& input);
  void showNotIdentified();

  // -- Rooms ---------

private:
  void clearCurrentLine();
  std::string statusBadge(UserStatus status);
  std::string statusBadge(const std::string& status);

};
