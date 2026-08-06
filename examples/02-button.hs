-- In this example we will learn how to handle a button input using libgpiod line settings.
module Main where

-- High-level resource brackets & exception handling
import Fuyu.GPIO.Chip (withChip)
import Fuyu.GPIO.Exception (withGpioApp)
import Fuyu.GPIO.Line (withSettings, withConfig, withRequest)
import qualified Fuyu.GPIO.Line as Line
import Fuyu.GPIO.EdgeEvent (withEventBuffer)
import qualified Fuyu.GPIO.EdgeEvent as Event

-- Base & third-party libraries
import Control.Monad (forever)
import Data.Vector.Storable (singleton)

chipPath :: FilePath
chipPath = "/dev/gpiochip0" 

-- This constant defines the maximum duration 'waitEdgeEvents' will wait for an event.
-- (This timeout can also be configured as infinite or immediate).
fiveSecondsNs :: Event.Timeout
fiveSecondsNs = Event.Nanoseconds 5000000000 

-- Do not confuse this with kernel ring buffer capacity. 'Capacity' refers to the user-space event buffer.
-- It is clamped between 1 and 1024, and must be constructed via 'userBufferCapacity'
-- (passing 0 defaults to 64).
bufferCapacity :: Event.Capacity
bufferCapacity = Event.userBufferCapacity 1 
 
buttonOffset :: Line.Offset
buttonOffset = Line.offset 257 


buttonSettings :: Line.Settings -> IO ()
buttonSettings stgs = do
  Line.setDirection stgs Line.DirInput     -- Configure line as input mode
  Line.setBias stgs Line.BiasPullUp        -- Enable internal pull-up resistor
                                           -- (the physical button connects GND when pressed, driving the line to Inactive)
  Line.setDebouncePeriodUs stgs 20000      -- 20ms debounce period to filter out mechanical contact bounce without threadDelay
  Line.setEdgeDetection stgs Line.EdgeBoth -- Listen for both Rising and Falling edge transitions

buttonWorker :: Line.Request -> Event.Buffer -> IO ()
buttonWorker req buf = do
  res <- Event.waitEdgeEvents req fiveSecondsNs
  case res of 
    Event.EventReady readyReq -> do
      events <- Event.readEdgeEvents readyReq buf -- Read events from user buffer (configured with capacity 1)
      print events    
    Event.TimeoutResult -> putStrLn "Timeout: No event was read" -- Printed after the 5-second wait timeout expires

main :: IO ()
main = withGpioApp runApp

runApp :: IO ()
runApp = do
  withChip chipPath $ \chip -> do
    withSettings $ \settings -> do
      buttonSettings settings
      withConfig $ \config -> do
        Line.addSettings config (singleton buttonOffset) settings
        withRequest chip Nothing config $ \request -> do
          withEventBuffer bufferCapacity $ \buffer -> do
            putStrLn "Loop started: Press the button to generate events or Ctrl+C to exit"
            forever (buttonWorker request buffer)
