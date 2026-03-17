{-# LANGUAGE NamedFieldPuns #-}

module Server.ServerState 
  (
    ServerState,
    newServerState,
    addUser
  ) 
where 

import qualified Data.Map as Map
import Server.ServerTypes as T
import Control.Concurrent.STM (TVar, newTVar, STM)

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

addUser :: StateClients -> Client -> Maybe Bool
addUser state Client{clientName}
  | Map.member clientName state = Nothing
  | otherwise = Just True

