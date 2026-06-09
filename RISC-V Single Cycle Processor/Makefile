# ============================================================
#  RV32I Single-Cycle Processor — Makefile
# ============================================================
IVERILOG = iverilog
VVP      = vvp

TOP      = tb/tb_riscv_single_cycle.v
SIM_OUT  = sim/sim.vvp

.PHONY: all sim clean waves

all: sim

sim: $(SIM_OUT)
	$(VVP) $(SIM_OUT) | tee sim/results.log

$(SIM_OUT): $(TOP) rtl/*.v
	@mkdir -p sim
	$(IVERILOG) -g2012 -Wall -o $(SIM_OUT) $(TOP)

waves: sim
	gtkwave sim/waves.vcd &

clean:
	rm -rf sim/
