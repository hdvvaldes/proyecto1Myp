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
  chan <- runSTM newTChan
  -- Initial temporary client, not yet in ServerState
  let initialClient = Client
        { clientName = "pending-handshake"
        , clientHandle = hdl
        , clientStatus = ACTIVE
        , clientChan = chan
        }
  -- Start delivery loop early
  _ <- withRunInIO $ \run ->
    forkIO $ run (deliveryLoop initialClient)
  
  -- Start the loop. Initially handlerClient in env is Nothing.
  connLoop initialClient

-- | The delivery loop responsible for sending outgoing messages.
deliveryLoop :: Client -> ConnHandler ()
deliveryLoop client@Client{clientHandle, clientChan} = do
  msg <- runSTM $ readTChan clientChan
  liftIO $ BSL.hPut clientHandle (BSL.fromStrict msg)
  deliveryLoop client

-- | The main connection loop for each client.
connLoop :: Client -> ConnHandler ()
connLoop client = do
  mEntry <- liftIO $ tryRead (clientHandle client)
  case mEntry of
    Nothing -> handleDisconnect -- Closed connection
    Just entry -> do
      case parseRequest (pack entry) of
        Nothing -> do
          liftIO $ BSL.hPut (clientHandle client) (encode $ makeInvalid "INVALID")
          handleDisconnect
        Just req -> do
          mIdentifiedClient <- asks handlerClient
          case mIdentifiedClient of
            Nothing -> 
              case req of
                Identify uname -> do
                  stateVar <- asks serverState
                  res <- runSTM $ SST.findClient stateVar (T.unpack uname)
                  case res of
                    Just _ -> do
                      liftIO $ BSL.hPut (clientHandle client) (encode $ makeResponse "IDENTIFY" "USER_ALREADY_EXISTS" uname Nothing)
                      connLoop client -- Allow retry
                    Nothing -> do
                      let identifiedClient = client { clientName = T.unpack uname }
                      addClient identifiedClient
                      liftIO $ BSL.hPut (clientHandle client) (encode $ makeResponse "IDENTIFY" "SUCCESS" uname Nothing)
                      broadcast $ BSL.toStrict $ encode $ makeNewUser uname
                      -- Proceed identified
                      local (\env -> env { handlerClient = Just identifiedClient }) (connLoop identifiedClient)
                _ -> do
                  liftIO $ BSL.hPut (clientHandle client) (encode $ makeInvalid "NOT_IDENTIFIED")
                  handleDisconnect
            Just _ -> do
              handleRequest req
              connLoop client

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
