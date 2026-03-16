module Server.ServerState 
  (
    ServerState(..)
  ) 
where 

import qualified Data.Map as Map
import Server.ServerTypes as T

data ServerState = 
  ServerState {
  stateClients :: Map.Map Username Client,
  stateRooms :: Map.Map RoomName Room
}
