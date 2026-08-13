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
  , pattern Offset
  , Value
  , pattern Active
  , pattern Inactive
  , pattern ValueError
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
  , direction
  , setEdgeDetection
  , edgeDetection
  , setBias
  , bias
  , setDrive
  , drive
  , setEventClock
  , eventClock
  , setActiveLow
  , activeLow
  , setDebouncePeriodUs
  , debouncePeriodUs
  , setOutputValue
  , outputValue
  , resetSettings

    -- * Line Configuration Operations
  , addSettings
  , settings
  , setOutputValues
  , numOffsets
  , configuredOffsets
  , resetConfig

    -- * Line Value Operations (Read / Write)
  , value
  , values
  , valuesSubset
  , setValue
  , setValues
  , setValuesSubset

    -- * Line Request Operations & Metadata
  , chipName
  , numLines
  , requestedOffsets
  , fd
  , reconfigureLines
  ) where

import Control.Exception (bracket, throwIO)
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
direction :: Settings -> IO Direction
direction = D.lineSettingsDirection

-- | Set edge detection in the settings.
setEdgeDetection :: Settings -> Edge -> IO ()
setEdgeDetection set edge = unwrapOrThrow LineSettingsSetFailed (D.lineSettingsSetEdgeDetection set edge)

-- | Get edge detection from the settings.
edgeDetection :: Settings -> IO Edge
edgeDetection = D.lineSettingsEdgeDetection

-- | Set electrical bias in the settings.
setBias :: Settings -> Bias -> IO ()
setBias _ BiasUnknown = throwIO $ InvalidArgument "setBias: BiasUnknown is a read-only state and cannot be set as a bias configuration."
setBias set biasVal      = unwrapOrThrow LineSettingsSetFailed (D.lineSettingsSetBias set biasVal)

-- | Get electrical bias from the settings.
bias :: Settings -> IO Bias
bias = D.lineSettingsBias

-- | Set drive mode in the settings.
setDrive :: Settings -> Drive -> IO ()
setDrive set driveMode = unwrapOrThrow LineSettingsSetFailed (D.lineSettingsSetDrive set driveMode)

-- | Get drive mode from the settings.
drive :: Settings -> IO Drive
drive = D.lineSettingsDrive

-- | Set event clock source in the settings.
setEventClock :: Settings -> Clock -> IO ()
setEventClock set clk = unwrapOrThrow LineSettingsSetFailed (D.lineSettingsSetEventClock set clk)

-- | Get event clock source from the settings.
eventClock :: Settings -> IO Clock
eventClock = D.lineSettingsEventClock

-- | Set active-low in the settings.
setActiveLow :: Settings -> Bool -> IO ()
setActiveLow = D.lineSettingsSetActiveLow

-- | Get active-low setting.
activeLow :: Settings -> IO Bool
activeLow = D.lineSettingsActiveLow

-- | Set debounce period in microseconds.
setDebouncePeriodUs :: Settings -> Word -> IO ()
setDebouncePeriodUs = D.lineSettingsSetDebouncePeriodUs

-- | Get debounce period in microseconds.
debouncePeriodUs :: Settings -> IO Word
debouncePeriodUs = D.lineSettingsDebouncePeriodUs

-- | Set default output value in the settings.
setOutputValue :: Settings -> Value -> IO ()
setOutputValue _ ValueError = throwIO $ InvalidArgument "setOutputValue: ValueError pattern is a read-only error state and cannot be set as an output value."
setOutputValue set val = unwrapOrThrow LineSettingsSetFailed (D.lineSettingsSetOutputValue set val)

-- | Get default output value from the settings.
outputValue :: Settings -> IO Value
outputValue = D.lineSettingsOutputValue

-- | Reset line settings object to default values.
resetSettings :: Settings -> IO ()
resetSettings = D.lineSettingsReset

--------------------------------------------------------------------------------
-- Line Configuration Operations
--------------------------------------------------------------------------------

-- | Add settings for a vector of line offsets in the configuration.
addSettings :: Config -> V.Vector Offset -> Settings -> IO ()
addSettings config offsets stgs = unwrapOrThrow LineConfigNewFailed (D.lineConfigAddLineSettings config offsets stgs)

