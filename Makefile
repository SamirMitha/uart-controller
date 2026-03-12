SIM ?= verilator
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/baud_gen.v
VERILOG_SOURCES += $(PWD)/uart_tx.v
VERILOG_SOURCES += $(PWD)/uart_rx.v
VERILOG_SOURCES += $(PWD)/uart_top.v

TOPLEVEL = uart_top
MODULE = tb.test_uart

# Enable Waveform generation
EXTRA_ARGS += --trace --trace-structs

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: test_uart
test_uart:
	$(MAKE) sim
	mv dump.vcd sim_build/UARTTest.vcd
