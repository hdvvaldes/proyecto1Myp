{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings#-}


-- | Server.ConnectionHandler module: Handles per-client connection logic.
module Server.ConnectionHandler (
  ConnHandler(..),
  HandlerEnv(..),
  runConn
) where

import qualified Server.ServerState as SST
import Server.Parser.Interface (parseRequest)
import qualified Server.Parser.ParserTypes as PT
import Server.ServerTypes (Client(..), Status(..))

import Control.Monad.Reader (ReaderT, runReaderT, asks, local)

import Data.Text.Encoding(encodeUtf8)

import GHC.IO.Handle (Handle, hSetBuffering, BufferMode(LineBuffering), hGetLine)
import Network.Socket (Socket, SockAddr, socketToHandle)
import GHC.IO.IOMode (IOMode(ReadWriteMode))
import Control.Concurrent.STM (TVar, STM, newTChan, atomically, readTChan)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.ByteString.Char8 (hPutStrLn, pack, ByteString)
import Control.Concurrent (forkIO)
import Control.Monad.IO.Unlift (MonadUnliftIO (withRunInIO))
import Control.Monad.RWS (MonadReader)
import Data.Text (Text)

-- NOTE maybe passing the whole map as env is not the most practical thing
data HandlerEnv =
  HandlerEnv{
    handlerClient :: Maybe Client,
    serverState :: TVar SST.ServerState
  }

newtype ConnHandler a = ConnHandler {
  runConnHandler :: ReaderT HandlerEnv IO a
} deriving (
  Functor, Applicative, Monad, 
  MonadReader HandlerEnv, MonadIO, MonadUnliftIO)

type UserConn = (Socket, SockAddr)

-- | Main entry point for a new client connection.
-- Converts the socket to a handle and runs the connection handler.
runConn :: HandlerEnv -> UserConn -> IO ()
runConn env (s, _) = do
  -- NOTE maybe this is supposed o be in another part and run it directily with the readerT
  hdl <- socketToHandle s ReadWriteMode
  hSetBuffering hdl LineBuffering
  runReaderT (runConnHandler (handleConnection hdl)) env

-- | Manages the handshake and adds the recognized client to the chat room.
-- After the handshake, it forks the delivery loop and enters the main connection loop.
handleConnection :: Handle -> ConnHandler ()
handleConnection hdl = do
  client <- handshake hdl 
  addClient client
  -- Update environment with the new client for subsequent actions
  local (\e -> e { handlerClient = Just client }) $ do
    -- Fork delivery loop
    _ <- withRunInIO $ \run -> forkIO $ run (deliveryLoop client)
    connLoop client

-- AUXILIAR FUNCTIONS ---

-- | Performs the initial handshake with the client.
-- Currently, it generates a unique guest name based on the client count.
-- TODO: Implement proper handshake logic (e.g., authentication).
handshake :: Handle -> ConnHandler Client
handshake hdl = do 
    chan <- runSTM newTChan
    stateVar <- asks serverState
    count <- runSTM $ SST.getClientCount stateVar
    -- TODO: Implement handshake
    let initialName = "Guest-" ++ show count
    return $ 
      Client {
      clientName = initialName,
      clientHandle = hdl,
      clientStatus = ACTIVE,
      clientChan = chan
  }

-- | The delivery loop is responsible for sending outgoing messages to the client.
-- It runs in a dedicated thread, waits for messages in the client's TChan,
-- and writes them directly to the client's network handle.
deliveryLoop :: Client -> ConnHandler ()
deliveryLoop 
  client@Client{clientHandle, clientChan} = do
  msg <- runSTM $ readTChan clientChan
  liftIO $ hPutStrLn clientHandle msg
  deliveryLoop client


-- | The main connection loop for each client.
-- It reads lines from the client's handle, parses them as requests, and handles them.
connLoop :: Client -> ConnHandler()
connLoop client = do
  -- TODO handle exception
  entry <- liftIO $ hGetLine (clientHandle client)
  case parseRequest (pack entry) of
    Nothing -> liftIO $ putStrLn "Invalid request"
    Just req -> handleRequest req
  connLoop client

-- | Orchestrates the handling of different client requests.
handleRequest :: PT.Request -> ConnHandler ()
handleRequest req = case req of
  PT.Identify uname -> do
    -- NOTE: Dead code - existing logic for identification needs implementation
    -- NOTE Remove this print 
    liftIO $ putStrLn $ "Identifying user: " ++ show uname
  PT.SendPublicText msg -> do 
    mClient <- asks handlerClient
    case mClient of 
      Nothing -> 
        liftIO $ putStrLn "Client not Identified"
      Just _ -> do
         formatted <- formatMsg msg
         broadcast formatted
  _ -> liftIO $ putStrLn "Other requests not yet implemented"

-- | Formats a message with the sender's name.
formatMsg :: Text -> ConnHandler ByteString
formatMsg msg = do 
  mClient <- asks handlerClient
  case mClient of
    Nothing -> return $ encodeUtf8 msg
    Just client -> 
      let name = clientName client
          formatted = "[" ++ name ++ "]: " ++ show msg
      in return $ pack formatted
 

-- | Helper to lift STM actions into the ConnHandler monad.
runSTM :: STM a -> ConnHandler a
runSTM action = liftIO $ atomically action

-- | Broadcasts a message to all connected clients.
-- TODO: making this generalized for any room.
broadcast :: ByteString -> ConnHandler()
broadcast msg = do 
  stateVar <- asks serverState
  runSTM $ SST.broadcast stateVar msg

-- | Adds a client to the server state.
addClient :: Client -> ConnHandler ()
addClient client = do
  stateVar <- asks serverState
  runSTM $ SST.addUser stateVar client
