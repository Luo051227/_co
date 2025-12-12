# 第一章
## 1. 基本邏輯閘 (Basic Logic Gates)
* Not 閘  
  邏輯思考：
  * 0, 0 -> 1
  * 0, 1 -> 1
  * 1, 0 -> 1
  * 1, 1 -> 0  

  `if in=0 then out=1 else out=0`  

  功能：  
  將輸入反轉。如果輸入是 0，輸出就是 1  
* And 閘
  只有兩個都為 1 時才輸出 1  
  `if a=1 and b=1 then out=1 else out=0`  
* Or (或閘)
  只要有任何一個輸入是 1，輸出就是 1  
  `if a=1 or b=1 then out=1 else out=0`  
* Xor (互斥或閘)  
  當兩個輸入不同時，輸出為 1；若兩個輸入相同（都是0或都是1），輸出為 0  
```text
Input A  Input B  And  Or  Xor
------------------------------
   0        0      0    0    0
   0        1      0    1    1
   1        0      0    1    1
   1        1      1    1    0
```
## 2. 選擇與分配器 (Selectors & Distributors)
* Mux (多工器)  
  多選一。它有兩個輸入數據 (a, b) 和一個選擇信號 (sel)  
  `sel == 0，輸出 a`  
  `sel == 1，輸出 b`        
* DMux (解多工器)  
  一分多。它有一個輸入 (in) 和一個選擇信號 (sel)，輸出分為 a 和 b  
  `sel == 0，原本的輸入傳送到 a（b 則為 0）`  
  `sel == 1，原本的輸入傳送到 b（a 則為 0）`
## 3. 多位元與多通道變體 (Bus & Multi-Way Variants)      
* Not16  
  將 16 個輸入位元全部反轉  
* And16  
  將兩個 16 位元的數字進行按位（Bit-wise）And 運算  
* Or16  
  將兩個 16 位元的數字進行按位 Or 運算  
* Mux16  
  在兩個 16 位元的數字之間做選擇  
   (sel) 仍然只有 1 個位元，但輸出是一整組 16 位元的數據  
* Or8Way  
  輸入是一個 8 位元的數據。只要這 8 個位元裡有任何一個是 1，輸出就是 1  
  用途：  
  常用來檢查一個數字是否為非零  
* Mux4Way16
  4 選 1 的多工器，每個選項都是 16 位元寬
  有 4 個選項 (a, b, c, d)，所以需要 2 個位元 的選擇信號 (sel[0..1])
  * 00 -> 選 a
  * 01 -> 選 b
  * 10 -> 選 c
  * 11 -> 選 d  
* Mux8Way16  
  8 選 1 的多工器，每個選項都是 16 位元寬  
  有 8 個選項，需要 3 個位元 的選擇信號 (2^3 = 8)  
* DMux4Way  
  將 1 個輸入信號分配到 4 個出口中的其中一個  
  需要 2 個位元的選擇信號  
* DMux8Way  
  將 1 個輸入信號分配到 8 個出口中的其中一個  
  需要 3 個位元的選擇信號  
  
