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
  ( -- * Operations & Brackets
    withChip
  , withChipInfo
  , withLineInfo
  , path
  , offsetFromName
  , fd

    -- * Line Watch & Info Events
  , module Fuyu.GPIO.Chip.Watch

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
import Fuyu.GPIO.Chip.Unsafe (openChip, closeChip)
import Fuyu.GPIO.Chip.Watch
import Fuyu.GPIO.Exception

-- | Open a GPIO chip by filesystem path (e.g. "/dev/gpiochip0") and automatically close it when finished.
withChip :: FilePath -> (Chip -> IO a) -> IO a
withChip path' = bracket (openChip path') closeChip

-- | Retrieve chip filesystem path as a 'ByteString'.
path :: Chip -> IO ByteString
path chip = unwrapOrThrow ChipInfoFailed (D.chipPath chip)

-- | Map a GPIO line name (e.g. "GPIO17") to its numeric 'Offset' on the chip.
offsetFromName :: Chip -> ByteString -> IO Offset
offsetFromName chip name = unwrapOrThrow LineInfoFailed (D.chipLineOffsetFromName chip name)

-- | Get the underlying Linux file descriptor associated with the GPIO chip handle.
fd :: Chip -> IO Fd
fd = D.chipFd

--------------------------------------------------------------------------------
-- General Utilities
--------------------------------------------------------------------------------
-- General Utilities
--------------------------------------------------------------------------------

-- | Check if the given filesystem path is a valid GPIO chip character device.
isGPIOChip :: FilePath -> IO Bool
isGPIOChip = D.isGPIOChip . BS8.pack

-- | Retrieve the underlying libgpiod C API version string (e.g. "2.1").
gpiodAPIVersion :: IO ByteString
gpiodAPIVersion = D.gpiodAPIVersion
