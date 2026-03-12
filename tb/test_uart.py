import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
from pyuvm import *

from tb.env import UARTEnv
from tb.seq import RandomPayloadSeq

# Connect TX to RX inside the testbench for loopback
async def loopback_wire(dut):
    """Wires dut.tx back directly into dut.rx for loopback testing"""
    while True:
        dut.rx.value = dut.tx.value
        await Timer(1, units="ns")

class UARTTest(uvm_test):
    def build_phase(self):
        self.env = UARTEnv("env", self)

    async def run_phase(self):
        self.raise_objection()
        
        # Note: BFM is already set by test_top below
        seq = RandomPayloadSeq("seq")
        
        # Start Sequence
        await seq.start(self.env.seqr)
        
        # Wait a bit for the last transmission to fully complete (UART is slow!)
        # 1 byte = 10 bits @ baud rate. 
        # If baud is e.g. 104 clocks... Give it 2000 clocks.
        import cocotb
        bfm = cocotb.top
        for _ in range(2000):
            await RisingEdge(bfm.clk)

        self.drop_objection()

@cocotb.test()
async def test_top(dut):
    """UART Loopback PyUVM Test"""
    
    # Start Clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Setup Loopback Wire (TX -> RX)
    cocotb.start_soon(loopback_wire(dut))

    # Run PyUVM
    await uvm_root().run_test("UARTTest")
