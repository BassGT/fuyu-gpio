-- |
-- Module      : Fuyu.GPIO.Chip.Watch.Unsafe
-- Description : Unsafe manual resource allocation for line info events.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- Manual resource allocation ('readInfoEvent', 'freeInfoEvent')
-- for applications that cannot use managed bracket functions.
module Fuyu.GPIO.Chip.Watch.Unsafe
  ( -- * Types & Security Token
    Chip
  , ReadyChip(..)
  , readyToChip
  , InfoEvent
  , LineInfo
  , Offset

    -- * Unsafe Manual Resource Allocation
  , watchLineInfo
  , unwatchLineInfo
  , readInfoEvent
  , freeInfoEvent
  ) where

import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types

-- | Start watching a line for status change events (e.g. requested, released, reconfigured).
-- Returns the initial 'LineInfo' snapshot of the line.
-- Must be manually unwatched using 'unwatchLineInfo'.
watchLineInfo :: Chip -> Offset -> IO LineInfo
watchLineInfo chip offset' = unwrapOrThrow LineInfoFailed (D.chipWatchLineInfo chip offset')

-- | Stop watching a line for status change events.
unwatchLineInfo :: Chip -> Offset -> IO ()
unwatchLineInfo chip offset' = unwrapOrThrow LineInfoFailed (D.chipUnwatchLineInfo chip offset')

-- | Read a line info event from a chip after 'Fuyu.GPIO.Chip.Watch.waitInfoEvent' confirms it is ready.
-- Must be manually freed using 'freeInfoEvent'.
readInfoEvent :: ReadyChip -> IO InfoEvent
readInfoEvent (ReadyChip chip) = unwrapOrThrow ReadInfoEventFailed (D.chipReadInfoEvent chip)

-- | Free an info event object.
freeInfoEvent :: InfoEvent -> IO ()
freeInfoEvent = D.infoEventFree
