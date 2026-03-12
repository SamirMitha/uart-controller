module uart_top #(
    parameter CLKS_PER_BIT = 104 // Configurable baud rate
)(
    input  logic       clk,
    input  logic       rst_n,

    // TX Interface
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic       tx_busy,
    output logic       tx,       // Serial Out

    // RX Interface
    input  logic       rx,       // Serial In
    output logic [7:0] rx_data,
    output logic       rx_done
);

    logic baud_tick_tx;
    logic baud_tick_rx;

    // Instantiate Baud Rate Generator
    baud_gen #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_baud_gen (
        .clk          (clk),
        .rst_n        (rst_n),
        .baud_tick_tx (baud_tick_tx),
        .baud_tick_rx (baud_tick_rx)
    );

    // Instantiate Transmitter
    uart_tx u_tx (
        .clk          (clk),
        .rst_n        (rst_n),
        .baud_tick_16 (baud_tick_rx),
        .tx_start     (tx_start),
        .tx_data      (tx_data),
        .tx           (tx),
        .tx_busy      (tx_busy)
    );

    // Instantiate Receiver
    uart_rx u_rx (
        .clk          (clk),
        .rst_n        (rst_n),
        .baud_tick_16 (baud_tick_rx),
        .rx           (rx),
        .rx_data      (rx_data),
        .rx_done      (rx_done)
    );

endmodule
