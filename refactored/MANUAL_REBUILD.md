# 可变参数波形发生器手动复刻教程

本文档用于按课程大作业要求手动复刻当前工程。流程从环境配置开始，全部步骤使用 Quartus 和 ModelSim 的图形界面或手动命令完成，不依赖一键生成工程脚本。

## 1. 验收结论

当前工程已经满足大作业必做要求：

- 可输出 4 种波形：正弦波、方波、锯齿波、三角波。
- 可通过按键设置波形类型、幅值、频率。
- 参数类型至少 2 个：已实现幅值和频率。
- 每个参数至少 4 个取值：幅值 4 档，频率 4 档。
- 串口配置是选做项，当前工程未实现，可在报告中写为后续扩展。

已验证结果：

- Quartus 编译：`0 errors, 8 warnings`
- ModelSim 仿真：`Errors: 0, Warnings: 0`

## 2. 环境配置

建议使用与当前工程一致的工具链：

- Quartus Prime Lite Edition 17.1
- ModelSim-Intel FPGA Starter Edition 10.5b
- Windows 系统

安装时注意：

- 先安装 Quartus Prime Lite，再安装随包的 ModelSim-Intel FPGA Starter Edition。
- 不要同时运行多个安装器，避免 ModelSim 文件复制不完整。
- ModelSim 选择 Intel FPGA Starter Edition，不要误装成需要许可证的版本。
- 安装完成后确认以下程序存在：
  - `C:\Users\belfry\intelFPGA_lite\17.1\quartus\bin64\quartus.exe`
  - `C:\Users\belfry\intelFPGA_lite\17.1\modelsim_ase\win32aloem\vsim.exe`

## 3. 工程目标

系统输入输出如下：

| 信号 | 方向 | 说明 |
| --- | --- | --- |
| `clk` | 输入 | 50 MHz 系统时钟 |
| `rst_n` | 输入 | 低电平复位 |
| `key1` | 输入 | 切换波形：正弦、方波、锯齿、三角 |
| `key2` | 输入 | 切换幅值：右移 0、1、2、3 位 |
| `key3` | 输入 | 切换频率：地址步进 1、2、3、4 |
| `dout[7:0]` | 输出 | 当前波形采样值 |

系统框架：

```text
按键输入 -> 边沿检测 -> 4 档计数器 -> 波形/幅值/频率选择
                                      |
                                      v
                  ROM 地址累加 -> 四个波形 ROM -> 波形选择 -> 幅值缩放 -> dout
```

## 4. 准备目录和文件

手动复刻时建议新建一个干净目录，例如：

```text
any_wave_manual/
  rtl/
  ip_config/
  mif/
  sim/
```

需要准备的资源：

- `mif/sin_wave.mif`
- `mif/square_wave.mif`
- `mif/sawtooth_wave.mif`
- `mif/triangular_wave.mif`
- `rtl/edge_pulse.v`
- `rtl/mod4_counter.v`
- `rtl/any_wave_refactored.v`
- `sim/any_wave_refactored_tb.v`

当前仓库中已经有这些文件，可以手动复制到你的复刻目录。不要复制 `db/`、`incremental_db/`、`output_files/`、`work/`、`work_libs/` 这类编译或仿真生成目录。

## 5. 手写 RTL 模块

### 5.1 按键边沿检测

文件：`rtl/edge_pulse.v`

作用：把按键信号同步到 `clk` 时钟域，并在上升沿到来时产生一个时钟周期的脉冲。

```verilog
module edge_pulse (
    input  wire clk,
    input  wire rst_n,
    input  wire signal_in,
    output reg  rise_pulse
);

reg signal_d1;
reg signal_d2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        signal_d1  <= 1'b0;
        signal_d2  <= 1'b0;
        rise_pulse <= 1'b0;
    end else begin
        signal_d1  <= signal_in;
        signal_d2  <= signal_d1;
        rise_pulse <= signal_d1 & ~signal_d2;
    end
end

endmodule
```

### 5.2 四档循环计数器

文件：`rtl/mod4_counter.v`

作用：每收到一次按键脉冲，就在 0、1、2、3 四个状态之间循环。

