module uart_tx #(
    parameter integer OVERSAMPLE = 16
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tick_16x,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    input  wire       parity_en,
    input  wire       parity_odd,
    output reg        tx_serial,
    output reg        tx_busy,
    output reg        tx_done
);

    localparam [2:0] ST_IDLE   = 3'd0;
    localparam [2:0] ST_START  = 3'd1;
    localparam [2:0] ST_DATA   = 3'd2;
    localparam [2:0] ST_PARITY = 3'd3;
    localparam [2:0] ST_STOP   = 3'd4;

    // SAMPLE_W: enough bits to count 0..(OVERSAMPLE-1) for any OVERSAMPLE value.
    // The +1 beyond $clog2 prevents rollover when OVERSAMPLE is an exact power of two
    // (e.g. OVERSAMPLE=16 -> $clog2=4, so without +1 the counter maxes at 15 = 4'b1111
    // and wraps before the == check can fire).
    localparam integer SAMPLE_W = $clog2(OVERSAMPLE) + 1;

    // BIT_W: enough bits to index 8 data bits (0..7); +1 is future-proof for
    // wider data words without touching the state machine logic.
    localparam integer BIT_W    = $clog2(8) + 1;

    reg [2:0]          state;
    reg [BIT_W-1:0]    bit_index;
    reg [SAMPLE_W-1:0] sample_count;
    reg [7:0]          tx_shift;
    reg                parity_bit;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= ST_IDLE;
            bit_index    <= 0;
            sample_count <= 0;
            tx_shift     <= 8'h00;
            parity_bit   <= 1'b0;
            tx_serial    <= 1'b1;
            tx_busy      <= 1'b0;
            tx_done      <= 1'b0;
        end else begin
            tx_done <= 1'b0;

            case (state)
                ST_IDLE: begin
                    tx_serial    <= 1'b1;
                    tx_busy      <= 1'b0;
                    bit_index    <= 0;
                    sample_count <= 0;

                    if (tx_start) begin
                        tx_busy    <= 1'b1;
                        tx_shift   <= tx_data;
                        parity_bit <= parity_odd ? ~(^tx_data) : (^tx_data);
                        state      <= ST_START;
                    end
                end

                ST_START: begin
                    tx_serial <= 1'b0;
                    if (tick_16x) begin
                        if (sample_count == (OVERSAMPLE - 1)) begin
                            sample_count <= 0;
                            state        <= ST_DATA;
                        end else begin
                            sample_count <= sample_count + 1;
                        end
                    end
                end

                ST_DATA: begin
                    tx_serial <= tx_shift[bit_index];
                    if (tick_16x) begin
                        if (sample_count == (OVERSAMPLE - 1)) begin
                            sample_count <= 0;
                            if (bit_index == 7) begin
                                bit_index <= 0;
                                state     <= parity_en ? ST_PARITY : ST_STOP;
                            end else begin
                                bit_index <= bit_index + 1;
                            end
                        end else begin
                            sample_count <= sample_count + 1;
                        end
                    end
                end

                ST_PARITY: begin
                    tx_serial <= parity_bit;
                    if (tick_16x) begin
                        if (sample_count == (OVERSAMPLE - 1)) begin
                            sample_count <= 0;
                            state        <= ST_STOP;
                        end else begin
                            sample_count <= sample_count + 1;
                        end
                    end
                end

                ST_STOP: begin
                    tx_serial <= 1'b1;
                    if (tick_16x) begin
                        if (sample_count == (OVERSAMPLE - 1)) begin
                            state        <= ST_IDLE;
                            sample_count <= 0;
                            tx_busy      <= 1'b0;
                            tx_done      <= 1'b1;
                        end else begin
                            sample_count <= sample_count + 1;
                        end
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
