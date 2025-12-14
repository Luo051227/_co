# Nand2Tetris 第六章筆記：組譯器 (Assembler)

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
