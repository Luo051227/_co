# 第6章

本章的目標是構建一個**組譯器 (Assembler)**，將符號化的 Hack 組合語言 (Assembly) 翻譯成二進制的機器語言 (Binary Code)。

## 1. 核心概念
組譯器是軟體層次的第一層，它填補了人類可讀的符號代碼與硬體可執行的二進制代碼之間的鴻溝。
- **輸入**：`Prog.asm` (Hack 組合語言程式)
- **輸出**：`Prog.hack` (Hack 機器語言，由 `0` 和 `1` 組成的文字檔)

## 2. 翻譯過程 (Translation)
組譯器需逐行讀取源碼，並處理以下兩種指令：

### A-指令 (A-Instruction)
- **語法**：`@value`
- **翻譯**：
  - 如果 `value` 是數字 (如 `@100`)，直接轉換為 15 位元二進制，並在最前面補 `0`。
  - 例如：`@2` -> `0000000000000010`
  - 如果 `value` 是符號 (如 `@LOOP` 或 `@i`)，則需查詢符號表 (Symbol Table) 獲取對應地址。

### C-指令 (C-Instruction)
- **語法**：`dest = comp ; jump` (`dest` 或 `jump` 可省略)
- **翻譯**：轉換為 `111accccccdddjjj` 格式。
  - **`comp` (計算域)**：查表轉換為 7 位元 (`acccccc`)。
  - **`dest` (存儲域)**：查表轉換為 3 位元 (`ddd`)。
  - **`jump` (跳轉域)**：查表轉換為 3 位元 (`jjj`)。

## 3. 符號處理 (Symbols)
Hack 語言支援三種符號，組譯器需透過**符號表 (Symbol Table)** 來管理：

1. **預定義符號 (Predefined Symbols)**：
   - `R0` - `R15` 對應 `RAM[0]` - `RAM[15]`。
   - `SCREEN` 對應 `RAM[16384]`，`KBD` 對應 `RAM[24576]`。
   - `SP`, `LCL`, `ARG`, `THIS`, `THAT` 對應 `R0` - `R4`。
2. **標籤符號 (Label Symbols)**：
   - 由偽指令 `(Xxx)` 定義。
   - 用於標記程式跳轉位置 (`goto`)。
   - 值為下一條指令的 ROM 地址 (程式行號)。
3. **變數符號 (Variable Symbols)**：
   - 使用者自定義的變數 (如 `@sum`)。
   - 從 `RAM[16]` 開始依序分配地址。

## 4. 實作策略 (Implementation Strategy)
建議採用 **兩次掃描 (Two-Pass)** 的方式來實作組譯器：

- **第一次掃描 (First Pass)**：
  - 只讀取程式碼，尋找所有的標籤符號 `(LABEL)`。
  - 將標籤及其對應的 ROM 地址存入符號表。
  - *注意：`(LABEL)` 本身不產生機器碼，不佔用行號。*
- **第二次掃描 (Second Pass)**：
  - 再次從頭讀取程式碼。
  - 處理 A-指令：
    - 若是數字，直接轉二進制。
    - 若是符號，查符號表。若符號表中不存在，則視為「新變數」，分配下一個可用的 RAM 地址 (從 16 開始)，並存入符號表。
  - 處理 C-指令：解析各欄位並查表轉換。
  - 將翻譯後的二進制碼寫入輸出檔案。

## 5. 模組化建議
建議將程式拆分為以下模組：
- `Parser`: 解析每一行指令，提取 instruction type, symbol, dest, comp, jump 等欄位。
- `Code`: 提供查表功能，將助記符 (如 `D+1`, `JGT`) 轉換為對應的二進制碼。
- `SymbolTable`: 管理符號與地址的對映 (Hash Map / Dictionary)。
- `Main`: 控制讀檔、兩次掃描流程及檔案輸出。

# 第7章

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
```
## 邏輯運算實作細節 (Arithmetic & Logic Implementation)

### 一元運算 (neg, not)
* **邏輯**: `Pop x` -> `計算 op x` -> `Push 結果`。
* **實作技巧**: 因為只涉及一個運算元，其實**不需要移動 SP 指標**，只需直接讀取 `M[SP-1]`，修改後寫回即可。

### 比較運算 (eq, gt, lt)
* **邏輯**: `Pop y` -> `Pop x` -> `比較 x 和 y`。
    * 如果 **True**: 推入 `-1` (二進制全為 1，即 `111...111`)。
    * 如果 **False**: 推入 `0`。
* **難點**: Hack ALU 沒有直接輸出 True/False 的指令。
    * **解法**: 使用減法 `D = x - y`，配合 Jump 指令 (`JEQ`, `JGT`, `JLT`) 來判斷 D 的值。
* **Label 唯一性問題**:
    * 一個 VM 程式中會有很多個 `eq` 或 `gt` 指令。
    * 翻譯成 Assembly 時，跳轉用的 Label (如 `(TRUE)`, `(FALSE)`, `(CONTINUE)`) 不能重複。
    * **解決方案**: 實作一個計數器，為每個 Label 加上流水號，例如 `(JUMP_TO_TRUE_001)`, `(END_EQ_001)`。

---

## 5. VM Translator 程式架構

建議將程式拆分為兩個主要模組，職責分離：

### A. Parser (解析器)
負責讀取 `.vm` 檔案並解析字串。
* `commandType()`: 回傳指令類型 (如 `C_ARITHMETIC`, `C_PUSH`, `C_POP` 等)。
* `arg1()`: 回傳指令的第一個參數 (例如 `add` 或 `local`)。
* `arg2()`: 回傳指令的第二個參數 (例如 `index` 數值)。

### B. CodeWriter (程式碼產生器)
負責輸出對應的 `.asm` 內容。
* `setFileName(fileName)`: 用於設定當前處理的檔案名稱 (處理 `static` 變數命名空間用)。
* `writeArithmetic(command)`: 翻譯算術邏輯指令 (`add`, `sub`, `eq` 等)。
* `writePushPop(command, segment, index)`: 核心邏輯所在，負責翻譯堆疊與記憶體區段的存取。

---

## 6. 實作細節與陷阱 (Tips)

1.  **SP 的維護規則**:
    * **Push**: 先把值放入 `M[SP]`，然後 `SP++`。
    * **Pop**: 先 `SP--`，然後取出 `M[SP]` 的值。

2.  **Pop 到 segment 的正確順序**:
    * 假設指令是 `pop local 2`。
    * **錯誤做法**: 先 Pop 資料到 D，再算地址。 (這樣 D 被佔用，算地址會很麻煩)。
    * **正確順序**:
        1. 先計算目標地址 (`LCL + 2`)。
        2. 將地址暫存到通用暫存器 **`R13`**。
        3. 從 Stack Pop 資料到 D。
        4. 將 D 寫入 `RAM[R13]` (`@R13`, `A=M`, `M=D`)。

3.  **True 的數值**:
    * 在 VM 規範中，True 代表 **`-1`** (`111...111`)，False 代表 `0`。
    * 千萬不要寫成 `1`。

4.  **Static 命名規範**:
    * 若輸入檔名為 `Xxx.vm`，指令 `static 5` 應翻譯為組合語言的符號 **`@X
