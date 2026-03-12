from pyuvm import *

class UARTItem(uvm_sequence_item):
    def __init__(self, name="UARTItem"):
        super().__init__(name)
        self.data = 0
        
    def __eq__(self, other):
        same = self.data == other.data
        return same

    def __str__(self):
        return f"{self.get_name()} : Data: 0x{self.data:02X}"
