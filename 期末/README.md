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
# 第8章

## 1. 核心概念 (Overview)
第八章擴充了 VM Translator 的功能，使其能夠處理完整的應用程式邏輯。
主要新增兩大功能：
1.  **程式流程控制 (Program Flow)**: `label`, `goto`, `if-goto` (分支與迴圈)。
2.  **函式呼叫協定 (Function Calling Protocol)**: `function`, `call`, `return` (這部分最複雜)。

---

## 2. 程式流程控制 (Program Flow)
VM 語言支援無條件跳轉和條件跳轉。

### A. Label (標籤)
* **VM 指令**: `label labelName`
* **功能**: 標記當前程式碼的位置，供跳轉使用。
* **實作細節**:
    * 翻譯成 Assembly 的 `(labelName)`。
    * **命名空間 (Scope)**: 為了避免不同函式中的 `loop` 標籤衝突，建議將 Label 命名為 `FunctionName$LabelName`。

### B. Goto (無條件跳轉)
* **VM 指令**: `goto labelName`
* **功能**: 直接跳到指定標籤。
* **Hack Assembly**:
    ```asm
    @labelName
    0;JMP
    ```

### C. If-goto (條件跳轉)
* **VM 指令**: `if-goto labelName`
* **功能**: 從堆疊 **Pop** 一個數值。如果該數值 **不為 0 (True)**，則跳轉；否則繼續執行。
* **Hack Assembly**:
    ```asm
    @SP
    AM=M-1  // Pop stack
    D=M     // D = cond
    @labelName
    D;JNE   // If D != 0, Jump
    ```

---

## 3. 函式呼叫協定 (Function Calling Protocol)

這是本章的核心，必須精確實作「堆疊幀 (Stack Frame)」的管理。

### A. Function (宣告函式)
* **VM 指令**: `function f nVars`
    * `f`: 函式名稱。
    * `nVars`: 區域變數 (local variables) 的數量。
* **實作步驟**:
    1.  產生函式入口標籤 `(f)`。
    2.  因為區域變數尚未初始化，需將 `0` 推入堆疊 `nVars` 次 (初始化 LCL 區段)。
    3.  *(Hack 提示: 使用迴圈來 Push 0)*

### B. Call (呼叫函式)
* **VM 指令**: `call f nArgs`
    * `nArgs`: 已經被 Push 到堆疊上的參數數量。
* **實作步驟 (Caller 的責任)**:
    這步驟稱為 "Saving the Frame" (保存當前狀態)。
    1.  **Push returnAddress**: 產生一個唯一的 Label (如 `RET_Addr_1`) 並 Push 該地址。
    2.  **Push LCL**: 保存呼叫者的 Local 指標。
    3.  **Push ARG**: 保存呼叫者的 Argument 指標。
    4.  **Push THIS**: 保存呼叫者的 This 指標。
    5.  **Push THAT**: 保存呼叫者的 That 指標。
    6.  **重設 ARG**: `ARG = SP - nArgs - 5` (將 ARG 指向參數列表的開頭)。
    7.  **重設 LCL**: `LCL = SP` (將 LCL 指向當前堆疊頂端，即新函式的區域變數起點)。
    8.  **Goto f**: 跳轉執行函式。
    9.  **宣告 (returnAddress)**: 放置第一步產生的 Label，這是函式回來後繼續執行的地方。

