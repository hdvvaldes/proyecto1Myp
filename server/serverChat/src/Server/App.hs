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
import Control.Concurrent.Async
import Control.Concurrent.STM

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
data Env = Env{
  socketConfig :: SocketConfig
}

data SocketConfig = SocketConfig {
  socketFamily :: Family,
  socketType :: SocketType,
  socketProtoN :: ProtocolNumber,
  socketAddress :: SockAddr
}

-- | Runs the app given the environment monad given an environment and an App computation.
runApp :: Env -> App a -> IO a
runApp e r = runReaderT (unApp r) e

-- | Starts the server.
-- 1. Builds the socket.
-- 2. Binds and listens.
-- 3. Enters the accept loop.
runServer :: App ()
runServer = do
  sock <- buildSocket
  liftIO $ putStrLn "Socket has been created"
  SocketConfig{socketAddress} <- asks socketConfig
  liftIO $ bind sock socketAddress
  startListening sock
  liftIO $ putStrLn "Listening at"
  liftIO $ putStr (show socketAddress)
  mainLoop sock

-- | The main recursive loop that accepts new client connections.
-- For each connection, it delegates handling to runConn.

mainLoop :: Socket -> App()
mainLoop sock = do
  conn <- liftIO $ accept sock
  liftIO $ do 
    putStr "Connection Found at "
    print $ snd conn
    putStrLn ""
  -- NOTE Hopefully forks and the app will still be able to receive new connections
  _ <- liftIO $ async $ runConn conn
  mainLoop sock

------ Helper Function ------
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


-- | Creates a new socket using the configuration in the environment.
buildSocket :: App Socket
buildSocket = do
  SocketConfig{
    socketFamily,
    socketType,
    socketProtoN} <- asks socketConfig
  liftIO $ socket socketFamily socketType socketProtoN
 

-- | Starts listening for connections.
startListening :: Socket -> App ()
startListening sock = do 
  SocketConfig{socketAddress} <- asks socketConfig
  liftIO $ bind sock socketAddress
  -- Maximum number of connections
  let maxConn = 3
  liftIO $ listen sock maxConn


