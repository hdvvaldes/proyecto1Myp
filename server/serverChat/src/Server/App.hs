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
import Server.Connection.Types (HandlerEnv(..))
import Server.ServerState (newServerState)

import Control.Concurrent (forkIO)
import Control.Concurrent.STM (atomically)

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
  -- Creates a new socket with the specified family, type, and protocol.
  sock <- socket 
    (socketFamily config) 
    (socketType config) 
    (socketProtoN config)
  -- Set ReuseAddr to allow immediate restart of the server after a crash/stop.
  setSocketOption sock ReuseAddr 1
  serverLog "Socket has been created"
  -- LISTENING ----
  let address = socketAddress config

  bind sock address
  listen sock maxConn
  serverLog $ "Listening at: " ++ show address
  serverLog $ "Max queued connections: " ++ show maxConn
  serverLog "Waiting for connections...." 
  
  -- Creating Server State
  stateVar <- atomically newServerState 
  
  let handleEnv = HandlerEnv { handlerClient = Nothing, serverState = stateVar }

  --- ACCEPT LOOP ----
  acceptLoop handleEnv sock 
  
-- | The main recursive loop that accepts new client connections.
-- For each connection, it delegates handling to runConn.
acceptLoop :: HandlerEnv -> Socket -> IO ()
acceptLoop env sock = do
  conn@(_, addr) <- accept sock
  serverLog $ "Connection Found at " ++ show addr
  _ <- forkIO $ runConn env conn
  acceptLoop env sock

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

-- | Server logging with format
serverLog :: String -> IO ()
serverLog msg = 
  putStrLn string
  where 
    string = "[server]" ++ msg

-- | Maximum Connections allowed
maxConn :: Int
maxConn = 10
