from pyuvm import *
from cocotb.triggers import RisingEdge
from .seq_item import UARTItem

class UARTDriver(uvm_driver):
    def build_phase(self):
        self.ap = uvm_analysis_port("ap", self)

    async def run_phase(self):
        import cocotb
        self.bfm = cocotb.top

        # Initial Reset
        self.bfm.rst_n.value = 0
        self.bfm.tx_start.value = 0
        self.bfm.tx_data.value = 0
        self.bfm.rx.value = 1 # Idle high
        await RisingEdge(self.bfm.clk)
        await RisingEdge(self.bfm.clk)
        self.bfm.rst_n.value = 1
        
        while True:
            self.bfm.tx_start.value = 0
            
            # Get next item to send
            item = await self.seq_item_port.get_next_item()
            
            # Wait until Tx is no longer busy
            while self.bfm.tx_busy.value == 1:
                await RisingEdge(self.bfm.clk)
                
            # Drive the item
            self.bfm.tx_data.value = item.data
            self.bfm.tx_start.value = 1
            await RisingEdge(self.bfm.clk)
            
            # Finish transaction
            self.bfm.tx_start.value = 0
            
            # Cocotb/Verilog race condition: wait one extra clock so tx_busy updates
            await RisingEdge(self.bfm.clk)
            
            # Output to analysis port (what we *tried* to send)
            self.ap.write(item)
            self.seq_item_port.item_done()
