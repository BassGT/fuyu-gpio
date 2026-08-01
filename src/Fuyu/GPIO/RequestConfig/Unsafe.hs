-- |
-- Module      : Fuyu.GPIO.RequestConfig.Unsafe
-- Description : Unsafe manual resource allocation for RequestConfig.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- Manual resource allocation ('newRequestConfig', 'freeRequestConfig') for 'RequestConfig' handles.
module Fuyu.GPIO.RequestConfig.Unsafe
  ( -- * Types
    RequestConfig

    -- * Unsafe Manual Resource Allocation
  , newRequestConfig
  , freeRequestConfig
  ) where

import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types

-- | Allocate a new request configuration object.
-- Must be manually freed with 'freeRequestConfig'.
newRequestConfig :: IO RequestConfig
newRequestConfig = unwrapOrThrow RequestConfigNewFailed D.requestConfigNew

-- | Free a request configuration object.
freeRequestConfig :: RequestConfig -> IO ()
freeRequestConfig = D.requestConfigFree
