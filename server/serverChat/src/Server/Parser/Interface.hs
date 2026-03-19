{-# LANGUAGE MultiParamTypeClasses #-}

module Server.Parser.Interface
  (
    parseRequest
  )
where 

import qualified Server.Parser.ParserTypes as PT

import Data.Text.Encoding(decodeUtf8)

import Data.ByteString.Char8 (ByteString)

-- NOTE this is for production
--parseRequest :: ByteString -> Maybe Request
-- parseRequest = decode . fromStrict


parseRequest :: ByteString -> Maybe PT.Request
parseRequest req = Just $ PT.SendPublicText (decodeUtf8 req)
