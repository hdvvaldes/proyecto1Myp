{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- | A custom implementation of the ReaderT monad transformer.
-- This module defines a ReaderT type that allows threading an environment 'e'
-- through a computation in another monad 'm'.
module Extra.ReaderT
  ( ReaderT,
    runReaderT,
    ask,
    lift,
  )
where

import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Reader.Class (MonadReader, ask, local)
import Control.Monad.Trans.Class (MonadTrans, lift)

-- | The ReaderT type.
-- It wraps a function that takes an environment 'e' and returns a computation in 'm a'.
newtype ReaderT e m a
  = ReaderT {runReaderT :: e -> m a}

-- | Functor instance for ReaderT.
-- Allows mapping a function over the result of the computation.
instance (Functor m) => Functor (ReaderT e m) where
  fmap f (ReaderT res) =
    ReaderT $ \env -> fmap f (res env)

-- | Applicative instance for ReaderT.
-- Allows applying a function wrapped in ReaderT to a value wrapped in ReaderT.
instance (Applicative m) => Applicative (ReaderT e m) where
  pure a = ReaderT $ \_ -> pure a
  ReaderT f <*> ReaderT a = ReaderT $ \env ->
    f env <*> a env

-- | Monad instance for ReaderT.
-- Allows sequencing computations where the next computation depends on the result of the previous one.
instance (Monad m) => Monad (ReaderT e m) where
  -- funcA : e -> m a
  -- t: a -> (e -> m b)
  -- return. ReaderT e -> m b
  ReaderT funcA >>= t =
    ReaderT $ \env ->
      let fstRes = funcA env
       in fstRes >>= \x -> runReaderT (t x) env

-- | MonadReader instance for ReaderT.
-- Provides 'ask' to retrieve the environment and 'local' to run a computation in a modified environment.
instance (Monad m) => MonadReader e (ReaderT e m) where
  ask = ReaderT return
  local modE (ReaderT res1) = ReaderT $ res1 . modE

-- | MonadTrans instance for ReaderT.
-- Allows lifting a computation from the underlying monad 'm' into ReaderT.
instance MonadTrans (ReaderT a) where
  lift res = ReaderT $ const res

-- | MonadIO instance for ReaderT.
-- Allows performing IO actions within the ReaderT monad if the underlying monad is IO.
instance MonadIO (ReaderT e IO) where
  liftIO = lift
