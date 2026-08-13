{-# LANGUAGE PatternSynonyms #-}

-- |
-- Module      : Fuyu.GPIO.Chip.Watch
-- Description : Operations for watching GPIO line status events.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- This module provides managed resource brackets ('withWatchLine', 'withEvent')
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
  , withWatchLine
  , withEvent

    -- * Line Watch Operations
  , watchLine
  , unwatchLine
  , waitEvent

    -- * InfoEvent Accessors
  , eventType
  , timestampNs
  , lineInfo
  ) where

import Control.Exception (bracket)
import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Chip.Watch.Unsafe (readInfoEvent, freeInfoEvent)
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types hiding (eventType)

-- | Start watching a line for status change events (e.g. requested, released, reconfigured)
-- within a bracket, automatically unwatching the line when finished.
--
-- Passes the initial 'LineInfo' snapshot of the line to the callback.
withWatchLine :: Chip -> Offset -> (LineInfo -> IO a) -> IO a
withWatchLine chip offset' = bracket (watchLine chip offset') (\_ -> unwatchLine chip offset')

-- | Start watching a line for status change events (e.g. requested, released, reconfigured).
-- Returns the initial 'LineInfo' snapshot of the line.
watchLine :: Chip -> Offset -> IO LineInfo
watchLine chip offset' = unwrapOrThrow LineInfoFailed (D.chipWatchLineInfo chip offset')

-- | Stop watching a line for status change events.
unwatchLine :: Chip -> Offset -> IO ()
unwatchLine chip offset' = unwrapOrThrow LineInfoFailed (D.chipUnwatchLineInfo chip offset')

-- | Wait for status change info events on any of the watched lines on the chip until the specified timeout.
-- Throws 'WaitInfoEventFailed' on error.
waitEvent :: Chip -> Timeout -> IO (WaitResult ReadyChip)
waitEvent chip timeout = do
  res <- unwrapOrThrow WaitInfoEventFailed (D.chipWaitInfoEvent chip timeout)
  pure $ case res of
    D.EventReady -> EventReady (ReadyChip chip)
    D.Timeout    -> TimeoutResult

-- | Read a status change info event from a chip once 'waitEvent' indicates it is ready,
-- and automatically free it afterwards.
withEvent :: ReadyChip -> (InfoEvent -> IO a) -> IO a
withEvent readyChip = bracket (readInfoEvent readyChip) freeInfoEvent

-- | Get the event type of an 'InfoEvent' ('Requested', 'Released', 'ConfigChanged').
eventType :: InfoEvent -> IO InfoEventType
eventType = D.infoEventType

-- | Get the timestamp in nanoseconds of an 'InfoEvent'.
timestampNs :: InfoEvent -> IO Timestamp
timestampNs = D.infoEventTimestamp

-- | Get the line info snapshot associated with an 'InfoEvent'.
lineInfo :: InfoEvent -> IO LineInfo
lineInfo = D.infoEventLineInfo
