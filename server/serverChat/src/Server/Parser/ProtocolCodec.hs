{-# LANGUAGE OverloadedStrings #-}

module Server.Parser.ProtocolCodec
  ( mkResponse,
    mkNewUser,
    mkNewStatus,
    mkUserList,
    mkTextFrom,
    mkPublicTextFrom,
    mkNewRoomResponse,
    mkInvitation,
    mkJoinedRoom,
    mkRoomUserList,
    mkRoomTextFrom,
    mkLeftRoom,
    mkDisconnected
  )
where

import qualified Data.Aeson as Aeson
import Data.Aeson ((.=))
import qualified Data.Aeson.Key as AesonKey
import qualified Data.Aeson.Types as AesonTypes
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as LBS
import qualified Data.Map as Map
import Data.ByteString (ByteString)
import Data.Text (Text)
import qualified Data.Text as T

import Server.ServerTypes (RoomName, Status (..), Username)

encodeValue :: AesonTypes.Value -> ByteString
encodeValue v = LBS.toStrict (Aeson.encode v)

statusToText :: Status -> Text
statusToText ACTIVE = "ACTIVE"
statusToText AWAY = "AWAY"
statusToText BUSY = "BUSY"

mkResponse :: Text -> Text -> Maybe Text -> ByteString
mkResponse operation result mExtra =
  let base =
        [ "type" .= ("RESPONSE" :: Text),
          "operation" .= operation,
          "result" .= result
        ]
      extraFields =
        case mExtra of
          Nothing -> []
          Just extra -> [ "extra" .= extra ]
      v = Aeson.object (base ++ extraFields)
   in encodeValue v

mkNewUser :: Username -> ByteString
mkNewUser username =
  encodeValue $
    Aeson.object
      [ "type" .= ("NEW_USER" :: Text),
        "username" .= T.pack username
      ]

mkNewStatus :: Username -> Status -> ByteString
mkNewStatus username st =
  encodeValue $
    Aeson.object
      [ "type" .= ("NEW_STATUS" :: Text),
        "username" .= T.pack username,
        "status" .= statusToText st
      ]

mkUserList :: Map.Map Username Status -> ByteString
mkUserList users =
  let usersObj =
        Aeson.object
          [ AesonKey.fromText (T.pack username) .= statusToText st
            | (username, st) <- Map.toList users
          ]
   in encodeValue $
        Aeson.object
          [ "type" .= ("USER_LIST" :: Text),
            "users" .= usersObj
          ]

mkTextFrom :: Username -> Text -> ByteString
mkTextFrom sender text =
  encodeValue $
    Aeson.object
      [ "type" .= ("TEXT_FROM" :: Text),
        "username" .= T.pack sender,
        "text" .= text
      ]

mkPublicTextFrom :: Username -> Text -> ByteString
mkPublicTextFrom sender text =
  encodeValue $
    Aeson.object
      [ "type" .= ("PUBLIC_TEXT_FROM" :: Text),
        "username" .= T.pack sender,
        "text" .= text
      ]

-- Convenience for `RESPONSE` with operation = NEW_ROOM.
mkNewRoomResponse :: Text -> Text -> ByteString
mkNewRoomResponse result extra =
  mkResponse "NEW_ROOM" result (Just extra)

mkInvitation :: Username -> RoomName -> ByteString
mkInvitation inviter roomName =
  encodeValue $
    Aeson.object
      [ "type" .= ("INVITATION" :: Text),
        "username" .= T.pack inviter,
        "roomname" .= T.pack roomName
      ]

mkJoinedRoom :: RoomName -> Username -> ByteString
mkJoinedRoom roomName username =
  encodeValue $
    Aeson.object
      [ "type" .= ("JOINED_ROOM" :: Text),
        "roomname" .= T.pack roomName,
        "username" .= T.pack username
      ]

mkRoomUserList :: RoomName -> Map.Map Username Status -> ByteString
mkRoomUserList roomName users =
  let usersObj =
        Aeson.object
          [ AesonKey.fromText (T.pack username) .= statusToText st
            | (username, st) <- Map.toList users
          ]
   in encodeValue $
        Aeson.object
          [ "type" .= ("ROOM_USER_LIST" :: Text),
            "roomname" .= T.pack roomName,
            "users" .= usersObj
          ]

mkRoomTextFrom :: RoomName -> Username -> Text -> ByteString
mkRoomTextFrom roomName sender text =
  encodeValue $
    Aeson.object
      [ "type" .= ("ROOM_TEXT_FROM" :: Text),
        "roomname" .= T.pack roomName,
        "username" .= T.pack sender,
        "text" .= text
      ]

mkLeftRoom :: RoomName -> Username -> ByteString
mkLeftRoom roomName username =
  encodeValue $
    Aeson.object
      [ "type" .= ("LEFT_ROOM" :: Text),
        "roomname" .= T.pack roomName,
        "username" .= T.pack username
      ]

mkDisconnected :: Username -> ByteString
mkDisconnected username =
  encodeValue $
    Aeson.object
      [ "type" .= ("DISCONNECTED" :: Text),
        "username" .= T.pack username
      ]

