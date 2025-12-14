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

## 4. Bootstrap Code (啟動程式碼)

VM Translator 產生的 `.asm` 檔必須包含一段初始化的程式碼，這段程式碼必須放在輸出檔案的**最開頭**。

**Bootstrap 邏輯**:
1.  **`SP = 256`**:
    * 初始化堆疊指標 (Stack Pointer)，因為 Hack 電腦的堆疊從 RAM[256] 開始。
2.  **`Call Sys.init`**:
    * 呼叫系統入口函式 `Sys.init`。
    * 這必須是一個標準的 `call` 指令操作，意味著你需要執行完整的 "Push return addr", "Save frame" 等動作。
    * 注意：`Sys.init` 通常不接受參數 (`nArgs = 0`)。

---

## 5. 實作陷阱與提示 (Tips)

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

# 第9章

## 1. 核心概念 (Overview)
這一章我們暫時不寫編譯器，而是先學習如何 **使用** Jack 語言。
* **目標**: 熟悉 Jack 語法、物件導向編程 (OOP) 概念，並利用 Hack OS 的標準函式庫來開發一個互動式程式（通常是一個簡單的遊戲）。
* **角色轉變**: 我們現在是軟體工程師，正在為我們親手打造的 Hack 電腦開發軟體。

---

## 2. Jack 語言特性 (Jack Language Features)
Jack 是一種簡單的、基於類別 (Class-based) 的物件導向語言，語法與 Java 或 C# 非常相似，但為了簡化編譯器的實作，去除了一些語法糖。

### 基本結構
* **檔案**: 每個檔案 (`.jack`) 包含且僅包含一個 `class`。
* **進入點**: 程式總是從 `Main` 類別中的 `function void main()` 開始執行。

### 資料型別 (Data Types)
1.  **Primitive Types (原始型別)**:
    * `int`: 16-bit 有號整數。
    * `boolean`: `true` (-1) 或 `false` (0)。
    * `char`: 字元 (ASCII)。
2.  **Object Types (物件型別)**:
    * `Array`: 陣列。
    * `String`: 字串。
    * 使用者自定義的 `Class`。

### 副程式類型 (Subroutine Types)
Jack 分成三種副程式，這在宣告時必須明確區分：

| 關鍵字 | 用途 | 隱含參數 (this) | 類似概念 |
| :--- | :--- | :---: | :--- |
| **function** | 靜態函式，不依賴物件實體 | No | Java `static method` |
| **method** | 物件方法，操作當前物件的數據 | **Yes** (argument 0) | Java instance method |
| **constructor** | 建構子，建立新物件實體 | No (but returns `this`) | Java constructor |

---

## 3. 語法範例 (Syntax Example)

```jack
class Point {
    // 欄位 (Fields, 只有 method/constructor 可存取)
    field int x, y;

    // 建構子
    constructor Point new(int Ax, int Ay) {
        let x = Ax;
        let y = Ay;
        return this; // 必須顯式回傳 this
    }

    // 方法 (Method)
    method void print() {
        do Output.printString("(");
        do Output.printInt(x);
        do Output.printString(",");
        do Output.printInt(y);
        do Output.printString(")");
        return;
    }

    // 記憶體釋放 (必須手動實作)
    method void dispose() {
        do Memory.deAlloc(this);
        return;
    }
}
```
## 4. 記憶體管理 (Memory Management)

這是 Jack 語言與現代高階語言（如 Java/Python）最大的不同之處：**Jack 沒有垃圾回收機制 (Garbage Collection)**。

* **分配 (Allocation)**:
    * 使用 `new` 關鍵字實例化物件時，OS 會自動尋找並分配記憶體。
* **釋放 (Deallocation)**:
    * 當物件不再使用時，程式設計師**必須手動釋放**記憶體，否則會造成 Memory Leak (記憶體洩漏)。

### 最佳實踐 (Best Practice)
1.  每個類別都應該實作一個 `dispose()` 方法。
2.  **釋放順序**: 先釋放成員物件 (Member Objects)，最後釋放自己。

