{-# LANGUAGE OverloadedStrings #-}

module Server.Connection.Factory
  ( -- Responses
    makeResponse
  , makeInvalid
    -- Global Notifications
  , makeNewUser
  , makeNewStatus
  , makeUserList
  , makeDisconnected
    -- Direct Messaging
  , makeTextFrom
    -- Public Messaging
  , makePublicTextFrom
    -- Room Notifications
  , makeInvitation
  , makeJoinedRoom
  , makeRoomUserList
  , makeRoomTextFrom
  , makeLeftRoom
  ) where

import Data.Aeson (Value, object, (.=), ToJSON)
import Data.Text (Text)
import Data.Map (Map)
import Server.ServerTypes (Status)

-- | Standard protocol response
makeResponse :: Text -> Text -> Text -> Maybe Text -> Value
makeResponse op result extra mExtraData = object $
  [ "type"      .= ("RESPONSE" :: Text)
  , "operation" .= op
  , "result"    .= result
  , "extra"     .= extra
  ] ++ maybe [] (\d -> ["data" .= d]) mExtraData

-- | Invalid request response
makeInvalid :: Text -> Value
makeInvalid reason = object
  [ "type"      .= ("RESPONSE" :: Text)
  , "operation" .= ("INVALID" :: Text)
  , "result"    .= reason
  ]

-- | NEW_USER notification
makeNewUser :: Text -> Value
makeNewUser uname = object
  [ "type"     .= ("NEW_USER" :: Text)
  , "username" .= uname
  ]

-- | NEW_STATUS notification
makeNewStatus :: Text -> Status -> Value
makeNewStatus uname status = object
  [ "type"     .= ("NEW_STATUS" :: Text)
  , "username" .= uname
  , "status"   .= status
  ]

-- | USER_LIST notification (response to USERS)
makeUserList :: Map Text Status -> Value
makeUserList users = object
  [ "type"  .= ("USER_LIST" :: Text)
  , "users" .= users
  ]

-- | DISCONNECTED notification
makeDisconnected :: Text -> Value
makeDisconnected uname = object
  [ "type"     .= ("DISCONNECTED" :: Text)
  , "username" .= uname
  ]

-- | TEXT_FROM notification
makeTextFrom :: Text -> Text -> Value
makeTextFrom from msg = object
  [ "type"     .= ("TEXT_FROM" :: Text)
  , "username" .= from
  , "text"     .= msg
  ]

-- | PUBLIC_TEXT_FROM notification
makePublicTextFrom :: Text -> Text -> Value
makePublicTextFrom from msg = object
  [ "type"     .= ("PUBLIC_TEXT_FROM" :: Text)
  , "username" .= from
  , "text"     .= msg
  ]

-- | INVITATION notification
makeInvitation :: Text -> Text -> Value
makeInvitation host room = object
  [ "type"     .= ("INVITATION" :: Text)
  , "username" .= host
  , "roomname" .= room
  ]

-- | JOINED_ROOM notification
makeJoinedRoom :: Text -> Text -> Value
makeJoinedRoom room uname = object
  [ "type"     .= ("JOINED_ROOM" :: Text)
  , "roomname" .= room
  , "username" .= uname
  ]

-- | ROOM_USER_LIST notification
makeRoomUserList :: Text -> Map Text Status -> Value
makeRoomUserList room users = object
  [ "type"     .= ("ROOM_USER_LIST" :: Text)
  , "roomname" .= room
  , "users"    .= users
  ]

-- | ROOM_TEXT_FROM notification
makeRoomTextFrom :: Text -> Text -> Text -> Value
makeRoomTextFrom room from msg = object
  [ "type"     .= ("ROOM_TEXT_FROM" :: Text)
  , "roomname" .= room
  , "username" .= from
  , "text"     .= msg
  ]

-- | LEFT_ROOM notification
makeLeftRoom :: Text -> Text -> Value
makeLeftRoom room uname = object
  [ "type"     .= ("LEFT_ROOM" :: Text)
  , "roomname" .= room
  , "username" .= uname
  ]
