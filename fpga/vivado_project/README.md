# Vivado Project

This directory is a placeholder for a Vivado project targeting the Arty A7 (or any Artix-7 board).

## How to create the project

1. Open Vivado and select **File → Project → New**.
2. Set the project location to this directory.
3. Add RTL sources from `../../src/`:
   - `uart_tx.v`
   - `uart_rx.v`
   - `uart_top.v`
4. Add the constraints file from `../../constraints/arty_a7.xdc`.
5. Set the top-level module to `uart_top`.
6. Configure parameters in the top-level instantiation:
   - `CLK_FREQ_HZ = 100000000` (Arty A7 runs at 100 MHz)
   - `BAUD_RATE = 115200`
   - `OVERSAMPLE = 16`

## Notes

- Vivado project files (`.xpr`, `.cache/`, `.runs/`, `.sim/`) are excluded from Git via `.gitignore`.
- Only source files and constraints are version-controlled; the project is regenerated locally.
- See `../../constraints/arty_a7.xdc` for ready-to-use pin assignments for the Arty A7-35T/100T.
