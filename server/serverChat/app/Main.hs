-- | Main module: Entry point for the serverdd application.
module Main where

import Server.App 

-- | Entry point of the server.
-- Initializes the environment with default configuration and starts the server loop.
main :: IO()
main = do 
  -- Initialize environment with default socket configuration (127.0.0.1:8080)
  let env = Env defaultSocket
  
  -- Run the app using our custom App monad
  _ <- runApp env $ do
    runServer
    
  putStrLn "Server Closed"
      
