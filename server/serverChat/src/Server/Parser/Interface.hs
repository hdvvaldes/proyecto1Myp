{-# LANGUAGE MultiParamTypeClasses #-}

module Server.Parser.Interface
  (
    parseInput
  )
where 

import Server.ServerTypes

type Input = String

parseInput :: Input -> Int
parseInput = const 1



