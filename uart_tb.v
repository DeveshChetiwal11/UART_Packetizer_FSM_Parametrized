`timescale 1ns / 1ps

module uart_tb;
    // Clock and Reset
    reg clk;
    reg rst;

    // Inputs to Top Module
    reg [7:0] data_in;
    reg data_valid;
    reg tx_ready;

    // Outputs from Top Module
    wire serial_out;
    wire fifo_full;
    wire tx_busy;

    // Clock generation (50 MHz)
    initial clk = 0;
    always #10 clk = ~clk; // 20ns period -> 50 MHz

    // Instantiate the UART top module
    uart_top uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .tx_ready(tx_ready),
        .serial_out(serial_out),
        .fifo_full(fifo_full),
        .tx_busy(tx_busy)
    );

    // Stimulus
    initial begin
      
        // Initialize signals
        rst = 1;
        data_valid = 0;
        data_in = 8'h00;
        tx_ready = 0;

        // Reset pulse
        #50 rst = 0;

        // Wait a little before sending data
        #100;

        // Send 1st packet
        tx_ready = 1;
        data_in = 8'hA5; // 10100101
        data_valid = 1;
        #20 data_valid = 0; // single pulse

        // Wait a few cycles
        #5000000;

        // Send 2nd packet
        data_in = 8'h3C; // 00111100
        data_valid = 1;
        #20 data_valid = 0;

        // Wait for transmission to finish
        #10000000;

        $finish;
    end
endmodule
