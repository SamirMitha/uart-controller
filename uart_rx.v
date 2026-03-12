module uart_rx (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       baud_tick_16, // 16x baud rate tick
    input  logic       rx,           // serial input bit

    output logic [7:0] rx_data,      // received byte
    output logic       rx_done       // single cycle pulse when byte is ready
);

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11
    } state_t;

    state_t state, next_state;

    logic [3:0] tick_counter; // 0 to 15 (samples per bit)
    logic [2:0] bit_counter;  // 0 to 7
    logic [7:0] shift_reg;
    
    // Simple synchronizer to mitigate metastability from async RX input
    logic rx_sync_1, rx_sync;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync_1 <= 1'b1;
            rx_sync   <= 1'b1;
        end else begin
            rx_sync_1 <= rx;
            rx_sync   <= rx_sync_1;
        end
    end

    // State Reg
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next State Logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                // Falling edge detected (Start bit)
                if (rx_sync == 1'b0) begin
                    next_state = START;
                end
            end
            START: begin
                // Wait half a bit period (8 ticks) to sample center of start bit
                if (baud_tick_16 && tick_counter == 7) begin
                    if (rx_sync == 1'b0) // Still 0? Valid start bit.
                        next_state = DATA;
                    else
                        next_state = IDLE; // False start
                end
            end
            DATA: begin
                // Wait full bit period (16 ticks) to sample center of data bits
                if (baud_tick_16 && tick_counter == 15 && bit_counter == 7) begin
                    next_state = STOP;
                end
            end
            STOP: begin
                // Wait full bit period (16 ticks) to sample stop bit
                if (baud_tick_16 && tick_counter == 15) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    // Outputs and Internal Registers
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_counter <= '0;
            bit_counter  <= '0;
            shift_reg    <= '0;
            rx_data      <= '0;
            rx_done      <= 1'b0;
        end else begin
            rx_done <= 1'b0; // Default off
            
            case (state)
                IDLE: begin
                    tick_counter <= '0;
                    bit_counter  <= '0;
                end

                START: begin
                    if (baud_tick_16) begin
                        if (tick_counter == 7) begin
                            tick_counter <= '0; // Reset for DATA phase
                        end else begin
                            tick_counter <= tick_counter + 1;
                        end
                    end
                end

                DATA: begin
                    if (baud_tick_16) begin
                        if (tick_counter == 15) begin
                            // Sample at center of the bit (tick 15 relative to start of bit phase)
                            // Actually if we reset at 7 above, the next center is 15 ticks away.
                            shift_reg    <= {rx_sync, shift_reg[7:1]};
                            tick_counter <= '0;
                            bit_counter  <= bit_counter + 1;
                        end else begin
                            tick_counter <= tick_counter + 1;
                        end
                    end
                end

                STOP: begin
                    if (baud_tick_16) begin
                        if (tick_counter == 15) begin
                            // Check Stop bit? Ideally it should be 1. 
                            // We can output data regardless.
                            rx_data <= shift_reg;
                            rx_done <= 1'b1;
                            tick_counter <= '0;
                        end else begin
                            tick_counter <= tick_counter + 1;
                        end
                    end
                end
            endcase
        end
    end

endmodule
