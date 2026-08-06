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
  , watchLineInfo
  , unwatchLineInfo
  , readInfoEvent
  , freeInfoEvent
  ) where

import qualified Data.ByteString.Char8 as BS8
import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Chip.Watch.Unsafe (watchLineInfo, unwatchLineInfo, readInfoEvent, freeInfoEvent)
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types

-- | Open a GPIO chip by its filesystem path (e.g. "/dev/gpiochip4").
-- Must be manually closed using 'closeChip'.
openChip :: FilePath -> IO Chip
openChip path = unwrapOrThrow (ChipOpenFailed path) (D.chipOpen (BS8.pack path))

-- | Close a GPIO chip handle.
closeChip :: Chip -> IO ()
closeChip = D.chipClose

