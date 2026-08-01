# fuyu-gpio

High-level, type-safe, and resource-managed Haskell interface for Linux GPIO character devices using **libgpiod v2**.

Built on top of [`fuyu-gpio-direct`](https://github.com/BassGT/fuyu-gpio-direct), `fuyu-gpio` provides automatic memory management (`bracket` / `with*` style), typed exception handling, metadata snapshots, and zero-copy vector operations for high-performance GPIO I/O.

---

## ⚡ Features

- **Safe Resource Brackets**: Automatic cleanup of chip handles, settings, line configurations, and requests using `withChip`, `withSettings`, `withConfig`, and `withRequest`.
- **Zero-Copy Vector I/O**: High-performance batch line reading and writing using `Data.Vector.Storable`.
- **Structured Metadata**: Clean, qualified metadata accessors via `Fuyu.GPIO.Chip.Info` and `Fuyu.GPIO.Line.Info`.
- **Full FFI Symmetry**: Manual lifecycle submodules (`.Unsafe`) available for custom monad stacks or manual allocation.
- **Strict Exception Handling**: Typed `GpioException` exceptions wrapping POSIX `errno` codes.

---

## 🚀 Quick Example: Blinking Multiple LEDs

The following example demonstrates how to open a GPIO chip, configure multiple output pins, request access, and toggle them concurrently:

```haskell
module Main where

import Control.Concurrent (threadDelay)
import Control.Monad (replicateM_)
import qualified Data.Vector.Storable as V
import Fuyu.GPIO.Chip 
import Fuyu.GPIO.Line 
import qualified Fuyu.GPIO.Line as Line  

-- Define target GPIO line offsets
ledOffsets :: V.Vector Offset
ledOffsets = V.fromList (map offset [256, 271, 268])

-- Define states for turning all LEDs ON or OFF
onValues :: V.Vector Value
onValues = V.fromList [Active, Active, Active]

offValues :: V.Vector Value
offValues = V.fromList [Inactive, Inactive, Inactive]

main :: IO ()
main = do
  -- Safely open the GPIO chip character device
  withChip "/dev/gpiochip0" $ \chip -> do
    -- Configure line direction as Output
    withSettings $ \settings -> do
      Line.setDirection settings DirOutput
      -- Attach settings to configured line offsets
      withConfig $ \config -> do
        Line.addSettings config ledOffsets settings
        -- Request access to the lines from the kernel
        withRequest chip Nothing config $ \request -> do
          -- Blink all 3 LEDs 10 times with 500ms delay
          replicateM_ 10 $ do 
            Line.setValues request onValues
            threadDelay 500000 -- 500ms
            Line.setValues request offValues
            threadDelay 500000 -- 500ms
```

---

## 🐳 Cross-Compilation & Container Environment

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
cabal build
```

---

## 📚 Module Architecture

| Domain Module | Managed Brackets (`with*`) | Metadata Submodule (`.Info`) | Manual Submodule (`.Unsafe`) |
| :--- | :--- | :--- | :--- |
| **Chip** | `Fuyu.GPIO.Chip` | `Fuyu.GPIO.Chip.Info` | `Fuyu.GPIO.Chip.Unsafe` |
| **Line / Settings** | `Fuyu.GPIO.Line` | `Fuyu.GPIO.Line.Info` | `Fuyu.GPIO.Line.Unsafe` |
| **RequestConfig** | `Fuyu.GPIO.RequestConfig` | — | `Fuyu.GPIO.RequestConfig.Unsafe` |
| **EdgeEvent** | `Fuyu.GPIO.EdgeEvent` | — | `Fuyu.GPIO.EdgeEvent.Unsafe` |

---

## 📄 License

This library is distributed under the **LGPL-2.1-or-later** license.

---

## 👤 Author & Maintainer

- **Author**: BassGT
- **Maintainer**: `springtrap9397@gmail.com`




