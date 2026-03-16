-- | Main module: Entry point for the server application.
module Main where

import Server.App 

-- | Entry point of the server.
-- Initializes the environment with default configuration and starts the server loop.
main :: IO()
main = do 
  putStrLn "==========================="
  putStrLn "        Chat Server        "
  putStrLn "==========================="
  runServer defaultSocket
  
  -- Initialize environment with default socket configuration (127.0.0.1:8080)
  let env = Env defaultSocket
  
  -- Run the app using our custom App monad
  -- NOTE We can return a int representing how it was closed
  _ <- runApp env >>= runServer 
    
  putStrLn "Server Closed"
      
