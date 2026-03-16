{-# LANGUAGE DerivingStrategies #-}

-- | Server.App module: Print server messages and starts
-- | connection handler
-- | and the core server lifecycle logic (setup, bind, listen, and accept loop).
module Server.App
  ( runServer,
    defaultSocket,
  )
where

import Network.Socket
import Server.ConnectionHandler (runConn)
import Control.Concurrent (forkIO)

-- | Socket configuration
data SocketConfig = SocketConfig
  { socketFamily :: Family,
    socketType :: SocketType,
    socketProtoN :: ProtocolNumber,
    socketAddress :: SockAddr
  }


-- | Set up server and starts listening
-- 1. Builds the socket.
-- 2. Binds and listens.
-- 3. Enters the accept loop.
runServer :: SocketConfig -> IO ()
runServer config = do
  -- BUILDS SOCKET ---- 
  -- TODO improve readability
  sock <- socket 
    (socketFamily config) 
    (socketType config) 
    (socketProtoN config)
  -- TODO Investigate implementation
  -- NOTE Web says to allow easier debugging
  setSocketOption sock ReuseAddr 1
  serverLog "Socket has been created"
  -- LISTENING ----
  bind sock (socketAddress config)
  listen sock maxConn
  serverLog $ "Listening at: " ++ show socketAddress
  serverLog $ "Max queued connections: " ++ show maxConn
  serverLog "Waiting for connections...." 
  --- ACCEPT LOOP ----
  acceptLoop sock

-- | The main recursive loop that accepts new client connections.
-- For each connection, it delegates handling to runConn.
acceptLoop :: Socket -> IO()
acceptLoop sock = do
  conn@(_, addr) <- accept sock
  serverLog $ "Connection Found at " ++ show addr
  -- NOTE Hopefully forks and the app will still be able to receive new connections
  _ <- forkIO $ runConn conn
  acceptLoop sock

------ Helper Functions ------

-- | Default socket configuration: localhost:8080
defaultSocket :: SocketConfig
defaultSocket =
  SocketConfig
    { socketFamily = AF_INET,
      socketType = Stream,
      socketProtoN = defaultProtocol,
      socketAddress = SockAddrInet port host
    }
  where
    port = 8080
    host = tupleToHostAddress (127, 0, 0, 1)

-- NOTE this could imprve by defining a transformer and limiting the actions over the external monad
-- NOTE Similar to the model of my previous implementation
-- | Server logging with format
serverLog :: String -> IO ()
serverLog msg = 
  putStrLn string
  where 
    string = "[server]" ++ msg

-- | Maximum Connections allowed
maxConn :: Int
maxConn = 10
