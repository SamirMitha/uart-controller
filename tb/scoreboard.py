from pyuvm import *
from .seq_item import UARTItem

class UARTScoreboard(uvm_scoreboard):
    def build_phase(self):
        self.cmd_fifo = uvm_tlm_analysis_fifo("cmd_fifo", self)
        self.result_fifo = uvm_tlm_analysis_fifo("result_fifo", self)
        
        self.cmd_export = self.cmd_fifo.analysis_export
        self.result_export = self.result_fifo.analysis_export

        self.passed = True

    async def run_phase(self):
        while True:
            # Wait for both a command (sent byte) and a result (received byte)
            cmd = await self.cmd_fifo.get()
            result = await self.result_fifo.get()

            if cmd == result:
                uvm_root().logger.info(f"PASSED: Sent {cmd.data:02X}, Received {result.data:02X}")
            else:
                uvm_root().logger.error(f"FAILED: Sent {cmd.data:02X}, Received {result.data:02X}")
                self.passed = False

    def check_phase(self):
        if not self.passed:
            self.logger.critical("TEST FAILED")
        else:
            self.logger.info("TEST PASSED")
