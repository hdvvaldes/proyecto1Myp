{-# LANGUAGE OverloadedStrings #-}

module Main where

import qualified Server.Parser.Interface as PI
import qualified Server.Parser.ParserTypes as PT
import qualified Server.ProtocolCodec as PC
import Server.ServerTypes (Status (..))

import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString as BS
import qualified Data.Map as Map

import System.Exit (exitFailure, exitSuccess)
import Data.ByteString (ByteString)

assert :: String -> Bool -> IO ()
assert label ok =
  if ok
    then pure ()
    else do
      putStrLn ("[FAIL] " ++ label)
      exitFailure

assertContains :: String -> ByteString -> String -> IO ()
assertContains label bs needle =
  let needleBs = BC.pack needle
   in assert label (needleBs `BS.isInfixOf` bs)

-- Note: Aeson has Key types in this environment; substring checks keep this
-- smoke test lightweight and dependency-free.
main :: IO ()
main = do
  -- parseRequest: IDENTIFY
  let identifyReq = BC.pack "{\"type\":\"IDENTIFY\",\"username\":\"Kimberly\"}"
  case PI.parseRequest identifyReq of
    Just (PT.Identify {PT.username = u}) ->
      assert "parse IDENTIFY username" (u == "Kimberly")
    other ->
      do
        putStrLn ("[FAIL] parse IDENTIFY: " ++ show other)
        exitFailure

  -- parseRequest: invalid JSON
  assert "parse invalid JSON => Nothing" (PI.parseRequest (BC.pack "{bad}") == Nothing)

  -- Response/event encoding smoke checks
  let newUserOut = PC.mkNewUser "Kimberly"
  assertContains "mkNewUser type" newUserOut "\"type\":\"NEW_USER\""
  assertContains "mkNewUser username" newUserOut "\"username\":\"Kimberly\""

  assertContains
    "mkNewStatus status field"
    (PC.mkNewStatus "Kimberly" ACTIVE)
    "\"status\":\"ACTIVE\""

  let users = Map.fromList [("Kimberly", ACTIVE), ("Luis", BUSY)]
  assertContains "mkUserList users object" (PC.mkUserList users) "\"Kimberly\":\"ACTIVE\""
  assertContains "mkUserList users object 2" (PC.mkUserList users) "\"Luis\":\"BUSY\""

  putStrLn "[OK] Protocol smoke checks passed."
  exitSuccess

