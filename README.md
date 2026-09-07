# SIMD-Multi-Precision-Shifter
## PROPOSED ARCHITECTURE

The proposed architecture implements a 32-bit clocked multi-precision shifter designed for posit arithmetic hardware. The design supports three precision modes (8-bit, 16-bit, and 32-bit) and performs bidirectional shifting under clocked operation. The architecture decomposes the 32-bit input into four independent 8-bit segments, enabling modular shift computation and reuse of a common shifting primitive.

### 1. Architectural Overview

The 32-bit input word is partitioned into four independent 8-bit sub-words:

**Input = {p3, p2, p1, p0}**

Each sub-word is processed in parallel using identical **8-bit shift units**, forming the first stage of the architecture. The design operates in two stages:

- **Stage 1 (Intra-block shifting):** Parallel 8-bit shifts within each sub-word.
- **Stage 2 (Inter-block recombination):** Cross-byte data movement based on precision mode.

This separation reduces complexity compared to a full 32-bit barrel shifter while preserving flexibility.

### 2. 8-Bit Shifter Unit

Each 8-bit block **(Figure 1)** is implemented as a synchronous shifter:

- **Inputs:** `in[7:0], shift[2:0], dir, clk`
- **Output:** `out[7:0]`

**Operation:**

- Left shift: `out = in << shift`
- Right shift: `out = in >> shift`

These units handle **fine-grain directional shifting (0–7 bits)** and operate in parallel for all four bytes, forming the base computational layer.

### 3. Intermediate Storage Bus

Outputs of the four 8-bit shifters are stored in a **32-bit intermediate bus**:

**{p3', p2', p1', p0'}**

This register stage provides:

- Synchronization across all sub-blocks
- Pipeline capability (1 clock latency)
- Reduced combinational depth in the recombination stage

### 4. Precision Modes and Dataflow

The architecture supports three precision modes controlled by `mode[1:0]`:

1. 8-bit precision mode (`mode[1:0] = 00`)
2. 16-bit precision mode (`mode[1:0] = 01`)
3. 32-bit precision mode (`mode[1:0] = 10`)

#### 4.1 8-Bit Precision Mode (`mode[1:0] = 00`)

- Each 8-bit block operates independently
- No inter-block data transfer

**out = {p3', p2', p1', p0'}**

This mode behaves as four parallel 8-bit shifters.

#### 4.2 16-Bit Precision Mode (`mode[1:0] = 01`)

The datapath is divided into two 16-bit segments:

- Lower segment: **{p1, p0}**
- Upper segment: **{p3, p2}**

**Key mechanism:** cross-byte merging using OR logic.

For shift amounts:

- **0–7 bits:**
  - Combines shifted output of higher byte with spillover bits from adjacent lower byte.
- **≥8 bits:**
  - Entire byte displacement occurs.

Example (left shift, shift < 8):

**Out[15:0] = {p1' | (p0 >> (8-shift)), p0'}**

This avoids a full 16-bit barrel structure by using **local shifts + boundary merging**.

#### 4.3 32-Bit Precision Mode (`mode[1:0] = 10`)

All four bytes form a unified 32-bit datapath.

Shifting is implemented using:

- **Fine shift:** via 8-bit units.
- **Coarse shift (byte-level):** via conditional recombination.

| Shift Range | Operation |
|---|---|
| 0-7 | Inter-byte merging across all boundaries |
| 8-15 | 1-byte shift + merging |
| 16-23 | 2-byte shift + merging |
| 24-31 | 3-byte shift |

Example (left shift, shift < 8):

**out[31:0] <= {p3' | (p2 >> (8-shift)), p2' | (p1 >> (8-shift)), p1' | (p0 >> (8-shift)), p0'}**

This structure emulates a full 32-bit barrel shifter using **hierarchical composition** rather than a monolithic design.

### 5. Direction Control

The `dir` signal determines shift direction:

- `0`: Left shift
- `1`: Right shift

- ### 6. Hardware Components

The architecture consists of:

- 4 × 8-bit synchronous shifters
- Combinational logic (MUX + OR gates) for boundary merging
- 32-bit register for intermediate storage
- Control logic driven by `mode`, `dir`, and `shift_amount`

Both directions are supported symmetrically by:

- Reversing data flow between adjacent blocks
- Adjusting bit extraction logic (`<<` vs `>>`)