-- | Get settings for a specific line offset from configuration.
settings :: Config -> Offset -> IO Settings
settings config offset' = unwrapOrThrow LineConfigNewFailed (D.lineConfigLineSettings config offset')

-- | Set output values for lines in configuration.
setOutputValues :: Config -> V.Vector Value -> IO ()
setOutputValues config vals
  | V.elem ValueError vals = throwIO $ InvalidArgument "setOutputValues: Vector contains ValueError pattern, which cannot be set as an output value."
  | otherwise              = unwrapOrThrow LineConfigNewFailed (D.lineConfigSetOutputValues config vals)

-- | Get the number of configured offsets in the line configuration.
numOffsets :: Config -> IO Word
numOffsets = D.lineConfigNumOffsets

-- | Get all configured line offsets in the configuration as a Storable 'V.Vector'.
configuredOffsets :: Config -> IO (V.Vector Offset)
configuredOffsets = D.lineConfigConfiguredOffsets

-- | Reset line configuration object to empty state.
resetConfig :: Config -> IO ()
resetConfig = D.lineConfigReset

--------------------------------------------------------------------------------
-- Line Reading & Writing
--------------------------------------------------------------------------------

-- | Get the logical value of a requested GPIO line at the given offset.
value :: Request -> Offset -> IO Value
value req offset' = unwrapOrThrow LineValueReadFailed (D.lineRequestValue req offset')

-- | Get the logical values of all requested lines as a Storable 'V.Vector'.
values :: Request -> IO (V.Vector Value)
values req = unwrapOrThrow LineValueReadFailed (D.lineRequestValues req)

-- | Get the logical values of a subset of requested lines specified by offsets.
valuesSubset :: Request -> V.Vector Offset -> IO (V.Vector Value)
valuesSubset req offsets = unwrapOrThrow LineValueReadFailed (D.lineRequestSubsetValues req offsets)

-- | Set the logical value of a requested GPIO line at the given offset.
setValue :: Request -> Offset -> Value -> IO ()
setValue _ _ ValueError  = throwIO $ InvalidArgument "setValue: ValueError pattern is a read-only error state and cannot be written to a GPIO line."
setValue req offset' val = unwrapOrThrow LineValueWriteFailed (D.lineRequestSetValue req offset' val)

-- | Set the logical values of all requested lines from a Storable 'V.Vector'.
setValues :: Request -> V.Vector Value -> IO ()
setValues req vals
  | V.elem ValueError vals = throwIO $ InvalidArgument "setValues: Vector contains ValueError pattern, which cannot be written to GPIO lines."
  | otherwise              = unwrapOrThrow LineValueWriteFailed (D.lineRequestSetValues req vals)

-- | Set the logical values of a subset of requested lines from vectors of offsets and values.
setValuesSubset :: Request -> V.Vector Offset -> V.Vector Value -> IO ()
setValuesSubset req offsets vals
  | V.elem ValueError vals = throwIO $ InvalidArgument "setValuesSubset: Vector contains ValueError pattern, which cannot be written to GPIO lines."
  | otherwise              = unwrapOrThrow LineValueWriteFailed (D.lineRequestSetValuesSubset req offsets vals)

--------------------------------------------------------------------------------
-- Line Request Operations & Metadata
--------------------------------------------------------------------------------

-- | Get the name of the chip this request was made on.
chipName :: Request -> IO ByteString
chipName = D.lineRequestChipName

-- | Get the number of lines in the request.
numLines :: Request -> IO Word
numLines = D.lineRequestNumLines

-- | Get all requested line offsets as a Storable 'V.Vector'.
requestedOffsets :: Request -> IO (V.Vector Offset)
requestedOffsets = D.lineRequestRequestedOffsets

-- | Get the file descriptor associated with the line request handle.
fd :: Request -> IO Fd
fd = D.lineRequestFd

-- | Update the configuration of lines associated with an active line request.
reconfigureLines :: Request -> Config -> IO ()
reconfigureLines req config = unwrapOrThrow LineReconfigureFailed (D.lineRequestReconfigure req config)
