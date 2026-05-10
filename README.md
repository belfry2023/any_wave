# 可变参数波形发生器

这是一个基于 Quartus Prime 17.1 Lite 和 ModelSim-Intel FPGA Starter Edition 的可变参数波形发生器工程。原工程代码位于 `srv/`，波形 ROM IP 位于 `ip_config/`，ModelSim 测试平台位于 `simulation/modelsim/`。

## 1. 工程功能

工程实现一路 8 位波形输出 `dout[7:0]`：

- `key1`：切换波形类型，顺序为正弦波、方波、锯齿波、三角波。
- `key2`：切换幅值档位，通过右移波形采样值实现。
- `key3`：切换频率档位，通过改变 ROM 地址累加步进实现。
- `rst_n`：低电平复位。
- `clk`：系统时钟。

当前原代码在 ModelSim 下已经验证可运行：

```text
Errors: 0, Warnings: 0
```

注意：原代码的频率档位是 `0/1/2/3`。当 `key3` 对应计数值为 `0` 时，地址不累加，输出会停在一个采样点；如果严格要求 4 个有效频率档，建议参考 `refactored/` 中的重构版本。

## 2. 目录说明

```text
any_wave/
  srv/
    any_wave.v           原工程顶层
    count.v              4 档循环计数器
    key_negedge.v        按键边沿检测
    ax_debounce.v        消抖模块，原顶层中未启用
  ip_config/
    sin.v                正弦波 ROM IP
    square.v             方波 ROM IP
    sawtooth.v           锯齿波 ROM IP
    triangular.v         三角波 ROM IP
  mif/
    *.mif                ROM 初始化数据
  simulation/modelsim/
    any_wave.vt          原工程 testbench
    run_local.do         本机可直接运行的 ModelSim 仿真脚本
  refactored/
    ...                  按大作业要求整理后的教学重构版
```

## 3. 最容易复现的仿真方案

推荐直接使用已经整理好的本地脚本 `simulation/modelsim/run_local.do`。

在 PowerShell 中进入工程根目录：

```powershell
cd C:\Users\belfry\github\any_wave
```

启动图形版 ModelSim，并运行到脚本设定的 `2000000 ps`：

```powershell
C:\Users\belfry\intelFPGA_lite\17.1\modelsim_ase\win32aloem\vsim.exe -do "do simulation/modelsim/run_local.do"
```

如果希望仿真持续运行，让 `key1`、`key2`、`key3` 不断变化：

```powershell
C:\Users\belfry\intelFPGA_lite\17.1\modelsim_ase\win32aloem\vsim.exe -do "do simulation/modelsim/run_local.do; run -all"
```

如果只想在命令行检查能否跑通：

```powershell
C:\Users\belfry\intelFPGA_lite\17.1\modelsim_ase\win32aloem\vsim.exe -c -do "do simulation/modelsim/run_local.do; quit -f"
```

预期末尾结果：

```text
Errors: 0, Warnings: 0
```

## 4. Testbench 如何让按键变化

原工程测试平台是 `simulation/modelsim/any_wave.vt`。其中关键激励如下：

```verilog
initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    key1 = 1'b0;
    key2 = 1'b0;
    key3 = 1'b0;
    #100 rst_n = 1'b1;
    $display("Running testbench");
end

always #10 clk = ~clk;
always #400000 key1 = ~key1;
always #200000 key2 = ~key2;
always #100000 key3 = ~key3;
```

含义：

- `clk` 每 `10 ps` 翻转一次，所以时钟周期是 `20 ps`。
- `rst_n` 在 `100 ps` 后释放复位。
- `key1` 每 `400000 ps` 翻转一次，用于切换波形。
- `key2` 每 `200000 ps` 翻转一次，用于切换幅值。
- `key3` 每 `100000 ps` 翻转一次，用于切换频率。

因为原工程的 `key_negedge.v` 实际检测的是上升沿，所以 key 从 `0` 变为 `1` 时会触发一次计数。

## 5. do 文件是什么

ModelSim 的 `.do` 文件可以理解为一串自动执行的 Tcl 命令。手动仿真时，你需要做的事情包括：

1. 建立仿真库。
2. 映射仿真库名称。
3. 编译 Quartus/Intel 提供的器件库。
4. 编译工程里的 ROM IP、RTL、testbench。
5. 启动 testbench。
6. 把常用信号加入 Wave 窗口。
7. 运行一段时间。

`run_local.do` 就是把这些步骤写成脚本，避免每次手点。

## 6. do 文件编写步骤

### 6.1 打开 transcript

