// Top-level UART Transmitter System with FIFO and FSM
module uart_top #(
    parameter BAUD_RATE = 9600,
    parameter CLK_FREQ = 50_000_000
)(
    input clk,                   // System clock 50 MHz
    input rst,                   // Active-high synchronous reset
    input [7:0] data_in,         // Incoming data byte
    input data_valid,            // Valid pulse for data_in
    input tx_ready,              // Receiver ready (for handshaking)
    output serial_out,           // UART TX serial line
    output fifo_full,            // FIFO full status
    output tx_busy              // UART busy flag
);
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // Intermediate signals
    wire fifo_empty;
    wire data_out_valid;
    wire [7:0] fifo_data_out;
    wire fifo_read_en;

    // FIFO Buffer
    fifo_buffer #(
        .DEPTH(16),
        .DATA_WIDTH(8)
    ) fifo_inst (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .write_en(data_valid),
        .read_en(fifo_read_en),
        .data_out(fifo_data_out),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty),
        .data_out_valid(data_out_valid)
    );

    // UART Transmitter
    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_tx_inst (
        .clk(clk),
        .rst(rst),
        .tx_ready(tx_ready),
        .fifo_empty(fifo_empty),
        .fifo_data_out(fifo_data_out),
        .fifo_read(fifo_read_en),
        .serial_out(serial_out),
        .tx_busy(tx_busy)
    );

endmodule