### C. Return (函式返回)
* **VM 指令**: `return`
* **實作步驟 (Callee 的責任)**:
    這步驟稱為 "Restoring the Frame" (恢復狀態)。
    1.  **FRAME = LCL**: 使用臨時變數 (如 `R13`) 暫存目前的 LCL 位置 (Stack Frame 的底端)。
    2.  **RET = *(FRAME - 5)**: 取得返回地址 (Return Address)，暫存到 `R14`。
        * *為什麼要先拿？* 因為如果沒有參數，接下來的操作可能會覆蓋掉 Stack Frame 的資料。
    3.  **Top Stack 處理**: 將回傳值 (`Pop()`) 放到 `*ARG` 的位置 (`ARG[0]`)。這是為了把回傳值交給 Caller。
    4.  **恢復 SP**: `SP = ARG + 1` (回收堆疊空間，SP 指向回傳值之後)。
    5.  **恢復 THAT**: `THAT = *(FRAME - 1)`
    6.  **恢復 THIS**: `THIS = *(FRAME - 2)`
    7.  **恢復 ARG**: `ARG = *(FRAME - 3)`
    8.  **恢復 LCL**: `LCL = *(FRAME - 4)`
    9.  **Goto RET**: 跳轉回 `R14` 儲存的返回地址。

---

## 4. 堆疊幀示意圖 (The Stack Frame Visualization)

當 `Sys.init` 呼叫 `main`，而 `main` 呼叫 `foo` 時，Global Stack 的長相：

```text
| ...           |
+---------------+
| arg 0         | \
| arg 1         |  > Arguments for foo
| ...           | /
+---------------+ < ARG (for foo)
| return addr   | \
| saved LCL     |  |
| saved ARG     |  > Saved State (5 words)
| saved THIS    |  |
| saved THAT    | /
+---------------+ < LCL (for foo)
| local 0       | \
| local 1       |  > Locals for foo (initialized to 0)
| ...           | /
+---------------+ < SP (Current Stack Pointer)
## 5. Bootstrap Code (啟動程式碼)

VM Translator 產生的 `.asm` 檔必須包含一段初始化的程式碼，這段程式碼必須放在輸出檔案的**最開頭**。

**Bootstrap 邏輯**:
1.  **`SP = 256`**:
    * 初始化堆疊指標 (Stack Pointer)，因為 Hack 電腦的堆疊從 RAM[256] 開始。
2.  **`Call Sys.init`**:
    * 呼叫系統入口函式 `Sys.init`。
    * 這必須是一個標準的 `call` 指令操作，意味著你需要執行完整的 "Push return addr", "Save frame" 等動作。
    * 注意：`Sys.init` 通常不接受參數 (`nArgs = 0`)。

---

## 6. 實作陷阱與提示 (Tips)

### Label 的唯一性
* 在實作 `call` 指令時，產生的 Return Address Label 必須是**全域唯一**的。
* **建議格式**: `Function$ret.i` (其中 `i` 為全域遞增的計數器)，例如 `Main.fibonacci$ret.1`。

### Return 時的順序 (關鍵 bug 源)
* 在 `return` 指令的實作中，**絕對不能**直接用 `LCL` 暫存器去進行減法計算 (如 `LCL - 5`)。
* **原因**: 在還原 `ARG` 等指標的過程中，可能會覆蓋到 `LCL` 指向的記憶體區域 (特別是當參數很少時，Stack Frame 重疊的情況)。
* **正確作法**:
    1.  必須先將 `LCL` 的值 copy 到一個臨時變數 (通常使用 `R13`，在筆記中稱為 `FRAME`)。
    2.  取得 Return Address (`*(FRAME - 5)`) 並存入 `R14` (`RET`)。
    3.  後續所有的 restore 操作 (`THAT`, `THIS`, `ARG`, `LCL`) 都必須基於 `R13` (`FRAME`) 進行計算。

### Sys.init 與測試
* 所有的標準 VM 程式都預設從 `Sys.init` 開始執行。
* 如果你的 Translator 沒有加入 Bootstrap code，像 `FibonacciElement` 這種跨檔案的複雜測試程式將無法運作。
* **例外情況**: 在測試 `SimpleFunction` (Chapter 7 的測試腳本) 時，通常**不需要** Bootstrap。
    * *建議*: 設計一個 Command Line Argument (如 `--no-bootstrap`) 來控制是否寫入啟動碼。
