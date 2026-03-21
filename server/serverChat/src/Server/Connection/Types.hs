{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE NamedFieldPuns #-}

module Server.Connection.Types
  ( HandlerEnv(..)
  , ConnHandler(..)
  , runConnHandler
  , UserConn
  ) where

import Control.Concurrent.STM (TVar)
import Control.Monad.Reader (ReaderT, MonadReader)
import Control.Monad.IO.Class (MonadIO)
import Control.Monad.IO.Unlift (MonadUnliftIO)
import Network.Socket (Socket, SockAddr)
import Server.ServerState (ServerState)
import Server.ServerTypes (Client)

data HandlerEnv = HandlerEnv
  { serverState :: TVar ServerState
  , handlerClient :: Maybe Client
  }

newtype ConnHandler a = ConnHandler
  { runConnHandler :: ReaderT HandlerEnv IO a
  } deriving ( Functor
             , Applicative
             , Monad
             , MonadReader HandlerEnv
             , MonadIO
             , MonadUnliftIO
             )

type UserConn = (Socket, SockAddr)
