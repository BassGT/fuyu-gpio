-- In this example we will learn how to coordinate an output (LED blinking) and an input (button press)
-- using concurrent threads and an MVar to dynamically control blinking speed.
module Main where

import Fuyu.GPIO.Chip (withChip)
import Fuyu.GPIO.Line as Line 
import Fuyu.GPIO.EdgeEvent as Event
import Fuyu.GPIO.Exception (withGpioApp)

import Data.Vector.Storable (singleton)
import Control.Monad (forever)
import Control.Concurrent (threadDelay, forkIO, killThread, MVar, newMVar, readMVar, modifyMVar_)
import Control.Exception (finally)
import System.IO (hSetBuffering, stdout, BufferMode(NoBuffering))

chipPath :: FilePath
chipPath = "/dev/gpiochip0"

-- This constant defines the maximum duration 'waitEdgeEvents' will wait for an event.
-- A short 100ms timeout yields execution back to the RTS so worker threads run smoothly.
waitTimeoutNs :: Timeout
waitTimeoutNs = Nanoseconds 100000000 

-- Do not confuse this with kernel ring buffer capacity. 'Capacity' refers to the user-space event buffer.
-- It is clamped between 1 and 1024, and must be constructed via 'userBufferCapacity'
-- (passing 0 defaults to 64).
bufferCapacity :: Capacity
bufferCapacity = userBufferCapacity 1

ledOffset :: Offset
ledOffset = offset 256 

buttonOffset :: Offset
buttonOffset = offset 271

type Microseconds = Int

-- Available blinking speed states
data LooptimeState = OneSec | HalfSec | FifthOfSec | TenthOfSec
  deriving (Eq, Show)

-- Convert LooptimeState into delay duration in microseconds
stateToMicroseconds :: LooptimeState -> Microseconds
stateToMicroseconds OneSec     = 1000000 -- 1.0s delay
stateToMicroseconds HalfSec    = 500000  -- 0.5s delay
stateToMicroseconds FifthOfSec = 200000  -- 0.2s delay
stateToMicroseconds TenthOfSec = 100000  -- 0.1s delay

-- Cycle to the next blinking speed state
nextSpeed :: LooptimeState -> LooptimeState 
nextSpeed OneSec     = HalfSec
nextSpeed HalfSec    = FifthOfSec
nextSpeed FifthOfSec = TenthOfSec
nextSpeed TenthOfSec = OneSec

ledSettings :: Settings -> IO ()
ledSettings stgs = Line.setDirection stgs DirOutput

buttonSettings :: Settings -> IO ()
buttonSettings stgs = do
  Line.setDirection stgs DirInput     -- Configure line as input mode
  Line.setBias stgs BiasPullUp        -- Enable internal pull-up resistor
                                      -- (the physical button connects GND when pressed, driving the line to Inactive)
  Line.setDebouncePeriodUs stgs 80000 -- 80ms native kernel debounce period to filter out mechanical contact bounce without threadDelay
  Line.setEdgeDetection stgs EdgeFalling -- Listen for Falling edge transitions (button press to GND)

-- Worker thread A: Blinks the LED continuously using the delay duration read from the MVar
ledWorker :: Request -> MVar LooptimeState -> IO ()
ledWorker req speedMVar = forever $ do
  lts <- readMVar speedMVar
  let delayUs = stateToMicroseconds lts
  Line.setValue req ledOffset Line.Active
  threadDelay delayUs
  Line.setValue req ledOffset Line.Inactive
  threadDelay delayUs

-- Worker thread B: Listens for button edge events and cycles the blinking speed state
buttonWorker :: Request -> Buffer -> MVar LooptimeState -> IO ()
buttonWorker req buf speedMVar = do
  res <- Event.waitEdgeEvents req waitTimeoutNs
  case res of
    EventReady readyReq -> do
      _events <- Event.readEdgeEvents readyReq buf -- Read events from user buffer (configured with capacity 1)
      modifyMVar_ speedMVar (return . nextSpeed)
    TimeoutResult -> threadDelay 20000 -- 20ms pause to yield file descriptor to LED worker thread

main :: IO ()
main = withGpioApp runApp

runApp :: IO ()
runApp = do
  hSetBuffering stdout NoBuffering
  initialSpeedMVar <- newMVar OneSec
  withChip chipPath $ \chip -> do  
    withSettings $ \buttonStgs -> do
      buttonSettings buttonStgs
      withSettings $ \ledStgs -> do 
        ledSettings ledStgs
        withConfig $ \config -> do
          Line.addSettings config (singleton ledOffset) ledStgs
          Line.addSettings config (singleton buttonOffset) buttonStgs
          withRequest chip Nothing config $ \request -> do
            withEventBuffer bufferCapacity $ \buffer -> do
              Line.setValue request ledOffset Line.Inactive
              putStrLn "Loop started: LED blinking concurrently. Press the button to change speed, or Ctrl+C to exit"
              tid <- forkIO (forever $ ledWorker request initialSpeedMVar)
              forever (buttonWorker request buffer initialSpeedMVar) `finally` killThread tid
