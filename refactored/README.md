# Any Wave 重构版

这个目录是原 Quartus 工程的教学重构版，用于完成“可变参数波形发生器设计”课程大作业。工程保留 4 个 ROM 波形 IP，把手写控制逻辑拆成更容易讲清楚、也更容易手动复刻的模块。

## 大作业完成情况

必做功能已经完成并验证：

- 4 种波形：正弦波、方波、锯齿波、三角波。
- 按键控制：`key1` 切换波形，`key2` 切换幅值，`key3` 切换频率。
- 参数种类：幅值、频率两类参数。
- 参数档位：幅值 4 档，频率 4 档。
- 验证结果：Quartus `0 errors`，ModelSim `Errors: 0, Warnings: 0`。

串口设置属于题目选做功能，当前工程未实现。

## 目录结构

- `rtl/edge_pulse.v`：同步按键信号，并在上升沿产生一个时钟周期的脉冲。
- `rtl/mod4_counter.v`：2 位循环计数器，用于波形、幅值、频率三类选择。
- `rtl/any_wave_refactored.v`：顶层控制器，负责 ROM 地址、波形选择、频率步进和幅值缩放。
- `sim/any_wave_refactored_tb.v`：ModelSim 测试平台。
- `sim/run_refactored.do`：已保留的仿真脚本，手动复刻教程不依赖它。
- `quartus/any_wave_refactored.sdc`：50 MHz 时钟约束文件。
- `MANUAL_REBUILD.md`：从环境配置开始的手动复刻教程。
- `ASSIGNMENT_CHECK.md`：大作业要求验收对照。

## 推荐阅读顺序

1. 先看 `ASSIGNMENT_CHECK.md`，确认工程和大作业要求的对应关系。
2. 再看 `MANUAL_REBUILD.md`，按环境配置、建工程、生成 ROM、写 RTL、仿真的顺序手动复刻。
