{-# LANGUAGE DeriveGeneric #-}

module Server.ServerTypes
  (
    Client(..),
    Room(..),
    Status(..),
    RoomName,
    Username,
  )
where 
import GHC.IO.Handle

import Control.Concurrent.STM (TChan)
import Data.ByteString (ByteString)
import GHC.Generics (Generic)

type Username = String
type RoomName = String

data Room = 
  Room {
  roomName :: RoomName,
  participants :: [Client],
  owner :: Maybe Username
  }

-- TODO manage clientStatus with a enum/data
type Messages = ByteString

data Status = ACTIVE | AWAY | BUSY
  deriving (Show, Eq, Generic)

data Client =
  Client {
  clientName :: Username,
  clientHandle :: Handle,
  clientStatus :: Status,
  clientChan :: TChan Messages
}
