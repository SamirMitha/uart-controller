from pyuvm import *
from cocotb.triggers import RisingEdge, ReadOnly
from .seq_item import UARTItem

class UARTMonitor(uvm_monitor):
    def build_phase(self):
        self.ap = uvm_analysis_port("ap", self)

    async def run_phase(self):
        import cocotb
        self.bfm = cocotb.top
        
        while True:
            await RisingEdge(self.bfm.clk)
            await ReadOnly()
            
            # Listen for the rx_done pulse from the UART Receiver
            if self.bfm.rx_done.value == 1:
                item = UARTItem("mon_item")
                item.data = int(self.bfm.rx_data.value)
                
                # Send received item to scoreboard
                self.ap.write(item)
