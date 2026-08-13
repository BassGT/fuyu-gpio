# fuyu-gpio

[![Haskell](https://img.shields.io/badge/Language-Haskell-purple.svg)](https://www.haskell.org/)
[![License](https://img.shields.io/badge/License-LGPL_2.1--or--later-blue.svg)](LICENSE)
[![Hackage](https://img.shields.io/badge/Hackage-fuyu--gpio-blue.svg)](https://hackage.haskell.org/package/fuyu-gpio)

High-level, type-safe, and resource-managed Haskell interface for Linux GPIO character devices using **libgpiod v2**.

Built on top of [`fuyu-gpio-direct`](https://github.com/BassGT/fuyu-gpio-direct), `fuyu-gpio` provides automatic memory management (`bracket` / `with*` style), typed exception handling, metadata snapshots, and zero-copy vector operations for high-performance GPIO I/O.

---

## Features

- **Safe Resource Brackets**: Automatic cleanup of chip handles, settings, line configurations, and requests using `withChip`, `withSettings`, `withConfig`, and `withRequest`.
- **Double-Safe Event Handling**: Event waiting and reading secured by `ReadyRequest` tokens, returning guaranteed `NonEmpty EdgeEvent` lists.
- **Smart Buffer Management**: Validated user-space event buffer allocation via `userBufferCapacity`.
- **Zero-Copy Vector I/O**: High-performance batch line reading and writing using `Data.Vector.Storable`.
- **Structured Metadata**: Clean, qualified metadata accessors via `Fuyu.GPIO.Chip.Info` and `Fuyu.GPIO.Line.Info`.
- **Full FFI Symmetry**: Manual lifecycle submodules (`.Unsafe`) available for custom monad stacks or manual allocation.
- **Strict Exception Handling**: Typed `GpioException` exceptions wrapping POSIX `errno` codes.

---

## Quick Example: Blinking an LED

The following example demonstrates how to verify a GPIO chip, configure an output line, request access from the kernel, and toggle an LED 10 times using nested resource brackets:

```haskell
module Main where

import Fuyu.GPIO.Chip (withChip, isGPIOChip)
import Fuyu.GPIO.Line (withSettings, withConfig, withRequest)
import qualified Fuyu.GPIO.Line as Line

import Control.Concurrent (threadDelay)
import Control.Monad (replicateM_)
import Data.Vector.Storable (singleton)

chipPath :: FilePath
chipPath = "/dev/gpiochip0" 

ledOffset :: Line.Offset 
ledOffset = Line.Offset 269 

main :: IO ()
main = do
   isChip <- isGPIOChip chipPath
   if isChip
     then runApp
     else putStrLn $ chipPath ++ " does not correspond to a valid GPIO Chip"

runApp :: IO ()
runApp = do
   withChip chipPath $ \chip -> do
      withSettings $ \settings -> do
         Line.setDirection settings Line.DirOutput
         withConfig $ \config -> do
            Line.addSettings config (singleton ledOffset) settings
            withRequest chip Nothing config $ \request -> do
               replicateM_ 10 $ do 
                 Line.setValue request ledOffset Line.Active
                 threadDelay 500000 -- 500ms   
                 Line.setValue request ledOffset Line.Inactive
                 threadDelay 500000 -- 500ms
```

---

## Documentation

Complete online Haddock API documentation with hyperlinked source code is published on Hackage:

👉 **[https://hackage.haskell.org/package/fuyu-gpio](https://hackage.haskell.org/package/fuyu-gpio)**

To generate documentation locally with hyperlinked source code:

```bash
cabal haddock --haddock-for-hackage --open
```

---

## Cross-Compilation & Container Environment

`fuyu-gpio` includes a `Dockerfile` targeting **Debian Trixie (ARM64)** pre-configured with GHC 9.10.3, Cabal, and `libgpiod v2`. This is ideal for cross-compiling or building binaries for single-board computers (Raspberry Pi, Orange Pi, BeagleBone, etc.) using Podman or Docker.

### 1. Build the Development Image

```bash
podman build -t fuyu-dev:latest .
```

### 2. Run the Container Environment

Mount your local repository directory into the container to compile:

```bash
podman run --rm -it --userns=keep-id -v $PWD:/app:z fuyu-dev:latest bash
```

### 3. Build inside the Container

Once inside the container shell, build the library and executables using Cabal:

```bash
cabal update

# Build only the library
cabal build lib:fuyu-gpio

# Build library and all examples
cabal build

# Run a specific example directly
cabal run exe:01-blink
```

---

## Module Architecture

| Domain Module | Managed Brackets (`with*`) | Metadata Submodule (`.Info`) | Manual Submodule (`.Unsafe`) |
| :--- | :--- | :--- | :--- |
| **Chip** | `Fuyu.GPIO.Chip` | `Fuyu.GPIO.Chip.Info` | `Fuyu.GPIO.Chip.Unsafe` |
| **Line / Settings** | `Fuyu.GPIO.Line` | `Fuyu.GPIO.Line.Info` | `Fuyu.GPIO.Line.Unsafe` |
| **RequestConfig** | `Fuyu.GPIO.RequestConfig` | — | `Fuyu.GPIO.RequestConfig.Unsafe` |
| **EdgeEvent** | `Fuyu.GPIO.EdgeEvent` | — | `Fuyu.GPIO.EdgeEvent.Unsafe` |

---

## License

This library is distributed under the **LGPL-2.1-or-later** license. See the [LICENSE](LICENSE) file for details.

---

## Author & Maintainer

- **Author**: BassGT
- **Maintainer**: `sebastian11medrano@gmail.com`




