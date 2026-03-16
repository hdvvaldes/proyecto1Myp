-- | Server.ConnectionHandler module: Handles per-client connection logic.
module Server.ConnectionHandler (
  runConn
) where

import Server.ServerState
import Server.Parser.Interface

import GHC.IO.Handle
import Network.Socket (Socket, SockAddr, socketToHandle)
import Extra.ReaderT
import GHC.IO.IOMode (IOMode(ReadWriteMode))
import Control.Concurrent.STM (TVar)
import Server.ServerTypes (Client)
import Control.Monad.IO.Class (MonadIO(liftIO))

-- NOTE maybe passing the whole map as env is not the most practical thing
newtype HandlerEnv =
  HandlerEnv {serverStatus :: TVar ServerState}

type ConnHandler a = ReaderT HandlerEnv IO a

type UserConn = (Socket, SockAddr)

runConn :: UserConn -> ConnHandler()
runConn (s, _) = do 
  -- TODO Improve multiple calls to liftIO  
  -- Convert socket to Handle with ReadWriteMode
  hdl <- liftIO $ socketToHandle s ReadWriteMode
  -- Enable line-buffering to ensure prompt delivery of messages
  liftIO $ hSetBuffering hdl LineBuffering
  user <- identifyConn hdl
  addUser user
  connLoop user

-- AUXILIAR FUNCTIONS ---
identifyConn :: Handle -> ConnHandler Client
identifyConn hdl =  do 
  input <- userInput hdl
  res <- execute parseInput input  

  -- TODO umpdate TVar ServerState 
  -- add user to map
  -- with default preachers
  -- Start user listening to the general chat
  -- action <- parse entry
  -- relaizeAction action

addUser :: Client -> ConnHandler()
addUser client = do 
  state <- ask serverStatus
  readTVar state 


connLoop :: Client -> ConnHandler()
connLoop client = do
  _ <- liftIO $ parseInput client
  connLoop client

-- TODO function to send text 

-- TODO function to receive text 


 
