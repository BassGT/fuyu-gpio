-- |
-- Module      : Fuyu.GPIO.Chip
-- Description : High-level operations for GPIO chips and line watching.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- This module provides managed resource brackets ('withChip') for opening and closing
-- Linux GPIO chips safely, as well as functions for watching line status changes.
module Fuyu.GPIO.Chip
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

    -- * Operations & Brackets
  , withChip
  , withChipInfo
  , withLineInfo
  , chipPath
  , lineOffsetFromName
  , getChipFd

    -- * Line Watch & Info Events
  , watchLineInfo
  , unwatchLineInfo
  , waitInfoEvent
  , withInfoEvent
  , getInfoEventType
  , getInfoEventTimestamp
  , getInfoEventLineInfo

    -- * General Utilities
  , isGPIOChip
  , gpiodAPIVersion
  ) where

import Control.Exception (bracket)
import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as BS8
import System.Posix.Types (Fd)
import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Chip.Info (withChipInfo)
import Fuyu.GPIO.Line.Info (withLineInfo)
import Fuyu.GPIO.Chip.Unsafe (openChip, closeChip, readInfoEvent, freeInfoEvent)
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types

-- | Open a GPIO chip by filesystem path (e.g. "/dev/gpiochip0") and automatically close it when finished.
withChip :: FilePath -> (Chip -> IO a) -> IO a
withChip path = bracket (openChip path) closeChip

-- | Retrieve chip filesystem path as a 'ByteString'.
chipPath :: Chip -> IO ByteString
chipPath chip = unwrapOrThrow ChipInfoFailed (D.chipPath chip)

-- | Map a GPIO line name (e.g. "GPIO17") to its numeric 'Offset' on the chip.
lineOffsetFromName :: Chip -> ByteString -> IO Offset
lineOffsetFromName chip name = unwrapOrThrow LineInfoFailed (D.chipLineOffsetFromName chip name)

-- | Get the underlying Linux file descriptor associated with the GPIO chip handle.
getChipFd :: Chip -> IO Fd
getChipFd = D.chipFd

--------------------------------------------------------------------------------
-- Line Watch & Info Events
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- General Utilities
--------------------------------------------------------------------------------

-- | Check if the given filesystem path is a valid GPIO chip character device.
isGPIOChip :: FilePath -> IO Bool
isGPIOChip = D.isGPIOChip . BS8.pack

-- | Retrieve the underlying libgpiod C API version string (e.g. "2.1").
gpiodAPIVersion :: IO ByteString
gpiodAPIVersion = D.gpiodAPIVersion
