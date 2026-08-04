-- In this example we will learn how to handle a button input using libgpiod line settings.
module Main where

import Fuyu.GPIO.Chip (withChip)
import Fuyu.GPIO.Line as Line 
import Fuyu.GPIO.EdgeEvent as Event
import Fuyu.GPIO.Exception (withGpioApp)

import Data.Vector.Storable (singleton)
import Control.Monad (forever)

chipPath :: FilePath
chipPath = "/dev/gpiochip0" 

-- This constant defines the maximum duration 'waitEdgeEvents' will wait for an event.
-- (This timeout can also be configured as infinite or immediate).
fiveSecondsNs :: Timeout
fiveSecondsNs = Nanoseconds 5000000000 

-- Do not confuse this with kernel ring buffer capacity. 'Capacity' refers to the user-space event buffer.
-- It is clamped between 1 and 1024, and must be constructed via 'userBufferCapacity'
-- (passing 0 defaults to 64).
bufferCapacity :: Capacity
bufferCapacity = userBufferCapacity 1 
 
buttonOffset :: Offset
buttonOffset = offset 257 


buttonSettings :: Settings -> IO ()
buttonSettings stgs = do
  Line.setDirection stgs DirInput     -- Configure line as input mode
  Line.setBias stgs BiasPullUp        -- Enable internal pull-up resistor
                                      -- (the physical button connects GND when pressed, driving the line to Inactive)
  Line.setDebouncePeriodUs stgs 20000 -- 20ms debounce period to filter out mechanical contact bounce without threadDelay
  Line.setEdgeDetection stgs EdgeBoth -- Listen for both Rising and Falling edge transitions

buttonWorker :: Request -> Buffer -> IO ()
buttonWorker req buf = do
  res <- Event.waitEdgeEvents req fiveSecondsNs
  case res of 
    EventReady readyReq -> do
      events <- Event.readEdgeEvents readyReq buf -- Read events from user buffer (configured with capacity 1)
      print events    
    TimeoutResult -> putStrLn "Timeout: No event was read" -- Printed after the 5-second wait timeout expires

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
