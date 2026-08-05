{-# LANGUAGE PatternSynonyms #-}

-- |
-- Module      : Fuyu.GPIO.Chip.Watch
-- Description : Operations for watching GPIO line status events.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- This module provides managed resource brackets ('withWatchLineInfo', 'withInfoEvent')
-- and functions for watching line status changes (e.g. requested, released, reconfigured).
--
-- It is designed to be imported qualified or used via top-level "Fuyu.GPIO":
--
-- @
-- import qualified Fuyu.GPIO.Chip.Watch as Watch
-- @
module Fuyu.GPIO.Chip.Watch
  ( -- * Types & Patterns
    Chip
  , LineInfo
  , Offset
  , offset
  , pattern Offset
  , InfoEvent
  , InfoEventType
  , pattern LineRequested
  , pattern LineReleased
  , pattern LineConfigChanged

    -- * Managed Brackets
  , withWatchLineInfo
  , withInfoEvent

    -- * Line Watch Operations
  , watchLineInfo
  , unwatchLineInfo
  , waitInfoEvent

    -- * InfoEvent Accessors
  , getInfoEventType
  , getInfoEventTimestamp
  , getInfoEventLineInfo
  ) where

import Control.Exception (bracket)
import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Chip.Watch.Unsafe (readInfoEvent, freeInfoEvent)
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types

-- | Start watching a line for status change events (e.g. requested, released, reconfigured)
-- within a bracket, automatically unwatching the line when finished.
--
-- Passes the initial 'LineInfo' snapshot of the line to the callback.
withWatchLineInfo :: Chip -> Offset -> (LineInfo -> IO a) -> IO a
withWatchLineInfo chip offset' = bracket (watchLineInfo chip offset') (\_ -> unwatchLineInfo chip offset')

-- | Start watching a line for status change events (e.g. requested, released, reconfigured).
-- Returns the initial 'LineInfo' snapshot of the line.
watchLineInfo :: Chip -> Offset -> IO LineInfo
watchLineInfo chip offset' = unwrapOrThrow LineInfoFailed (D.chipWatchLineInfo chip offset')

-- | Stop watching a line for status change events.
unwatchLineInfo :: Chip -> Offset -> IO ()
unwatchLineInfo chip offset' = unwrapOrThrow LineInfoFailed (D.chipUnwatchLineInfo chip offset')

-- | Wait for status change info events on a watched line.
-- Returns 'True' if an event is ready, or 'False' if the timeout expired.
waitInfoEvent :: Chip -> Timeout -> IO Bool
waitInfoEvent chip timeout = do
  res <- unwrapOrThrow WaitInfoEventFailed (D.chipWaitInfoEvent chip timeout)
  pure $ case res of
    D.EventReady -> True
    D.Timeout    -> False

-- | Read a status change info event from a chip and automatically free it afterwards.
withInfoEvent :: Chip -> (InfoEvent -> IO a) -> IO a
withInfoEvent chip = bracket (readInfoEvent chip) freeInfoEvent

-- | Get the event type of an 'InfoEvent' ('LineRequested', 'LineReleased', 'LineConfigChanged').
getInfoEventType :: InfoEvent -> IO InfoEventType
getInfoEventType = D.infoEventType

-- | Get the timestamp in nanoseconds of an 'InfoEvent'.
getInfoEventTimestamp :: InfoEvent -> IO Timestamp
getInfoEventTimestamp = D.infoEventTimestamp

-- | Get the line info snapshot associated with an 'InfoEvent'.
getInfoEventLineInfo :: InfoEvent -> IO LineInfo
getInfoEventLineInfo = D.infoEventLineInfo
