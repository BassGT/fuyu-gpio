{-# LANGUAGE PatternSynonyms #-}
module Fuyu.GPIO.Types
  ( -- * Handles & Opaque Objects
    Chip
  , ChipInfo
  , LineInfo
  , Settings
  , Config
  , Request
  , RequestConfig
  , Buffer
  , Event
  , ReadyRequest(..)
  , readyToRequest

    -- * Units & Index Types
  , Offset
  , offset
  , pattern Offset
  , Capacity
  , userBufferCapacity
  , getCapacity
  , KernelBufferSize
  , Timeout
  , pattern Nanoseconds
  , pattern Immediate
  , pattern Infinite
  , Timestamp
  , WaitResult(..)
  , EdgeEvent(..)

    -- * Line Values & Patterns
  , Value
  , pattern Active
  , pattern Inactive
  , pattern Error

    -- * Line Direction & Patterns
  , Direction
  , pattern DirAsIs
  , pattern DirInput
  , pattern DirOutput

    -- * Edge Detection & Patterns
  , Edge
  , pattern EdgeNone
  , pattern EdgeRising
  , pattern EdgeFalling
  , pattern EdgeBoth

    -- * Electrical Bias & Patterns
  , Bias
  , pattern BiasAsIs
  , pattern BiasUnknown
  , pattern BiasDisabled
  , pattern BiasPullUp
  , pattern BiasPullDown

    -- * Drive Mode & Patterns
  , Drive
  , pattern PushPull
  , pattern OpenDrain
  , pattern OpenSource

    -- * Event Clock & Patterns
  , Clock
  , pattern Monotonic
  , pattern Realtime
  , pattern Hardware

    -- * Edge Event Types & Patterns
  , EdgeEventType
  , pattern Rising
  , pattern Falling

    -- * Line Info Event Types & Patterns
  , InfoEvent
  , InfoEventType
  , pattern LineRequested
  , pattern LineReleased
  , pattern LineConfigChanged
  ) where

import Data.Word (Word32)
import Foreign.C.Types (CUInt, CULong)
import qualified Fuyu.GPIO.Direct as D

-- | Alias for 'D.Chip'
type Chip          = D.Chip
-- | Alias for 'D.ChipInfo'
type ChipInfo      = D.ChipInfo
-- | Alias for 'D.LineInfo'
type LineInfo      = D.LineInfo
-- | Alias for 'D.LineSettings'
type Settings      = D.LineSettings
-- | Alias for 'D.LineConfig'
type Config        = D.LineConfig
-- | Alias for 'D.LineRequest'
type Request       = D.LineRequest
-- | Alias for 'D.RequestConfig'
type RequestConfig = D.RequestConfig
-- | Alias for 'D.EventBuffer'
type Buffer        = D.EventBuffer
-- | Alias for 'D.RawEdgeEvent'
type Event         = D.RawEdgeEvent

-- | Alias for 'D.LineOffset'
type Offset        = D.LineOffset
-- | Alias for 'D.TimeoutNs'
type Timeout       = D.TimeoutNs
-- | Alias for 'D.TimestampNs'
type Timestamp     = D.TimestampNs
-- | Alias for 'D.LineValue'
type Value         = D.LineValue
-- | Alias for 'D.LineDirection'
type Direction     = D.LineDirection
-- | Alias for 'D.LineEdge'
type Edge          = D.LineEdge
-- | Alias for 'D.LineBias'
type Bias          = D.LineBias
-- | Alias for 'D.LineDrive'
type Drive         = D.LineDrive
-- | Alias for 'D.LineClock'
type Clock         = D.LineClock
-- | Alias for 'D.EdgeEventType'
type EdgeEventType = D.EdgeEventType
-- | Alias for 'D.InfoEvent'
type InfoEvent     = D.InfoEvent
-- | Alias for 'D.InfoEventType'
type InfoEventType = D.InfoEventType

-- | Helper function to construct an 'Offset' from a 32-bit unsigned integer (e.g. 'offset 17').
{-# INLINE offset #-}
offset :: Word32 -> Offset
offset n = D.LineOffset (fromIntegral n)

-- | Security token wrapping a 'Request' that has been confirmed ready by 'Fuyu.GPIO.EdgeEvent.waitEdgeEvents'.
newtype ReadyRequest = ReadyRequest Request
  deriving (Eq, Show)

-- | Extract the underlying 'Request' from a 'ReadyRequest'.
readyToRequest :: ReadyRequest -> Request
readyToRequest (ReadyRequest req) = req

-- | Result of waiting for edge events on a line request.
data WaitResult
  = EventReady ReadyRequest
  | TimeoutResult
  deriving (Eq, Show)

-- | Pure Haskell representation of a parsed edge detection event.
data EdgeEvent = EdgeEvent
  { eventLineOffset :: !Offset
  , eventType       :: !EdgeEventType
  , eventTimestamp  :: !Timestamp
  } deriving (Eq, Ord, Show, Read)

-- | Pattern constructor for 'Offset'.
pattern Offset :: CUInt -> Offset 
pattern Offset n = D.LineOffset n

-- | Capacity for the user-space edge event buffer (in number of events).
newtype Capacity = Capacity Word
  deriving (Eq, Ord, Show, Read)

-- | Smart constructor for user-space event buffer 'Capacity'.
-- Automatically clamps capacity between 1 and 1024 (where 0 defaults to 64 per libgpiod specifications).
userBufferCapacity :: Word -> Capacity
userBufferCapacity n
  | n == 0    = Capacity 64
  | n > 1024  = Capacity 1024
  | otherwise = Capacity n

-- | Extract the numeric capacity value from a 'Capacity' handle.
getCapacity :: Capacity -> Word
getCapacity (Capacity n) = n

-- | Size of the kernel-level event ring-buffer (in number of events).
-- Pass 0 to use the kernel default size (64).
type KernelBufferSize = Word

-- | Pattern constructor for 'Timeout' in nanoseconds.
pattern Nanoseconds :: CULong -> Timeout
pattern Nanoseconds n = D.Nanoseconds n

-- | Immediate (non-blocking) timeout value.
pattern Immediate :: Timeout
pattern Immediate = D.Immediate

-- | Infinite (blocking) timeout value.
pattern Infinite :: Timeout
pattern Infinite = D.Infinite

-- | Active line logical state (high/active).
pattern Active :: Value
pattern Active = D.LineActive

-- | Inactive line logical state (low/inactive).
pattern Inactive :: Value
pattern Inactive = D.LineInactive

-- | Error line state.
pattern Error :: Value
pattern Error = D.LineError

-- | Leave direction configuration as is.
pattern DirAsIs :: Direction
pattern DirAsIs = D.DirAsIs

-- | Configure line direction as input.
pattern DirInput :: Direction
pattern DirInput = D.DirInput

-- | Configure line direction as output.
pattern DirOutput :: Direction
pattern DirOutput = D.DirOutput

-- | Disable edge detection.
pattern EdgeNone :: Edge
pattern EdgeNone = D.EdgeNone

-- | Detect rising edge transitions.
pattern EdgeRising :: Edge
pattern EdgeRising = D.EdgeRising

-- | Detect falling edge transitions.
pattern EdgeFalling :: Edge
pattern EdgeFalling = D.EdgeFalling

-- | Detect both rising and falling edge transitions.
pattern EdgeBoth :: Edge
pattern EdgeBoth = D.EdgeBoth

-- | Leave bias configuration as is.
pattern BiasAsIs :: Bias
pattern BiasAsIs = D.BiasAsIs

-- | Unknown electrical bias.
pattern BiasUnknown :: Bias
pattern BiasUnknown = D.BiasUnknown

-- | Disable electrical bias (floating).
pattern BiasDisabled :: Bias
pattern BiasDisabled = D.BiasDisabled

-- | Enable internal pull-up resistor.
pattern BiasPullUp :: Bias
pattern BiasPullUp = D.BiasPullUp

-- | Enable internal pull-down resistor.
pattern BiasPullDown :: Bias
pattern BiasPullDown = D.BiasPullDown

-- | Push-pull drive mode.
pattern PushPull :: Drive
pattern PushPull = D.PushPull

-- | Open-drain drive mode.
pattern OpenDrain :: Drive
pattern OpenDrain = D.OpenDrain

-- | Open-source drive mode.
pattern OpenSource :: Drive
pattern OpenSource = D.OpenSource

-- | Monotonic clock source for event timestamps.
pattern Monotonic :: Clock
pattern Monotonic = D.Monotonic

-- | Realtime clock source for event timestamps.
pattern Realtime :: Clock
pattern Realtime = D.Realtime

-- | Hardware clock source for event timestamps.
pattern Hardware :: Clock
pattern Hardware = D.Hardware

-- | Rising edge event type.
pattern Rising :: EdgeEventType
pattern Rising = D.Rising

-- | Falling edge event type.
pattern Falling :: EdgeEventType
pattern Falling = D.Falling

-- | Line requested info event type.
pattern LineRequested :: InfoEventType
pattern LineRequested = D.LineRequested

-- | Line released info event type.
pattern LineReleased :: InfoEventType
pattern LineReleased = D.LineReleased

-- | Line configuration changed info event type.
pattern LineConfigChanged :: InfoEventType
pattern LineConfigChanged = D.LineConfigChanged
