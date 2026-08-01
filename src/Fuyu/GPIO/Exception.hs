{-# LANGUAGE DeriveAnyClass #-}

-- |
-- Module      : Fuyu.GPIO.Exception
-- Description : Exception types for fuyu-gpio operations.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX
--
-- High-level exception type 'GpioException' thrown by fuyu-gpio operations.
module Fuyu.GPIO.Exception
  ( GpioException(..)
  , unwrapOrThrow
  ) where

import Control.Exception (Exception, throwIO)
import Foreign.C.Error (Errno(..))

-- | High-level exceptions thrown by fuyu-gpio operations.
data GpioException
  = ChipOpenFailed FilePath Errno
  | ChipInfoFailed Errno
  | LineInfoFailed Errno
  | LineSettingsNewFailed Errno
  | LineSettingsSetFailed Errno
  | LineConfigNewFailed Errno
  | RequestConfigNewFailed Errno
  | LineRequestFailed Errno
  | EventBufferNewFailed Errno
  | LineValueReadFailed Errno
  | LineValueWriteFailed Errno
  | LineReconfigureFailed Errno
  | WaitEdgeEventsFailed Errno
  | ReadEdgeEventsFailed Errno
  | WaitInfoEventFailed Errno
  | ReadInfoEventFailed Errno
  | RawEdgeEventCopyFailed Errno
  | LineInfoCopyFailed Errno
  | CustomGpioError String Errno
  deriving (Exception)

instance Eq GpioException where
  ChipOpenFailed p1 e1 == ChipOpenFailed p2 e2 = p1 == p2 && e1 == e2
  ChipInfoFailed e1 == ChipInfoFailed e2 = e1 == e2
  LineInfoFailed e1 == LineInfoFailed e2 = e1 == e2
  LineSettingsNewFailed e1 == LineSettingsNewFailed e2 = e1 == e2
  LineSettingsSetFailed e1 == LineSettingsSetFailed e2 = e1 == e2
  LineConfigNewFailed e1 == LineConfigNewFailed e2 = e1 == e2
  RequestConfigNewFailed e1 == RequestConfigNewFailed e2 = e1 == e2
  LineRequestFailed e1 == LineRequestFailed e2 = e1 == e2
  EventBufferNewFailed e1 == EventBufferNewFailed e2 = e1 == e2
  LineValueReadFailed e1 == LineValueReadFailed e2 = e1 == e2
  LineValueWriteFailed e1 == LineValueWriteFailed e2 = e1 == e2
  LineReconfigureFailed e1 == LineReconfigureFailed e2 = e1 == e2
  WaitEdgeEventsFailed e1 == WaitEdgeEventsFailed e2 = e1 == e2
  ReadEdgeEventsFailed e1 == ReadEdgeEventsFailed e2 = e1 == e2
  WaitInfoEventFailed e1 == WaitInfoEventFailed e2 = e1 == e2
  ReadInfoEventFailed e1 == ReadInfoEventFailed e2 = e1 == e2
  RawEdgeEventCopyFailed e1 == RawEdgeEventCopyFailed e2 = e1 == e2
  LineInfoCopyFailed e1 == LineInfoCopyFailed e2 = e1 == e2
  CustomGpioError s1 e1 == CustomGpioError s2 e2 = s1 == s2 && e1 == e2
  _ == _ = False

instance Show GpioException where
  show (ChipOpenFailed path (Errno e)) = "ChipOpenFailed: Failed to open chip at '" ++ path ++ "' (errno " ++ show e ++ ")"
  show (ChipInfoFailed (Errno e)) = "ChipInfoFailed (errno " ++ show e ++ ")"
  show (LineInfoFailed (Errno e)) = "LineInfoFailed (errno " ++ show e ++ ")"
  show (LineSettingsNewFailed (Errno e)) = "LineSettingsNewFailed (errno " ++ show e ++ ")"
  show (LineSettingsSetFailed (Errno e)) = "LineSettingsSetFailed (errno " ++ show e ++ ")"
  show (LineConfigNewFailed (Errno e)) = "LineConfigNewFailed (errno " ++ show e ++ ")"
  show (RequestConfigNewFailed (Errno e)) = "RequestConfigNewFailed (errno " ++ show e ++ ")"
  show (LineRequestFailed (Errno e)) = "LineRequestFailed (errno " ++ show e ++ ")"
  show (EventBufferNewFailed (Errno e)) = "EventBufferNewFailed (errno " ++ show e ++ ")"
  show (LineValueReadFailed (Errno e)) = "LineValueReadFailed (errno " ++ show e ++ ")"
  show (LineValueWriteFailed (Errno e)) = "LineValueWriteFailed (errno " ++ show e ++ ")"
  show (LineReconfigureFailed (Errno e)) = "LineReconfigureFailed (errno " ++ show e ++ ")"
  show (WaitEdgeEventsFailed (Errno e)) = "WaitEdgeEventsFailed (errno " ++ show e ++ ")"
  show (ReadEdgeEventsFailed (Errno e)) = "ReadEdgeEventsFailed (errno " ++ show e ++ ")"
  show (WaitInfoEventFailed (Errno e)) = "WaitInfoEventFailed (errno " ++ show e ++ ")"
  show (ReadInfoEventFailed (Errno e)) = "ReadInfoEventFailed (errno " ++ show e ++ ")"
  show (RawEdgeEventCopyFailed (Errno e)) = "RawEdgeEventCopyFailed (errno " ++ show e ++ ")"
  show (LineInfoCopyFailed (Errno e)) = "LineInfoCopyFailed (errno " ++ show e ++ ")"
  show (CustomGpioError msg (Errno e)) = "CustomGpioError '" ++ msg ++ "' (errno " ++ show e ++ ")"

-- | Helper to unwrap an 'Either Errno a' from low-level FFI calls or throw a 'GpioException'.
unwrapOrThrow :: (Errno -> GpioException) -> IO (Either Errno a) -> IO a
unwrapOrThrow mkExc action = do
  res <- action
  case res of
    Left errno -> throwIO (mkExc errno)
    Right val  -> pure val
