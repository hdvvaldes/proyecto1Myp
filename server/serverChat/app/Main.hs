-- | Main module: Entry point for the server application.
module Main where

import Server.App as App


-- | Entry point of the server.
-- Initializes the environment with default configuration and starts the server loop.
main :: IO()
main = do 
  putStrLn "==========================="
  putStrLn "        Chat Server        "
  putStrLn "==========================="
  runServer defaultSocket
  putStrLn "Server Closed"
      
