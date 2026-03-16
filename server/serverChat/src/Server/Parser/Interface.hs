{-# LANGUAGE MultiParamTypeClasses #-}

module Server.Parser.Interface
  (
    parseInput
  )
where 

import Server.ServerTypes

type ServerAction = Maybe Action 

type Action = IO ()

parseInput :: Client -> Maybe a
parseInput c = Nothing



