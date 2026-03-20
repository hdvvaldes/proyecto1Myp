#pragma once

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

  // -- Lifecycle --
  void showWelcome();
  void showHelp();
  void showPrompt();

  // -- Messages ------
  void showPublicMessage(const std::string& from, 
      const std::string& text);

  // -- Conection Logging --------
  void showConnected(const std::string& host, int port);

  // -- Error Logging 
  void showError(const std::string& message);
  void showUnknownCommand(const std::string& input);

private:
  void clearCurrentLine();


};
