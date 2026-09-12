# Transposed Convolution FPGA Accelerator

## Overview

Deep Learning에서 사용되는 **Transposed Convolution(ConvTranspose2D)** 연산을 FPGA에서 가속하기 위해 Verilog HDL 기반 Hardware Accelerator를 설계한 프로젝트입니다.

PyTorch의 `nn.ConvTranspose2d` 연산 구조를 분석하여 RTL로 구현했으며, 동일한 kernel weight가 입력 feature map의 여러 위치에서 반복적으로 사용되는 특성을 활용해 **Kernel Weight Reuse 구조**를 적용했습니다.

또한 Input Size, Kernel Size, Stride, Padding, Input/Output Channel 등의 변화에 대응할 수 있도록 연산 구조를 parameterized하게 설계했습니다.

설계한 accelerator는 **Xilinx Zynq-7000 SoC 기반 Zybo Z7-20 FPGA**에서 검증했으며, 동일한 ConvTranspose2D 연산을 ARM Processor System(PS)에서 수행한 결과와 비교하여 Programmable Logic(PL)의 가속 효과를 확인했습니다.

---

## ConvTranspose2D Operation

ConvTranspose2D는 입력 feature map의 각 값을 kernel과 곱한 뒤, 대응되는 output feature map 위치에 결과를 누적하는 방식으로 동작합니다.

```text
Input Feature Map
        │
        ▼
   Input Value
        │
        ▼
 × Kernel Weights
        │
        ▼
Partial Products
        │
        ▼
Output Position Mapping
        │
        ▼
   Accumulation
        │
        ▼
Output Feature Map
```

일반적인 convolution과 달리 하나의 input value가 kernel 전체와 연산되어 여러 output position에 영향을 주기 때문에, Hardware에서는 **weight reuse와 output accumulation 구조**가 중요합니다.

---

## Hardware Architecture

ConvTranspose2D 연산을 여러 계층의 RTL module로 구성하여 구현했습니다.

```text
Input Feature Map
        │
        ▼
┌─────────────────────┐
│ ConvTranspose2D     │
│                     │
│   ┌─────────────┐   │
│   │   Cluster   │   │
│   │             │   │
│   │   ┌─────┐   │   │
│   │   │Core │   │   │
│   │   └─────┘   │   │
│   └─────────────┘   │
│          │          │
│          ▼          │
│        SAVE         │
└──────────┼──────────┘
           ▼
  Output Feature Map
```

### Core

ConvTranspose2D의 기본 Multiply-Accumulate 연산을 수행합니다.

입력 feature value와 kernel weight를 곱하고, 연산 결과를 대응되는 output position에 누적합니다.

```text
Input Value
    │
    ▼
Multiplication ◀── Kernel Weight
    │
    ▼
Partial Sum
    │
    ▼
Accumulation
```

### Cluster

Core의 연산을 제어하고 channel 및 feature map 단위의 ConvTranspose2D 연산을 구성합니다.

여러 입력 및 kernel 연산을 순차적으로 처리하면서 output feature map에 필요한 partial sum을 생성합니다.

### SAVE

연산이 완료된 결과를 output memory에 저장합니다.

```text
Compute Result
      │
      ▼
     SAVE
      │
      ▼
Output Memory
```

---

## Kernel Weight Reuse

ConvTranspose2D에서는 동일한 kernel weight가 입력 feature map의 여러 위치에서 반복적으로 사용됩니다.

본 프로젝트에서는 kernel weight를 연산마다 다시 읽는 대신 **내부 buffer에 저장한 상태에서 input value를 순차적으로 처리**하도록 설계했습니다.

```text
             Kernel Weights
                   │
                   ▼
              Weight Buffer
                   │
        ┌──────────┼──────────┐
        │          │          │
        ▼          ▼          ▼
     Input 1    Input 2    Input 3
        │          │          │
        ×          ×          ×
        │          │          │
        ▼          ▼          ▼
     Partial    Partial    Partial
      Result     Result     Result
```

이를 통해 동일한 weight를 반복적으로 활용하는 **Data Reuse 구조**를 구현했습니다.

---

## Parameterized RTL Design

다양한 ConvTranspose2D configuration에 대응할 수 있도록 주요 연산 조건을 parameter 또는 macro로 정의했습니다.

```verilog
IW          // Input Width
IH          // Input Height

FW          // Filter Width
FH          // Filter Height

C           // Channel
S           // Stride
PAD         // Padding

BITS        // Data Bit-width
MULT_BITS   // Multiplication Result Bit-width
```

예를 들어 padding을 제외한 기본 output feature map의 크기는 다음과 같이 결정됩니다.

```text
Output Width  = Filter Width
              + Stride × (Input Width - 1)

Output Height = Filter Height
              + Stride × (Input Height - 1)
```

RTL 내부에서는 이러한 parameter를 기반으로 input/output index와 연산 범위를 계산하도록 구성했습니다.

---

## Dataflow

전체 ConvTranspose2D 연산은 다음과 같은 흐름으로 수행됩니다.

```text
Input Feature Map
        │
        ▼
Read Input Value
        │
        ▼
Read / Reuse Kernel
        │
        ▼
Multiply
        │
        ▼
Calculate Output Position
        │
        ▼
Accumulate Partial Sum
        │
        ▼
Channel / Kernel Iteration
        │
        ▼
Save Output
```

하나의 kernel을 buffer에 유지한 상태에서 input feature 값을 순차적으로 처리하여 kernel data reuse를 높이는 방향으로 구성했습니다.

---

## Verification

RTL 구현 결과는 Software Reference와 비교하여 기능을 검증했습니다.

PyTorch의 `nn.ConvTranspose2d` 연산 결과를 Golden Reference로 사용하고, 동일한 input feature map과 kernel weight를 RTL Testbench에 입력하여 결과를 비교했습니다.

