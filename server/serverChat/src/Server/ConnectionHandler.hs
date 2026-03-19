{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

-- | Server.ConnectionHandler module: Handles per-client connection logic.
module Server.ConnectionHandler (
  ConnHandler(..),
  HandlerEnv(..),
  runConn
) where

import Server.ServerState
import Server.Parser.Interface (parseRequest)
import Server.Parser.ParserTypes as PT
import Server.ServerTypes (Client(..), Username)

import Control.Monad.Reader (ReaderT, runReaderT, ask, asks)

import GHC.IO.Handle (Handle, hSetBuffering, BufferMode(LineBuffering), hGetLine)
import Network.Socket (Socket, SockAddr, socketToHandle)
import GHC.IO.IOMode (IOMode(ReadWriteMode))
import Control.Concurrent.STM (TVar, modifyTVar', STM, newTChan, atomically, modifyTVar, readTChan, readTVar)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.ByteString.Char8 (hPutStrLn, pack)
import Control.Concurrent (forkIO)
import Control.Monad.IO.Unlift (MonadUnliftIO (withRunInIO))
import Control.Monad.RWS (MonadReader)

-- NOTE maybe passing the whole map as env is not the most practical thing
data HandlerEnv =
  HandlerEnv{
    handlerClient :: Maybe Client,
    serverState :: TVar ServerState
  }

newtype ConnHandler a = ConnHandler {
  runConnHandler :: ReaderT HandlerEnv IO a
} deriving (
  Functor, Applicative, Monad, 
  MonadReader HandlerEnv, MonadIO, MonadUnliftIO)

type UserConn = (Socket, SockAddr)
runConn :: HandlerEnv -> UserConn -> IO ()
runConn env (s, _) = do
  hdl <- socketToHandle s ReadWriteMode
  hSetBuffering hdl LineBuffering
  -- Standardize username handling or initial handshake here
  let initialName = "Guest" -- TODO: Get from handshake
  runReaderT (runConnHandler (handleConnection hdl initialName)) env

handleConnection :: Handle -> Username -> ConnHandler ()
handleConnection hdl uname = do
  client <- createClient hdl uname
  addClient client
  -- Fork delivery loop
  _ <- withRunInIO $ \run -> forkIO $ run (deliveryLoop client)
  connLoop client

-- AUXILIAR FUNCTIONS ---
-- | Creates formal Client to communicate
createClient :: Handle -> Username -> ConnHandler Client
createClient hdl uname = do 
    chan <- runSTM newTChan
    return $ 
      Client {
      clientName = uname,
      clientHandle = hdl,
      clientStatus = P.ACTIVE,
      clientChan = chan
  }

deliveryLoop :: Client -> ConnHandler ()
deliveryLoop 
  client@Client{clientHandle, clientChan} = do
  msg <- runSTM $ readTChan clientChan
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

handleRequest :: Request -> ConnHandler ()
handleRequest req = case req of
  Identify uname -> do
    -- Existing logic for identification
    -- NOTE Remove this print 
    liftIO $ putStrLn $ "Identifying user: " ++ show uname
  SendPublicText msg -> do 
    case asks handlerClient of 
      Nothing -> 
        liftIO $ putStrLn $ "Client not Identified"
      Just a -> 
        liftIO $ putStrLn
        -- echo this msg to all the other clients
  _ -> liftIO $ putStrLn "Other requests not yet implemented"

clientActionLog :: String -> ConnHandler()
clientActionLog msg = do
  putStrLn 

  case asks handlerClient of 
    Nothing -> 

-- MODIFYING SERVER STATE ---

runSTM :: STM a -> ConnHandler a
runSTM action = liftIO $ atomically action

addClient :: Client -> ConnHandler ()
addClient client = do
  stateVar <- asks serverState
  runSTM $ addUser stateVar client
-- TODO function to send text

-- TODO function to receive text
