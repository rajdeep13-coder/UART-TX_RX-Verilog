# Quartus Project

This directory is a placeholder for a Quartus Prime project targeting an Intel/Altera FPGA (e.g., DE10-Lite, Cyclone IV/V).

## How to create the project

1. Open Quartus Prime and select **File → New Project Wizard**.
2. Set the project directory to this folder and give it a name (e.g., `uart_top`).
3. Add RTL sources from `../../src/`:
   - `uart_tx.v`
   - `uart_rx.v`
   - `uart_top.v`
4. Set the top-level entity to `uart_top`.
5. Assign pins using the **Pin Planner** or a `.qsf` file. Key parameters to set:
   - `CLK_FREQ_HZ` — match your board's oscillator frequency
   - `BAUD_RATE = 115200`
   - `OVERSAMPLE = 16`

## Notes

- Quartus project files (`.qpf`, `.qsf`, `db/`, `incremental_db/`, `output_files/`) are excluded from Git via `.gitignore`.
- The `.qsf` (settings file) can optionally be checked in to preserve pin assignments — add it manually if you want to commit your pin mapping.
- No vendor-specific constraints file is provided here; use the Pin Planner to assign `clk`, `rst_n`, `rx_serial`, and `tx_serial` to your board's UART and clock pins.
