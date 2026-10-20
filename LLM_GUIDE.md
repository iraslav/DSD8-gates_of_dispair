# LLM Guide: DSD8 Gates of Dispair

## 1) Project Purpose
This repository is a **starter/certification framework** for a DSD-8 CPU project, not a finished CPU implementation. Most RTL modules in `rtl/` are placeholders with frozen interfaces and TODO logic.

## 2) What This Repo Contains
- `rtl/`: CPU and component RTL skeletons (`*.v`) with frozen ports.
- `tb/tb_dsd8.v`: supplied conformance harness (do not edit for normal work).
- `tb/tb_alu_example.v`: example self-checking unit testbench pattern.
- `sim/peripherals.v`: instructor-supplied reference peripheral models.
- `tools/dsd8asm.py`: assembler for DSD-8 assembly to `.hex`.
- `tools/dsd8sim.py`: golden reference simulator and trace generator.
- `scripts/run_conformance.py`: assemble + simulate + trace diff pipeline.
- `scripts/run_unit_tests.py`: runs `tb/tb_*.v` (except `tb_dsd8.v`).
- `scripts/lint.sh`: Verilator lint (`--lint-only -Wall`).
- `tests/conformance/`: sample `.asm` conformance programs.
- `doc/`: report templates.

## 3) Current Implementation State (Important)
- `dsd8_cpu.v`, `dsd8_top.v`, and most core modules are placeholders.
- Placeholder CPU keeps `retire=0`, so conformance currently fails by design.
- This is expected until real RTL is implemented.

## 4) Critical Rules for Any Automated Contributor
1. **Keep frozen interfaces unchanged** in RTL modules (ports/names/widths).
2. **Do not break `tb/tb_dsd8.v` compatibility** (grading depends on trace signals).
3. **Respect trace semantics**: `retire` must pulse once per retired instruction in program order.
4. **Preserve testbench output convention** for unit benches:
   - `TESTBENCH: PASS`
   - `TESTBENCH: FAIL (N errors)`
5. **Do not treat conformance pass/fail as optional noise**; trace diff is the core oracle.

## 5) How Verification Works
1. Assemble `.asm` with `tools/dsd8asm.py` into `.hex`.
2. Generate golden trace via `tools/dsd8sim.py`.
3. Compile DUT (`rtl/*.v` + `sim/peripherals.v` + `tb/tb_dsd8.v`) with Icarus.
4. Run DUT simulation and emit DUT trace.
5. Diff golden and DUT traces; first mismatch is reported.

## 6) Standard Commands
- `make lint`
- `make test`
- `make conformance`
- `make all`

Equivalent scripts:
- `python3 scripts/run_unit_tests.py`
- `python3 scripts/run_conformance.py [optional_test_name_filter]`

## 7) Architecture and Responsibility Hints
Based on file headers:
- Member A modules: `prog_counter.v`, `instr_decoder.v`, `instr_memory.v`
- Member B modules: `alu.v`, `flags_reg.v`, `register_file.v`
- Member C modules: `control_unit.v`, `data_memory.v`, `io_bus.v`
- Shared integration: `dsd8_cpu.v`, `dsd8_top.v`

## 8) DSD-8 ISA/Behavior Source of Truth
- For instruction encoding: `tools/dsd8asm.py`
- For instruction semantics and flags: `tools/dsd8sim.py` (`Cpu.step`)
- For conformance output format: `tb/tb_dsd8.v` and `tools/dsd8sim.py::format_trace_line`

## 9) High-Value Editing Strategy for LLMs
1. Implement one module at a time, preserving ports.
2. Add/extend module-level self-checking testbench (`tb_*.v`).
3. Run lint + unit tests immediately after each module change.
4. Run conformance and use first trace mismatch to guide next fix.
5. Avoid broad refactors; this repo expects incremental, trace-driven progress.

## 10) Common Pitfalls
- Editing frozen interfaces and breaking harness compile.
- Changing supplied conformance harness behavior.
- Ignoring I/O handshake (`io_ready`) semantics.
- Incorrect flag updates (especially SUB/CMP carry/borrow convention).
- Failing to keep reset behavior and zero-initialization requirements.

## 11) Suggested Prompt Context for Future LLM Sessions
When asking an LLM to work here, include:
- Target module/file(s)
- Expected spec behavior (opcode/flags/reset/handshake)
- Required checks: `make lint`, `make test`, `make conformance`
- Constraint: preserve frozen ports and conformance harness compatibility
