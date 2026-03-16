module Server.ServerTypes
  (
    Client(..),
    Room(..),
    RoomName,
    Username,
    ServerAction,
  )
where 
import GHC.IO.Handle

type Username = String
type RoomName = String

newtype ServerAction = 
  ServerAction {
    action :: Int
  }


data Room = 
  Room {
  roomName :: RoomName,
  participants :: [Username],
  owner :: Maybe Username
  }


-- TODO manage clientStatus with a enum/data
data Client =
  Client {
  clientName :: Username,
  clientHandle :: Handle,
  clientStatus :: String
}
