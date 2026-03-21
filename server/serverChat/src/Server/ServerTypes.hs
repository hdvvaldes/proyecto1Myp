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
import Data.Aeson (ToJSON)
import Data.ByteString (ByteString)
import GHC.Generics (Generic)

type Username = String
type RoomName = String

data Room = 
  Room {
  roomName :: RoomName,
  participants :: [Client],
  invitedUsers :: [Username],
  owner :: Maybe Username
  }

type Messages = ByteString

data Status = ACTIVE | AWAY | BUSY
  deriving (Show, Eq, Generic)

instance ToJSON Status

data Client =
  Client {
  clientName :: Username,
  clientHandle :: Handle,
  clientStatus :: Status,
  clientChan :: TChan Messages
}