```verilog
module mod4_counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [1:0] value
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        value <= 2'd0;
    else if (en)
        value <= value + 2'd1;
end

endmodule
```

### 5.3 顶层波形发生器

文件：`rtl/any_wave_refactored.v`

顶层完成以下功能：

- 例化 3 个 `edge_pulse`，分别处理 `key1`、`key2`、`key3`。
- 例化 3 个 `mod4_counter`，分别产生 `wave_sel`、`amp_sel`、`freq_sel`。
- 例化 4 个 ROM IP，读取正弦、方波、锯齿、三角采样值。
- 用 `wave_sel` 选择当前波形。
- 用 `amp_sel` 右移采样值，实现 4 档幅值。
- 用 `freq_step = freq_sel + 1` 控制地址步进，实现 1、2、3、4 四个有效频率档。

关键逻辑如下：

```verilog
assign freq_step = {1'b0, freq_sel} + 3'd1;
assign dout = selected_wave >> amp_sel;
```

这里必须让频率步进从 1 开始。如果直接用 `freq_sel` 作为地址步进，第 0 档会让地址停住，输出变成静态值，不适合作为有效频率档。

## 6. 手动创建 Quartus 工程

打开 Quartus Prime，按以下步骤创建工程：

1. 选择 `File > New Project Wizard`。
2. Project directory 选择你的手动复刻目录。
3. Project name 填 `any_wave_refactored`。
4. Top-level entity 填 `any_wave_refactored`。
5. 暂时跳过添加文件，后面手动加入。
6. Device family 选择 `Cyclone IV E`。
7. Device 选择 `EP4CE6F17C8`。
8. EDA Tool Settings 中仿真工具选择 ModelSim-Intel FPGA Verilog HDL。
9. 完成工程创建。

创建完成后，手动添加 RTL 文件：

1. 打开 `Project > Add/Remove Files in Project`。
2. 添加：
   - `rtl/edge_pulse.v`
   - `rtl/mod4_counter.v`
   - `rtl/any_wave_refactored.v`

## 7. 手动生成 4 个 ROM IP

每种波形使用一个 `256 x 8` 的单端口 ROM。四个 ROM 名称必须和顶层例化一致：

- `sin`
- `square`
- `sawtooth`
- `triangular`

在 Quartus 中逐个生成：

1. 打开 `Tools > IP Catalog`。
2. 进入 `Library > Basic Functions > On Chip Memory`。
3. 选择 `ROM: 1-PORT`。
4. 生成文件位置选择 `ip_config/`。
5. IP 名称分别填写 `sin`、`square`、`sawtooth`、`triangular`。
6. 参数设置：
   - Data width：`8`
   - Number of words：`256`
   - Address width：`8`
   - Read enable：启用
   - Output register：启用
   - Memory initialization file：选择对应 `.mif`
7. 每生成一个 ROM，就把对应 `.qip` 加入 Quartus 工程。

对应关系：

| ROM 名称 | 初始化文件 |
| --- | --- |
| `sin` | `mif/sin_wave.mif` |
| `square` | `mif/square_wave.mif` |
| `sawtooth` | `mif/sawtooth_wave.mif` |
| `triangular` | `mif/triangular_wave.mif` |

常见坑：ROM 生成文件里的 `init_file` 路径可能是相对路径。若编译或仿真提示找不到 `.mif`，把四个 `.mif` 复制到 Quartus 工程根目录，或重新在 IP 参数中选择正确路径。

## 8. 管脚和时序约束

打开 `Assignments > Pin Planner`，按原工程分配按键和时钟管脚：

| 信号 | 管脚 |
| --- | --- |
| `clk` | `PIN_E1` |
| `rst_n` | `PIN_N15` |
| `key1` | `PIN_M16` |
| `key2` | `PIN_M15` |
| `key3` | `PIN_E16` |

`dout[7:0]` 如果接 DAC、排针或实验板扩展口，需要按你的硬件原理图继续分配。若只做仿真，`dout` 可以不分配实体管脚。

设置默认 I/O 标准：

1. 打开 `Assignments > Device`。
2. 点击 `Device and Pin Options`。
3. 在未单独指定的 I/O 标准中选择 `3.3-V LVTTL`。

