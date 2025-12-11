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
  Input A,Input B,And,Or,Xor  
  0,0,0,0,0  
  0,1,0,1,1  
  1,0,0,1,1  
  1,1,1,1,0  
## 2. 選擇與分配器 (Selectors & Distributors)
* Mux (多工器)  
  多選一。它有兩個輸入數據 (a, b) 和一個選擇信號 (sel)  
  sel == 0，輸出 a，sel == 1，輸出 b    
  ![licensed-image](https://github.com/user-attachments/assets/65084fb8-6b52-4879-aeb7-8964c0e65cdc)  
* DMux (解多工器)  
  一分多。它有一個輸入 (in) 和一個選擇信號 (sel)，輸出分為 a 和 b  
  sel == 0，原本的輸入傳送到 a（b 則為 0），sel == 1，原本的輸入傳送到 b（a 則為 0）    
* 16-bit
  
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