```jack
method void dispose() {
    // 1. 先呼叫成員物件的 dispose (如果有的話)
    if (~(obj == null)) {
        do obj.dispose();
    }

    // 2. 最後呼叫 OS 釋放當前物件佔用的記憶體
    do Memory.deAlloc(this);
    return;
}
```
## 5. 標準函式庫 (Standard Library / OS API)

Hack 平台提供了一組類似作業系統 (OS) 的 API 供我們使用。在開發遊戲或應用程式時，最常使用以下模組：

### A. Output (文字輸出)
負責處理螢幕上的文字顯示 (11 rows, 64 cols)。
* `Output.printString(String s)`: 印出字串。
* `Output.printInt(int i)`: 印出整數。
* `Output.moveCursor(int row, int col)`: 移動游標到指定位置。

### B. Screen (圖形繪製)
負責像素級的繪圖 (256 rows, 512 cols)。
* `Screen.drawRectangle(x1, y1, x2, y2)`: 繪製實心矩形。
* `Screen.drawCircle(x, y, r)`: 繪製實心圓。
* `Screen.setColor(boolean b)`: 設定畫筆顏色 (`true`=黑, `false`=白/擦除)。

### C. Keyboard (鍵盤輸入)
負責讀取使用者輸入。
* `Keyboard.keyPressed()`: 回傳當前按下的鍵碼 (ASCII)。
    * 若無按鍵，則回傳 `0`。
    * **常用鍵碼**: 左箭頭(130), 上(131), 右(132), 下(133), Enter(128)。
* `Keyboard.readInt(String message)`: 顯示提示訊息並讀取使用者輸入的整數。

### D. Math (數學運算)
提供基本的數學功能 (因為 Hack 硬體不支援乘除法)。
* `Math.multiply(int a, int b)`: 乘法。
* `Math.divide(int a, int b)`: 除法。
* `Math.sqrt(int x)`: 開根號。
* > **注意**：Jack 語言不支援浮點數運算 (No floating point support)。

### E. Memory (記憶體存取)
允許直接操作實體記憶體 (RAM)。
* `Memory.peek(int address)`: 讀取指定地址的數值 (等同 `return RAM[address]`)。
* `Memory.poke(int address, int value)`: 修改指定地址的數值 (等同 `RAM[address] = value`)。
# 第10章

## 1. 核心概念 (Overview)
這是兩階段編譯器的第一階段。
* **輸入**: `.jack` 原始碼檔案。
* **處理**:
    1.  **Tokenizer (詞彙分析)**: 將字元流 (Characters) 切割成有意義的標記 (Tokens)。
    2.  **Parser (語法分析)**: 根據 Jack 的文法規則 (Grammar)，將 Tokens 組織成樹狀結構。
* **輸出**: `.xml` 檔案 (解析樹)。
    * *注意*: 這一章還不會產生 `.vm` 程式碼，XML 只是為了驗證你的 Parser 對結構的理解是否正確。

---

## 2. 詞彙分析 (Lexical Analysis / Tokenizer)

Tokenizer 的工作是忽略空白與註解，將程式碼分解為以下五種 Token：

### Token 類型
1.  **Keyword (關鍵字)**: `class`, `constructor`, `function`, `method`, `int`, `boolean`, `if`, `while`... 等保留字。
2.  **Symbol (符號)**: `{`, `}`, `(`, `)`, `[`, `]`, `.`, `,`, `;`, `+`, `-`, `*`, `/`, `&`, `|`, `<`, `>`, `=`, `~`。
3.  **Integer Constant (整數常數)**: 0 ~ 32767 的數字。
4.  **String Constant (字串常數)**: 被雙引號包圍的字串 (不含引號與換行)。
5.  **Identifier (識別字)**: 程式設計師自定義的名稱 (變數名、類別名、函式名)。不能以數字開頭。

