{-# LANGUAGE NamedFieldPuns #-}

module Server.ServerState 
  (
    ServerState(..),
    newServerState,
    addUser,
    broadcast,
    getClientCount
  ) 
where 

import Server.ServerTypes

import qualified Data.Map as Map
import Control.Concurrent.STM (TVar, newTVar, STM, modifyTVar', readTVar, writeTChan)
import Control.Monad (forM_)
import Data.ByteString (ByteString)


data ServerState = 
  ServerState {
  stateClients :: StateClients,
  stateRooms :: StateRooms
}

-- | Creates the initial modifiable server state with an empty client map and rooms.
newServerState :: STM (TVar ServerState)
newServerState = newTVar ServerState {
  stateClients = Map.empty,
  stateRooms = 
    StateRooms {
    mainRoom = Nothing, 
    userRooms = Map.empty
  }
}

type StateClients = Map.Map Username Client

data StateRooms = 
  StateRooms {
    mainRoom :: Maybe Room,
    userRooms :: Map.Map RoomName Room
}

-- | Broadcasts a message to all connected clients.
broadcast :: TVar ServerState -> ByteString -> STM()
broadcast stateVar msg = do
    -- 1. Grab the current state
    currentState <- readTVar stateVar
    -- 2. Extract just the list of Clients from the Map
    let allClients = Map.elems (stateClients currentState)
    -- 3. Loop through every client and drop the message in their queue
    forM_ allClients $ \client -> do
        writeTChan (clientChan client) msg

-- | Adds a new client to the server state.
addUser :: TVar ServerState -> Client -> STM ()
addUser stateVar client@Client{clientName} = 
  modifyTVar' stateVar $ \st -> st { 
    stateClients = Map.insert clientName client (stateClients st) 
  }

-- | Returns the current number of connected clients.
getClientCount :: TVar ServerState -> STM Int
getClientCount stateVar = do
  st <- readTVar stateVar
  return $ Map.size (stateClients st)


