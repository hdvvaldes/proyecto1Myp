{-# LANGUAGE MultiParamTypeClasses #-}

module Server.Parser.Interface
  (
    parseRequest
  )
where 

import Server.Parser.ParserTypes (Request (SendPublicText))
import Data.Aeson (decode)
import Data.ByteString.Lazy (fromStrict)
import Data.ByteString.Char8 (ByteString)

-- NOTE this is for production
--parseRequest :: ByteString -> Maybe Request
--parseRequest = decode . fromStrict

parseRequest :: ByteString -> Maybe Request
parseRequest = Just SendPublicText



