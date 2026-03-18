{-# LANGUAGE NamedFieldPuns #-}

module Server.ServerState 
  (
    ServerState(..),
    newServerState,
    addUser
  ) 
where 

import qualified Data.Map as Map
import Server.ServerTypes as T
import Control.Concurrent.STM (TVar, newTVar, STM, modifyTVar')

data ServerState = 
  ServerState {
  stateClients :: StateClients,
  stateRooms :: StateRooms
}

-- | Creates modifiable server state
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

addUser :: TVar ServerState -> Client -> STM ()
addUser stateVar client@Client{clientName} = 
  modifyTVar' stateVar $ \st -> st { 
    stateClients = Map.insert clientName client (stateClients st) 
  }
