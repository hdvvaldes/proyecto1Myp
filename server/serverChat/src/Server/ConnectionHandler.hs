{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE PatternGuards #-}
{-# LANGUAGE ScopedTypeVariables #-}

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
import Data.ByteString.Char8 (pack)
import qualified Data.ByteString.Lazy as BSL
import GHC.IO.Handle (Handle, hSetBuffering, BufferMode(LineBuffering), hGetLine)
import GHC.IO.IOMode (IOMode(ReadWriteMode))
import Network.Socket (socketToHandle)
import Data.Aeson (encode)
import qualified Data.Text as T
import Control.Exception (try, IOException)

import Server.Connection.Types
import Server.Connection.Actions
import Server.Connection.Factory
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
  -- The client is initially NOT identified (handshake sets a guest name, but mClient is Nothing in env)
  connLoop client

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
  liftIO $ BSL.hPut clientHandle (BSL.fromStrict msg)
  deliveryLoop client

-- | The main connection loop for each client.
connLoop :: Client -> ConnHandler ()
connLoop client = do
  -- Use hGetLine but handle EOF/closed handle
  mEntry <- liftIO $ tryRead (clientHandle client)
  case mEntry of
    Nothing -> handleDisconnect -- Closed connection
    Just entry -> do
      case parseRequest (pack entry) of
        Nothing  -> do
          liftIO $ BSL.hPut (clientHandle client) (encode $ makeInvalid "INVALID")
          handleDisconnect
        Just req -> do
          -- Protocol Rule: If not identified, only IDENTIFY is allowed.
          mIdentifiedClient <- asks handlerClient
          case mIdentifiedClient of
            Nothing | Identify uname <- req -> do
              -- Perform Identification
              stateVar <- asks serverState
              let guestName = clientName client
              res <- runSTM $ SST.findClient stateVar (T.unpack uname)
              case res of
                Just _ -> do
                  liftIO $ BSL.hPut (clientHandle client) (encode $ makeResponse "IDENTIFY" "USER_ALREADY_EXISTS" uname Nothing)
                  connLoop client
                Nothing -> do
                  -- Update state with new name
                  runSTM $ SST.removeUser stateVar guestName
                  let identifiedClient = client { clientName = T.unpack uname }
                  runSTM $ SST.addUser stateVar identifiedClient
                  liftIO $ BSL.hPut (clientHandle client) (encode $ makeResponse "IDENTIFY" "SUCCESS" uname Nothing)
                  broadcast $ BSL.toStrict $ encode $ makeNewUser uname
                  -- Continue loop with identified client in env
                  local (\env -> env { handlerClient = Just identifiedClient }) (connLoop identifiedClient)
            
            Nothing -> do
              -- Not identified and NOT an IDENTIFY request
              liftIO $ BSL.hPut (clientHandle client) (encode $ makeInvalid "NOT_IDENTIFIED")
              handleDisconnect
              
            Just identifiedClient -> do
              -- Already identified, handle normally
              handleRequest req
              -- Continue loop with identified client
              connLoop identifiedClient

tryRead :: Handle -> IO (Maybe String)
tryRead h = do
  res <- try (hGetLine h)
  case res of
    Left (_ :: IOException) -> return Nothing
    Right s -> return $ Just s

-- | Orchestrates the handling of different client requests using guards.
handleRequest :: Request -> ConnHandler ()
handleRequest req
  | Identify uname <- req            = handleIdentify uname
  | SetStatus status <- req          = handleSetStatus status
  | GetUsers <- req                  = handleGetUsers
  | SendText target content <- req   = handleSendText target content
  | SendPublicText content <- req    = handleSendPublicText content
  | CreateRoom rname <- req          = handleCreateRoom rname
  | Invite rname unames <- req       = handleInvite rname unames
  | JoinRoom rname <- req            = handleJoinRoom rname
  | GetRoomUsers rname <- req        = handleGetRoomUsers rname
  | SendRoomText rname content <- req= handleSendRoomText rname content
  | LeaveRoom rname <- req           = handleLeaveRoom rname
  | Disconnect <- req                = handleDisconnect
