-- |
-- Module      : Fuyu.GPIO.EdgeEvent.Unsafe
-- Description : Unsafe manual resource allocation and raw buffer reading for event buffers.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- Manual resource allocation ('newEventBuffer', 'freeEventBuffer') and raw reading ('readEventsRaw') for edge 'Buffer' handles.
module Fuyu.GPIO.EdgeEvent.Unsafe
  ( -- * Types & Security Token
    Buffer
  , Capacity
  , userBufferCapacity
  , capacity
  , ReadyRequest(..)

    -- * Unsafe Manual Resource Allocation & Reading
  , newEventBuffer
  , freeEventBuffer
  , readEventsRaw
  ) where

import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types

-- | Allocate an edge event buffer of the specified capacity.
-- Must be manually freed with 'freeEventBuffer'.
newEventBuffer :: Capacity -> IO Buffer
newEventBuffer cap = unwrapOrThrow EventBufferNewFailed (D.eventBufferNew (capacity cap))

-- | Free an edge event buffer object.
freeEventBuffer :: Buffer -> IO ()
freeEventBuffer = D.eventBufferFree

-- | Read raw edge events into the buffer and return the number of events read.
-- Automatically uses the buffer's full capacity.
-- Throws 'ReadEdgeEventsFailed' on error.
readEventsRaw :: ReadyRequest -> Buffer -> IO Int
readEventsRaw (ReadyRequest req) buf = do
  cap <- D.eventBufferCapacity buf
  unwrapOrThrow ReadEdgeEventsFailed (D.lineRequestReadEdgeEvents req buf cap)
