-- |
-- Module      : Fuyu.GPIO.Chip.Info
-- Description : Read-only metadata query functions for ChipInfo.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- This module provides functions to inspect 'ChipInfo' snapshots.
-- It is designed to be imported qualified:
--
-- @
-- import qualified Fuyu.GPIO.Chip.Info as ChipInfo
-- @
module Fuyu.GPIO.Chip.Info
  ( -- * Types
    ChipInfo

    -- * Managed Resource Allocation
  , withChipInfo

    -- * Metadata Accessors
  , name
  , label
  , numLines
  ) where

import Control.Exception (bracket)
import Data.ByteString (ByteString)
import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Chip.Info.Unsafe (chipInfo, freeChipInfo)
import Fuyu.GPIO.Types

-- | Retrieve information about a GPIO chip and free it automatically afterwards.
withChipInfo :: Chip -> (ChipInfo -> IO a) -> IO a
withChipInfo chip = bracket (chipInfo chip) freeChipInfo

-- | Get the name of the GPIO chip (e.g. "gpiochip4").
name :: ChipInfo -> IO ByteString
name = D.chipInfoName

-- | Get the label of the GPIO chip.
label :: ChipInfo -> IO ByteString
label = D.chipInfoLabel

-- | Get the total number of lines exposed by the GPIO chip.
numLines :: ChipInfo -> IO Word
numLines = D.chipInfoNumLines
