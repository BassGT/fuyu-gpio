-- |
-- Module      : Fuyu.GPIO.Chip.Info.Unsafe
-- Description : Unsafe manual resource allocation for ChipInfo.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- Manual resource allocation ('getChipInfo', 'freeChipInfo') for 'ChipInfo' handles.
module Fuyu.GPIO.Chip.Info.Unsafe
  ( -- * Types
    ChipInfo

    -- * Unsafe Manual Resource Allocation
  , getChipInfo
  , freeChipInfo
  ) where

import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types

-- | Retrieve chip info directly.
-- Must be manually freed using 'freeChipInfo'.
getChipInfo :: Chip -> IO ChipInfo
getChipInfo chip = unwrapOrThrow ChipInfoFailed (D.chipInfo chip)

-- | Free a 'ChipInfo' handle.
freeChipInfo :: ChipInfo -> IO ()
freeChipInfo = D.chipInfoFree
