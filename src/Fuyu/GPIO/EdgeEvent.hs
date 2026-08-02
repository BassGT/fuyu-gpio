{-# LANGUAGE PatternSynonyms #-}

-- |
-- Module      : Fuyu.GPIO.EdgeEvent
-- Description : High-level edge event waiting, reading, and buffer management.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- This module provides managed resource brackets ('withEventBuffer') and functions for waiting
-- on edge events ('waitEdgeEvents') and reading them ('readEdgeEvents') securely using the
-- 'ReadyRequest' capability token.
module Fuyu.GPIO.EdgeEvent
  ( -- * Security Token & Wait Result
    WaitResult(..)
  , ReadyRequest(..)
  , readyToRequest

    -- * Buffer & Event Types
  , Buffer
  , Capacity
  , userBufferCapacity
  , getCapacity
  , pattern EventBufferCapacity
  , Event
  , Timeout
  , pattern Nanoseconds
  , pattern Immediate
  , pattern Infinite
  , Timestamp
  , EdgeEventType
  , pattern Rising
  , pattern Falling

    -- * Event Data Type & Parser
  , NonEmpty(..)
  , EdgeEvent(..)
  , parseEdgeEvent

    -- * Event Buffer Operations (Managed)
  , withEventBuffer
  , eventBufferCapacity
  , eventBufferNumEvents
  , eventBufferGetEvent

    -- * Waiting & Reading Events
  , waitEdgeEvents
  , readEdgeEvents
  , readEdgeEventsRaw
  , withRawEdgeEvents

    -- * RawEdgeEvent Metadata Accessors
  , getEventType
  , getTimestampNs
  , getLineOffset
  , getGlobalSeqNo
  , getLineSeqNo
  , copyEvent
  ) where

import Control.Exception (bracket)
import Control.Monad (forM)
import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.List.NonEmpty as NE
import Data.Word (Word64)
import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.EdgeEvent.Unsafe (newEventBuffer, freeEventBuffer)
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types

-- | Allocate an edge event buffer of the specified capacity and free it automatically afterwards.
withEventBuffer :: Capacity -> (Buffer -> IO a) -> IO a
withEventBuffer capacity = bracket (newEventBuffer capacity) freeEventBuffer

-- | Get the capacity of an event buffer.
eventBufferCapacity :: Buffer -> IO Capacity
eventBufferCapacity buf = userBufferCapacity <$> D.eventBufferCapacity buf

-- | Get the number of events currently stored in an event buffer.
eventBufferNumEvents :: Buffer -> IO Word
eventBufferNumEvents = D.eventBufferNumEvents

-- | Get a specific edge event from the buffer by index.
eventBufferGetEvent :: Buffer -> Word -> IO Event
eventBufferGetEvent buf idx = unwrapOrThrow ReadEdgeEventsFailed (D.eventBufferGetEvent buf idx)

-- | Wait for edge events to occur on requested lines until the specified timeout.
-- Throws 'WaitEdgeEventsFailed' on error.
waitEdgeEvents :: Request -> Timeout -> IO WaitResult
waitEdgeEvents req timeout = do
  res <- unwrapOrThrow WaitEdgeEventsFailed (D.lineRequestWaitEdgeEvents req timeout)
  pure $ case res of
    D.EventReady -> EventReady (ReadyRequest req)
    D.Timeout    -> TimeoutResult

-- | Read raw edge events into the buffer and return the number of events read.
-- Automatically uses the buffer's full capacity.
-- Throws 'ReadEdgeEventsFailed' on error.
readEdgeEventsRaw :: ReadyRequest -> Buffer -> IO Int
readEdgeEventsRaw (ReadyRequest req) buf = do
  cap <- D.eventBufferCapacity buf
  unwrapOrThrow ReadEdgeEventsFailed (D.lineRequestReadEdgeEvents req buf cap)

-- | Parse a raw edge event pointer into a pure Haskell 'EdgeEvent' structure.
parseEdgeEvent :: Event -> IO EdgeEvent
parseEdgeEvent ev = EdgeEvent
  <$> D.rawEdgeEventLineOffset ev
  <*> D.rawEdgeEventType ev
  <*> D.rawEdgeEventTimestampNs ev

-- | Read buffered edge events once 'waitEdgeEvents' indicates they are ready,
-- parsing them into a non-empty list of pure 'EdgeEvent' structures.
readEdgeEvents :: ReadyRequest -> Buffer -> IO (NonEmpty EdgeEvent)
readEdgeEvents readyReq buf = withRawEdgeEvents readyReq buf parseEdgeEvent

-- | Process raw edge events directly in the buffer using a callback without intermediate allocations,
-- returning a non-empty list of results.
withRawEdgeEvents :: ReadyRequest -> Buffer -> (Event -> IO a) -> IO (NonEmpty a)
withRawEdgeEvents readyReq buf action = do
  count <- readEdgeEventsRaw readyReq buf
  results <- forM [0 .. count - 1] $ \idx -> do
    ev <- eventBufferGetEvent buf (fromIntegral idx)
    action ev
  case NE.nonEmpty results of
    Just ne -> pure ne
    Nothing -> ioError (userError "readEdgeEvents: expected at least one event from ReadyRequest but got none")

--------------------------------------------------------------------------------
-- RawEdgeEvent Metadata Accessors
--------------------------------------------------------------------------------

-- | Get the type of event ('Rising' or 'Falling').
getEventType :: Event -> IO EdgeEventType
getEventType = D.rawEdgeEventType

-- | Get the event timestamp in nanoseconds.
getTimestampNs :: Event -> IO Timestamp
getTimestampNs = D.rawEdgeEventTimestampNs

-- | Get the offset of the line that triggered the event.
getLineOffset :: Event -> IO Offset
getLineOffset = D.rawEdgeEventLineOffset

-- | Get the global sequence number of the event.
getGlobalSeqNo :: Event -> IO Word64
getGlobalSeqNo = D.rawEdgeEventGlobalSeqNo

-- | Get the line-specific sequence number of the event.
getLineSeqNo :: Event -> IO Offset
getLineSeqNo = D.rawEdgeEventLineSeqNo

-- | Make a copy of a raw edge event object.
copyEvent :: Event -> IO Event
copyEvent ev = unwrapOrThrow RawEdgeEventCopyFailed (D.rawEdgeEventCopy ev)
