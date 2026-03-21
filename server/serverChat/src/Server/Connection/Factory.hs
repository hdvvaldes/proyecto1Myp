{-# LANGUAGE OverloadedStrings #-}

module Server.Connection.Factory
  ( makeResponse
  , makeError
  , makeNotification
  ) where

import Data.Aeson (Value, object, (.=))
import Data.Text (Text)

-- | Creates a standard response JSON.
makeResponse :: Text -> Value
makeResponse msg = object
  [ "type" .= ("RESPONSE" :: Text)
  , "content" .= msg
  ]

-- | Creates an error JSON.
makeError :: Text -> Value
makeError err = object
  [ "type" .= ("ERROR" :: Text)
  , "message" .= err
  ]

-- | Creates a notification JSON (e.g., for broadcast).
makeNotification :: Text -> Text -> Value
makeNotification sender msg = object
  [ "type" .= ("NOTIFICATION" :: Text)
  , "sender" .= sender
  , "content" .= msg
  ]
