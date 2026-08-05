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
  ( -- * Types
    Chip
  , InfoEvent

    -- * Unsafe Manual Resource Allocation
  , readInfoEvent
  , freeInfoEvent
  ) where

import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types

-- | Read a line info event from a chip.
-- Must be manually freed using 'freeInfoEvent'.
readInfoEvent :: Chip -> IO InfoEvent
readInfoEvent chip = unwrapOrThrow ReadInfoEventFailed (D.chipReadInfoEvent chip)

-- | Free an info event object.
freeInfoEvent :: InfoEvent -> IO ()
freeInfoEvent = D.infoEventFree
