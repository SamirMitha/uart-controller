from pyuvm import *
from .seq_item import UARTItem
import random

class RandomPayloadSeq(uvm_sequence):
    async def body(self):
        for _ in range(50): # Send 50 random bytes
            req = UARTItem("item")
            await self.start_item(req)
            req.data = random.randint(0, 255)
            await self.finish_item(req)
