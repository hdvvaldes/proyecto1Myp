module Server.ServerTypes
  (
    Client(..),
    Room(..),
    RoomName,
    Username,
  )
where 
import GHC.IO.Handle

import Control.Concurrent.STM (TChan)

type Username = String
type RoomName = String

data Room = 
  Room {
  roomName :: RoomName,
  participants :: [Client],
  owner :: Maybe Username
  }

-- TODO manage clientStatus with a enum/data
data Client =
  Client {
  clientName :: Username,
  clientHandle :: Handle,
  clientStatus :: String,
  clientChan :: TChan String
}
