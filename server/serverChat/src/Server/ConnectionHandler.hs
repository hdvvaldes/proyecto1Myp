{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE PatternGuards #-}

-- | Server.ConnectionHandler module: Handles per-client connection logic.
module Server.ConnectionHandler
  ( runConn
  , handleConnection
  , connLoop
  , handleRequest
  ) where

import Control.Concurrent (forkIO)
import Control.Concurrent.STM (newTChan, readTChan)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (runReaderT, asks, local)
import Control.Monad.IO.Unlift (withRunInIO)
import Data.ByteString.Char8 (hPutStrLn, pack)
import GHC.IO.Handle (Handle, hSetBuffering, BufferMode(LineBuffering), hGetLine)
import GHC.IO.IOMode (IOMode(ReadWriteMode))
import Network.Socket (socketToHandle)

import Server.Connection.Types
import Server.Connection.Actions
import Server.Parser.Interface (parseRequest)
import Server.Parser.ParserTypes
import Server.ServerTypes (Client(..), Status(..))
import qualified Server.ServerState as SST

-- | Main entry point for a new client connection.
runConn :: HandlerEnv -> UserConn -> IO ()
runConn env (s, _) = do
  hdl <- socketToHandle s ReadWriteMode
  hSetBuffering hdl LineBuffering
  runReaderT (runConnHandler (handleConnection hdl)) env

-- | Manages the handshake and adds the recognized client to the chat room.
handleConnection :: Handle -> ConnHandler ()
handleConnection hdl = do
  client <- handshake hdl
  addClient client
  _ <- withRunInIO $ \run ->
    forkIO $ run (deliveryLoop client)
  -- Update env with identifying client
  local (\env -> env { handlerClient = Just client }) (connLoop client)

-- | Performs the initial handshake with the client.
handshake :: Handle -> ConnHandler Client
handshake hdl = do
    chan <- runSTM newTChan
    stateVar <- asks serverState
    count <- runSTM $ SST.getClientCount stateVar
    let initialName = "Guest-" ++ show count
    return $ Client
      { clientName = initialName
      , clientHandle = hdl
      , clientStatus = ACTIVE
      , clientChan = chan
      }

-- | The delivery loop responsible for sending outgoing messages.
deliveryLoop :: Client -> ConnHandler ()
deliveryLoop client@Client{clientHandle, clientChan} = do
  msg <- runSTM $ readTChan clientChan
  liftIO $ hPutStrLn clientHandle msg
  deliveryLoop client

-- | The main connection loop for each client.
connLoop :: Client -> ConnHandler ()
connLoop client = do
  entry <- liftIO $ hGetLine (clientHandle client)
  case parseRequest (pack entry) of
    Nothing  -> liftIO $ putStrLn "Invalid request"
    Just req -> handleRequest req
  connLoop client

-- | Orchestrates the handling of different client requests using guards.
handleRequest :: Request -> ConnHandler ()
handleRequest req
  | Identify uname <- req      = handleIdentify uname
  | SendPublicText msg <- req  = handlePublicText msg
  | otherwise                  = liftIO $ putStrLn "Other requests not yet implemented"
