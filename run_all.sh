#!/bin/bash
# Start Haskell Server in the background
echo "Starting Haskell Server..."
cd /app/server && cabal run &

# Wait for server to be ready
echo "Waiting for server to start..."
sleep 5

# Start C++ Client
echo "Starting C++ Client..."
cd /app/chat-client && ./chat-client
