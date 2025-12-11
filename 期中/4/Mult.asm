// Mult.asm
// Computes R2 = R0 * R1
// Logic: Initialize R2 to 0, then add R1 to R2, R0 times.

    @R2
    M=0     // R2 = 0 (初始化結果為0，這是好習慣)

    @R0
    D=M
    @END
    D;JEQ   // 如果 R0 == 0，直接跳到 END (乘數為0，結果為0)

    @R1
    D=M
    @END
    D;JEQ   // 如果 R1 == 0，直接跳到 END (被乘數為0，結果為0)

(LOOP)
    @R1
    D=M     // D = R1
    @R2
    M=D+M   // R2 = R2 + R1 (累加)

    @R0
    M=M-1   // R0 = R0 - 1 (計數器減 1)

    D=M     // D = 目前剩下的 R0
    @LOOP
    D;JGT   // 如果 D > 0 (R0還沒歸零)，跳回 LOOP 繼續加

(END)
    @END
    0;JMP   // 無限迴圈，防止程式跑到後面的記憶體
//Hack 組合語言沒有乘法指令。我們要用累加法。
//R0 * R1 等於把 R1 加 R0 次。
//例如 3 * 5，就是 0 + 5 + 5 + 5
