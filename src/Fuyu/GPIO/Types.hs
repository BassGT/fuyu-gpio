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
  , pattern EventBufferCapacity
  , BufferIndex
  , pattern BufferIndex
  , Timeout
  , pattern Nanoseconds
  , pattern Immediate
  , pattern Infinite
  , Timestamp
  , WaitResult(..)

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

import Foreign.C.Types (CUInt, CULong, CSize)
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
-- | Alias for 'D.EventBufferCapacity'
type Capacity      = D.EventBufferCapacity
-- | Alias for 'D.BufferIndex'
type BufferIndex   = D.BufferIndex
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

-- | Helper function to construct an 'Offset' from any integral number (e.g. 'offset 17').
{-# INLINE offset #-}
offset :: Integral a => a -> Offset
offset n = D.LineOffset (fromIntegral n)

-- | Security token wrapping a 'Request' that has been confirmed ready by 'waitEdgeEvents'.
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

pattern Offset :: CUInt -> Offset 
pattern Offset n = D.LineOffset n

pattern EventBufferCapacity :: CSize -> Capacity
pattern EventBufferCapacity s = D.EventBufferCapacity s

pattern BufferIndex :: CULong -> BufferIndex
pattern BufferIndex i = D.BufferIndex i

pattern Nanoseconds :: CULong -> Timeout
pattern Nanoseconds n = D.Nanoseconds n

pattern Immediate :: Timeout
pattern Immediate = D.Immediate

pattern Infinite :: Timeout
pattern Infinite = D.Infinite

pattern Active :: Value
pattern Active = D.LineActive

pattern Inactive :: Value
pattern Inactive = D.LineInactive

pattern Error :: Value
pattern Error = D.LineError

pattern DirAsIs :: Direction
pattern DirAsIs = D.DirAsIs

pattern DirInput :: Direction
pattern DirInput = D.DirInput

pattern DirOutput :: Direction
pattern DirOutput = D.DirOutput

pattern EdgeNone :: Edge
pattern EdgeNone = D.EdgeNone

pattern EdgeRising :: Edge
pattern EdgeRising = D.EdgeRising

pattern EdgeFalling :: Edge
pattern EdgeFalling = D.EdgeFalling

pattern EdgeBoth :: Edge
pattern EdgeBoth = D.EdgeBoth

pattern BiasAsIs :: Bias
pattern BiasAsIs = D.BiasAsIs

pattern BiasUnknown :: Bias
pattern BiasUnknown = D.BiasUnknown

pattern BiasDisabled :: Bias
pattern BiasDisabled = D.BiasDisabled

pattern BiasPullUp :: Bias
pattern BiasPullUp = D.BiasPullUp

pattern BiasPullDown :: Bias
pattern BiasPullDown = D.BiasPullDown

pattern PushPull :: Drive
pattern PushPull = D.PushPull

pattern OpenDrain :: Drive
pattern OpenDrain = D.OpenDrain

pattern OpenSource :: Drive
pattern OpenSource = D.OpenSource

pattern Monotonic :: Clock
pattern Monotonic = D.Monotonic

pattern Realtime :: Clock
pattern Realtime = D.Realtime

pattern Hardware :: Clock
pattern Hardware = D.Hardware

pattern Rising :: EdgeEventType
pattern Rising = D.Rising

pattern Falling :: EdgeEventType
pattern Falling = D.Falling

pattern LineRequested :: InfoEventType
pattern LineRequested = D.LineRequested

pattern LineReleased :: InfoEventType
pattern LineReleased = D.LineReleased

pattern LineConfigChanged :: InfoEventType
pattern LineConfigChanged = D.LineConfigChanged
