`timescale 1 ps / 1 ps

module any_wave_refactored_tb;

reg clk;
reg rst_n;
reg key1;
reg key2;
reg key3;

wire [7:0] dout;

any_wave_refactored dut (
    .clk   (clk),
    .rst_n (rst_n),
    .key1  (key1),
    .key2  (key2),
    .key3  (key3),
    .dout  (dout)
);

initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
end

initial begin
    rst_n = 1'b0;
    key1  = 1'b0;
    key2  = 1'b0;
    key3  = 1'b0;

    #100 rst_n = 1'b1;

    forever begin
        #100000 key3 = ~key3;
        #100000 key2 = ~key2;
        #200000 key1 = ~key1;
    end
end

endmodule
