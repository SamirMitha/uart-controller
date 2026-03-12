module baud_gen #(
    parameter CLKS_PER_BIT = 104 // e.g., 10MHz Clock / 9600 baud = 1041.6 -> approx 104. 
                                 // For testbenches, we can use much smaller numbers.
)(
    input  logic clk,
    input  logic rst_n,
    output logic baud_tick_tx,   // 1 tick per bit (for Tx)
    output logic baud_tick_rx    // 16 ticks per bit (for Rx oversampling)
);

    // TX Counter (counts to CLKS_PER_BIT)
    logic [$clog2(CLKS_PER_BIT):0] tx_counter;
    
    // RX Counter (counts to CLKS_PER_BIT / 16)
    // Avoid division by 0 if testbench uses very small CLKS_PER_BIT
    localparam RX_MAX = (CLKS_PER_BIT > 16) ? (CLKS_PER_BIT / 16) : 1;
    logic [$clog2(RX_MAX):0] rx_counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_counter   <= '0;
            baud_tick_tx <= 1'b0;
        end else begin
            /* verilator lint_off WIDTHEXPAND */
            if (tx_counter == CLKS_PER_BIT - 1) begin
            /* verilator lint_on WIDTHEXPAND */
                tx_counter   <= '0;
                baud_tick_tx <= 1'b1;
            end else begin
                tx_counter   <= tx_counter + 1;
                baud_tick_tx <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_counter   <= '0;
            baud_tick_rx <= 1'b0;
        end else begin
            /* verilator lint_off WIDTHEXPAND */
            if (rx_counter == RX_MAX - 1) begin
            /* verilator lint_on WIDTHEXPAND */
                rx_counter   <= '0;
                baud_tick_rx <= 1'b1;
            end else begin
                rx_counter   <= rx_counter + 1;
                baud_tick_rx <= 1'b0;
            end
        end
    end

endmodule
