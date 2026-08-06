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
  , ReadyChip(..)
  , readyToChip
  , WaitResult(..)
  , LineInfo
  , Offset
  , offset
  , pattern Offset
  , Timeout
  , pattern Nanoseconds
  , pattern Immediate
  , pattern Infinite
  , Timestamp
  , InfoEvent
  , InfoEventType
  , pattern Requested
  , pattern Released
  , pattern ConfigChanged

    -- * Managed Brackets
  , withWatchLineInfo
  , withInfoEvent

    -- * Line Watch Operations
  , waitInfoEvent

    -- * InfoEvent Accessors
  , getInfoEventType
  , getInfoEventTimestamp
  , getInfoEventLineInfo
  ) where

import Control.Exception (bracket)
import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Chip.Watch.Unsafe (watchLineInfo, unwatchLineInfo, readInfoEvent, freeInfoEvent)
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types

-- | Start watching a line for status change events (e.g. requested, released, reconfigured)
-- within a bracket, automatically unwatching the line when finished.
--
-- Passes the initial 'LineInfo' snapshot of the line to the callback.
withWatchLineInfo :: Chip -> Offset -> (LineInfo -> IO a) -> IO a
withWatchLineInfo chip offset' = bracket (watchLineInfo chip offset') (\_ -> unwatchLineInfo chip offset')

-- | Wait for status change info events on any of the watched lines on the chip until the specified timeout.
-- Throws 'WaitInfoEventFailed' on error.
waitInfoEvent :: Chip -> Timeout -> IO (WaitResult ReadyChip)
waitInfoEvent chip timeout = do
  res <- unwrapOrThrow WaitInfoEventFailed (D.chipWaitInfoEvent chip timeout)
  pure $ case res of
    D.EventReady -> EventReady (ReadyChip chip)
    D.Timeout    -> TimeoutResult

-- | Read a status change info event from a chip once 'waitInfoEvent' indicates it is ready,
-- and automatically free it afterwards.
withInfoEvent :: ReadyChip -> (InfoEvent -> IO a) -> IO a
withInfoEvent readyChip = bracket (readInfoEvent readyChip) freeInfoEvent

-- | Get the event type of an 'InfoEvent' ('LineRequested', 'LineReleased', 'LineConfigChanged').
getInfoEventType :: InfoEvent -> IO InfoEventType
getInfoEventType = D.infoEventType

-- | Get the timestamp in nanoseconds of an 'InfoEvent'.
getInfoEventTimestamp :: InfoEvent -> IO Timestamp
getInfoEventTimestamp = D.infoEventTimestamp

-- | Get the line info snapshot associated with an 'InfoEvent'.
getInfoEventLineInfo :: InfoEvent -> IO LineInfo
getInfoEventLineInfo = D.infoEventLineInfo