```text
Input Feature Map
     +
Kernel Weights
       │
       ├───────────────────────┐
       │                       │
       ▼                       ▼
PyTorch ConvTranspose2d     Verilog RTL
       │                       │
       ▼                       ▼
Golden Reference           RTL Output
       │                       │
       └──────── Compare ──────┘
```

이를 통해 stride, padding, feature map size 등의 조건에 따른 RTL 연산 결과를 검증했습니다.

---

## FPGA Implementation

설계한 RTL Accelerator는 **Zybo Z7-20** 보드에서 FPGA Implementation 및 실제 동작 검증을 수행했습니다.

| Item | Configuration |
|---|---|
| FPGA Board | Zybo Z7-20 |
| SoC | Xilinx Zynq-7000 |
| HDL | Verilog HDL |
| Clock Frequency | 135 MHz |
| FPGA Tool | Xilinx Vivado |
| Software Tool | Xilinx Vitis |

Zynq SoC의 구조를 활용하여 동일한 ConvTranspose2D 연산을 각각 다음 환경에서 수행했습니다.

```text
Zynq-7000 SoC

┌───────────────────────────────┐
│                               │
│   Processor System (PS)       │
│   ARM Processor               │
│                               │
├───────────────────────────────┤
│                               │
│   Programmable Logic (PL)     │
│   ConvTranspose2D Accelerator │
│                               │
└───────────────────────────────┘
```

PS에서는 Software로 ConvTranspose2D 연산을 수행하고, PL에서는 설계한 RTL Accelerator를 사용하여 latency를 비교했습니다.

---

## Performance

대표적인 테스트 환경에서 PS와 PL의 연산 latency를 비교했습니다.

```text
Input Feature Map : 2 × 2
Kernel            : 4 × 4
Clock Frequency   : 135 MHz
```

| Platform | Latency |
|---|---:|
| Processor System (PS) | 18.19 μs |
| Programmable Logic (PL) | **8.01 μs** |
| Speedup | **2.27×** |

동일한 ConvTranspose2D 연산에 대해 FPGA PL에서 **약 2.27배의 가속 효과**를 확인했습니다.

---

## Video Demo

Zybo Z7-20 FPGA에 구현한 **Transposed Convolution Accelerator의 실제 동작 및 PS-PL 검증 과정**을 아래 영상에서 확인할 수 있습니다.

<p align="center">
  <a href="https://www.youtube.com/watch?v=hRp8RzAKacU&t=65s">
    <img src="https://img.youtube.com/vi/hRp8RzAKacU/maxresdefault.jpg" width="75%">
  </a>
</p>

<p align="center">
  <b>▶ Click to watch the FPGA Accelerator Demo</b>
</p>

---

## PS-PL Verification Flow

FPGA에서의 전체 검증 과정은 다음과 같이 구성했습니다.

```text
Input / Kernel Data
        │
        ▼
   ARM Processor
        │
        ├───────────────┐
        │               │
        ▼               ▼
 PS Computation     PL Accelerator
        │               │
        ▼               ▼
   PS Result         PL Result
        │               │
        └──────┬────────┘
               ▼
        Result Compare
               │
               ▼
        Latency Compare
```

이를 통해 RTL 기능 검증뿐만 아니라 실제 SoC 환경에서 Software와 Hardware의 연산 시간을 비교했습니다.

---

## Repository Structure

현재 Repository는 ConvTranspose2D RTL/FPGA 프로젝트와 FPGA 검증 자료로 구성되어 있습니다.

```text
Transposed_Convolution_FPGA_Accelerator/
│
├── ConvTranspose2D/
│   └── ...                     # RTL / FPGA project files
│
├── [ConvTranspose2D_최종] FPGA 검증.pdf
│                               # FPGA implementation & verification
│
└── README.md
```

---

## Key Features

* **ConvTranspose2D RTL Design**  
  PyTorch `nn.ConvTranspose2d`의 연산 구조를 Verilog HDL로 구현

* **Kernel Weight Reuse**  
  동일한 kernel weight를 buffer에 유지하고 여러 input에 반복적으로 활용

* **Parameterized Hardware Architecture**  
  Input Size, Kernel Size, Stride, Padding, Channel 변화에 대응하도록 연산 구조 일반화

* **Hierarchical RTL Architecture**  
  Core → Cluster → ConvTranspose2D → SAVE 구조로 연산 및 제어 모듈 구성

* **Software–Hardware Verification**  
  PyTorch reference와 RTL Simulation 결과를 비교하여 연산 정확성 검증

* **Zynq FPGA Implementation**  
  Zybo Z7-20의 Programmable Logic에 ConvTranspose2D Accelerator 구현

* **PS–PL Performance Comparison**  
  135 MHz 환경에서 PS `18.19 μs`, PL `8.01 μs`로 약 **2.27× speedup** 확인

* **FPGA Demonstration**  
  실제 Zybo Z7-20 FPGA 환경에서 Accelerator 동작 및 PS-PL 검증 과정 시연

---

## Publication

본 프로젝트의 연구 결과는 다음 국제학술대회에서 발표되었습니다.

**Design of Transpose Convolution Layer on FPGA**

* Conference: International Conference on Electrical and Electronics Engineering (ICEEE)
* Year: 2025

본 연구에서는 Transposed Convolution의 연산 특성을 분석하고, kernel weight reuse를 활용한 FPGA Hardware Architecture를 설계하여 Zynq 기반 환경에서 Software 대비 Hardware 가속 효과를 검증했습니다.

---

## Tech Stack

`Verilog HDL` · `FPGA` · `RTL Design` · `Xilinx Vivado` · `Vitis` · `Zynq-7000` · `Zybo Z7-20` · `PyTorch`