### XML 輸出範例
Tokenizer 會將每個 Token 包在對應的標籤中：
```xml
<keyword> if </keyword>
<symbol> ( </symbol>
<identifier> x </identifier>
<symbol> &lt; </symbol>  <integerConstant> 0 </integerConstant>
<symbol> ) </symbol>
```
## 3. 語法分析 (Syntax Analysis / Parser)

我們使用 **遞迴下降解析器 (Recursive Descent Parser)** 來實作。這意味著對於文法中的每一個「非終端規則 (Non-terminal rule)」，我們都會編寫一個對應的方法來處理。



### 文法規則 (Grammar Rules)
Jack 的文法是 **LL(1)** 的，這代表我們只需要「偷看 (Lookahead)」下一個 Token，就能決定要呼叫哪個編譯方法，不需要回溯 (Backtracking)。

#### 1. 程式結構 (Program Structure)
* `class`: `class className { classVarDec* subroutineDec* }`
* `classVarDec`: `static` | `field` type varName, ... ;
* `subroutineDec`: `constructor` | `function` | `method` ...

#### 2. 陳述句 (Statements)
* `letStatement`: `let varName = expression;`
* `ifStatement`: `if (expression) { statements } else { statements }`
* `whileStatement`: `while (expression) { statements }`
* `doStatement`: `do subroutineCall;`
* `returnStatement`: `return expression?;`

#### 3. 表達式 (Expressions)
這是最複雜的部分，因為有運算子優先權與嵌套結構的問題。
* `expression`: `term (op term)*`
* `term`: `integerConstant` | `stringConstant` | `keywordConstant` | `varName` | `varName[expression]` | `subroutineCall` | `(expression)` | `unaryOp term`

---

## 4. 實作架構 (Implementation Architecture)



建議將程式拆分為兩個主要模組：

### A. JackTokenizer (模組)
負責處理字串流 (Input Stream)。
* `hasMoreTokens()`: 是否還有下一個標記？
* `advance()`: 讀取下一個標記。
* `tokenType()`: 回傳當前 Token 的類型 (`KEYWORD`, `SYMBOL`, `IDENTIFIER`...)。
* `keyWord()`, `symbol()`, `intVal()`...: 回傳具體的 Token 內容。

### B. CompilationEngine (模組)
負責遞迴解析，並輸出 XML 檔案。
建構子通常接收一個 `JackTokenizer` 物件和一個輸出檔案 (或 Stream)。

* **結構編譯**:
    * `compileClass()`
    * `compileClassVarDec()`
    * `compileSubroutine()`
* **陳述句編譯**:
    * `compileStatements()`: 迴圈檢查下一個 Token 是否為 `let`/`if`/`while`/`do`/`return`。
    * `compileLet()`, `compileIf()`, `compileWhile()`...
* **表達式編譯**:
    * `compileExpression()`
    * `compileTerm()`: **(最難點)** 需判斷是變數、陣列存取還是函式呼叫。
    * `compileExpressionList()`

---

## 5. 實作細節與難點 (Implementation Tips)

### 1. 處理 XML 特殊字元
XML 規範中，`<`, `>`, `&` 必須轉義，否則瀏覽器或比對器無法正確讀取。
* `<`  -> `&lt;`
* `>`  -> `&gt;`
* `&`  -> `&amp;`
* `"`  -> `&quot;` (雙引號通常可不轉，但建議轉義以防萬一)

### 2. LL(1) 的衝突解決 (Lookahead)
在 `compileTerm` 時會遇到歧義，例如開頭都是 `identifier`：
* `varName` (變數)
* `varName[expression]` (陣列存取)
* `varName.method()` (方法呼叫)

**解法**: 當讀到 `identifier` 時，必須**偷看 (Lookahead)** 下一個 Token：
* 如果是 `[` -> 呼叫陣列處理邏輯。
* 如果是 `(` 或 `.` -> 呼叫副程式處理邏輯。
* 否則 -> 視為單純變數。

