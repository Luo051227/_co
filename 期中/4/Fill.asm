// Fill.asm
// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen.
// When no key is pressed, the program clears the screen.

(START)
    @KBD
    D=M             // 讀取鍵盤輸入
    @BLACK
    D;JNE           // 如果 KBD != 0 (有按鍵)，跳轉到 BLACK 設定顏色
    @WHITE
    D;JEQ           // 如果 KBD == 0 (沒按鍵)，跳轉到 WHITE 設定顏色

(BLACK)
    @-1
    D=A             // D = 1111111111111111 (全黑)
    @color
    M=D             // 把顏色存入變數 color
    @DRAW_PREP
    0;JMP           // 跳去準備繪圖

(WHITE)
    @0
    D=A             // D = 0000000000000000 (全白)
    @color
    M=D             // 把顏色存入變數 color
    @DRAW_PREP
    0;JMP           // 跳去準備繪圖

(DRAW_PREP)
    @SCREEN
    D=A
    @address
    M=D             // address = 16384 (螢幕記憶體的起始位置)

    @8192
    D=A
    @count
    M=D             // count = 8192 (螢幕總共有幾個 Word 要畫)

(DRAW_LOOP)
    @count
    D=M
    @START
    D;JEQ           // 如果 count == 0，代表畫完了，跳回 START 重新監聽鍵盤

    @color
    D=M             // 讀取剛才決定的顏色 (-1 或 0)
    
    @address
    A=M             // 取出 address 裡面的值，設為當前的位址 A
                    // 關鍵！這裡 A 變成了 16384, 16385... 等等
    M=D             // 把顏色寫入 RAM[address] (螢幕變色！)

    @address
    M=M+1           // address 指標往後移一格
    @count
    M=M-1           // 計數器減一

    @DRAW_LOOP
    0;JMP           // 繼續畫下一個像素單元

//決定顏色： 有按鍵 -> -1 (全黑, 1111...)；沒按鍵 -> 0 (全白, 0000...)
//螢幕記憶體從 16384 開始，總共有 8192 個 Word (因為 256列 * 512行 / 16位元 = 8192)。
//用一個迴圈把這 8192 個格子都填入剛才決定的顏色
