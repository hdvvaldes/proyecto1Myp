-- | Server.ConnectionHandler module: Handles per-client connection logic.

module Server.ConnectionHandler (
  runConn
) where

import Network.Socket (Socket, SockAddr, socketToHandle)
import GHC.IO.Handle (Handle, hSetBuffering, BufferMode (LineBuffering), hGetLine)
import GHC.IO.IOMode (IOMode(ReadWriteMode))
import GHC.IO.Handle.Text (hPutStrLn)
import Control.Concurrent.STM
import qualified Data.Map.Strict as M


-- | Entry point for handling a new connection.
-- Converts the Socket to a Handle for easier line-based I/O and starts the echo loop.

data User = User {
  name :: String, 
  subject :: Handle,
  -- The user is listening to preachers
  preachers :: [Handle]
}

type UserMap = M.Map String User
type UserConn = (Socket, SockAddr)

userSetUp :: Handle -> IO User
userSetUp user = do 

    -- Asks for name
    -- Create User

generalChannel :: Handle 
generalChannel = undefined



runConn :: UserConn -> IO()
runConn (s, _) = do 
  -- Convert socket to Handle with ReadWriteMode
  hdl <- socketToHandle s ReadWriteMode
  -- Enable line-buffering to ensure prompt delivery of messages
  hSetBuffering hdl LineBuffering
  user <- userSetUp hdl
  -- add user to map
  -- with default preachers
  -- Start user listening to the general chat
  -- action <- parse entry
  -- relaizeAction action

-- | Reads a single line from the handle and writes it back.
echoInput :: Handle -> IO ()
echoInput hdl = do 
  -- Read a line (awaits input from client)
  msg <- hGetLine hdl
  -- Write the same line back to the client
  hPutStrLn hdl msg
