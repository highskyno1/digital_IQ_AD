# 数字I/Q正交解调A/D转换的原理与仿真~中频采样接收机&amp;Rader接收机&amp;Shaw-Pohlig接收机
本项目是一篇CSDN博文的附录代码，文章地址：https://blog.csdn.net/weixin_41476562/article/details/135684222

本项目Github仓库：https://github.com/highskyno1/digital_IQ_AD/
# 前言
I/Q解调技术广泛存在于无线通信中，其重要性毋庸置疑，然而传统的I/Q解调存在I/Q通道不匹配问题，导致Q通道存在I通道的“残余镜像”，严重破坏了正交性。近年来随着电子技术的发展，数字I/Q技术开始从理论走向实际，该技术可以克服模拟接收机通道的匹配限制。这些方法的特征包括在进行 A/D 转换之前采用模拟混频以及滤波方法将单一的实输入信号搬移到较低的中频。这样，同 RF 频段采样相比，会大大降低对 A/D 转换速度的耍求。此外，选择IF 频段会使对信号$exp(j\omega _0n)$的复数乘法运算变为相当简单的形式。其次，这类方法通过数字滤波和降采样联合处理来获得最终的输出，它仅包含所需原始频谱的边带信号，而且近似奈奎斯特采样率为每秒 $\beta$ 个复数样本[^1]。
# 中频采样接收机
根据奈奎斯特采样定理，不失真采样率至少要为信号最高频率的两倍，才能实现无失真采样，如果按照该定理，采样率达到载频的两倍以上才能把信号采下来。实际上，当原信号为==带通信号==时，采样率只需要满足一定的条件（==无需达到奈奎斯特采样率==），就能无失真地将信号采样下来！
中频采样定理的原理如下图所示，左边为信号采样前的幅度谱，右边为采样后的频谱，采样率固定为400Hz，当带通信号的频带满足一定条件时，采样后的频谱与将该带通信号下变频后再采样（如下图最后一行和第一行所示）的频谱一致，不会发生频谱混叠！
# Rader接收机
Rader接收机的数字I/Q结构将所需的模拟信号通道数由两个减少为一个，并使得正交振荡器以及增益，匹配问题变得毫无意义，另外A/D模块也减少到了一个。但是Rader接收机也有一些缺点，所需的A/D转换速率为传统I/Q解调的4倍，并且需要引入高速率的数字滤波器。
# Shaw-Pohlig接收机
Shaw-Pohlig接收机由Shaw和Pohlig(1995)[^3]所提出，与Rader接收机相比，Shaw-Pohlig接收机的主要优点为A/D转换的采样率只需是信号带宽的2.5倍，而不是4倍，但也存在以下两个个缺点：
1. 较低的中频和采样率要求数字滤波器具有较陡峭的暂态导致滤波器阶数的增加和系统运算量的增加。
2. 最终采样率比基带信号的奈奎斯特采样率增加25%，而Rader的系统采样率与奈奎斯特采样率相同，采样率的增加使得整个数字系统处理中所需的最小计算量增加25%。
需要注意的是，由于Shaw-Pohlig接收机采用的是信号的下边带，而其它接收机采用的是上边带，这回导致Shaw-Pohlig接收机的Q通道（即输出信号的虚部）与其它三种接收机符号相反。

[^1]:Richards, M. A. (2005). Fundamentals of radar signal processing (Vol. 1). New York: Mcgraw-hill.
[^2]:Rader, C. M. (1984). A simple method for sampling in-phase and quadrature components. IEEE Transactions on Aerospace and Electronic Systems, (6), 821-824.
[^3]:Shaw, G. A., & Pohlig, S. C. (1995). I/Q baseband demodulation in the RASSP SAR benchmark. Lincoln Laboratory, Massachusetts Institute of Technology.
