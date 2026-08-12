-- In this example we will learn the basic usage of libgpiod line configuration for output.
-- We check and initialize a GPIO chip, set a line direction to output mode, and blink an LED 10 times
-- using nested resource allocation brackets ('withChip', 'withSettings', 'withConfig', 'withRequest').
module Main where

-- High-level resource brackets & utility functions
import Fuyu.GPIO.Chip (withChip, isGPIOChip)
import Fuyu.GPIO.Line (withSettings, withConfig, withRequest)
import qualified Fuyu.GPIO.Line as Line

-- Base & third-party libraries
import Control.Concurrent (threadDelay)
import Control.Monad (replicateM_)
import Data.Vector.Storable (singleton)

-- We could check if this file is a GPIO Chip with 'isGPIOChip' function
chipPath :: FilePath
chipPath = "/dev/gpiochip0" 

-- In Orange Pi devices we could find this information with 'gpio readall' command (or in docs)
-- In this case the line offset 269 corresponds to physical pin 7 
ledOffset :: Line.Offset 
ledOffset = Line.Offset 269 

main :: IO ()
main = do
   isChip <- isGPIOChip chipPath
   if isChip
     then do 
       putStrLn "Example started: LED blinking"
       runApp
     else putStrLn $ chipPath ++ " does not correspond to a valid GPIO Chip"

runApp :: IO ()
runApp = do
   withChip chipPath $ \chip -> do
      withSettings $ \settings -> do
         Line.setDirection settings Line.DirOutput
         withConfig $ \config -> do
            Line.addSettings config (singleton ledOffset) settings
            -- The use of Nothing instead of a 'RequestConfig' means that we are using a NULL request configuration object.
            -- (Do not confuse Fuyu.GPIO.RequestConfig with Fuyu.GPIO.Line.Config, the first one is used for kernel options
            -- and the second one is used for line config).  
            withRequest chip Nothing config $ \request -> do
               replicateM_ 10 $ do 
                 Line.setValue request ledOffset Line.Active
                 threadDelay 500000 -- 0.5 seconds pause   
                 Line.setValue request ledOffset Line.Inactive
                 threadDelay 500000 -- 0.5 seconds pause
