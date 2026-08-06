module Main where

-- High-level resource brackets & exception handling
import Fuyu.GPIO.Chip (Chip, withChip)
import Fuyu.GPIO.Line (withRequest, withConfig, withSettings)
import Fuyu.GPIO.Exception (withGpioApp)

-- Qualified Domain Modules
import qualified Fuyu.GPIO.Chip.Watch as Watch
import qualified Fuyu.GPIO.Line as Line

-- Base & third-party libraries
import Control.Concurrent (forkIO, threadDelay)
import Data.Vector.Storable (singleton)

chipPath :: FilePath
chipPath = "/dev/gpiochip0"

targetOffset :: Line.Offset
targetOffset = Line.offset 257

waitTimeoutNs :: Watch.Timeout
waitTimeoutNs = Watch.Nanoseconds 5000000000 -- 5 seconds

main :: IO ()
main = withGpioApp $ do
  putStrLn "Starting line status event monitor..."
  runApp 
  putStrLn "Line status event monitor completed successfully."

-- 'runApp' centralizes worker threads and watchers to avoid pyramid of doom
runApp :: IO ()
runApp = do
  putStrLn "Opening GPIO chip and starting line status watching..."
  withChip chipPath $ \chip -> do
    -- Register the line watch in the kernel before any interaction
    -- (required so the kernel starts queueing status events for targetOffset)
    Watch.withWatchLineInfo chip targetOffset $ \_lineInfo -> do
      _ <- forkIO $ lineApp chip
      monitorApp chip 

-- 'monitorApp' waits for status change events using 'waitInfoEvent' and security token 'ReadyChip'
monitorApp :: Chip -> IO ()
monitorApp chip = do     
  putStrLn "Waiting for line status change event (timeout: 5s)..."
  res <- Watch.waitInfoEvent chip waitTimeoutNs
  case res of
    -- Same pattern as 'Fuyu.GPIO.EdgeEvent.waitEdgeEvents'
    Watch.EventReady readyChip -> do
      Watch.withInfoEvent readyChip $ \infoEvent -> do
        -- In this case, we expect a 'Requested' info event type
        eventType <- Watch.getInfoEventType infoEvent      
        putStrLn ("Event received! " ++ show eventType)
    Watch.TimeoutResult -> putStrLn "Wait timed out (timeout)."

-- 'lineApp' simulates line interactions (requesting access to targetOffset) in a concurrent thread
lineApp :: Chip -> IO () 
lineApp chip = do   
  withSettings $ \settings -> do
    Line.setDirection settings Line.DirAsIs  
    withConfig $ \config -> do
      Line.addSettings config (singleton targetOffset) settings 
      withRequest chip Nothing config $ \request -> do
        name <- Line.getRequestChipName request
        putStrLn ("Line request created successfully on chip: " ++ show name)
        threadDelay 500000 -- Hold requested line briefly
