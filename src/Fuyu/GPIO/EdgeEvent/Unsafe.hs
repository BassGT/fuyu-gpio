-- |
-- Module      : Fuyu.GPIO.EdgeEvent.Unsafe
-- Description : Unsafe manual resource allocation for event buffers.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- Manual resource allocation ('newEventBuffer', 'freeEventBuffer') for edge 'Buffer' handles.
module Fuyu.GPIO.EdgeEvent.Unsafe
  ( -- * Types
    Buffer
  , Capacity
  , userBufferCapacity
  , getCapacity
  , pattern EventBufferCapacity

    -- * Unsafe Manual Resource Allocation
  , newEventBuffer
  , freeEventBuffer
  ) where

import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types

-- | Allocate an edge event buffer of the specified capacity.
-- Must be manually freed with 'freeEventBuffer'.
newEventBuffer :: Capacity -> IO Buffer
newEventBuffer cap = unwrapOrThrow EventBufferNewFailed (D.eventBufferNew (getCapacity cap))

-- | Free an edge event buffer object.
freeEventBuffer :: Buffer -> IO ()
freeEventBuffer = D.eventBufferFree
