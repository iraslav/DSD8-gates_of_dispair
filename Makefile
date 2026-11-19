# Makefile -- the four commands that certify this repository.
#
#   make lint         verilator --lint-only on rtl/ (no inferred latches, etc.)
#   make test         every unit testbench under tb/ (tb_*.v except tb_dsd8.v)
#   make conformance  the full conformance suite (tests/conformance/*.asm)
#   make all          lint + test + conformance, in that order
#   make nn           regenerate tests/nn/*.asm from nn/data/weights_q.json
#   make bench        NN end-to-end: RTL vs golden for all samples + speedup table
#   make cnn          regenerate tests/cnn/*.asm from cnn/data/weights_q.json
#   make cnnbench     CNN end-to-end: RTL vs golden for all samples + speedup table
#   make waveform     compact processor + NN accelerator VCD for GTKWave
#
# The pre-push hook (githooks/pre-push, installed by
# scripts/install_hooks.sh) runs `lint` and `test` before every push,
# so what passes here is what gets graded.

PYTHON ?= python3

.PHONY: all lint test conformance nn bench cnn cnnbench waveform clean

all: lint test conformance

lint:
	bash ./scripts/lint.sh

test:
	$(PYTHON) scripts/run_unit_tests.py

conformance:
	$(PYTHON) scripts/run_conformance.py

nn:
	$(PYTHON) nn/gen_programs.py

bench: nn
	$(PYTHON) scripts/run_nn.py

cnn:
	$(PYTHON) cnn/gen_programs_cnn.py

cnnbench: cnn
	$(PYTHON) scripts/run_cnn.py

waveform:
	$(PYTHON) scripts/run_waveform.py

clean:
	rm -rf build
