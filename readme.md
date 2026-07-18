# Verilog UART TX/RX

[![Domain](https://img.shields.io/badge/Domain-VLSI-blueviolet.svg)](#)
[![HDL](https://img.shields.io/badge/HDL-Verilog-blue.svg)](#)
[![Simulation CI](https://github.com/rajdeep13-coder/UART-transmitter-Verilog/actions/workflows/sim-ci.yml/badge.svg)](https://github.com/rajdeep13-coder/UART-transmitter-Verilog/actions/workflows/sim-ci.yml)

Compact, vendor-independent UART transmitter/receiver RTL with parity support, parameterized oversampling, loopback simulation, and FPGA project scaffolding for Vivado/Quartus flows.

---

## Protocol Overview

![UART Frame & Waveform](docs/UART_state_machine_%26_waveform.png)

A UART frame consists of a start bit (low), 8 data bits (LSB first), an optional parity bit, and a stop bit (high). The receiver samples each bit at the mid-point of its window using oversampling ticks.

![UART Block Diagram](docs/UART2.png)

---

## Project Summary

This project implements a reusable UART (Universal Asynchronous Receiver/Transmitter) communication core in Verilog, including both transmit (TX) and receive (RX) paths. It converts parallel bytes to serial UART frames and reconstructs received serial frames back into bytes, with optional parity checking and framing/parity error reporting.

The core is entirely written in Verilog with no vendor-specific IP, making it portable across any FPGA family (Xilinx, Intel/Altera, Lattice) or ASIC flow.

It is useful for:

- Learning digital communication protocol design in RTL
- Integrating serial debug/command interfaces in FPGA projects
- Serving as a clean reference design for UART timing, framing, and verification

Core functions provided:

- UART byte transmission with configurable baud and oversampling
- UART byte reception with start-bit validation and error flags
- Loopback testbench and script-based simulation workflow for quick validation

---

## Features

- Configurable `CLK_FREQ_HZ`, `BAUD_RATE`, and `OVERSAMPLE` (default `16`)
- Supports any power-of-two `OVERSAMPLE` value (16, 32, 64…) — counter widths scale automatically via `$clog2`
- TX frame: `start(0)` + `8 data bits (LSB first)` + `optional parity` + `stop(1)`
- RX two-flop input synchroniser to prevent metastability
- RX start-bit validation at mid-bit (`OVERSAMPLE/2`) to reject glitches
- RX status outputs: `rx_valid`, `parity_error`, `framing_error`
- Ready-to-run simulation flow for Windows PowerShell and Linux/macOS
- Arty A7 XDC with real pin assignments ready to use out of the box

---

## Why a Custom Verilog UART?

- **Vendor independence** — no AXI wrappers, no encrypted IP, synthesizes on any toolchain
- **Resource efficiency** — minimal LUT/FF usage; no bloat from features you don't need
- **Readable RTL** — clean state machine structure, suitable as a learning reference or interview piece
- **Foundation block** — drop it into any FPGA design that needs a serial debug/command channel

---

## Port Interface

### `uart_top` (top-level)

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low synchronous reset |
| `tx_start` | input | 1 | Pulse high for one clock to begin TX |
| `tx_data` | input | 8 | Byte to transmit (captured on `tx_start`) |
| `parity_en` | input | 1 | Enable parity bit in frame |
| `parity_odd` | input | 1 | `1` = odd parity, `0` = even parity |
| `tx_serial` | output | 1 | UART TX line (connect to RX of target) |
| `tx_busy` | output | 1 | High while TX frame is in progress |
| `tx_done` | output | 1 | One-cycle pulse when TX frame completes |
| `rx_serial` | input | 1 | UART RX line (connect to TX of source) |
| `rx_data` | output | 8 | Received byte (valid when `rx_valid` is high) |
| `rx_valid` | output | 1 | One-cycle pulse when a frame is received |
| `rx_busy` | output | 1 | High while RX frame is in progress |
| `parity_error` | output | 1 | High if received parity bit is wrong |
| `framing_error` | output | 1 | High if stop bit is not detected as high |
| `baud_tick_16x` | output | 1 | Oversampling tick (exposed for debug/testing) |

### Parameters

| Parameter | Default | Description |
|---|---|---|
| `CLK_FREQ_HZ` | `50_000_000` | Input clock frequency in Hz |
| `BAUD_RATE` | `115_200` | Target baud rate |
| `OVERSAMPLE` | `16` | Oversampling ratio (any power of two) |

---

## Instantiation

Drop `uart_top` into your design like this:

```verilog
uart_top #(
    .CLK_FREQ_HZ (100_000_000),  // 100 MHz (Arty A7)
    .BAUD_RATE   (115_200),
    .OVERSAMPLE  (16)
) u_uart (
    .clk           (clk),
    .rst_n         (rst_n),

    // TX
    .tx_start      (tx_start),
    .tx_data       (tx_data),
    .parity_en     (1'b0),        // disable parity
    .parity_odd    (1'b0),
    .tx_serial     (uart_tx_pin),
    .tx_busy       (tx_busy),
    .tx_done       (tx_done),

    // RX
    .rx_serial     (uart_rx_pin),
    .rx_data       (rx_data),
    .rx_valid      (rx_valid),
    .rx_busy       (rx_busy),
    .parity_error  (parity_error),
    .framing_error (framing_error),

    .baud_tick_16x ()             // leave open if not needed
);
```

---

## Repository Layout

```
UART-transmitter-Verilog/
├── src/                 # RTL: uart_tx.v, uart_rx.v, uart_top.v
├── test/                # Verilog testbenches + Cocotb Python tests
├── sim/                 # Icarus + GTKWave scripts and Makefile
├── constraints/         # Arty A7 (ready) and Basys3 (template) XDC files
├── fpga/
│   ├── vivado_project/  # See README inside for Vivado setup steps
│   └── quartus_project/ # See README inside for Quartus setup steps
├── docs/                # Waveform and block diagram images
├── .gitignore
├── LICENSE
└── readme.md
```

---

## Prerequisites

| Tool | Purpose |
|---|---|
| Icarus Verilog (`iverilog`, `vvp`) | Compile and run Verilog simulations |
| GTKWave | View `.vcd` waveform files (optional) |
| Python 3.6+ | Required for Cocotb testbenches |
| `cocotb`, `pytest` | Python-based simulation framework |

### Install on Windows (Chocolatey)

```powershell
choco install iverilog gtkwave -y
pip install cocotb pytest
```

### Install on Linux/macOS

```bash
sudo apt-get install iverilog gtkwave   # Debian/Ubuntu
pip install cocotb pytest
```

### Icarus troubleshooting (Windows)

If `iverilog` is not found after install:

1. Open PowerShell **as Administrator** and clear lock files:

```powershell
Remove-Item "C:\ProgramData\chocolatey\lib\*.lock" -Force -ErrorAction SilentlyContinue
choco install iverilog -y
```

2. Open a **new** terminal and verify:

```powershell
iverilog -V
vvp -V
```

If local install remains blocked, push the repo — the GitHub Actions CI will run the simulation in the cloud automatically.

---

## Quick Start

### Option A: PowerShell (Windows)

```powershell
# Full loopback testbench
Set-Location sim
.\run_sim.ps1 -Target main

# RX-only testbench
.\run_sim.ps1 -Target rx

# Open waveform in GTKWave after run
.\run_sim.ps1 -Target main -Wave
```

### Option B: Make (Linux/macOS)

```bash
cd sim
make run        # loopback testbench
make run-rx     # RX-only testbench
make wave       # run + open GTKWave
```

### Option C: Cocotb Python Testbenches

```bash
cd test
make
```

---

## Test Coverage

The Cocotb test suite (`test/test_uart.py`) covers three scenarios:

| Test | What it verifies |
|---|---|
| `test_uart_loopback` | Sends 20 random bytes TX→RX; asserts data integrity and no errors for each |
| `test_uart_parity` | Transmits a fixed byte set with even and odd parity; asserts `parity_error` stays low |
| `test_uart_bad_parity_sets_error` | Injects a frame with a deliberately flipped parity bit; asserts `parity_error` goes high |

The Verilog testbenches (`uart_tb.v`, `uart_rx_only_tb.v`) additionally cover framing error detection with a bad stop bit.

---

## UART Timing Notes

- `OVERSAMPLE=16` means one UART bit spans 16 oversampling ticks.
- TX advances to the next bit every 16 ticks.
- RX validates the start bit at tick `OVERSAMPLE/2` (mid-bit) to reject glitches, then samples each data bit every 16 ticks thereafter.
- Counter widths scale with `$clog2(OVERSAMPLE)+1` — safe for any power-of-two oversample ratio.

---

## FPGA Bring-Up Notes

- **Arty A7-35T / A7-100T**: `constraints/arty_a7.xdc` has real pin assignments filled in — `clk` on `E3`, `rx_serial` on `A9`, `tx_serial` on `D10`. Uncomment and it's ready.
- **Basys3**: `constraints/basys3.xdc` is a template with pin suggestions for Rev. D. Check your board revision and fill in the correct `PACKAGE_PIN` values.
- Set `CLK_FREQ_HZ` to match your board's oscillator (100 MHz for both Arty A7 and Basys3).
- Keep top-level port names aligned with `uart_top.v` (`clk`, `rst_n`, `rx_serial`, `tx_serial`).

---

## Development Notes

- RTL is written in Verilog-2001 style and compiles cleanly with `iverilog -g2012`.
- Generated simulation artifacts (`*.vvp`, `*.vcd`) are excluded by `.gitignore`.
- See `CONTRIBUTING.md` for the recommended contribution and PR workflow.

---

## License

This project is licensed under the MIT License. See [`LICENSE`](LICENSE).
