-- In this example we will learn how to coordinate GPIO output (LED blinking) and input (button press)
-- concurrently using 'forkIO' and an 'MVar' to dynamically control the LED blinking speed upon
-- detecting button press edge events.
--
-- We introduce 'Control.Monad.Managed' ('managed', 'runManaged') to acquire and compose nested resources
-- in a clean, linear 'do' block. This effectively eliminates the "Pyramid of Doom" (deeply nested 'with*'
-- brackets) in an accessible, lightweight manner before introducing more advanced abstractions like
-- monad transformers ('ContT' / 'StateT') in example 05.
module Main where

-- High-level resource brackets & exception handling
import Fuyu.GPIO.Chip (Chip, withChip)
import Fuyu.GPIO.Exception (withGpioApp)
import qualified Fuyu.GPIO.Line as Line
import qualified Fuyu.GPIO.EdgeEvent as Event

-- Base & third-party libraries
import Control.Monad.Managed (managed, runManaged)
import Control.Monad.IO.Class (liftIO)
import Control.Concurrent (MVar, forkIO, killThread, modifyMVar_, newMVar, readMVar, threadDelay)
import Control.Exception (finally)
import Control.Monad (forever)
import Data.Vector.Storable (singleton)
import System.IO (BufferMode(NoBuffering), hSetBuffering, stdout)

chipPath :: FilePath
chipPath = "/dev/gpiochip0"

-- This constant defines the maximum duration 'waitEvents' will wait for an event.
-- A short 100ms timeout yields execution back to the RTS so worker threads run smoothly.
waitTimeoutNs :: Event.Timeout
waitTimeoutNs = Event.Nanoseconds 100000000 

-- Do not confuse this with kernel ring buffer capacity. 'Capacity' refers to the user-space event buffer.
-- It is clamped between 1 and 1024, and must be constructed via 'userBufferCapacity'
-- (passing 0 defaults to 64).
bufferCapacity :: Event.Capacity
bufferCapacity = Event.userBufferCapacity 1

ledOffset :: Line.Offset
ledOffset = Line.Offset 256 

buttonOffset :: Line.Offset
buttonOffset = Line.Offset 271

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

myLedSettings :: Line.Settings -> IO ()
myLedSettings stgs = Line.setDirection stgs Line.DirOutput

myButtonSettings :: Line.Settings -> IO ()
myButtonSettings stgs = do
  Line.setDirection stgs Line.DirInput     -- Configure line as input mode
  Line.setBias stgs Line.BiasPullUp        -- Enable internal pull-up resistor
                                           -- (the physical button connects GND when pressed, driving the line to Inactive)
  Line.setDebouncePeriodUs stgs 80000      -- 80ms native kernel debounce period to filter out mechanical contact bounce without threadDelay
  Line.setEdgeDetection stgs Line.EdgeFalling -- Listen for Falling edge transitions (button press to GND)

-- Blinks the LED continuously using the delay duration read from the MVar
ledWorker :: Line.Request -> MVar LooptimeState -> IO ()
ledWorker req speedMVar = forever $ do
  lts <- readMVar speedMVar
  let delayUs = stateToMicroseconds lts
  Line.setValue req ledOffset Line.Active
  threadDelay delayUs
  Line.setValue req ledOffset Line.Inactive
  threadDelay delayUs

-- Listens for button edge events and cycles the blinking speed state
buttonWorker :: Line.Request -> Event.Buffer -> MVar LooptimeState -> IO ()
buttonWorker req buf speedMVar = do
  res <- Event.waitEvents req waitTimeoutNs
  case res of
    Event.EventReady readyReq -> do
      _events <- Event.readEvents readyReq buf -- Read events from user buffer (configured with capacity 1)
      modifyMVar_ speedMVar (return . nextSpeed)
    Event.TimeoutResult -> threadDelay 20000 -- 20ms pause to yield file descriptor to LED worker thread

withAppConfig :: Line.Settings -> Line.Settings -> (Line.Config -> IO r) -> IO r
withAppConfig ledStgs btnStgs action =
   Line.withConfig $ \config -> do   
     Line.addSettings config (singleton ledOffset)  ledStgs
     Line.addSettings config (singleton buttonOffset)  btnStgs
     action config
        
withAppRequest :: Chip -> Line.Config -> (Line.Request -> IO r) -> IO r
withAppRequest chip = Line.withRequest chip Nothing 

main :: IO ()
main = withGpioApp runApp

---------------------------------------------------------------------
-- Resource Management with Managed (avoiding the Pyramid of Doom)
---------------------------------------------------------------------

runApp :: IO ()
runApp = do
  hSetBuffering stdout NoBuffering
  initialSpeedMVar <- newMVar OneSec

  -- Instead of nesting 6 levels of 'with*' brackets, 'runManaged' flattens
  -- resource acquisition sequentially while guaranteeing safe cleanup on exit.
  runManaged $ do
    chip        <- managed (withChip chipPath)
    ledSettings <- managed Line.withSettings
    btnSettings <- managed Line.withSettings
    liftIO $ do
      myLedSettings ledSettings
      myButtonSettings btnSettings
    config      <- managed (withAppConfig ledSettings btnSettings)
    request     <- managed (withAppRequest chip config)
    buffer      <- managed (Event.withBuffer bufferCapacity)
    liftIO (appLoop request initialSpeedMVar buffer)
  
appLoop :: Line.Request -> MVar LooptimeState -> Event.Buffer -> IO ()
appLoop request speed buffer = do
  Line.setValue request ledOffset Line.Inactive
  putStrLn "Loop started: LED blinking concurrently. Press the button to change speed, or Ctrl+C to exit"
  tid <- forkIO (forever $ ledWorker request speed)
  forever (buttonWorker request buffer speed) `finally` killThread tid

{-
-- For comparison, here is how 'runApp' would look without 'Control.Monad.Managed'
-- (demonstrating the "Pyramid of Doom" caused by multiple nested brackets):

runAppPyramid :: IO ()
runAppPyramid = do
  hSetBuffering stdout NoBuffering
  initialSpeedMVar <- newMVar OneSec
  withChip chipPath $ \chip -> do  
    withSettings $ \btnStgs -> do
      myButtonSettings btnStgs
      withSettings $ \ledStgs -> do 
        myLedSettings ledStgs
        withConfig $ \config -> do
          Line.addSettings config (singleton ledOffset) ledStgs
          Line.addSettings config (singleton buttonOffset) btnStgs
          withRequest chip Nothing config $ \request -> do
            withBuffer bufferCapacity $ \buffer -> do
              appLoop request initialSpeedMVar buffer
-}
