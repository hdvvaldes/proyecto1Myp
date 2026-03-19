{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}


module Server.Parser.ParserTypes 
  ( Request(..)
  )
where 

import GHC.Generics (Generic)
import Data.Aeson (FromJSON(..), (.:), withObject)
import Data.Text (Text)

-- NOTE this may cause problems due having to definitions of statu

data Status = ACTIVE | AWAY | BUSY
  deriving (Show, Eq, Generic)
instance FromJSON Status

data Request
  = Identify { username :: Text }
  | SetStatus { status :: Status }
  | GetUsers
  | SendText { target :: Text, content :: Text }
  | SendPublicText { content :: Text }
  | CreateRoom { roomName :: Text }
  | Invite { roomName :: Text, usernames :: [Text] }
  | JoinRoom { roomName :: Text }
  | GetRoomUsers { roomName :: Text }
  | SendRoomText { roomName :: Text, content :: Text }
  | LeaveRoom { roomName :: Text }
  | Disconnect
  deriving (Show, Eq, Generic)

instance FromJSON Request where
  parseJSON = withObject "Request" $ \v -> do
    t <- v .: "type"
    case (t :: Text) of
      "IDENTIFY"    -> Identify <$> v .: "username"
      "STATUS"      -> SetStatus <$> v .: "status"
      "USERS"       -> pure GetUsers
      "TEXT"        -> SendText <$> v .: "username" <*> v .: "text"
      "PUBLIC_TEXT" -> SendPublicText <$> v .: "text"
      "NEW_ROOM"    -> CreateRoom <$> v .: "roomname"
      "INVITE"      -> Invite <$> v .: "roomname" <*> v .: "usernames"
      "JOIN_ROOM"   -> JoinRoom <$> v .: "roomname"
      "ROOM_USERS"  -> GetRoomUsers <$> v .: "roomname"
      "ROOM_TEXT"   -> SendRoomText <$> v .: "roomname" <*> v .: "text"
      "LEAVE_ROOM"  -> LeaveRoom <$> v .: "roomname"
      "DISCONNECT"  -> pure Disconnect
      _             -> fail "Unknown request type"
