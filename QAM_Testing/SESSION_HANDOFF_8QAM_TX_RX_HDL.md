# Session Handoff & Continuation Guide — 8-QAM TX/RX HDL & Vivado Verification

> **Purpose of this file:** Reference this file (`@SESSION_HANDOFF_8QAM_TX_RX_HDL.md` and `@QAM_TxRx_HDL_Technical_Reference.md`) when starting a new session after changing the workspace directory to `D:\HoriTech_Files\QAM_Testing` so the assistant can immediately continue from the exact state reached here.

---

## 1. Executive Summary & Current Status

All requested tasks up to **8-QAM Simulink Implementation (Option A), HDL Coder RTL Generation, and Xilinx Vivado 2019.1 Verification** are **100% complete and verified**:

1. **Original 64-QAM Model Explored & Documented (Untouched)**:
   * Original files in `QAMTxRxHDLExample/` (`commqamtxrxhdl.slx`, `commqamtxrxhdl_init.m`, `commqamtxrxhdl_analyze.m`, `QAMTxRxHDLExample.mlx`) are preserved untouched.
   * Complete block-by-block architecture, fixed-point formats, sample rates, and $M$-QAM modification rules are documented in [`QAM_TxRx_HDL_Technical_Reference.md`](file:///d:/HoriTech_Files/QAM_Testing/QAM_TxRx_HDL_Technical_Reference.md).
2. **Standalone 8-QAM Simulink Design (Option A) Built & Verified**:
   * Created standalone model [`QAMTxRxHDLExample/comm8qamtxrxhdl.slx`](file:///d:/HoriTech_Files/QAM_Testing/QAMTxRxHDLExample/comm8qamtxrxhdl.slx) with companion scripts [`QAMTxRxHDLExample/comm8qamtxrxhdl_init.m`](file:///d:/HoriTech_Files/QAM_Testing/QAMTxRxHDLExample/comm8qamtxrxhdl_init.m) and [`QAMTxRxHDLExample/comm8qamtxrxhdl_analyze.m`](file:///d:/HoriTech_Files/QAM_Testing/QAMTxRxHDLExample/comm8qamtxrxhdl_analyze.m).
   * **Simulink Verification**: Locks onto every consecutive 56-symbol 8-QAM packet (`Hello! ~8-QAM~ 000` .. `099`) and achieves **`BER = 0`** across all steady-state 50-packet measurement windows (`EbNo = 14 dB`, `frequencyOffset = 1000 Hz`, `phaseOffset = 30 deg`, `channelDelay = 1.5 samples`).
   * **HDL Coder Compatibility (`checkhdl`)**: Both `comm8qamtxrxhdl/QAM Tx HDL` and `comm8qamtxrxhdl/QAM Rx HDL` passed with **0 errors, 0 warnings, and 0 messages**.
3. **Verilog RTL Generated & Bit-Exact Verified in Xilinx Vivado 2019.1 (`xsim`)**:
   * **Transmitter (`QAM_Tx_HDL`)**: 10 Verilog modules generated in [`hdl_rtl_verilog/QAM_Tx_HDL/comm8qamtxrxhdl/`](file:///d:/HoriTech_Files/QAM_Testing/hdl_rtl_verilog/QAM_Tx_HDL/comm8qamtxrxhdl/). Verified via [`tb_QAM_Tx_HDL.sv`](file:///d:/HoriTech_Files/QAM_Testing/tb_QAM_Tx_HDL.sv) with **`3,998 / 3,998` (`100%`) bit-exact matches** (`0` mismatches).
   * **Receiver (`QAM_Rx_HDL`)**: 36 Verilog modules generated in [`hdl_rtl_verilog/QAM_Rx_HDL/comm8qamtxrxhdl/`](file:///d:/HoriTech_Files/QAM_Testing/hdl_rtl_verilog/QAM_Rx_HDL/comm8qamtxrxhdl/). Verified via [`tb_QAM_Rx_HDL.sv`](file:///d:/HoriTech_Files/QAM_Testing/tb_QAM_Rx_HDL.sv) across `80,000` input samples ($4\text{ MSPS}$) / `40,000` output cycles ($2\text{ MSPS}$) with **`40,000 / 40,000` (`100%`) bit-exact matches**, decoding **`314` consecutive 8-QAM packets** in RTL with **`BER = 0.000000`**.
   * **Vivado 2019.1 Project**: Ready-to-open `.xpr` project created at [`vivado_project_2019_1/QAM8_TxRx_HDL_Vivado.xpr`](file:///d:/HoriTech_Files/QAM_Testing/vivado_project_2019_1/QAM8_TxRx_HDL_Vivado.xpr).

---

## 2. Environment & Installed Tool Paths

* **OS**: Windows (PowerShell)
* **Project Root Directory**: `D:\HoriTech_Files\QAM_Testing`
* **MATLAB / Simulink / HDL Coder (R2025b)**:
  * Executable: `C:\Program Files\MATLAB\R2025b\bin\matlab.exe`
  * Batch execution flag: `matlab -batch "..."`
* **Xilinx Vivado 2019.1**:
  * Binaries Directory: `C:\Xilinx\Vivado\2019.1\bin`
  * Tools: `vivado.bat`, `xvlog.bat`, `xelab.bat`, `xsim.bat`

---

## 3. Complete File & Directory Inventory (`D:\HoriTech_Files\QAM_Testing`)

```text
D:\HoriTech_Files\QAM_Testing\
├── SESSION_HANDOFF_8QAM_TX_RX_HDL.md          <-- This continuation handoff file
├── QAM_TxRx_HDL_Technical_Reference.md        <-- Complete 750+ line technical reference (64-QAM & 8-QAM)
├── build_and_verify_8qam.m                    <-- Script that programmatically builds & verifies comm8qamtxrxhdl.slx
├── generate_8qam_rtl_and_vectors.m            <-- Script that runs makehdl (TX & RX Verilog) + exports .mem vectors
├── tb_QAM_Tx_HDL.sv                           <-- SystemVerilog self-checking testbench for QAM_Tx_HDL
├── tb_QAM_Rx_HDL.sv                           <-- SystemVerilog self-checking testbench + packet decoder for QAM_Rx_HDL
├── create_vivado_project.tcl                  <-- Tcl script to generate the Vivado 2019.1 .xpr project
│
├── QAMTxRxHDLExample\
│   ├── commqamtxrxhdl.slx                     <-- Original 64-QAM Simulink model (untouched)
│   ├── commqamtxrxhdl_init.m                  <-- Original 64-QAM init script (untouched)
│   ├── commqamtxrxhdl_analyze.m               <-- Original 64-QAM analysis script (untouched)
│   ├── QAMTxRxHDLExample.mlx                  <-- Original MathWorks Live Script (untouched)
│   ├── comm8qamtxrxhdl.slx                    <-- Standalone 8-QAM (Option A) Simulink model
│   ├── comm8qamtxrxhdl_init.m                 <-- Standalone 8-QAM (Option A) init script
│   ├── comm8qamtxrxhdl_analyze.m              <-- Standalone 8-QAM (Option A) analysis script
│   └── hdlprj\hdlsrc\comm8qamtxrxhdl\         <-- HDL Coder checkhdl HTML reports (QAM_Tx_HDL_report.html, QAM_Rx_HDL_report.html)
│
├── hdl_rtl_verilog\
│   ├── QAM_Tx_HDL\comm8qamtxrxhdl\            <-- 10 synthesizable Verilog files for 8-QAM Transmitter (top: QAM_Tx_HDL.v)
│   └── QAM_Rx_HDL\comm8qamtxrxhdl\            <-- 36 synthesizable Verilog files for 8-QAM Receiver (top: QAM_Rx_HDL.v)
│
├── test_vectors\
│   ├── golden_tx_out_re.mem                   <-- 4,000 golden TX I samples (16-bit hex, sfix16_En15 @ 4 MSPS)
│   ├── golden_tx_out_im.mem                   <-- 4,000 golden TX Q samples (16-bit hex, sfix16_En15 @ 4 MSPS)
│   ├── rx_in_re.mem                           <-- 80,001 noisy channel RX input I samples (sfix16_En15 @ 4 MSPS)
│   ├── rx_in_im.mem                           <-- 80,001 noisy channel RX input Q samples (sfix16_En15 @ 4 MSPS)
│   └── golden_rx_out.mem                      <-- 40,001 golden RX outputs ({packetStart, dValid, bit1, bit2, bit3} @ 2 MSPS)
│
├── vivado_project_2019_1\
│   └── QAM8_TxRx_HDL_Vivado.xpr               <-- Vivado 2019.1 project (target part: xc7z020clg484-1)
│
└── vivado_sim\                                <-- Vivado xsim working directory, compiled snapshots (tb_tx_sim, tb_rx_sim), logs
```

---

## 4. Key Technical Details & Design Decisions to Remember

1. **8-QAM ($4 \times 2$ Rectangular Grid) Scaling & Constellation**:
   * $M = 8$, $k = 3\text{ bits/symbol}$ (`bit1` MSB, `bit2`, `bit3` LSB).
   * Unscaled grid ($d_{\min} = 2$): $I \in \{-3, -1, +1, +3\}$, $Q \in \{-1, +1\}$.
   * **TX Modulator**: `MinDist = 0.5` $\implies$ outer points at $\pm 0.75 \pm 0.25j$ ($|s_{\max}| = 0.7906 < 1.0$, fitting safely in `sfix16_En15`).
   * **RX Scaling (`Demodulate/Shift Arithmetic`)**: `BinPtShiftNumber = 2` (`Right`, $\times 4$), scaling $d_{\min}$ from $0.5 \to 2.0$ (`sfix16_En14` $\to$ `sfix16_En12`).
   * **Preamble Mapping**: Uses antipodal outer corners Symbol `1` (`001` $\to -3-1j$) and Symbol `4` (`100` $\to +3+1j$). In `comm8qamtxrxhdl_init.m`:
     * `preambleTxMap = [1 4].';`
     * `preambleRxMap = [-3-1j 3+1j].';`
     * `SimParams.preambleRx = 0.25 * preambleRxMap(preambleBits+1);`
2. **Option A Packet Format ($56\text{ symbols} = 168\text{ bits}$)**:
   * **Preamble**: $14\text{ symbols} \times 3\text{ bits} = 42\text{ bits}$ (`Controller FSM` counts `0..41`).
   * **Payload**: $42\text{ symbols} \times 3\text{ bits} = 126\text{ bits} = 18 \times 7\text{-bit ASCII chars}$ (`'Hello! ~8-QAM~ %03i'`, `Controller FSM` counts `0..125`).
   * **Total Packet**: $56\text{ symbols} = 168\text{ bits}$.
3. **HDL-Compatible 8-QAM Demodulator (`Rect8QAMDemod`)**:
   * Simulink's built-in `Rectangular QAM Demodulator Baseband` S-function rejects fixed-point inputs when $\log_2(M)$ is odd ($M=8$).
   * Replaced in `comm8qamtxrxhdl/QAM Rx HDL/Demodulate` with an HDL-synthesizable `#codegen` MATLAB Function block (`Rectangular_QAM_Demodulator_Baseband.v`):
     ```matlab
     function y = Rect8QAMDemod(u)
     %#codegen
     I = real(u);
     Q = imag(u);
     b1 = (I >= 0);       % MSB: 0 for I < 0, 1 for I >= 0
     b2 = (abs(I) <= 2);  % Mid: 0 for |I| > 2 (+-3), 1 for |I| <= 2 (+-1)
     b3 = (Q < 0);        % LSB: 0 for Q >= 0 (+1), 1 for Q < 0 (-1)
     y  = [b1; b2; b3];
     ```
4. **Phase-Invariant Preamble Matched Filter (`Discrete FIR Filter4`)**:
   * `Preamble Matched Filter` correlates $(I+Q)*h_3 + j(I-Q)*h_4$. To remain phase-invariant when $\text{Re}(\text{PreAmb}) \neq \text{Im}(\text{PreAmb})$, `Discrete FIR Filter4` uses `Coefficients = -real(fliplr(conj(PreAmb/7)))` and `threshold = 1.1`.
5. **Vivado `xelab` Optimization in `Data_Source.v`**:
   * HDL Coder originally emitted `wire [32767:0] data_lookup_table_data` with 32,768 continuous `assign` statements, which overflows `xelab`'s C compiler stack on Windows.
   * In [`hdl_rtl_verilog/QAM_Tx_HDL/comm8qamtxrxhdl/Data_Source.v`](file:///d:/HoriTech_Files/QAM_Testing/hdl_rtl_verilog/QAM_Tx_HDL/comm8qamtxrxhdl/Data_Source.v), the LUT is structured as a compact $1024 \times 32\text{-bit}$ word-addressed ROM (`reg [31:0] rom_words [0:1023]`), which elaborates in `< 2 seconds` in `xelab` and matches Simulink 100% bit-for-bit.
   * *(Note: If you re-run `makehdl('comm8qamtxrxhdl/QAM Tx HDL')`, re-apply the `rom_words` compaction to `Data_Source.v` before running `xelab`.)*

---

## 5. Quick-Start Commands for Future Sessions

### A. Run the 8-QAM Simulink Model in MATLAB
```powershell
& "C:\Program Files\MATLAB\R2025b\bin\matlab.exe" -batch "cd('D:\HoriTech_Files\QAM_Testing\QAMTxRxHDLExample'); sim('comm8qamtxrxhdl');"
```

### B. Re-Run Vivado 2019.1 Simulation (`xsim`) for TX or RX
```powershell
Set-Location "D:\HoriTech_Files\QAM_Testing\vivado_sim"

# Run TX Simulation (tb_tx_sim snapshot is already built)
cmd /c "C:\Xilinx\Vivado\2019.1\bin\xsim.bat tb_tx_sim -runall"

# Run RX Simulation (tb_rx_sim snapshot is already built)
cmd /c "C:\Xilinx\Vivado\2019.1\bin\xsim.bat tb_rx_sim -runall"
```

### C. Open or Synthesize the Vivado 2019.1 Project
```powershell
# Open in Vivado GUI:
& "C:\Xilinx\Vivado\2019.1\bin\vivado.bat" "D:\HoriTech_Files\QAM_Testing\vivado_project_2019_1\QAM8_TxRx_HDL_Vivado.xpr"
```

