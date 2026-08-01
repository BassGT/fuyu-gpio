-- |
-- Module      : Fuyu.GPIO
-- Description : High-level, type-safe Haskell interface for Linux GPIO (libgpiod v2).
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux GPIO character device interface)
--
-- This is the main umbrella module for @fuyu-gpio@, providing high-level,
-- managed resource wrappers ('withChip', 'withSettings', 'withConfig', 'withRequest')
-- and exception handling ('GpioException') for Linux GPIO character devices.
--
-- For detailed metadata inspection, import "Fuyu.GPIO.Chip.Info" or "Fuyu.GPIO.Line.Info" qualified.
-- For manual/unmanaged FFI resource lifecycle, import the corresponding @.Unsafe@ submodules.
module Fuyu.GPIO
  ( -- * Domain Modules
    module Fuyu.GPIO.Chip
  , module Fuyu.GPIO.Line
  , module Fuyu.GPIO.RequestConfig
  , module Fuyu.GPIO.EdgeEvent

    -- * Exception Types
  , GpioException(..)
  ) where

import Fuyu.GPIO.Chip
import Fuyu.GPIO.Line
import Fuyu.GPIO.RequestConfig
import Fuyu.GPIO.EdgeEvent
import Fuyu.GPIO.Exception (GpioException(..))
