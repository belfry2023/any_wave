library verilog;
use verilog.vl_types.all;
entity any_wave is
    port(
        clk             : in     vl_logic;
        key1            : in     vl_logic;
        key2            : in     vl_logic;
        key3            : in     vl_logic;
        dout            : out    vl_logic_vector(7 downto 0)
    );
end any_wave;
