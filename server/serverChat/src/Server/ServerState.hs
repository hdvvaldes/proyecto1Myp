{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}

module Server.ServerState 
  ( ServerState(..)
  , StateRooms(..)
  , newServerState
  , addUser
  , removeUser
  , findClient
  , updateUserStatus
  , getAllUsers
  , broadcast
  , getClientCount
  -- Room Management
  , createRoom
  , inviteToRoom
  , joinRoom
  , leaveRoom
  , getRoomUsers
  , broadcastToRoom
  ) where

import Server.ServerTypes
import qualified Data.Map as Map
import Control.Concurrent.STM (TVar, newTVar, STM, modifyTVar', readTVar, writeTChan)
import Control.Monad (forM_)
import Data.ByteString (ByteString)
import Data.Text (Text, pack)

data ServerState = 
  ServerState {
  stateClients :: Map.Map Username Client,
  stateRooms :: StateRooms
}

data StateRooms = 
  StateRooms {
    userRooms :: Map.Map RoomName Room
}

-- | Creates the initial server state.
newServerState :: STM (TVar ServerState)
newServerState = newTVar ServerState {
  stateClients = Map.empty,
  stateRooms = StateRooms { userRooms = Map.empty }
}

-- | Adds a new client to the server state.
addUser :: TVar ServerState -> Client -> STM ()
addUser stateVar client@Client{clientName} = 
  modifyTVar' stateVar $ \st -> st { 
    stateClients = Map.insert clientName client (stateClients st) 
  }

-- | Removes a client from the server state and all rooms.
removeUser :: TVar ServerState -> Username -> STM ()
removeUser stateVar uname = modifyTVar' stateVar $ \st ->
  let newClients = Map.delete uname (stateClients st)
      newRooms = Map.map (removeUserFromRoom uname) (userRooms (stateRooms st))
  in st { stateClients = newClients, stateRooms = (stateRooms st) { userRooms = newRooms } }

removeUserFromRoom :: Username -> Room -> Room
removeUserFromRoom uname room = room { 
  participants = filter (\c -> clientName c /= uname) (participants room),
  invitedUsers = filter (/= uname) (invitedUsers room)
}

-- | Finds a client by username.
findClient :: TVar ServerState -> Username -> STM (Maybe Client)
findClient stateVar uname = do
  st <- readTVar stateVar
  return $ Map.lookup uname (stateClients st)

-- | Updates a client's status.
updateUserStatus :: TVar ServerState -> Username -> Status -> STM ()
updateUserStatus stateVar uname newStatus = modifyTVar' stateVar $ \st ->
  let updateClient c = c { clientStatus = newStatus }
      newClients = Map.adjust updateClient uname (stateClients st)
  in st { stateClients = newClients }

-- | Returns a map of all usernames and their current status.
getAllUsers :: TVar ServerState -> STM (Map.Map Text Status)
getAllUsers stateVar = do
  st <- readTVar stateVar
  let userMap = stateClients st
  return $ Map.fromList $ Map.elems $ Map.mapWithKey (\k v -> (pack k, clientStatus v)) userMap

-- | Broadcasts a message to all connected clients.
broadcast :: TVar ServerState -> ByteString -> STM ()
broadcast stateVar msg = do
    currentState <- readTVar stateVar
    let allClients = Map.elems (stateClients currentState)
    forM_ allClients $ \client -> writeTChan (clientChan client) msg

-- | Returns the current number of connected clients.
getClientCount :: TVar ServerState -> STM Int
getClientCount stateVar = do
  st <- readTVar stateVar
  return $ Map.size (stateClients st)

-- ROOM MANAGEMENT ---

-- | Creates a new room.
createRoom :: TVar ServerState -> RoomName -> Username -> STM (Either String ())
createRoom stateVar rname ownerName = do
  st <- readTVar stateVar
  case Map.lookup rname (userRooms (stateRooms st)) of
    Just _ -> return $ Left "ROOM_ALREADY_EXISTS"
    Nothing -> do
      case Map.lookup ownerName (stateClients st) of
        Nothing -> return $ Left "NO_SUCH_USER"
        Just ownerClient -> do
          let newRoom = Room {
                roomName = rname,
                participants = [ownerClient],
                invitedUsers = [],
                owner = Just ownerName
              }
          modifyTVar' stateVar $ \s -> s {
            stateRooms = (stateRooms s) { 
              userRooms = Map.insert rname newRoom (userRooms (stateRooms s))
            }
          }
          return $ Right ()

