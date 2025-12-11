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
[作業](https://github.com/Luo051227/_co/tree/main/%E6%9C%9F%E4%B8%AD/3)
[AI](https://gemini.google.com/share/343a93793658)
# 第四章
[作業](https://github.com/Luo051227/_co/tree/main/%E6%9C%9F%E4%B8%AD/4)
[AI](https://gemini.google.com/share/c1643e25113f)
# 第五章
[作業](https://github.com/Luo051227/_co/tree/main/%E6%9C%9F%E4%B8%AD/5)
[AI](https://gemini.google.com/share/d22f4a1e0077)
