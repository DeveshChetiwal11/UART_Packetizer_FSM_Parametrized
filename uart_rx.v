// UART Receiver Module
module uart_rx #(
    parameter CLKS_PER_BIT = 50_000_000/9600 // Clock cycles per UART bit (baud rate), default: 9600 bps @ 50 MHz
)(
    input clk,            // System clock
    input rst,            // Asynchronous reset
    input serial_in,      // Serial input line
    output reg [7:0] data_out,   // Received byte
    output reg data_valid        // Flag indicating data_out is valid
);

    // State encoding for UART receiver FSM
    parameter IDLE         = 2'b00;  // Waiting for start bit
    parameter START_BIT    = 2'b01;  // Receiving start bit
    parameter DATA_BITS    = 2'b10;  // Receiving data bits
    parameter STOP_BIT     = 2'b11;  // Receiving stop bit

    // Internal registers
    reg [2:0] state     = 0;         // Current state of the FSM
    reg [15:0] clock_count = 0;      // Counts clock cycles for bit timing
    reg [2:0] bit_index   = 0;       // Index for data bit being received (0 to 7)
    reg [7:0] rx_Data     = 0;       // Buffer for incoming serial data

    // UART reception state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all internal states and outputs
            state <= IDLE;
            clock_count <= 0;
            bit_index <= 0;
            data_valid <= 0;
        end else begin
            data_valid <= 0; // Default: data not valid unless set in STOP_BIT

            case (state)
                // Wait for falling edge on serial_in (start bit)
                IDLE : begin
                    if (~serial_in) begin // Detect start bit (logic 0)
                        state <= START_BIT;
                        clock_count <= 0;
                    end
                end

                // Wait until the middle of the start bit to confirm it's valid
                START_BIT : begin
                    if (clock_count == (CLKS_PER_BIT - 1) / 2) begin
                        if (~serial_in) begin // Confirm it’s still low (valid start)
                            clock_count <= 0;
                            state <= DATA_BITS;
                        end else begin
                            state <= IDLE; // False start due to noise
                        end
                    end else begin
                        clock_count <= clock_count + 1;
                    end
                end

                // Receive each of the 8 data bits (LSB first)
                DATA_BITS : begin
                    if (clock_count < CLKS_PER_BIT - 1) begin
                        clock_count <= clock_count + 1;
                    end else begin
                        clock_count <= 0;
                        rx_Data[bit_index] <= serial_in; // Sample the current data bit
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= STOP_BIT;
                        end
                    end
                end

                // Receive the stop bit (should be logic high)
                STOP_BIT : begin
                    if (clock_count < CLKS_PER_BIT - 1) begin
                        clock_count <= clock_count + 1;
                    end else begin
                        // Only mark data valid if stop bit is correctly high
                        if (serial_in) begin
                            data_valid <= 1;
                            data_out <= rx_Data; // Transfer received byte to output
                        end
                        state <= IDLE; // Go back to IDLE state for next frame
                    end
                end

                // Fallback to IDLE in case of unexpected state
                default : state <= IDLE;
            endcase
        end
    end

endmodule