添加时序约束文件：

1. 新建文件 `any_wave_refactored.sdc`。
2. 写入：

```tcl
create_clock -name clk -period 20.000 [get_ports clk]
derive_clock_uncertainty
```

3. 在 `Project > Add/Remove Files in Project` 中加入该 `.sdc` 文件。

## 9. 编译检查

点击 Quartus 左侧 `Compile Design`。

预期结果：

- Analysis & Synthesis：`0 errors`
- Full Compilation：`0 errors`
- TimeQuest 中能看到 20 ns 的 `clk` 约束

当前已验证工程的完整编译结果是：

```text
Quartus Prime Full Compilation was successful. 0 errors, 8 warnings
```

这些 warning 主要来自管脚未完整分配、并行编译线程、板级 I/O 提醒等，不是 RTL 功能错误。

## 10. 手动建立 ModelSim 仿真

不使用一键仿真脚本时，可以在 ModelSim 中按下面做：

1. 打开 ModelSim-Intel FPGA Starter Edition。
2. 选择 `File > Change Directory`，切到工程根目录。
3. 选择 `File > New > Project`，新建仿真工程。
4. 添加并编译这些文件：
   - Quartus 安装目录下的 `eda/sim_lib/altera_mf.v`
   - `ip_config/sin.v`
   - `ip_config/square.v`
   - `ip_config/sawtooth.v`
   - `ip_config/triangular.v`
   - `rtl/edge_pulse.v`
   - `rtl/mod4_counter.v`
   - `rtl/any_wave_refactored.v`
   - `sim/any_wave_refactored_tb.v`
5. 启动仿真顶层 `any_wave_refactored_tb`。
6. 把以下信号加入 Wave 窗口：
   - `clk`
   - `rst_n`
   - `key1`
   - `key2`
   - `key3`
   - `dout`
   - `dut/wave_sel`
   - `dut/amp_sel`
   - `dut/freq_sel`
   - `dut/freq_step`
   - `dut/address`
7. 运行 `2000000 ps`。

预期观察结果：

- `wave_sel` 在 0、1、2、3 间变化，对应 4 种波形。
- `amp_sel` 在 0、1、2、3 间变化，`dout` 幅值逐档缩小。
- `freq_sel` 在 0、1、2、3 间变化，同时 `freq_step` 为 1、2、3、4。
- `address` 的累加速度随 `freq_step` 增大而加快。

当前已验证工程的仿真结果是：

```text
Errors: 0, Warnings: 0
```

## 11. 报告写作对应关系

课程报告中可以按下面组织：

| 报告要求 | 可写内容 |
| --- | --- |
| 总体设计思路 | 按键控制、4 档计数器、ROM 查表、波形选择、幅值缩放、地址步进调频 |
| 主要组成模块 | `edge_pulse`、`mod4_counter`、`any_wave_refactored`、4 个 ROM IP |
| 模块间时序关系 | 按键边沿脉冲更新选择状态，地址按频率步进累加，ROM 输出采样，组合逻辑选择并缩放 |
| 测试验证结果 | Quartus `0 errors`，ModelSim `Errors: 0, Warnings: 0`，观察 4 种波形和 4 档参数变化 |
| 问题及解决方法 | 原频率第 0 档地址不变，改为 `freq_step = freq_sel + 1` |
| 源程序 | 放 RTL 顶层、边沿检测、4 档计数器和 ROM IP 说明 |
| 心得体会 | 可写 ROM 查表法实现波形发生器简单稳定，按键状态机适合做参数切换 |

## 12. 常见问题

- 找不到 ROM 初始化文件：检查 `.mif` 路径，必要时把 `.mif` 放到 Quartus 工程根目录。
- Quartus 推断 latch：检查组合 `case` 是否有 `default`，组合块是否覆盖所有赋值。
- TimeQuest 按错误时钟分析：检查 `.sdc` 是否加入工程，`clk` 周期是否写成 `20.000` ns。
- ModelSim 找不到 `altsyncram`：需要先编译 Quartus 的 `altera_mf.v`。
- ModelSim 波形是静态值：确认 `freq_step` 是 1、2、3、4，而不是直接用 0、1、2、3 做地址步进。