-- | Invites a user to a room.
inviteToRoom :: TVar ServerState -> RoomName -> Username -> STM (Either String ())
inviteToRoom stateVar rname targetName = do
  st <- readTVar stateVar
  case Map.lookup rname (userRooms (stateRooms st)) of
    Nothing -> return $ Left "NO_SUCH_ROOM"
    Just room -> do
      case Map.lookup targetName (stateClients st) of
        Nothing -> return $ Left "NO_SUCH_USER"
        Just _ -> 
          if targetName `elem` invitedUsers room || any (\c -> clientName c == targetName) (participants room)
          then return $ Right () -- Already invited or in room
          else do
            let updatedRoom = room { invitedUsers = targetName : invitedUsers room }
            modifyTVar' stateVar $ \s -> s {
              stateRooms = (stateRooms s) {
                userRooms = Map.insert rname updatedRoom (userRooms (stateRooms s))
              }
            }
            return $ Right ()

-- | Joins a user to a room.
joinRoom :: TVar ServerState -> RoomName -> Username -> STM (Either String ())
joinRoom stateVar rname uname = do
  st <- readTVar stateVar
  case Map.lookup rname (userRooms (stateRooms st)) of
    Nothing -> return $ Left "NO_SUCH_ROOM"
    Just room -> 
      if uname `notElem` invitedUsers room
      then return $ Left "NOT_INVITED"
      else case Map.lookup uname (stateClients st) of
        Nothing -> return $ Left "NO_SUCH_USER"
        Just client -> do
          let updatedRoom = room { 
                participants = client : participants room,
                invitedUsers = filter (/= uname) (invitedUsers room)
              }
          modifyTVar' stateVar $ \s -> s {
            stateRooms = (stateRooms s) {
              userRooms = Map.insert rname updatedRoom (userRooms (stateRooms s))
            }
          }
          return $ Right ()

-- | Leaves a room.
leaveRoom :: TVar ServerState -> RoomName -> Username -> STM (Either String ())
leaveRoom stateVar rname uname = do
  st <- readTVar stateVar
  case Map.lookup rname (userRooms (stateRooms st)) of
    Nothing -> return $ Left "NO_SUCH_ROOM"
    Just room -> 
      if all (\c -> clientName c /= uname) (participants room)
      then return $ Left "NOT_JOINED"
      else do
        let newParticipants = filter (\c -> clientName c /= uname) (participants room)
            updatedRoom = room { participants = newParticipants }
        modifyTVar' stateVar $ \s -> 
          if null newParticipants
          then s { stateRooms = (stateRooms s) { userRooms = Map.delete rname (userRooms (stateRooms s)) } }
          else s { stateRooms = (stateRooms s) { userRooms = Map.insert rname updatedRoom (userRooms (stateRooms s)) } }
        return $ Right ()

-- | Returns users in a room.
getRoomUsers :: TVar ServerState -> RoomName -> Username -> STM (Either String (Map.Map Text Status))
getRoomUsers stateVar rname uname = do
  st <- readTVar stateVar
  case Map.lookup rname (userRooms (stateRooms st)) of
    Nothing -> return $ Left "NO_SUCH_ROOM"
    Just room -> 
      if all (\c -> clientName c /= uname) (participants room)
      then return $ Left "NOT_JOINED"
      else do
        let userMap = Map.fromList $ map (\c -> (pack (clientName c), clientStatus c)) (participants room)
        return $ Right userMap

-- | Broadcasts a message to all users in a room.
broadcastToRoom :: TVar ServerState -> RoomName -> ByteString -> STM ()
broadcastToRoom stateVar rname msg = do
  st <- readTVar stateVar
  case Map.lookup rname (userRooms (stateRooms st)) of
    Nothing -> return ()
    Just room -> forM_ (participants room) $ \client -> writeTChan (clientChan client) msg
