#pragma once

#include "Model.hpp"
class MessageCodec {
public:

  // Parse a JSON line and return a 
  // populated ModelEventData.
  // Returns an event == 
  // ModelEvent::ERROR_RESPONSE with 
  // result == "PARSE_ERROR"
  // if the line cannot be decoded.
  static ModelEventData parse(const std::string& jsonLine);
}
