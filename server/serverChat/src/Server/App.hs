{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE NamedFieldPuns#-}

-- | Server.App module: Defines the application-level monad, environment, 
-- and the core server lifecycle logic (setup, bind, listen, and accept loop).

module Server.App(
  App(..),
  Env(..),
  runApp,
  runServer,
  defaultSocket
) where

import Network.Socket
import Extra.ReaderT
import Control.Monad.Reader.Class(MonadReader, asks)
import Control.Monad.IO.Class(MonadIO, liftIO)
import Server.ConnectionHandler(runConn)

-- | The Application Monad.
-- A wrapper around ReaderT that provides access to the application environment (Env)
-- and supports IO and MonadReader operations.
newtype App a = App
  {unApp :: ReaderT Env IO a} 
  deriving newtype 
    (Functor, 
    Applicative, 
    Monad,
    MonadReader Env,
    MonadIO
    )

-- | The application environment.
-- Currently holds only socket-related configuration.
data Env = Env {
  socketConfig :: SocketConfig
}

data SocketConfig = SocketConfig {
  socketFamily ::Family,
  socketType :: SocketType,
  socketProtoN :: ProtocolNumber,
  socketAddress :: SockAddr
}

-- | Helper to run the App monad given an environment and an App computation.
runApp :: Env -> App a -> IO a
runApp e r = runReaderT (unApp r) e

defaultSocket :: SocketConfig 
defaultSocket = SocketConfig {
  socketFamily  = AF_INET, 
  socketType    = Stream,
  socketProtoN  = defaultProtocol,
  socketAddress = SockAddrInet port host
}
  where
    port = 8080
    host = tupleToHostAddress(127,0,0,1)

-- | Starts the server.
-- 1. Builds the socket.
-- 2. Binds and listens.
-- 3. Enters the accept loop.
runServer :: App ()
runServer = do
  sock <- buildSocket
  startSocket sock
  mainLoop sock

------ Helper Function ------

-- | Creates a new socket using the configuration in the environment.
buildSocket :: App Socket
buildSocket = do
  SocketConfig{
    socketFamily,
    socketType,
    socketProtoN} <- asks socketConfig
  liftIO $ socket socketFamily socketType socketProtoN

-- | Binds the socket to the configured address and starts listening for connections.
startSocket :: Socket -> App ()
startSocket sock = do 
  SocketConfig{socketAddress} <- asks socketConfig
  liftIO $ bind sock socketAddress
  let maxConn = 2
  liftIO $ listen sock maxConn

-- | The main recursive loop that accepts new client connections.
-- For each connection, it delegates handling to runConn.
mainLoop :: Socket -> App()
mainLoop sock = do
  conn <- liftIO $ accept sock
  liftIO $ runConn conn
  liftIO $ putStrLn "connection found"
  mainLoop sock

