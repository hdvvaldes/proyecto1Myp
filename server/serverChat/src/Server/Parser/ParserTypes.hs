module Server.Parser.ParserTypes 
  (
  )
where 

import Server.ServerTypes

newtype IDENTIFY = 
  IDENTIFY {
    runAction :: Maybe Client 
}



