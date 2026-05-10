module mod4_counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [1:0] value
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        value <= 2'd0;
    end else if (en) begin
        value <= value + 2'd1;
    end
end

endmodule
