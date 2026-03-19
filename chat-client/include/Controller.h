class Controller {
public:
    Controller();
    ~Controller() = default;

    // Starts the interactive loop; returns when the user types /quit.
    void run();
};