### 3. 表達式的遞迴結構
`compileExpression` 的邏輯通常如下 (處理 `term op term` 結構)：
```python
# Pseudo code
compileTerm() # 處理第一個項 (例如: a)

while (nextToken is op): # 檢查是否為 + - * / & | < > =
    write symbol (op)    # 輸出運算子
    advance()            # 消耗運算子
    compileTerm()        # 處理下一個項 (例如: b)
```
### 4. 終端與非終端符號的處理 (Terminal vs. Non-terminal Handling)

在實作遞迴下降解析器 (Recursive Descent Parser) 時，區分這兩者對於正確生成 XML 結構至關重要。

#### **A. 終端符號 (Terminal Symbols)**
* **定義**: 這是遞迴的**終點**，也就是語法樹 (Parse Tree) 的葉節點 (Leaf Nodes)。
* **內容**: 來自 Tokenizer 的基本單元。
* **範例**: 關鍵字 (`class`, `while`)、符號 (`{`, `;`)、整數常數 (`123`)、字串常數、識別字 (`varName`)。
* **處理方式**: 直接寫入 XML 標籤中，**不需要**再呼叫其他 `compile` 方法。
    ```xml
    <keyword> class </keyword>
    <symbol> { </symbol>
    ```

#### **B. 非終端符號 (Non-terminal Symbols)**
* **定義**: 這是遞迴的**過程**，由多個終端符號或其他非終端符號組成的高階結構。
* **內容**: 文法規則中定義的結構 (Grammar Rules)。
* **範例**: `class`, `subroutineDec`, `expression`, `ifStatement`。
* **處理方式**: 需要用 XML 標籤將遞迴過程「包裹」起來。
* **邏輯流程 (以 `expression` 為例)**:
    1.  先寫入開始標籤 `<expression>`。
    2.  呼叫 `compileExpression()` (這會在內部遞迴處理更多的 `term` 和 `op`)。
    3.  從函式返回後，寫入結束標籤 `</expression>`。



#### **C. 實作範例 (Pseudo-code)**

```python
def compileWhile(self):
    # 1. 寫入非終端標籤 (開始)
    self.write("<whileStatement>")

    # 2. 處理內部結構 (混合終端與非終端)
    self.write("<keyword> while </keyword>")  # 終端
    self.write("<symbol> ( </symbol>")        # 終端

    self.compileExpression()                  # 非終端 (遞迴)

    self.write("<symbol> ) </symbol>")        # 終端
    self.write("<symbol> { </symbol>")        # 終端

    self.compileStatements()                  # 非終端 (遞迴)

    self.write("<symbol> } </symbol>")        # 終端

    # 3. 寫入非終端標籤 (結束)
    self.write("</whileStatement>")
```
# 第11章
## 1. 核心概念 (Overview)
這是編譯器的後端 (Back-end)。我們不再輸出 XML，而是使用 `VMWriter` 輸出 `.vm` 指令。
* **目標**: 將 Jack 語言的高階邏輯翻譯成堆疊機 (Stack Machine) 的操作。
* **核心挑戰**:
    1.  **資料對應**: 如何將變數對應到 VM 的記憶體區段 (local, argument, this, static)。
    2.  **表達式計算**: 將中綴表示法 (Infix) `x + y` 轉為後綴堆疊操作。
    3.  **物件操作**: 處理 `this` 指標、建構子記憶體分配、方法呼叫。
    4.  **流程控制**: 自動生成 Label 以處理 `if` 和 `while`。

---

## 2. 符號表 (Symbol Table)
為了將變數名稱 (如 `salary`, `i`, `p`) 轉換為 VM 指令 (如 `pop local 2`)，我們需要一個符號表來追蹤所有變數。



### 作用域 (Scopes)
我們需要兩個 Hash Map (或類似結構)：
1.  **Class-Level (類別級)**: 記錄 `static` 和 `field` 變數。
2.  **Subroutine-Level (函式級)**: 記錄 `argument` 和 `var` (local) 變數。每次編譯新的 subroutine 時需清空並重置。

