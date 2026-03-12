module uart_tx (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       baud_tick_16, // 16x baud tick
    input  logic       tx_start,     // pulse to start transmission
    input  logic [7:0] tx_data,      // byte to send

    output logic       tx,           // serial output bit
    output logic       tx_busy       // 1 when currently transmitting
);

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11
    } state_t;

    state_t state, next_state;
    logic [7:0] shift_reg;
    logic [3:0] tick_counter; // 0 to 15
    logic [2:0] bit_counter;  // 0 to 7

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
                if (tx_start) next_state = START;
            end
            START: begin
                if (baud_tick_16 && tick_counter == 15) next_state = DATA;
            end
            DATA: begin
                if (baud_tick_16 && tick_counter == 15 && bit_counter == 7) next_state = STOP;
            end
            STOP: begin
                if (baud_tick_16 && tick_counter == 15) next_state = IDLE;
            end
        endcase
    end

    // Outputs and Internal logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx           <= 1'b1;
            tx_busy      <= 1'b0;
            shift_reg    <= '0;
            bit_counter  <= '0;
            tick_counter <= '0;
        end else begin
            case (state)
                IDLE: begin
                    tx      <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        shift_reg    <= tx_data;
                        tx_busy      <= 1'b1;
                        tx           <= 1'b0; // Output start bit
                        tick_counter <= '0;
                    end
                end

                START: begin
                    tx      <= 1'b0; // Start bit is 0
                    tx_busy <= 1'b1;
                    if (baud_tick_16) begin
                        if (tick_counter == 15) begin
                            tick_counter <= '0;
                            bit_counter  <= '0;
                        end else begin
                            tick_counter <= tick_counter + 1;
                        end
                    end
                end

                DATA: begin
                    tx      <= shift_reg[0]; // LSB first
                    tx_busy <= 1'b1;
                    if (baud_tick_16) begin
                        if (tick_counter == 15) begin
                            tick_counter <= '0;
                            shift_reg    <= {1'b0, shift_reg[7:1]};
                            bit_counter  <= bit_counter + 1;
                        end else begin
                            tick_counter <= tick_counter + 1;
                        end
                    end
                end

                STOP: begin
                    tx      <= 1'b1; // Stop bit is 1
                    tx_busy <= 1'b1;
                    if (baud_tick_16) begin
                        if (tick_counter == 15) begin
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
