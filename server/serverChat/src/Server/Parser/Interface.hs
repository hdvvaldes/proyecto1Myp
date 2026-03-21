{-# LANGUAGE MultiParamTypeClasses #-}

module Server.Parser.Interface
  (
    parseRequest
  )
where 

import qualified Server.Parser.ParserTypes as PT


import Data.ByteString.Char8 (ByteString)

import Data.Aeson (decode)
import qualified Data.ByteString.Lazy as BSL

parseRequest :: ByteString -> Maybe PT.Request
parseRequest req = decode (BSL.fromStrict req)