### 記錄內容 (Properties)
對於每個變數，我們需要記錄：
* **Name**: 識別字 (如 `x`)。
* **Type**: 資料型別 (如 `int`, `boolean`, `Point`)。
* **Kind**: 變數種類 (決定對應的 VM segment)。
* **Index**: 該種類中的序號 (從 0 開始)。

| Variable Kind | VM Segment | 備註 |
| :--- | :--- | :--- |
| **field** | `this` | 物件的成員變數 |
| **static** | `static` | 類別共用變數 |
| **var** | `local` | 區域變數 |
| **argument** | `argument` | 函式參數 |

---

## 3. 變數與表達式編譯 (Variables & Expressions)

### 變數的使用
當 Parser 遇到一個識別字 (Identifier) 時，先查 **Subroutine-Level** 表，如果找不到，再查 **Class-Level** 表。
* **Push (讀取)**: `int x = i;` -> `push local 0` (假設 i 是第 0 個 var)。
* **Pop (寫入)**: `let salary = 5000;` -> `push constant 5000`, `pop this 2` (假設 salary 是第 2 個 field)。



### 表達式運算
Jack 的 `term op term` 結構天然適合遞迴編譯成堆疊指令。
* **Jack**: `x + y`
* **Logic**: `compileExpression(x)` -> `compileExpression(y)` -> `writeOp(+)`
* **VM**:
    ```vm
    push local 0  // x
    push local 1  // y
    add
    ```

---

## 4. 物件導向處理 (Handling Objects)

這是本章最複雜的部分，需要精確操作記憶體。



### A. 建構子 (Constructors)
* **任務**: 為新物件分配記憶體，並回傳 `this`。
* **編譯邏輯**:
    1.  計算 `field` 變數的數量 (查 Symbol Table)。
    2.  呼叫 `Memory.alloc(size)`。
    3.  將回傳的 Base Address 設定給 `pointer 0` (也就是 `THIS`)。
    4.  最後必須 `push pointer 0` 並 `return`，將物件參照傳回給呼叫者。
* **VM Code**:
    ```vm
    push constant 2    // 假設有 2 個 fields
    call Memory.alloc 1
    pop pointer 0      // 設定 THIS = address
    ... (初始化欄位) ...
    push pointer 0     // 回傳 this
    return
    ```

### B. 方法 (Methods) vs 函式 (Functions)
* **Function**: 靜態呼叫，無隱藏參數。
* **Method**: 物件呼叫，**第一個參數 (Argument 0) 永遠是 `this`**。
* **編譯 Method 定義**:
    * 進入 method 後的第一件事，是將 `argument 0` (Caller 傳入的物件地址) 設定給 `THIS` 指標。
    * **VM Code**:
        ```vm
        push argument 0
        pop pointer 0    // 設定 THIS segment 對齊當前物件
        ```
* **編譯 Method 呼叫 (`obj.foo(x)`)**:
    * 必須先 Push `obj` 的參照 (Reference) 到堆疊上。
    * 然後 Push `x`。
    * 最後 `call Class.foo 2` (參數個數是 1+1)。

### C. 陣列 (Arrays)
陣列存取 `a[i] = y` 需要操作 `THAT` 指標 (`pointer 1`)。
* **邏輯**:
    1.  Push 陣列基底地址 `a`。
    2.  Push 索引 `i`。
    3.  `add` (計算出 `a + i` 的目標地址)。
    4.  **注意**: 這裡不能直接 Pop，因為我們要先算等號右邊的 `y`。通常使用 `temp` 暫存或是特殊的堆疊順序。
    5.  標準做法:
        * 算好地址 `a+i`。
        * Pop 到 `pointer 1` (現在 `THAT` 指向 `a[i]`)。
        * Push `y`。
        * `pop that 0`。

---

## 5. 流程控制 (Flow Control)

`if` 和 `while` 需要生成唯一的 Label 來控制跳轉。

### If Statement
**Jack**: `if (cond) { s1 } else { s2 }`
**VM Logic**:
```vm
    // compile condition (cond)
    not
    if-goto L1
    // compile s1
    goto L2
label L1
    // compile s2 (if exists)
label L2
```
