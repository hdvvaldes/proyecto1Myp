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
import Server.ServerTypes (Client(..), Username, Status(..))

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

-- | Runs the ConnHandler with the given environment
runConn :: HandlerEnv -> UserConn -> IO ()
runConn env (s, _) = do
  -- NOTE maybe this is supposed o be in another part and run it directily with the readerT
  hdl <- socketToHandle s ReadWriteMode
  hSetBuffering hdl LineBuffering
  runReaderT (runConnHandler (handleConnection hdl)) env

-- | Manages the handshake and adds the recognized client to the chat room.
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
-- | Handshake function, not fully implemented 
-- TODO modify this function to be the 
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

-- | Function to listen the Client 
deliveryLoop :: Client -> ConnHandler ()
deliveryLoop 
  client@Client{clientHandle, clientChan} = do
  msg <- runSTM $ readTChan clientChan
  -- NOTE remove this print 
  liftIO $ hPutStrLn clientHandle msg
  deliveryLoop client

connLoop :: Client -> ConnHandler()
connLoop client = do
  -- TODO handle exception
  entry <- liftIO $ hGetLine (clientHandle client)
  case parseRequest (pack entry) of
    Nothing -> liftIO $ putStrLn "Invalid request"
    Just req -> handleRequest req
  connLoop client

handleRequest :: PT.Request -> ConnHandler ()
handleRequest req = case req of
  PT.Identify uname -> do
    -- Existing logic for identification
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

-- | Returns Text formatted and encoded as UTF8
formatMsg :: Text -> ConnHandler ByteString
formatMsg msg = do 
  mClient <- asks handlerClient
  case mClient of
    Nothing -> return $ encodeUtf8 msg
    Just client -> 
      let name = clientName client
          formatted = "[" ++ name ++ "]: " ++ show msg
      in return $ pack formatted
 


-- MODIFYING SERVER STATE ---
runSTM :: STM a -> ConnHandler a
runSTM action = liftIO $ atomically action

-- TODO ubicate this alias correctly in servertypes 
-- TODO make this generalized for any rooom 
-- type Message = ByteString
broadcast :: ByteString -> ConnHandler()
broadcast msg = do 
  stateVar <- asks serverState
  runSTM $ SST.broadcast stateVar msg

addClient :: Client -> ConnHandler ()
addClient client = do
  stateVar <- asks serverState
  runSTM $ SST.addUser stateVar client
