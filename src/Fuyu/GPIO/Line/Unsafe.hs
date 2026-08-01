-- |
-- Module      : Fuyu.GPIO.Line.Unsafe
-- Description : Unsafe manual resource allocation for line settings, config, and requests.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- Manual resource allocation ('newSettings', 'freeSettings', 'newConfig', 'freeConfig',
-- 'requestLines', 'releaseRequest') for line settings, configs, and requests.
module Fuyu.GPIO.Line.Unsafe
  ( -- * Types
    Chip
  , Settings
  , Config
  , Request
  , RequestConfig

    -- * Unsafe Manual Resource Allocation
  , newSettings
  , freeSettings
  , newConfig
  , freeConfig
  , requestLines
  , releaseRequest
  ) where

import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types

-- | Allocate a new line settings object.
-- Must be manually freed with 'freeSettings'.
newSettings :: IO Settings
newSettings = unwrapOrThrow LineSettingsNewFailed D.lineSettingsNew

-- | Free a line settings object.
freeSettings :: Settings -> IO ()
freeSettings = D.lineSettingsFree

-- | Allocate a new line configuration object.
-- Must be manually freed with 'freeConfig'.
newConfig :: IO Config
newConfig = unwrapOrThrow LineConfigNewFailed D.lineConfigNew

-- | Free a line configuration object.
freeConfig :: Config -> IO ()
freeConfig = D.lineConfigFree

-- | Request GPIO lines from a chip.
-- Must be manually released with 'releaseRequest'.
requestLines :: Chip -> Maybe RequestConfig -> Config -> IO Request
requestLines chip maybeReqConf lineConf =
  unwrapOrThrow LineRequestFailed (D.chipRequestLines chip maybeReqConf lineConf)

-- | Release a line request handle.
releaseRequest :: Request -> IO ()
releaseRequest = D.lineRequestRelease
