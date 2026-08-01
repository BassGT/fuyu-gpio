-- |
-- Module      : Fuyu.GPIO.Line
-- Description : High-level operations for GPIO line settings, requests, and value I/O.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- This module provides managed resource brackets ('withSettings', 'withConfig', 'withRequest')
-- for configuring GPIO line properties (direction, bias, drive mode, active-low, debounce)
-- and requesting access to read or write logical values to GPIO lines.
module Fuyu.GPIO.Line
  ( -- * Types & Patterns
    Settings
  , Config
  , Request
  , RequestConfig
  , Offset
  , offset
  , pattern Offset
  , Value
  , pattern Active
  , pattern Inactive
  , pattern Error
  , Direction
  , pattern DirAsIs
  , pattern DirInput
  , pattern DirOutput
  , Edge
  , pattern EdgeNone
  , pattern EdgeRising
  , pattern EdgeFalling
  , pattern EdgeBoth
  , Bias
  , pattern BiasAsIs
  , pattern BiasUnknown
  , pattern BiasDisabled
  , pattern BiasPullUp
  , pattern BiasPullDown
  , Drive
  , pattern PushPull
  , pattern OpenDrain
  , pattern OpenSource
  , Clock
  , pattern Monotonic
  , pattern Realtime
  , pattern Hardware

    -- * Managed Resource Allocation (with*)
  , withSettings
  , withConfig
  , withRequest

    -- * Line Settings Operations
  , setDirection
  , getDirection
  , setEdgeDetection
  , getEdgeDetection
  , setBias
  , getBias
  , setDrive
  , getDrive
  , setEventClock
  , getEventClock
  , setActiveLow
  , getActiveLow
  , setDebouncePeriodUs
  , getDebouncePeriodUs
  , setOutputValue
  , getOutputValue
  , resetSettings

    -- * Line Configuration Operations
  , addSettings
  , getSettings
  , setOutputValues
  , getNumOffsets
  , getConfiguredOffsets
  , resetConfig

    -- * Line Value Operations (Read / Write)
  , getValue
  , getValues
  , getValuesSubset
  , setValue
  , setValues
  , setValuesSubset

    -- * Line Request Operations & Metadata
  , getRequestChipName
  , getRequestNumLines
  , getRequestRequestedOffsets
  , getRequestFd
  , reconfigureLines
  ) where

import Control.Exception (bracket)
import Data.ByteString (ByteString)
import qualified Data.Vector.Storable as V
import System.Posix.Types (Fd)
import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Line.Unsafe (newSettings, freeSettings, newConfig, freeConfig, requestLines, releaseRequest)
import Fuyu.GPIO.Types

--------------------------------------------------------------------------------
-- Resource Bracket Management
--------------------------------------------------------------------------------

-- | Allocate a new line settings object and free it automatically afterwards.
withSettings :: (Settings -> IO a) -> IO a
withSettings = bracket newSettings freeSettings

-- | Allocate a new line configuration object and free it automatically afterwards.
withConfig :: (Config -> IO a) -> IO a
withConfig = bracket newConfig freeConfig

-- | Request GPIO lines from a chip and automatically release them afterwards.
withRequest :: Chip -> Maybe RequestConfig -> Config -> (Request -> IO a) -> IO a
withRequest chip maybeReqConf lineConf = bracket (requestLines chip maybeReqConf lineConf) releaseRequest

--------------------------------------------------------------------------------
-- Line Settings Setters & Getters
--------------------------------------------------------------------------------

-- | Set the line direction in the settings.
setDirection :: Settings -> Direction -> IO ()
setDirection set dir = unwrapOrThrow LineSettingsSetFailed (D.lineSettingsSetDirection set dir)

-- | Get the line direction from the settings.
getDirection :: Settings -> IO Direction
getDirection = D.lineSettingsDirection

-- | Set edge detection in the settings.
setEdgeDetection :: Settings -> Edge -> IO ()
setEdgeDetection set edge = unwrapOrThrow LineSettingsSetFailed (D.lineSettingsSetEdgeDetection set edge)

-- | Get edge detection from the settings.
getEdgeDetection :: Settings -> IO Edge
getEdgeDetection = D.lineSettingsEdgeDetection

-- | Set electrical bias in the settings.
setBias :: Settings -> Bias -> IO ()
setBias set bias = unwrapOrThrow LineSettingsSetFailed (D.lineSettingsSetBias set bias)

-- | Get electrical bias from the settings.
getBias :: Settings -> IO Bias
getBias = D.lineSettingsBias

-- | Set drive mode in the settings.
setDrive :: Settings -> Drive -> IO ()
setDrive set drive = unwrapOrThrow LineSettingsSetFailed (D.lineSettingsSetDrive set drive)

-- | Get drive mode from the settings.
getDrive :: Settings -> IO Drive
getDrive = D.lineSettingsDrive

-- | Set event clock source in the settings.
setEventClock :: Settings -> Clock -> IO ()
setEventClock set clk = unwrapOrThrow LineSettingsSetFailed (D.lineSettingsSetEventClock set clk)