[作業](https://github.com/Luo051227/_co/tree/main/%E6%9C%9F%E4%B8%AD/1)
[AI](https://gemini.google.com/share/18d05542899e)
# 第二章
## 1. 基礎加法器 (The Adders)
* HalfAdder (半加器)  
  計算 a + b，輸入： a, b  
  輸出：  
  `sum (總和)：當前位元的結果`  
  `carry (進位)：是否進位到下一位`  
  原理：  
  `1 + 0 = 1 (sum=1, carry=0)`  
  `1 + 1 = 10 (二進制的 2。sum=0, carry=1)`  
  組成：   
  一個 Xor 閘 (算 sum) + 一個 And 閘 (算 carry)  
  缺點：  
  沒辦法處理「上一位傳過來的進位」，所以只能用在個位數相加。  
* FullAdder (全加器)  
  解決半加器的缺點，全加器多了一個「進位輸入」  
  功能：  
  計算 a + b + c (c 是前一位的進位)  
  輸入：  
  a, b, c (input carry)  
  輸出：  
  `sum` , `carry`  
  組成：  
  由 2 個 HalfAdder 和 1 個 Or 閘組成  
  意義：多位元加法的基本磚塊，多個 FullAdder 串起來，就能算大數字
## 2. 16-bit 運算單元
* Add16  
  功能：  
  計算兩個 16 位元數字的相加 (out = a + b)  
  實作：  
  把 16 個 FullAdder 排成一排  
  * 第 0 位的 carry 輸出連到第 1 位的 carry 輸入，以此類推  
  * 這在硬體上被稱為「漣波進位加法器 (Ripple Carry Adder)」，因為進位像波浪一樣從最低位傳到最高位。  
* Inc16  
  功能：  
  將輸入的數字加 1 (out = in + 1)  
  用途：  
  這是電腦運作最常用的功能之一，主要用於 Program Counter (PC)。電腦執行完一行指令後，需要把地址 +1 跳到下一行指令，這就是 Inc16 的工作  
  實作：  
  一個 Add16，其中一個輸入是 in，另一個輸入固定設為 1  
## 3. 電腦的大腦
* ALU  
  前面所有的元件（Add, And, Or, Not...）最後都封裝在這裡面  
  功能：  
  根據「控制信號 (Control Bits)」，決定要對輸入的數據做什麼運算（加法、減法、And、Or、反轉...）  
  輸入：  
  `x, y (兩個 16-bit 數據)`  
  `zx, nx, zy, ny, f, no (6 個控制位元，這是 Hack 電腦架構的特徵)`  
  輸出：  
  `out (計算結果)`  
  `zr (Zero flag): 是不是 0`  
  `ng (Negative flag): 是不是負數`  
  運作流程：  
  ALU 內部充滿了 Mux (多工器)  
  * 控制位元 f 決定 要算術(Add)還是要邏輯(And)  
  * 控制位元 no 決定 最後要不要把結果反轉(Not)  
 
總結：  
1. HalfAdder (只能算個位)  
2. FullAdder (能處理進位)  
3. Add16 (串聯 16 個 FullAdder)  
4. ALU (結合了 Add16 和之前學的 And16/Or16，變成一個萬能計算器)  

[作業](https://github.com/Luo051227/_co/tree/main/%E6%9C%9F%E4%B8%AD/2)
[AI](https://gemini.google.com/share/e8517dddc71d)
# 第三章
## 1. 基礎儲存單元
* Bit  
  只能儲存一個 0 或 1  
  功能：  
  能記住上一個時間點的狀態  
  原理：  
  由一個 DFF (Data Flip-Flop，資料正反器) 和一個 Mux (多工器) 組成  
  `load = 1 時，寫入新值`  
  `load = 0 時，Mux 會將 DFF 的輸出拉回輸入，形成迴圈，保持舊值不變`  
* Register  
  CPU 運算時使用的基本儲存單元  
  結構：  
  16 個 Bit 並排組成（在 Hack 電腦架構中）  
  功能：  
  可以儲存一個 16-bit 的字組 (Word)，例如一個整數或一個記憶體位址  
  運作：  
  16 個 Bit 共用同一個 load 訊號，load = 1，這 16 個 Bit 會同時更新  
## 2. RAM (隨機存取記憶體) 系列
`遞迴 (Recursive) 結構，利用小的 RAM 組合出大的 RAM`
* RAM8  
  容量：  
  8 個 16-bit 暫存器  
  定址 (Address)：  
  3 個位元 ($2^3 = 8$)，範圍是 000 到 111  
  原理：  
  * 輸入 (DMux)： 使用 address 的前幾位將輸入訊號導向正確的暫存器  
  * 輸出 (Mux)： 使用 address 將正確暫存器的輸出選出來  
* RAM64  
  容量：  
  64 個暫存器 (由 8 個 RAM8 組成)  
  定址：  
  6 個位元 ($2^6 = 64$)  
  原理：  
  * 高 3 位 address 用來選擇是哪一個 RAM8  
  * 低 3 位 address 用來選擇該 RAM8 裡面的哪一個 Register  
* RAM512  
  容量：  
  512 個暫存器 (由 8 個 RAM64 組成)  
  定址：  
  9 個位元  
  原理：  
  高 3 位選 RAM64，低 6 位交給被選中的 RAM64 處理  
* RAM4K (4096)  
  容量：  
  4096 個暫存器 (由 8 個 RAM512 組成)  
  定址：  
  12 個位元  
* RAM16K (16384)  
  容量：  
  16384 個暫存器 (由 4 個 RAM4K 組成)  
  定址：  
  14 個位元  
  注意：  
  這是 Hack 電腦的主記憶體大小。因為它是用 4 個 RAM4K 組成的（而不是 8 個），所以它的最上層邏輯稍微不同（使用 DMux4Way 和 Mux4Way）。  
## 3. 特殊功能暫存器
* PC  
  告訴 CPU 「下一行程式碼在哪裡」  
  功能：  
  儲存著下一條指令的記憶體位址  
  邏輯 (由高優先級到低優先級)：  
  1. Reset (重置)： 若 reset = 1，PC 歸零 (goto 0)。通常用於電腦重啟  
  2. Load (跳轉)： 若 load = 1，PC 被設為輸入值 (Jump 到特定行數)  
  3. Inc (遞增)： 若 inc = 1，PC 值加 1 (執行下一行)  
  4. Hold (保持)： 若以上皆非，保持原值  
## 總結
| 元件名稱 | 組成結構 | Address 位元數 | 功能描述 |
| :--- | :--- | :--- | :--- |
| **Bit** | `DFF` + `Mux` | 0 | 儲存 1 bit 資訊 (0 或 1) |
| **Register** | 16 x `Bit` | 0 | 儲存 16 bit 數值 (Word) |
| **RAM8** | 8 x `Register` | 3 (`kkk`) | 小型記憶體 |
| **RAM64** | 8 x `RAM8` | 6 (`nnnkkk`) | 中型記憶體 |
| **RAM512** | 8 x `RAM64` | 9 | 大型記憶體 |
| **RAM4K** | 8 x `RAM512` | 12 | 巨型記憶體 |
| **RAM16K** | 4 x `RAM4K` | 14 | Hack 電腦的主記憶體 |
| **PC** | `Register` + `Inc` | 0 | 程式計數器，控制執行順序 |  


[作業](https://github.com/Luo051227/_co/tree/main/%E6%9C%9F%E4%B8%AD/3)
[AI](https://gemini.google.com/share/343a93793658)
# 第四章
## 1. 核心觀念：Hack 電腦的架構 (The Architecture)
Hack 電腦有兩個主要的記憶體（Instruction Memory 和 Data Memory），以及三個關鍵的「暫存器 (Registers)」  
* D 暫存器 (Data Register): 專門用來儲存數據、計算結果  
* A 暫存器 (Address Register): 雙重用途  
  1. 儲存數據（常數）  
  2. 儲存記憶體位址（當你想讀寫 RAM 時，A 的值就是地址）  
* M (Memory): 這不是一個實體暫存器，它代表 RAM[A]。也就是說，目前 A 暫存器指到的那個記憶體位址裡面的值  
## 2. 實作工具：Hack 指令集 (Instruction Set)  
* A-Instruction (A 指令)  
  語法：`@value`    
  功能：  
  將數值載入到 A 暫存器  
  用途：   
  1. 設定常數 (例如 @100 -> A=100)  
  2. 選定記憶體位址 (例如 @sum -> A 指向變數 sum 的位址)  
  3. 設定跳轉目標 (例如 @LOOP -> A 指向標籤 LOOP 的程式行號)  
* C-Instruction (C 指令)  
  語法：  
  dest = comp ; jump (dest 和 jump 是選填的)  
  功能：  
  執行計算、存儲結果、決定是否跳轉  
  範例：  
  * D=M+1 (讀取記憶體 M 的值，加 1，存入 D)  
  * 0;JMP (無條件跳轉到 A 指向的行號)  
  * D;JGT (如果 D > 0，則跳轉到 A 指向的行號)  
## 3. 實作策略：如何寫 Hack Assembly  
* 變數與賦值 (Variables)  
  1. 選址 (@x)  
  2. 賦值 (M=10) (前提是 10 已經在 D 或可以直接生成)  
  ```text
  @10
  D=A   // 把常數 10 放入 D
  @x    // 讓 A 指向變數 x 的記憶體位置
  M=D   // 把 D 的值 (10) 存入 M (也就是 x)
  ```
* 迴圈與邏輯控制 (Loops & Logic)  
  定義 Label：  
  使用 (LOOP) 或 (END) 來標記位置  
  比較：  
  做減法運算 (例如 D-A)  
  跳轉：  
  根據運算結果決定是否跳轉 (JEQ, JGT, JLT 等)  
  ```text
  (LOOP)  
   // 這裡寫你的程式碼...
   @LOOP
   0;JMP // 無條件跳回 LOOP 標籤
  ```
* 指標與螢幕操作 (Pointers & I/O)  
  * SCREEN (RAM[16384]): 改變這裡的數值會直接讓螢幕像素變黑或變白  
  * KBD (RAM[24576]): 讀取這裡的數值可以知道使用者按了什麼鍵  
## 具體任務流程 (Project 4 Workflow)  
思考邏輯：  
先用 Pseudo-code (類似 Python 或 C) 寫下邏輯  
Mult:`i=0, sum=0, while i < R1: sum += R0, i++`  
Fill:`if KBD != 0: fill_screen_black() else: fill_screen_white()`  
使用 CPU Emulator：  
* 這是 Nand2Tetris 提供的軟體工具  
* 載入 .asm 檔  
* 會模擬 Hack 電腦的運作。可以單步執行 (Single Step)，觀察 D、A、RAM 的數值變化   
[作業](https://github.com/Luo051227/_co/tree/main/%E6%9C%9F%E4%B8%AD/4)
[AI](https://gemini.google.com/share/c1643e25113f)
# 第五章
## 1. Memory (記憶體)  
Hack 平台中，Memory 晶片不只是一條 RAM，它是一個 「記憶體映射 (Memory Map)」 裝置。這意味著不同的地址範圍對應到不同的硬體  
目標：  
建立一個單一介面，根據輸入的 address，將數據導向正確的硬體  
Hack Memory 的結構：  
* RAM16K: 負責數據儲存 (地址 0 ~ 16383)  
* Screen: 負責顯示 (地址 16384 ~ 24575)  
* Keyboard: 負責輸入 (地址 24576)  
實作邏輯 ：  
`需要觀察 15 位元地址 (address[0..14]) 的前幾位來決定要啟動哪個零件`  
* RAM16K: 當 address[14] == 0 時，存取 RAM  
* Screen: 當 address[14] == 1 且 address[13] == 0 時，存取螢幕  
* Keyboard: 當 address[14] == 1 且 address[13] == 1 時，讀取鍵盤  
構建：  
* DMux (Demultiplexer) 來分配 load 訊號（決定寫入 RAM 還是 Screen）  
* Mux (Multiplexer) 來整合最後的 out 輸出（決定輸出 RAM 的值、Screen 的值還是 Keyboard 的值）  
## 2. CPU (中央處理器)  
CPU 的主要組成：  
* ALU: 負責計算 (在 Project 2 做過)  
* Register A (A 暫存器): 存放數據或「地址」  
* Register D (D 暫存器): 專門存放數據  
* PC (Program Counter): 決定下一行指令在哪裡  
實作核心邏輯 (解碼指令)：  
Hack 的指令是 16-bit 的 (instruction[16])。你需要判斷它是 A-指令 還是 C-指令  
* 分辨指令類型 (Bit 15):  
  * instruction[15] == 0：這是 A-指令 (例如 @100)。這時你需要把數值載入 A 暫存器  
  * instruction[15] == 1：這是 C-指令 (例如 D=M+1)。這時你需要控制 ALU 運算並決定存入哪裡  
* 控制訊號 (C-指令的解碼):  
  * ALU 的輸入:  
    其中一個輸入永遠是 D 暫存器；另一個輸入取決於 instruction[12] (a-bit)，決定是讀取 A 暫存器 還是 Memory input (inM)  
  * 寫入控制 (Destination bits):  
    d1, d2, d3 (bits 5, 4, 3) 分別控制是否寫入 A 暫存器、D 暫存器或 Memory (writeM)  
  * 跳轉邏輯 (Jump bits):  
    j1, j2, j3 (bits 2, 1, 0) 配合 ALU 的輸出旗標 (zr, ng) 來決定 PC 是否要載入新地址 (Jump) 還是繼續 +1
## 3. Computer (整台電腦)  
結構 (馮·紐曼架構):  
* ROM32K (唯讀記憶體): 這裡存放程式碼  
* CPU: 執行運算  
* Memory: 存放數據  
連接方式 (繞圈圈的資料流):  
* ROM -> CPU:  
  ROM32K 的輸出 (instruction) 連接到 CPU 的 instruction 輸入  
* CPU -> Memory:  
  CPU 計算出的 outM (數據)、addressM (地址)、writeM (寫入訊號) 全部連到 Memory 的對應輸入  
* Memory -> CPU:  
  Memory 的輸出 out 連回到 CPU 的 inM (這是為了讓 CPU 讀取記憶體的值)  
* CPU -> ROM:  
  CPU 的 pc (Program Counter) 輸出，連接到 ROM32K 的 address 輸入 (告訴 ROM 下一行要給 CPU 什麼指令)  
Reset 按鈕:  
Computer 晶片有一個 reset 輸入，直接連到 CPU 的 reset 腳位。當按下時，PC 歸零，程式重頭開始  
## 總結  
* Memory: 最簡單，練習操作地址位元 (Bit manipulation)  
* CPU: 最難，建議先把那張 Hack CPU 的架構圖印出來，用筆畫出 A-指令和 C-指令時數據該怎麼流動  
* Computer: 最快，只要正確連接上面兩個晶片與 ROM 即可  
[作業](https://github.com/Luo051227/_co/tree/main/%E6%9C%9F%E4%B8%AD/5)
[AI](https://gemini.google.com/share/d22f4a1e0077)
