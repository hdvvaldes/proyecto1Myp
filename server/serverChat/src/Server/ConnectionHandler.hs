{-# LANGUAGE NamedFieldPuns #-}

-- | Server.ConnectionHandler module: Handles per-client connection logic.
module Server.ConnectionHandler (
  runConn
) where

import Server.ServerState
import Server.Parser.Interface
import Server.ServerTypes (Client(..))

import Extra.ReaderT

import GHC.IO.Handle
import Network.Socket (Socket, SockAddr, socketToHandle)
import GHC.IO.IOMode (IOMode(ReadWriteMode))
import Control.Concurrent.STM (TVar, modifyTVar', STM, newTChan, atomically)
import Control.Monad.IO.Class (MonadIO(liftIO))

-- NOTE maybe passing the whole map as env is not the most practical thing
data HandlerEnv = 
  HandlerEnv{
    serverState :: TVar ServerState,
    handlerClient :: Client
  }

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
  forkIO liftIO $ transmitter clientChan user
  connLoop user

-- AUXILIAR FUNCTIONS ---
-- | Creates formal Client to communicate
identifyConn :: Handle -> ConnHandler Client
identifyConn hdl = do 
    chan <- liftIO $ atomically newTChan
    return $ 
  -- TODO Validation :
  -- Need to idntify itself in order to get into sign up onto the server
      Client {
      clientName = "testingName" ,
      clientHandle = hdl,
      clientStatus = "testingStatus",
      clientChan = chan
  }
--  input <- userInput hdl
 --  res <- parseInput input "CREATE_USER"

  -- TODO umpdate TVar ServerState 
  -- add user to map
  -- with default preachers
  -- Start user listening to the general chat
  -- action <- parse entry
  -- relaizeAction action

addUser :: Client -> ConnHandler()
addUser client = undefined
  -- TODO Add to map
  -- TODO Add client to main room
  -- TODO Write to main 
  -- TODO Receive from currentRoom

connLoop :: Client -> ConnHandler()
connLoop client = do
  -- TODO handle exception
  entry <- liftIO $ hGetLine (clientHandle client)
  runAction $ parseInput entry
  connLoop client

runAction :: Int -> ConnHandler (Maybe a)
runAction n  
  | n == -1 = undefined
  | otherwise = undefined

runSMT :: STM a -> ConnHandler a
runSMT action = liftIO $ atomically action


-- TODO function to send text

-- TODO function to receive text
