-- |
-- Module      : Fuyu.GPIO.Line.Info
-- Description : Read-only metadata query functions for LineInfo snapshots.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- This module provides functions to inspect 'LineInfo' snapshots.
-- It is designed to be imported qualified:
--
-- @
-- import qualified Fuyu.GPIO.Line.Info as LineInfo
-- @
module Fuyu.GPIO.Line.Info
  ( -- * Types
    LineInfo

    -- * Managed Resource Allocation
  , withLineInfo

    -- * Metadata Accessors
  , offset
  , name
  , isUsed
  , consumer
  , direction
  , edgeDetection
  , bias
  , drive
  , isActiveLow
  , isDebounced
  , debouncePeriod
  , eventClock
  ) where

import Control.Exception (bracket)
import Data.ByteString (ByteString)
import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Line.Info.Unsafe (getLineInfo, freeLineInfo)
import Fuyu.GPIO.Types

-- | Retrieve information about a specific line on a chip and free it automatically afterwards.
withLineInfo :: Chip -> Offset -> (LineInfo -> IO a) -> IO a
withLineInfo chip offset' = bracket (getLineInfo chip offset') freeLineInfo

-- | Get the numeric 'Offset' of the line from a 'LineInfo' snapshot.
offset :: LineInfo -> IO Offset
offset = D.lineInfoOffset

-- | Get the name of the line (e.g. "GPIO17"), if set.
name :: LineInfo -> IO (Maybe ByteString)
name = D.lineInfoName

-- | Check if the line is currently in use by a consumer kernel driver or user process.
isUsed :: LineInfo -> IO Bool
isUsed = D.lineInfoIsUsed

-- | Get the consumer name string of the line, if in use.
consumer :: LineInfo -> IO (Maybe ByteString)
consumer = D.lineInfoConsumer

-- | Get the configured direction of the line ('DirInput', 'DirOutput', 'DirAsIs').
direction :: LineInfo -> IO Direction
direction = D.lineInfoDirection

-- | Get the configured edge detection of the line ('EdgeNone', 'EdgeRising', 'EdgeFalling', 'EdgeBoth').
edgeDetection :: LineInfo -> IO Edge
edgeDetection = D.lineInfoEdgeDetection

-- | Get the configured electrical bias ('BiasDisabled', 'BiasPullUp', 'BiasPullDown', etc.).
bias :: LineInfo -> IO Bias
bias = D.lineInfoBias

-- | Get the configured drive mode ('PushPull', 'OpenDrain', 'OpenSource').
drive :: LineInfo -> IO Drive
drive = D.lineInfoDrive

-- | Check if active-low logic is configured for the line.
isActiveLow :: LineInfo -> IO Bool
isActiveLow = D.lineInfoIsActiveLow

-- | Check if hardware debounce is configured for the line.
isDebounced :: LineInfo -> IO Bool
isDebounced = D.lineInfoIsDebounced

-- | Get the debounce period in microseconds for the line.
debouncePeriod :: LineInfo -> IO Word
debouncePeriod = D.lineInfoDebouncePeriod

-- | Get the event clock source configured for the line ('Monotonic', 'Realtime', 'Hardware').
eventClock :: LineInfo -> IO Clock
eventClock = D.lineInfoEventClock
