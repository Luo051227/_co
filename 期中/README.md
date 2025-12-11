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
## 2. 選擇與分配器 (Selectors & Distributors)
* Mux (多工器)  
  多選一。它有兩個輸入數據 (a, b) 和一個選擇信號 (sel)  
  `sel == 0，輸出 a`  
  `sel == 1，輸出 b`        
* DMux (解多工器)  
  一分多。它有一個輸入 (in) 和一個選擇信號 (sel)，輸出分為 a 和 b  
  `sel == 0，原本的輸入傳送到 a（b 則為 0）`  
  `sel == 1，原本的輸入傳送到 b（a 則為 0）`        
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
  用途： 常用來檢查一個數字是否為非零  
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
[AI](https://gemini.google.com/share/e8517dddc71d)
# 第三章
[AI](https://gemini.google.com/share/343a93793658)
# 第四章
[AI](https://gemini.google.com/share/c1643e25113f)
# 第五章
[AI](https://gemini.google.com/share/d22f4a1e0077)
