# UART Controller with PyUVM Testbench

This project implements a standard UART (Universal Asynchronous Receiver-Transmitter) Controller in Verilog from scratch, and verifies it using a complete UVM-style testbench written in Python with `pyuvm` and `cocotb`.

## What is UART?

UART is a hardware communication protocol that uses asynchronous serial communication. It is one of the oldest and most common ways to send data between two devices.

Key characteristics:
- **Asynchronous**: There is no shared clock signal between the sender and receiver. Instead, both sides agree on a timing speed beforehand (the **Baud Rate**).
- **Serial**: Data is sent one bit at a time over a single wire (TX for transmit, RX for receive).
- **Framing**: Because there is no clock, the data is framed with special bits to tell the receiver when a byte begins and ends:
  - **Start Bit**: A transition from High (Idle) to Low (0) signals the start of a transmission.
  - **Data Bits**: Usually 8 bits of data, sent Least Significant Bit (LSB) first.
  - **Stop Bit**: A return to the High (1) state signals the end of the byte.

## Hardware Implementation (RTL)

The Verilog design is broken down into three main components:

1. **Baud Rate Generator (`baud_gen.v`)**: Since UART is asynchronous, the hardware needs to generate internal timing ticks. This module takes the system clock and divides it down to create a `16x` baud tick.
2. **UART Transmitter (`uart_tx.v`)**: A state machine that takes an 8-bit parallel byte and serializes it out the `tx` wire, adding the Start and Stop bits.
3. **UART Receiver (`uart_rx.v`)**: A more complex state machine that monitors the `rx` wire. When it detects a Start bit (falling edge), it uses the `16x` oversampling clock to wait until the exact center of the bit period before sampling the data line. This makes the receiver highly robust against slight clock drifts between the sender and receiver.
4. **Top Level (`uart_top.v`)**: Wraps the generator, transmitter, and receiver together.

## PyUVM Verification Testbench

The verification environment is built using **[PyUVM](https://github.com/pyuvm/pyuvm)**, which is a Python implementation of the Universal Verification Methodology (UVM) running on top of **cocotb**.

### The Loopback Test
The primary test (`tb/test_uart.py`) is a **Loopback Test**. In the testbench, the transmitter's output wire (`tx`) is physically wired directly back into the receiver's input wire (`rx`). 

The testbench operates as follows:
1. **Sequence (`tb/seq.py`)**: Generates 50 random 8-bit payloads (`UARTItem`).
2. **Driver (`tb/driver.py`)**: Tells the Verilog RTL to transmit the payload, waiting for it to finish. It sends what it *intended* to transmit to the Scoreboard.
3. **Monitor (`tb/monitor.py`)**: Passively listens to the Verilog Receiver logic. When a full byte is deserialized and completely received, it sends it to the Scoreboard.
4. **Scoreboard (`tb/scoreboard.py`)**: Collects the sent items and received items, comparing them one-by-one to ensure the serial bus did not corrupt any data.

### How to Run

1. Activate your Verilator/Python environment:
    ```bash
    source ~/verilator_python/bin/activate
    cd ~/Verilator/uart
    ```

2. Run the simulation using the provided Makefile:
    ```bash
    make sim
    ```
    *(Alternatively, you can run `make test_uart`)*

3. Look for the final PyUVM Scoreboard output to confirm the test passed!

### Viewing Waveforms
The simulation is configured to automatically dump waveform traces. After running the test, you can open the trace in GTKWave:
```bash
gtkwave sim_build/UARTTest.vcd
```