```tcl
transcript on
```

作用：打开 ModelSim 日志输出，方便查看编译和仿真报错。

### 6.2 设置工具链和工程路径

```tcl
set QUARTUS_ROOT "C:/Users/belfry/intelFPGA_lite/17.1/quartus"
set PROJECT_ROOT "C:/Users/belfry/github/any_wave"
```

注意：ModelSim 的 Tcl 脚本里建议用 `/`，不要用 Windows 的 `\`，这样路径转义问题最少。

如果换电脑，只需要改这两行：

- `QUARTUS_ROOT`：Quartus 安装目录。
- `PROJECT_ROOT`：本工程目录。

### 6.3 编译 Intel 仿真库

原工程 ROM IP 使用了 `altsyncram`，所以至少要编译 `altera_mf.v`。为了兼容 Quartus 自动生成脚本，这里也编译了常见器件库：

```tcl
vlib verilog_libs/altera_mf_ver
vmap altera_mf_ver ./verilog_libs/altera_mf_ver
vlog -vlog01compat -work altera_mf_ver "$QUARTUS_ROOT/eda/sim_lib/altera_mf.v"
```

命令含义：

- `vlib`：创建一个仿真库目录。
- `vmap`：把逻辑库名映射到目录。
- `vlog`：编译 Verilog/SystemVerilog 文件。
- `-work altera_mf_ver`：把编译结果放入 `altera_mf_ver` 库。

### 6.4 建立工程工作库

```tcl
if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work
```

这一步会删除旧的 `rtl_work`，重新创建干净工作库，避免旧编译结果影响新仿真。

### 6.5 编译原工程代码

按依赖顺序编译：

```tcl
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/srv "$PROJECT_ROOT/srv/key_negedge.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/ip_config "$PROJECT_ROOT/ip_config/sin.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/ip_config "$PROJECT_ROOT/ip_config/square.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/ip_config "$PROJECT_ROOT/ip_config/triangular.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/ip_config "$PROJECT_ROOT/ip_config/sawtooth.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/srv "$PROJECT_ROOT/srv/any_wave.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/srv "$PROJECT_ROOT/srv/count.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/srv "$PROJECT_ROOT/srv/ax_debounce.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/simulation/modelsim "$PROJECT_ROOT/simulation/modelsim/any_wave.vt"
```

`+incdir+...` 用于告诉编译器包含文件搜索路径。这个工程里没有复杂 include，但保留它可以减少 IP 或后续文件引用路径问题。

### 6.6 启动 testbench

```tcl
vsim -t 1ps \
    -L altera_ver \
    -L lpm_ver \
    -L sgate_ver \
    -L altera_mf_ver \
    -L altera_lnsim_ver \
    -L cycloneive_ver \
    -L rtl_work \
    -L work \
    -voptargs="+acc" \
    any_wave_vlg_tst
```

关键点：

- `-t 1ps`：仿真时间精度为 `1 ps`。
- `-L xxx`：告诉 ModelSim 去哪些库里找模块。
- `-voptargs="+acc"`：保留内部层级信号访问权限，方便 Wave 窗口观察 `count_key1`、`address` 等内部信号。
- `any_wave_vlg_tst`：testbench 顶层模块名。

### 6.7 添加 Wave 信号

```tcl
add wave -divider "testbench"
add wave sim:/any_wave_vlg_tst/clk
add wave sim:/any_wave_vlg_tst/rst_n
add wave sim:/any_wave_vlg_tst/key1
add wave sim:/any_wave_vlg_tst/key2
add wave sim:/any_wave_vlg_tst/key3
add wave -radix unsigned sim:/any_wave_vlg_tst/dout

add wave -divider "dut"
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/count_key1
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/count_key2
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/count_key3
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/address
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/sin_wave
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/square_wave
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/sawtooth_wave
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/triangular_wave
```

建议重点观察：

- `key1/key2/key3`：确认按键激励在变化。
- `count_key1`：波形选择档位。
- `count_key2`：幅值选择档位。
- `count_key3`：频率选择档位。
- `address`：ROM 地址是否递增。
- `dout`：最终输出数据。

### 6.8 运行仿真

运行固定时间：

```tcl
run 2000000 ps
wave zoom full
```

持续运行：

```tcl
run -all
```

如果使用 `run -all`，由于 testbench 中三个 key 都是 `always` 翻转，仿真会一直跑下去，直到你手动点击停止。

## 7. 完整 run_local.do

当前仓库已经提供完整脚本：

[simulation/modelsim/run_local.do](simulation/modelsim/run_local.do)

你也可以按下面的最小版本重新写一个新的 `.do` 文件：

```tcl
transcript on

