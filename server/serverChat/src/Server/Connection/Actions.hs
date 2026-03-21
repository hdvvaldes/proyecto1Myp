{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NamedFieldPuns #-}

module Server.Connection.Actions
  ( runSTM
  , broadcast
  , addClient
  , formatMsg
  , handleIdentify
  , handlePublicText
  ) where

import Control.Concurrent.STM (STM, atomically)
import Control.Monad.Reader (asks)
import Control.Monad.IO.Class (liftIO)
import Data.ByteString.Char8 (ByteString, pack)
import Data.Text (Text)
import Data.Text.Encoding (encodeUtf8)

import Server.Connection.Types
import qualified Server.ServerState as SST
import Server.ServerTypes (Client(..))

-- | Helper to lift STM actions into the ConnHandler monad.
runSTM :: STM a -> ConnHandler a
runSTM = liftIO . atomically

-- | Broadcasts a message to all connected clients.
broadcast :: ByteString -> ConnHandler ()
broadcast msg = do
  stateVar <- asks serverState
  runSTM $ SST.broadcast stateVar msg

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
      let name = clientName client
          formatted = "[" ++ name ++ "]: " ++ show msg
      in return $ pack formatted

-- | Handles the 'Identify' request.
handleIdentify :: Text -> ConnHandler ()
handleIdentify uname = do
  liftIO $ putStrLn $ "Identifying user: " ++ show uname
  -- TODO: Actual identification logic (e.g., updating client name)

-- | Handles the 'SendPublicText' request.
handlePublicText :: Text -> ConnHandler ()
handlePublicText msg = do
  mClient <- asks handlerClient
  case mClient of
    Nothing -> liftIO $ putStrLn "Client not Identified"
    Just _  -> do
      formatted <- formatMsg msg
      broadcast formatted
