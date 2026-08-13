{-# LANGUAGE OverloadedStrings #-}
-- In this example we will learn how to read a rotary encoder using a custom 'RequestConfig',
-- flattening resource allocation brackets with monadic continuation ('ContT'), and managing state
-- cleanly with 'Control.Monad.Trans.State.Strict' (StateT).
module Main where

-- High-level resource brackets & exception handling
import Fuyu.GPIO.Chip (withChip)
import qualified Fuyu.GPIO.Line as Line
import qualified Fuyu.GPIO.EdgeEvent as EdgeEvent  
import qualified Fuyu.GPIO.RequestConfig as ReqConf  
import Fuyu.GPIO.Exception (withGpioApp)

-- Base & third-party libraries
import Control.Monad.Trans.Cont (evalContT, ContT(..))
import Control.Monad.Trans.State.Strict (StateT, evalStateT, gets, modify')
import Control.Monad.IO.Class (liftIO)
import Control.Monad (forever, when)
import qualified Data.Vector.Storable as V (fromList)
import Data.List.NonEmpty (NonEmpty(..))

chipPath :: FilePath
chipPath = "/dev/gpiochip0"

-- Line offsets for the rotary encoder signals
offsetCLK :: Line.Offset
offsetCLK = Line.Offset 256

offsetDT :: Line.Offset
offsetDT = Line.Offset 271

-- Timeout for waiting on edge events (5 seconds)
fiveSecondsNs :: EdgeEvent.Timeout
fiveSecondsNs = EdgeEvent.Nanoseconds 5000000000

-- Setting user buffer capacity to 1 guarantees that 'readEvents' returns exactly 1 event at a time.
-- This simplifies pattern matching to '(ev :| _)' without losing any events in the kernel queue.
capacity :: EdgeEvent.Capacity
capacity = EdgeEvent.userBufferCapacity 1

--------------------------------------------------------------------------------
-- Encoder State Definition
--------------------------------------------------------------------------------

-- Clean pure Haskell record representing the quadrature state and step count.
data EncoderState = EncoderState
  { clkPin   :: !Int  -- Logical level of CLK line (1 = HIGH, 0 = LOW)
  , dtPin    :: !Int  -- Logical level of DT line (1 = HIGH, 0 = LOW)
  , position :: !Int  -- Accumulated rotary encoder step count
  } deriving (Eq, Show)

-- Initial state at startup (both lines idle at HIGH with 0 position count)
initialState :: EncoderState
initialState = EncoderState { clkPin = 1, dtPin = 1, position = 0 }

main :: IO ()
main = withGpioApp $ do
  putStrLn "Starting request config example..."
  runApp
  putStrLn "Request config example completed successfully."

--------------------------------------------------------------------------------
-- Helper Configurator Brackets
--------------------------------------------------------------------------------

-- Encapsulates the creation and configuration of RequestConfig (consumer label & buffer size).
withAppRequestConfig :: (ReqConf.RequestConfig -> IO r) -> IO r
withAppRequestConfig action = ReqConf.withRequestConfig $ \reqconf -> do
  ReqConf.setConsumer reqconf "encoder-app"
  ReqConf.setBufferSize reqconf 256
  action reqconf

-- Encapsulates line settings configuration (input mode, 1ms debounce, edge detection).
withAppLineSettings :: (Line.Settings -> IO r) -> IO r
withAppLineSettings action = Line.withSettings $ \settings -> do
  Line.setDirection settings Line.DirInput
  Line.setDebouncePeriodUs settings 1000 -- 1ms debounce suitable for rotary encoder hardware
  Line.setEdgeDetection settings Line.EdgeBoth 
  action settings

-- Encapsulates building line configuration for target pin offsets (CLK & DT).
withAppLineConfig :: Line.Settings -> (Line.Config -> IO r) -> IO r
withAppLineConfig settings action = Line.withConfig $ \config -> do
  Line.addSettings config (V.fromList [offsetCLK, offsetDT]) settings
  action config

--------------------------------------------------------------------------------
-- Resource Setup using ContT and Execution with StateT
--------------------------------------------------------------------------------

-- Monadic resource setup using 'ContT' flattens nested 'with...' brackets into a linear 'do' block.
-- 'evalStateT' then runs the application loop with managed pure state ('EncoderState').
runApp :: IO ()
runApp = evalContT $ do
  chip     <- ContT $ withChip chipPath
  reqconf  <- ContT withAppRequestConfig
  settings <- ContT withAppLineSettings
  config   <- ContT $ withAppLineConfig settings
  request  <- ContT $ Line.withRequest chip (Just reqconf) config
  buffer   <- ContT $ EdgeEvent.withBuffer capacity

  -- Run stateful application loop starting with 'initialState'
  liftIO $ evalStateT (appLoop request buffer) initialState

--------------------------------------------------------------------------------
-- Encoder Application Loop using MonadState (StateT)
--------------------------------------------------------------------------------

-- Application loop running in 'StateT EncoderState IO ()'.
appLoop :: Line.Request -> EdgeEvent.Buffer -> StateT EncoderState IO ()
appLoop request buffer = forever $ do
  result <- liftIO $ EdgeEvent.waitEvents request fiveSecondsNs
  case result of
    EdgeEvent.TimeoutResult -> 
      liftIO $ putStrLn "No edge event was read (timeout)."

    EdgeEvent.EventReady req -> do
      (ev :| _) <- liftIO $ EdgeEvent.readEvents req buffer
      oldPos    <- gets position
      
      -- Update pure state cleanly using strict 'modify''
      modify' (updateEncoderState ev)
      
      newPos    <- gets position
      when (newPos /= oldPos)
        $ liftIO $ putStrLn $ "Encoder Position: " ++ show newPos

-- Pure function that updates 'EncoderState' based on incoming 'EdgeEvent'.
-- When CLK transitions to LOW (Falling edge), we inspect the current state of DT:
--   - DT == 1 (HIGH) -> Clockwise rotation (+1)
--   - DT == 0 (LOW)  -> Counter-Clockwise rotation (-1)
updateEncoderState :: EdgeEvent.EdgeEvent -> EncoderState -> EncoderState
updateEncoderState (EdgeEvent.EdgeEvent offset evType _) st = case (offset, evType) of
  (Line.Offset 256, EdgeEvent.Falling) ->
    let delta  = if dtPin st == 1 then 1 else (-1)
    in st { clkPin = 0, position = position st + delta }

  (Line.Offset 256, EdgeEvent.Rising)  -> st { clkPin = 1 }
  (Line.Offset 271, EdgeEvent.Falling) -> st { dtPin = 0 }
  (Line.Offset 271, EdgeEvent.Rising)  -> st { dtPin = 1 }
  _                                    -> st
