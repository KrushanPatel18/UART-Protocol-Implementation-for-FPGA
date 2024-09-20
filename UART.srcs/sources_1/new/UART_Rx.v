module uart_rx (
    input wire clk,            // System clock
    input wire rst,            // Reset signal
    input wire rx_in,          // UART receive input
    output reg [7:0] data_out, // Data received
    output reg rx_done         // Reception complete signal
);

    parameter CLK_FREQ = 50000000;   // Clock frequency (50 MHz)
    parameter BAUD_RATE = 9600;      // Baud rate (9600 bps)
    localparam BAUD_TICKS = CLK_FREQ / BAUD_RATE;

    reg [3:0] bit_counter;    // Number of bits received (start + 8 data + stop)
    reg [15:0] baud_counter;  // Baud rate counter
    reg [9:0] shift_reg;      // Shift register for receiving data
    reg rx_active;            // Reception active flag

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 8'd0;
            rx_done <= 1'b0;
            baud_counter <= 16'd0;
            bit_counter <= 4'd0;
            rx_active <= 1'b0;
        end else begin
            if (!rx_active && rx_in == 1'b0) begin
                // Start bit detected, start reception
                rx_active <= 1'b1;
                baud_counter <= 16'd0;
                bit_counter <= 4'd0;
            end else if (rx_active) begin
                if (baud_counter < BAUD_TICKS) begin
                    baud_counter <= baud_counter + 1;
                end else begin
                    baud_counter <= 16'd0;
                    shift_reg <= {rx_in, shift_reg[9:1]};  // Shift in the received bit
                    bit_counter <= bit_counter + 1;
                    if (bit_counter == 10) begin
                        // Reception complete
                        data_out <= shift_reg[8:1];  // Extract the 8 data bits
                        rx_done <= 1'b1;
                        rx_active <= 1'b0;
                    end
                end
            end else begin
                rx_done <= 1'b0;
            end
        end
    end
endmodule
