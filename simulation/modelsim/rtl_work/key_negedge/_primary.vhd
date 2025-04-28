library verilog;
use verilog.vl_types.all;
entity key_negedge is
    port(
        clk             : in     vl_logic;
        key             : in     vl_logic;
        rst_n           : in     vl_logic;
        q               : out    vl_logic
    );
end key_negedge;
