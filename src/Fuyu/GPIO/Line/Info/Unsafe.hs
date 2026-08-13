-- |
-- Module      : Fuyu.GPIO.Line.Info.Unsafe
-- Description : Unsafe manual resource allocation for LineInfo snapshots.
-- Maintainer  : BassGT
-- Stability   : experimental
-- Portability : POSIX (Linux gpiod v2)
--
-- Manual resource allocation ('lineInfo', 'freeLineInfo', 'copyLineInfo') for 'LineInfo' handles.
module Fuyu.GPIO.Line.Info.Unsafe
  ( -- * Types
    LineInfo

    -- * Unsafe Manual Resource Allocation
  , lineInfo
  , freeLineInfo
  , copyLineInfo
  ) where

import qualified Fuyu.GPIO.Direct as D
import Fuyu.GPIO.Exception
import Fuyu.GPIO.Types

-- | Retrieve information about a specific line on a chip.
-- Must be manually freed using 'freeLineInfo'.
lineInfo :: Chip -> Offset -> IO LineInfo
lineInfo chip offset' = unwrapOrThrow LineInfoFailed (D.chipLineInfo chip offset')

-- | Free a 'LineInfo' handle.
freeLineInfo :: LineInfo -> IO ()
freeLineInfo = D.lineInfoFree

-- | Make a copy of a 'LineInfo' snapshot.
-- Must be manually freed using 'freeLineInfo'.
copyLineInfo :: LineInfo -> IO LineInfo
copyLineInfo info = unwrapOrThrow LineInfoCopyFailed (D.lineInfoCopy info)
