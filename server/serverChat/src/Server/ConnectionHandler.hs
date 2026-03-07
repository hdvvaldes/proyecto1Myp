-- | Server.ConnectionHandler module: Handles per-client connection logic.

module Server.ConnectionHandler (
  runConn
) where

import Network.Socket (Socket, SockAddr, socketToHandle)
import GHC.IO.Handle (Handle, hSetBuffering, BufferMode (LineBuffering), hGetLine)
import GHC.IO.IOMode (IOMode(ReadWriteMode))
import GHC.IO.Handle.Text (hPutStrLn)

-- | Entry point for handling a new connection.
-- Converts the Socket to a Handle for easier line-based I/O and starts the echo loop.
runConn :: (Socket, SockAddr) -> IO ()
runConn (s, _) = do 
  -- Convert socket to Handle with ReadWriteMode
  hdl <- socketToHandle s ReadWriteMode
  -- Enable line-buffering to ensure prompt delivery of messages
  hSetBuffering hdl LineBuffering
  -- Enter the echo loop
  echoInput hdl

-- | Reads a single line from the handle and writes it back.
echoInput :: Handle -> IO ()
echoInput hdl = do 
  -- Read a line (awaits input from client)
  msg <- hGetLine hdl
  -- Write the same line back to the client
  hPutStrLn hdl msg
