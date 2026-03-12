from pyuvm import *
from .driver import UARTDriver
from .monitor import UARTMonitor
from .scoreboard import UARTScoreboard

class UARTEnv(uvm_env):
    def build_phase(self):
        self.seqr = uvm_sequencer("seqr", self)
        self.drvr = UARTDriver("drvr", self)
        self.mon = UARTMonitor("mon", self)
        self.scbd = UARTScoreboard("scbd", self)

    def connect_phase(self):
        self.drvr.seq_item_port.connect(self.seqr.seq_item_export)
        # Driver analysis port goes to scoreboard CMD
        self.drvr.ap.connect(self.scbd.cmd_export)
        # Monitor analysis port goes to scoreboard RESULT
        self.mon.ap.connect(self.scbd.result_export)