set QUARTUS_ROOT "C:/Users/belfry/intelFPGA_lite/17.1/quartus"
set PROJECT_ROOT "C:/Users/belfry/github/any_wave"

vlib verilog_libs/altera_mf_ver
vmap altera_mf_ver ./verilog_libs/altera_mf_ver
vlog -vlog01compat -work altera_mf_ver "$QUARTUS_ROOT/eda/sim_lib/altera_mf.v"

if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work "$PROJECT_ROOT/srv/key_negedge.v"
vlog -vlog01compat -work work "$PROJECT_ROOT/srv/count.v"
vlog -vlog01compat -work work "$PROJECT_ROOT/srv/ax_debounce.v"
vlog -vlog01compat -work work "$PROJECT_ROOT/ip_config/sin.v"
vlog -vlog01compat -work work "$PROJECT_ROOT/ip_config/square.v"
vlog -vlog01compat -work work "$PROJECT_ROOT/ip_config/sawtooth.v"
vlog -vlog01compat -work work "$PROJECT_ROOT/ip_config/triangular.v"
vlog -vlog01compat -work work "$PROJECT_ROOT/srv/any_wave.v"
vlog -vlog01compat -work work "$PROJECT_ROOT/simulation/modelsim/any_wave.vt"

vsim -t 1ps -L altera_mf_ver -L work -voptargs="+acc" any_wave_vlg_tst

add wave sim:/any_wave_vlg_tst/clk
add wave sim:/any_wave_vlg_tst/rst_n
add wave sim:/any_wave_vlg_tst/key1
add wave sim:/any_wave_vlg_tst/key2
add wave sim:/any_wave_vlg_tst/key3
add wave -radix unsigned sim:/any_wave_vlg_tst/dout
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/count_key1
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/count_key2
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/count_key3
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/address

view wave
run 2000000 ps
wave zoom full
```

## 8. 常见问题

### 8.1 路径报错

现象：ModelSim 提示找不到文件。

处理：

- 确认从工程根目录运行命令。
- 检查 `run_local.do` 里的 `PROJECT_ROOT` 是否是 `C:/Users/belfry/github/any_wave`。
- Tcl 路径尽量用 `/`，不要用 `\`。

### 8.2 旧仿真窗口占用文件

现象：命令行里出现类似提示：

```text
Unable to unlink file "rtl_work/..."
WLF file currently in use: vsim.wlf
```

原因：之前打开的 ModelSim 图形仿真还在运行，正在占用 `rtl_work/` 或 `vsim.wlf`。

处理：

- 最稳妥：先关闭旧的 ModelSim 仿真窗口，再重新执行命令。
- 如果只是看波形，ModelSim 自动创建 `wlft...` 临时波形文件也能继续运行。
- 如果你正在持续 `run -all`，不要同时反复跑命令行仿真，否则日志会比较乱。

### 8.3 找不到 `altsyncram`

现象：ROM IP 加载时报 `altsyncram` 未定义。

处理：先编译 Quartus 自带的 `altera_mf.v`，并在 `vsim` 中加入 `-L altera_mf_ver`。

### 8.4 波形窗口看不到内部信号

现象：`count_key1`、`address` 这类内部信号无法 add wave。

处理：启动仿真时保留：

```tcl
-voptargs="+acc"
```

### 8.5 仿真一直不停

如果执行了：

```tcl
run -all
```

因为 testbench 里有三个无限翻转的 `always` 块，仿真会一直运行。需要停止时，在 ModelSim 中点击停止按钮，或在 transcript 输入：

```tcl
stop
```

### 8.6 `key3` 第 0 档时输出不动

这是原代码本身的逻辑：

```verilog
address <= address + count_key3;
```

当 `count_key3 == 0` 时，地址不累加，输出保持在当前采样点。这不影响原代码仿真跑通，但如果按课程要求解释“4 个有效频率档”，建议使用 `refactored/` 里的修正版逻辑。

## 9. 推荐检查顺序

仿真打开后，按这个顺序看：

1. `rst_n` 是否在 `100 ps` 后拉高。
2. `key1/key2/key3` 是否周期翻转。
3. `count_key1/count_key2/count_key3` 是否在 `0/1/2/3` 间循环。
4. `address` 是否随 `count_key3` 增大而更快累加。
5. `dout` 是否随波形、幅值、频率选择发生变化。

能看到这些现象，就说明老代码在仿真层面功能正常。
