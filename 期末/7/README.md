`參考`[_nand2tetris/07](https://github.com/ccc114a/cpu2os/tree/master/_nand2tetris/07)  
# Nand2Tetris Chapter 7: Virtual Machine I - Stack Arithmetic

## 1. 核心概念 (Overview)
這一章引入了 **虛擬機 (Virtual Machine, VM)** 作為中間層 (Intermediate Representation)。這採用了現代編譯器的「雙層編譯模型」：
1.  **前端**: 高階語言 (Jack) -> VM Code (`.vm`)
2.  **後端**: VM Code -> 組合語言 (Hack Assembly `.asm`) -> 機器碼

**本章目標**: 實作一個 VM Translator，處理 **堆疊運算 (Stack Arithmetic)** 和 **記憶體存取 (Memory Access)** 指令。

---

## 2. 堆疊機模型 (The Stack Machine)
VM 語言是基於堆疊 (Stack) 的架構，這意味著所有的運算都發生在堆疊頂端。
* 運算元從堆疊 **Pop (彈出)**。
* 運算結果 **Push (推入)** 回堆疊。

### 標準記憶體映射 (Standard Mapping over Hack RAM)
VM Translator 需要管理 Hack 電腦的 RAM，將 VM 的概念映射到實體記憶體：

| RAM Address | Usage |
| :--- | :--- |
| **0** | **SP** (Stack Pointer, 指向堆疊頂端下一個空位) |
| **1** | **LCL** (Local segment base) |
| **2** | **ARG** (Argument segment base) |
| **3** | **THIS** (This segment base / Pointer 0) |
| **4** | **THAT** (That segment base / Pointer 1) |
| **5 - 12** | **Temp** segment (固定 8 個暫存位置) |
| **13 - 15** | **General Purpose** (R13-R15, 可供 VM 實作運算時暫存用) |
| **16 - 255** | **Static** segment (由組譯器分配) |
| **256 - 2047** | **Stack** (全域堆疊區) |

---

## 3. 記憶體區段 (Memory Segments)
VM 透過 8 個虛擬區段來抽象化記憶體存取。`push/pop segment index` 指令的實作方式依區段不同而異：

### A. 動態區段 (local, argument, this, that)
這些區段的位置不是固定的，而是由 RAM[1]~RAM[4] 的指標決定。
* **公式**: `Address = BasePointer + Index`
* **Hack 實作邏輯**:
    1.  讀取 Base 地址 (例如 `@LCL`, `D=M`)。
    2.  加上 Index (`@i`, `D=D+A`)。
    3.  存取該地址的資料。
    * *提示*: 對於 `pop` 指令，你需要先把計算出的目標地址存到臨時變數 (如 R13)，因為 ALU 一次只能算一個地址。

### B. 固定區段 (temp, pointer)
這些區段映射到固定的 RAM 地址。
* **pointer 0**: 對應 `THIS` (RAM[3])。
* **pointer 1**: 對應 `THAT` (RAM[4])。
* **temp i**: 對應 `RAM[5 + i]`。
* **Hack 實作**: 直接用 `R3`, `R4`, `R5` 等符號操作即可，不需要讀取 Base。

### C. 靜態區段 (static)
* **static i**: 每個 VM 檔案私有。
* **Hack 實作**: 翻譯成組合語言的 label 變數，例如 `Filename.i`。讓之後的 Assembler (第六章做的) 去決定實際 RAM 位置 (16-255)。

### D. 常數區段 (constant)
這是一個虛擬區段，只用於 `push`。
* `push constant i`: 代表將數值 `i` 推入堆疊。
* **Hack 實作**: `D=i`, 然後把 D 推入堆疊。(`*SP = D`, `SP++`)

---

## 4. 算術邏輯指令 (Arithmetic / Logical Commands)
這些指令從堆疊彈出數值，計算後將結果推回。

### 二元運算 (add, sub, and, or)
邏輯：Pop y, Pop x, 計算 x op y, Push 結果。
**Hack Assembly 樣板 (以 add 為例)**:
```asm
@SP
AM=M-1  // SP--, A=SP (指向 y)
D=M     // D = y
A=A-1   // A 指向 x (注意 SP 已經減了，這裡直接看前一個位置即可)
M=D+M   // x = x + y (直接覆蓋 x 的位置，SP 停在這裡剛好)
