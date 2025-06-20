
// FIFO Buffer Module
module fifo_buffer #(
    parameter DEPTH = 16,                    // Number of entries in the FIFO
    parameter DATA_WIDTH = 8,                // Width of each data word
    parameter ADDR_WIDTH = $clog2(DEPTH)     // Address width based on FIFO depth
) (
    input clk,                               // Clock input
    input rst,                               // Synchronous reset
    input [DATA_WIDTH -1:0] data_in,         // Input data to write into FIFO
    input write_en,                          // Write enable signal
    input read_en,                           // Read enable signal
    output [DATA_WIDTH -1:0] data_out,       // Output data from FIFO
    output fifo_full,                        // FIFO full indicator
    output fifo_empty,                       // FIFO empty indicator
    output data_out_valid                    // High when valid data is available for read
);

    // FIFO memory array
    reg [DATA_WIDTH -1:0] memory [0:DEPTH-1];

    // Write and read pointers
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;

    // Counter to track number of items in FIFO
    reg [ADDR_WIDTH:0] fifo_count;

    // Sequential logic for write and read operations
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset FIFO state
            wr_ptr <= 0;
            rd_ptr <= 0;
            fifo_count <= 0;
        end else begin
            // Write operation
            if (write_en && (fifo_count < DEPTH)) begin
                memory[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
                fifo_count <= fifo_count + 1;
            end
            // Read operation
            if (read_en && (fifo_count > 0)) begin
                rd_ptr <= rd_ptr + 1;
                fifo_count <= fifo_count - 1;  
            end
        end
    end

    // Assign the current read pointer value to data output
    assign data_out = memory[rd_ptr];

    // FIFO status indicators
    assign fifo_full = (fifo_count == DEPTH);
    assign fifo_empty = (fifo_count == 0);
    assign data_out_valid = (fifo_count > 0);

endmodule
