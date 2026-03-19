#include "View.hpp"
#include <iostream>


// --- Constructor ----
View::View() = default;

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
