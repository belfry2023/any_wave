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
