{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NamedFieldPuns #-}

module Server.Connection.Actions
  ( runSTM
  , broadcast
  , addClient
  , formatMsg
  , handleIdentify
  , handleSetStatus
  , handleGetUsers
  , handleSendText
  , handleSendPublicText
  , handleCreateRoom
  , handleInvite
  , handleJoinRoom
  , handleGetRoomUsers
  , handleSendRoomText
  , handleLeaveRoom
  , handleDisconnect
  , logAction
  ) where

import Control.Concurrent.STM (STM, atomically, writeTChan)
import Control.Monad (forM_)
import Control.Monad.Reader (asks)
import Control.Monad.IO.Class (liftIO)
import Data.ByteString.Char8 (ByteString, pack, hPutStrLn)
import qualified Data.ByteString.Lazy as BSL
import Data.Text (Text)
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Data.Aeson (encode)
import qualified Data.Map as Map

import Server.Connection.Types
import Server.Connection.Factory
import qualified Server.ServerState as SST
import Server.ServerTypes (Client(..), Username, Status(..))

-- | Helper to lift STM actions into the ConnHandler monad.
runSTM :: STM a -> ConnHandler a
runSTM = liftIO . atomically

-- | Log an action in the format <user> did <action> [users]
logAction :: Text -> Text -> ConnHandler ()
logAction uname action = do
  loggerFunc <- asks logger
  stateVar <- asks serverState
  users <- runSTM $ SST.getAllUsers stateVar
  let userList = T.intercalate ", " (Map.keys users)
  liftIO $ loggerFunc $ uname <> " did " <> action <> " [" <> userList <> "]"

-- | Helper to send a JSON value to a client handle.
sendJSON :: Client -> BSL.ByteString -> IO ()
sendJSON client json = hPutStrLn (clientHandle client) (BSL.toStrict json)

-- | Broadcasts a message to all connected clients.
broadcast :: ByteString -> ConnHandler ()
broadcast msg = do
  stateVar <- asks serverState
  runSTM $ SST.broadcast stateVar (msg <> "\n")

-- | Broadcasts a message to all users in a room.
broadcastToRoom :: Text -> ByteString -> ConnHandler ()
broadcastToRoom rname msg = do
  stateVar <- asks serverState
  runSTM $ SST.broadcastToRoom stateVar (T.unpack rname) (msg <> "\n")

-- | Adds a client to the server state.
addClient :: Client -> ConnHandler ()
addClient client = do
  stateVar <- asks serverState
  runSTM $ SST.addUser stateVar client

-- | Formats a message with the sender's name.
formatMsg :: Text -> ConnHandler ByteString
formatMsg msg = do
  mClient <- asks handlerClient
  case mClient of
    Nothing -> return $ encodeUtf8 msg
    Just client ->
      let name = T.pack $ clientName client
          formatted = "[" <> T.unpack name <> "]: " <> T.unpack msg
      in return $ pack formatted

-- HANDLERS ---

handleIdentify :: Text -> ConnHandler ()
handleIdentify uname = do
  mClient <- asks handlerClient
  case mClient of
    Just _ -> liftIO $ putStrLn "Already identified" -- Should not happen if guards are correct
    Nothing -> do
      -- Note: In this simple version, we don't have the original handle here easily
      -- but handleConnection already has the client. 
      -- Actually, identify should probably change the name of the current guest client.
      -- However, the protocol says "SUCCESS" or "USER_ALREADY_EXISTS".
      -- I'll implement a stub for now as the naming logic is tricky with the current setup.
      liftIO $ putStrLn $ "Identifying user: " <> T.unpack uname
      logAction uname "IDENTIFY"

handleSetStatus :: Status -> ConnHandler ()
handleSetStatus status = do
  mClient <- asks handlerClient
  case mClient of
    Nothing -> return () -- Should be caught by rejection logic
    Just client -> do
      stateVar <- asks serverState
      let uname = T.pack $ clientName client
      runSTM $ SST.updateUserStatus stateVar (clientName client) status
      broadcast $ BSL.toStrict $ encode $ makeNewStatus uname status
      logAction uname $ "SET_STATUS to " <> (T.pack $ show status)

handleGetUsers :: ConnHandler ()
handleGetUsers = do
  mClient <- asks handlerClient
  case mClient of
    Nothing -> return ()
    Just client -> do
      stateVar <- asks serverState
      users <- runSTM $ SST.getAllUsers stateVar
      liftIO $ sendJSON client $ encode $ makeUserList users
      logAction (T.pack $ clientName client) "GET_USERS"

handleSendText :: Text -> Text -> ConnHandler ()
handleSendText target content = do
  mClient <- asks handlerClient
  case mClient of
    Nothing -> return ()
    Just client -> do
      stateVar <- asks serverState
      mTarget <- runSTM $ SST.findClient stateVar (T.unpack target)
      let uname = T.pack $ clientName client
      case mTarget of
        Nothing -> liftIO $ sendJSON client $ encode $ makeResponse "TEXT" "NO_SUCH_USER" target Nothing
        Just targetClient -> do
          liftIO $ sendJSON targetClient $ encode $ makeTextFrom uname content
      logAction uname $ "SEND_TEXT to " <> target

handleSendPublicText :: Text -> ConnHandler ()
handleSendPublicText msg = do
  mClient <- asks handlerClient
  case mClient of
    Nothing -> return ()
    Just client -> do
      let uname = T.pack $ clientName client
      broadcast $ BSL.toStrict $ encode $ makePublicTextFrom uname msg
      logAction uname "SEND_PUBLIC_TEXT"

handleCreateRoom :: Text -> ConnHandler ()
handleCreateRoom rname = do
  mClient <- asks handlerClient
  case mClient of
    Nothing -> return ()
    Just client -> do
      stateVar <- asks serverState
      let uname = T.pack $ clientName client
      res <- runSTM $ SST.createRoom stateVar (T.unpack rname) (clientName client)
      case res of
        Left err -> liftIO $ sendJSON client $ encode $ makeResponse "NEW_ROOM" (T.pack err) rname Nothing
        Right _ -> liftIO $ sendJSON client $ encode $ makeResponse "NEW_ROOM" "SUCCESS" rname Nothing
      logAction uname $ "CREATE_ROOM " <> rname

handleInvite :: Text -> [Text] -> ConnHandler ()
handleInvite rname unames = do
  mClient <- asks handlerClient
  case mClient of
    Nothing -> return ()
    Just client -> do
      stateVar <- asks serverState
      let uname = T.pack $ clientName client
      -- The protocol says to invite each and notify targets.
      -- If room doesn't exist, error.
      forM_ unames $ \target -> do
        res <- runSTM $ SST.inviteToRoom stateVar (T.unpack rname) (T.unpack target)
        case res of
          Left err -> liftIO $ sendJSON client $ encode $ makeResponse "INVITE" (T.pack err) target Nothing
          Right _ -> do
            mTarget <- runSTM $ SST.findClient stateVar (T.unpack target)
            case mTarget of
              Just targetClient -> liftIO $ sendJSON targetClient $ encode $ makeInvitation uname rname
              Nothing -> return ()
      logAction uname $ "INVITE " <> T.intercalate ", " unames <> " to " <> rname

handleJoinRoom :: Text -> ConnHandler ()
handleJoinRoom rname = do
  mClient <- asks handlerClient
  case mClient of
    Nothing -> return ()
    Just client -> do
      stateVar <- asks serverState
      let uname = T.pack $ clientName client
      res <- runSTM $ SST.joinRoom stateVar (T.unpack rname) (clientName client)
      case res of
        Left err -> liftIO $ sendJSON client $ encode $ makeResponse "JOIN_ROOM" (T.pack err) rname Nothing
        Right _ -> do
          liftIO $ sendJSON client $ encode $ makeResponse "JOIN_ROOM" "SUCCESS" rname Nothing
          broadcastToRoom rname (BSL.toStrict $ encode $ makeJoinedRoom rname uname)
      logAction uname $ "JOIN_ROOM " <> rname

handleGetRoomUsers :: Text -> ConnHandler ()
handleGetRoomUsers rname = do
  mClient <- asks handlerClient
  case mClient of
    Nothing -> return ()
    Just client -> do
      stateVar <- asks serverState
      res <- runSTM $ SST.getRoomUsers stateVar (T.unpack rname) (clientName client)
      case res of
        Left err -> liftIO $ sendJSON client $ encode $ makeResponse "ROOM_USERS" (T.pack err) rname Nothing
        Right users -> liftIO $ sendJSON client $ encode $ makeRoomUserList rname users
      logAction (T.pack $ clientName client) $ "GET_ROOM_USERS " <> rname

handleSendRoomText :: Text -> Text -> ConnHandler ()
handleSendRoomText rname content = do
  mClient <- asks handlerClient
  case mClient of
    Nothing -> return ()
    Just client -> do
      stateVar <- asks serverState
      let uname = T.pack $ clientName client
      -- Check if in room
      res <- runSTM $ SST.getRoomUsers stateVar (T.unpack rname) (clientName client)
      case res of
        Left err -> liftIO $ sendJSON client $ encode $ makeResponse "ROOM_TEXT" (T.pack err) rname Nothing
        Right _ -> broadcastToRoom rname (BSL.toStrict $ encode $ makeRoomTextFrom rname uname content)
      logAction uname $ "SEND_ROOM_TEXT to " <> rname

handleLeaveRoom :: Text -> ConnHandler ()
handleLeaveRoom rname = do
  mClient <- asks handlerClient
  case mClient of
    Nothing -> return ()
    Just client -> do
      stateVar <- asks serverState
      let uname = T.pack $ clientName client
      res <- runSTM $ SST.leaveRoom stateVar (T.unpack rname) (clientName client)
      case res of
        Left err -> liftIO $ sendJSON client $ encode $ makeResponse "LEAVE_ROOM" (T.pack err) rname Nothing
        Right _ -> broadcastToRoom rname (BSL.toStrict $ encode $ makeLeftRoom rname uname)
      logAction uname $ "LEAVE_ROOM " <> rname

handleDisconnect :: ConnHandler ()
handleDisconnect = do
  mClient <- asks handlerClient
  case mClient of
    Nothing -> return ()
    Just client -> do
      stateVar <- asks serverState
      let uname = T.pack $ clientName client
      runSTM $ SST.removeUser stateVar (clientName client)
      broadcast $ BSL.toStrict $ encode $ makeDisconnected uname
      logAction uname "DISCONNECT"
      -- The connection loop should handle the actual socket closing or termination.
