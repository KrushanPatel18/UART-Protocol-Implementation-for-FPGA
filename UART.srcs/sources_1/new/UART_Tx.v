module uart_tx (
    input wire clk,            // System clock
    input wire rst,            // Reset signal
    input wire [7:0] data_in,  // Data to be transmitted (8 bits)
    input wire tx_start,       // Start transmission
    output reg tx_out,         // UART transmit output
    output reg tx_done         // Transmission complete signal
);

    parameter CLK_FREQ = 50000000;   // Clock frequency (50 MHz)
    parameter BAUD_RATE = 9600;      // Baud rate (9600 bps)
    localparam BAUD_TICKS = CLK_FREQ / BAUD_RATE;  // Number of clock ticks per baud

    reg [9:0] shift_reg;  // Shift register for transmitting data (start + data + stop)
    reg [15:0] baud_counter;  // Baud rate counter
    reg [3:0] bit_counter;    // Number of bits sent (start + 8 data + stop)
    reg tx_active;            // Transmission active flag

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_out <= 1'b1;  // Idle state is high
            tx_done <= 1'b0;
            baud_counter <= 16'd0;
            bit_counter <= 4'd0;
            tx_active <= 1'b0;
        end else begin
            if (tx_start && !tx_active) begin
                // Start transmission
                shift_reg <= {1'b1, data_in, 1'b0};  // Stop bit + Data + Start bit
                tx_active <= 1'b1;
                baud_counter <= 16'd0;
                bit_counter <= 4'd0;
                tx_done <= 1'b0;
            end else if (tx_active) begin
                // Transmitting data
                if (baud_counter < BAUD_TICKS) begin
                    baud_counter <= baud_counter + 1;
                end else begin
                    baud_counter <= 16'd0;
                    tx_out <= shift_reg[0];  // Transmit LSB first
                    shift_reg <= shift_reg >> 1;  // Shift the data
                    bit_counter <= bit_counter + 1;
                    if (bit_counter == 10) begin
                        tx_active <= 1'b0;  // Transmission complete
                        tx_done <= 1'b1;
                        tx_out <= 1'b1;  // Go back to idle state
                    end
                end
            end
        end
    end
endmodule