-- | Get event clock source from the settings.
getEventClock :: Settings -> IO Clock
getEventClock = D.lineSettingsEventClock

-- | Set active-low in the settings.
setActiveLow :: Settings -> Bool -> IO ()
setActiveLow = D.lineSettingsSetActiveLow

-- | Get active-low setting.
getActiveLow :: Settings -> IO Bool
getActiveLow = D.lineSettingsActiveLow

-- | Set debounce period in microseconds.
setDebouncePeriodUs :: Settings -> Word -> IO ()
setDebouncePeriodUs = D.lineSettingsSetDebouncePeriodUs

-- | Get debounce period in microseconds.
getDebouncePeriodUs :: Settings -> IO Word
getDebouncePeriodUs = D.lineSettingsDebouncePeriodUs

-- | Set default output value in the settings.
setOutputValue :: Settings -> Value -> IO ()
setOutputValue set val = unwrapOrThrow LineSettingsSetFailed (D.lineSettingsSetOutputValue set val)

-- | Get default output value from the settings.
getOutputValue :: Settings -> IO Value
getOutputValue = D.lineSettingsOutputValue

-- | Reset line settings object to default values.
resetSettings :: Settings -> IO ()
resetSettings = D.lineSettingsReset

--------------------------------------------------------------------------------
-- Line Configuration Operations
--------------------------------------------------------------------------------

-- | Add settings for a vector of line offsets in the configuration.
addSettings :: Config -> V.Vector Offset -> Settings -> IO ()
addSettings config offsets settings = unwrapOrThrow LineConfigNewFailed (D.lineConfigAddLineSettings config offsets settings)

-- | Get settings for a specific line offset from configuration.
getSettings :: Config -> Offset -> IO Settings
getSettings config offset' = unwrapOrThrow LineConfigNewFailed (D.lineConfigLineSettings config offset')

-- | Set output values for lines in configuration.
setOutputValues :: Config -> V.Vector Value -> IO ()
setOutputValues config values = unwrapOrThrow LineConfigNewFailed (D.lineConfigSetOutputValues config values)

-- | Get the number of configured offsets in the line configuration.
getNumOffsets :: Config -> IO Word
getNumOffsets = D.lineConfigNumOffsets

-- | Get all configured line offsets in the configuration as a Storable 'V.Vector'.
getConfiguredOffsets :: Config -> IO (V.Vector Offset)
getConfiguredOffsets = D.lineConfigConfiguredOffsets

-- | Reset line configuration object to empty state.
resetConfig :: Config -> IO ()
resetConfig = D.lineConfigReset

--------------------------------------------------------------------------------
-- Line Reading & Writing
--------------------------------------------------------------------------------

-- | Get the logical value of a requested GPIO line at the given offset.
getValue :: Request -> Offset -> IO Value
getValue req offset' = unwrapOrThrow LineValueReadFailed (D.lineRequestValue req offset')

-- | Get the logical values of all requested lines as a Storable 'V.Vector'.
getValues :: Request -> IO (V.Vector Value)
getValues req = unwrapOrThrow LineValueReadFailed (D.lineRequestValues req)

-- | Get the logical values of a subset of requested lines specified by offsets.
getValuesSubset :: Request -> V.Vector Offset -> IO (V.Vector Value)
getValuesSubset req offsets = unwrapOrThrow LineValueReadFailed (D.lineRequestSubsetValues req offsets)

-- | Set the logical value of a requested GPIO line at the given offset.
setValue :: Request -> Offset -> Value -> IO ()
setValue req offset' val = unwrapOrThrow LineValueWriteFailed (D.lineRequestSetValue req offset' val)

-- | Set the logical values of all requested lines from a Storable 'V.Vector'.
setValues :: Request -> V.Vector Value -> IO ()
setValues req vals = unwrapOrThrow LineValueWriteFailed (D.lineRequestSetValues req vals)

-- | Set the logical values of a subset of requested lines from vectors of offsets and values.
setValuesSubset :: Request -> V.Vector Offset -> V.Vector Value -> IO ()
setValuesSubset req offsets vals = unwrapOrThrow LineValueWriteFailed (D.lineRequestSetValuesSubset req offsets vals)

--------------------------------------------------------------------------------
-- Line Request Operations & Metadata
--------------------------------------------------------------------------------

-- | Get the name of the chip this request was made on.
getRequestChipName :: Request -> IO ByteString
getRequestChipName = D.lineRequestChipName

-- | Get the number of lines in the request.
getRequestNumLines :: Request -> IO Word
getRequestNumLines = D.lineRequestNumLines

-- | Get all requested line offsets as a Storable 'V.Vector'.
getRequestRequestedOffsets :: Request -> IO (V.Vector Offset)
getRequestRequestedOffsets = D.lineRequestRequestedOffsets

-- | Get the file descriptor associated with the line request handle.
getRequestFd :: Request -> IO Fd
getRequestFd = D.lineRequestFd

-- | Update the configuration of lines associated with an active line request.
reconfigureLines :: Request -> Config -> IO ()
reconfigureLines req config = unwrapOrThrow LineReconfigureFailed (D.lineRequestReconfigure req config)
