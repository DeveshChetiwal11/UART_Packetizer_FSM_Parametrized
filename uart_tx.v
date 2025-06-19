// UART Transmitter Module
module uart_tx #(
    parameter CLKS_PER_BIT = 50_000_000/9600 // Default for 50MHz clock and 9600 baud
) (
    input clk,
    input rst,
    input tx_ready,
    input fifo_empty,
    input [7:0] fifo_data_out,
    output reg fifo_read,
    output reg serial_out,
    output tx_busy
);

    parameter IDLE      = 2'b00;
    parameter START_BIT = 2'b01;
    parameter DATA_BITS = 2'b10;
    parameter STOP_BIT  = 2'b11;

    reg [1:0] state        = 0;
    reg [15:0] clock_count = 0;
    reg [2:0] bit_index    = 0;
    reg [7:0] Data         = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            serial_out  <= 1;
            tx_busy     <= 0;
            fifo_read   <= 0;
            clock_count <= 0;
            bit_index   <= 0;
        end else begin
            fifo_read <= 0;
            case (state)
                IDLE :
                  begin
                    serial_out <= 1;
                    clock_count <= 0;
                    bit_index <= 0;
                    if (~fifo_empty && tx_ready) begin
                        tx_busy <= 1;
                        Data <= fifo_data_out;
                        fifo_read <= 1;
                        state <= START_BIT;
                    end
                  end
                START_BIT :
                  begin
                    serial_out <= 0;
                    if (clock_count  < CLKS_PER_BIT - 1) begin
                        clock_count  <= clock_count  + 1;
                    end else begin
                        clock_count  <= 0;
                        state <= DATA_BITS;
                    end
                  end
                DATA_BITS :
                  begin
                    serial_out <= Data[bit_index];
                    if (clock_count  < CLKS_PER_BIT - 1) begin
                        clock_count <= clock_count + 1;
                    end else begin
                        clock_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= STOP_BIT;
                        end
                    end
                  end
                STOP_BIT :
                  begin
                    serial_out <= 1;
                    if (clock_count < CLKS_PER_BIT - 1) begin
                        clock_count <= clock_count + 1;
                    end else begin
                        clock_count <= 0;
                        state <= IDLE;
                        tx_busy <= 0;
                    end
                  end
                default :
                  state <= IDLE;
            endcase
        end
    end


endmodule
