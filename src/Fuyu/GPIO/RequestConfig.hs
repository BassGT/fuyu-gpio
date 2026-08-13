-- |
-- Module      : Fuyu.GPIO.RequestConfig
-- Description : Managed resource operations for line request configurations.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- Managed configuration options (consumer name, kernel event buffer size) for line requests.
module Fuyu.GPIO.RequestConfig
  ( RequestConfig
  , KernelBufferSize
  , withRequestConfig
  , setConsumer
  , consumer
  , setBufferSize
  , bufferSize
  ) where

import Control.Exception (bracket)
import Data.ByteString (ByteString)
import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.RequestConfig.Unsafe (newRequestConfig, freeRequestConfig)
import Fuyu.GPIO.Types

-- | Allocate a new request configuration object and free it automatically afterwards.
withRequestConfig :: (RequestConfig -> IO a) -> IO a
withRequestConfig = bracket newRequestConfig freeRequestConfig

-- | Set consumer name for request config.
setConsumer :: RequestConfig -> ByteString -> IO ()
setConsumer = D.requestConfigSetConsumer

-- | Get consumer name from request config.
consumer :: RequestConfig -> IO ByteString
consumer = D.requestConfigConsumer

-- | Set kernel event buffer size for request config. Pass 0 to use kernel default (64).
setBufferSize :: RequestConfig -> KernelBufferSize -> IO ()
setBufferSize = D.requestConfigSetEventBufferSize

-- | Get kernel event buffer size from request config.
bufferSize :: RequestConfig -> IO KernelBufferSize
bufferSize = D.requestConfigEventBufferSize
