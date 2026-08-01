-- |
-- Module      : Fuyu.GPIO.Chip.Unsafe
-- Description : Unsafe manual resource allocation for GPIO chips and info events.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- Manual resource allocation ('openChip', 'closeChip', 'readInfoEvent', 'freeInfoEvent')
-- for applications that cannot use managed bracket functions.
module Fuyu.GPIO.Chip.Unsafe
  ( -- * Types
    Chip
  , InfoEvent

    -- * Unsafe Manual Resource Allocation
  , openChip
  , closeChip
  , readInfoEvent
  , freeInfoEvent
  ) where

import qualified Data.ByteString.Char8 as BS8
import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types

-- | Open a GPIO chip by its filesystem path (e.g. "/dev/gpiochip4").
-- Must be manually closed using 'closeChip'.
openChip :: FilePath -> IO Chip
openChip path = unwrapOrThrow (ChipOpenFailed path) (D.chipOpen (BS8.pack path))

-- | Close a GPIO chip handle.
closeChip :: Chip -> IO ()
closeChip = D.chipClose

-- | Read a line info event from a chip.
-- Must be manually freed using 'freeInfoEvent'.
readInfoEvent :: Chip -> IO InfoEvent
readInfoEvent chip = unwrapOrThrow ReadInfoEventFailed (D.chipReadInfoEvent chip)

-- | Free an info event object.
freeInfoEvent :: InfoEvent -> IO ()
freeInfoEvent = D.infoEventFree
