`timescale 1ns/1ps

module uart_rx_only_tb;

    localparam integer OVERSAMPLE  = 16;
    // Tick divisor: tick_16x fires once every TICK_DIV clocks.
    // Chosen to keep the testbench self-contained without a full baud generator.
    localparam integer TICK_DIV    = 4;

    reg clk;
    reg rst_n;
    reg rx_serial;
    reg parity_en;
    reg parity_odd;

    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_busy;
    wire parity_error;
    wire framing_error;

    // -----------------------------------------------------------------
    // FIX 4: tick_16x is a 1-clock-wide pulse fired every TICK_DIV
    // cycles, matching the behaviour of uart_top's baud generator.
    // The previous implementation toggled every clock (50% duty cycle),
    // which drove the RX FSM at 2x the intended rate.
    // -----------------------------------------------------------------
    reg [2:0] tick_count;
    reg       tick_16x;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_count <= 3'd0;
            tick_16x   <= 1'b0;
        end else begin
            if (tick_count == (TICK_DIV - 1)) begin
                tick_count <= 3'd0;
                tick_16x   <= 1'b1;
            end else begin
                tick_count <= tick_count + 3'd1;
                tick_16x   <= 1'b0;
            end
        end
    end
    // -----------------------------------------------------------------

    uart_rx #(
        .OVERSAMPLE(OVERSAMPLE)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .tick_16x(tick_16x),
        .rx_serial(rx_serial),
        .parity_en(parity_en),
        .parity_odd(parity_odd),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_busy(rx_busy),
        .parity_error(parity_error),
        .framing_error(framing_error)
    );

    always #5 clk = ~clk;

    // Wait for N rising edges of tick_16x
    task wait_ticks;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge tick_16x);
        end
    endtask

    // Drive a full UART frame bit-by-bit at tick_16x rate
    task send_frame;
        input [7:0] data;
        input       parity_bit;
        input       stop_bit;
        integer i;
        begin
            // Start bit
            rx_serial <= 1'b0;
            wait_ticks(OVERSAMPLE);

            // Data bits LSB first
            for (i = 0; i < 8; i = i + 1) begin
                rx_serial <= data[i];
                wait_ticks(OVERSAMPLE);
            end

            // Parity bit
            rx_serial <= parity_bit;
            wait_ticks(OVERSAMPLE);

            // Stop bit
            rx_serial <= stop_bit;
            wait_ticks(OVERSAMPLE);

            // Return to idle
            rx_serial <= 1'b1;
            wait_ticks(OVERSAMPLE);
        end
    endtask

    // -----------------------------------------------------------------
    // FIX 3: rx_valid monitor with assertions instead of $display-only.
    // Each frame sets expected_* before calling send_frame so the
    // monitor can check the correct values on rx_valid.
    // -----------------------------------------------------------------
    reg       expect_parity_error;
    reg       expect_framing_error;
    reg [7:0] expect_data;

    always @(posedge clk) begin
        if (rx_valid) begin
            $display("[RX_ONLY_TB] RX=0x%02h parity_error=%0d framing_error=%0d",
                     rx_data, parity_error, framing_error);

            if (rx_data !== expect_data)
                $fatal(1, "[FAIL] Data mismatch: got 0x%02h, expected 0x%02h",
                       rx_data, expect_data);

            if (parity_error !== expect_parity_error)
                $fatal(1, "[FAIL] parity_error=%0d, expected %0d",
                       parity_error, expect_parity_error);

            if (framing_error !== expect_framing_error)
                $fatal(1, "[FAIL] framing_error=%0d, expected %0d",
                       framing_error, expect_framing_error);

            $display("[PASS] Frame verified correctly.");
        end
    end
    // -----------------------------------------------------------------

    initial begin
        clk        = 1'b0;
        rst_n      = 1'b0;
        rx_serial  = 1'b1;
        parity_en  = 1'b1;
        parity_odd = 1'b0;

        expect_data          = 8'h00;
        expect_parity_error  = 1'b0;
        expect_framing_error = 1'b0;

        $dumpfile("uart_rx_only_tb.vcd");
        $dumpvars(0, uart_rx_only_tb);

        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        // --- Frame 1: 0x3C, even parity correct, stop=1 (no errors expected) ---
        expect_data          = 8'h3C;
        expect_parity_error  = 1'b0;
        expect_framing_error = 1'b0;
        send_frame(8'h3C, ^8'h3C, 1'b1);

        // --- Frame 2: 0xA5, intentionally WRONG parity, stop=1 ---
        // ~(^8'hA5) flips the correct even parity bit -> parity_error expected
        expect_data          = 8'hA5;
        expect_parity_error  = 1'b1;
        expect_framing_error = 1'b0;
        send_frame(8'hA5, ~(^8'hA5), 1'b1);

        // --- Frame 3: 0xF0, correct parity, stop=0 (framing error expected) ---
        expect_data          = 8'hF0;
        expect_parity_error  = 1'b0;
        expect_framing_error = 1'b1;
        send_frame(8'hF0, ^8'hF0, 1'b0);

        repeat (200) @(posedge clk);
        $display("[RX_ONLY_TB] All frames completed.");
        $finish;
    end

endmodule
