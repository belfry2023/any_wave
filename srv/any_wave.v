module any_wave(
	clk,key1,key2,key3,rst_n,dout
);

input clk;
input key1;
input key2;
input key3;
input rst_n;
output [7:0] dout;

reg rden;
reg [7:0] address;

wire [7:0] sin_wave;
wire [7:0] square_wave;
wire [7:0] sawtooth_wave;
wire [7:0] triangular_wave;

wire [3:0] count_key1;
wire botton1_negedge;
wire t1;
count count_m1(
	.clk		(clk),
	.rst_n		(rst_n),
	.en			(button1_negedge),
	.clr		(1'b0),
	.data		(count_key1),
	.t			(t1)
);

ax_debounce ax_debounce_m1(
    .clk             (clk),
    .rst             (~rst_n),
    .button_in       (key1),
    .button_posedge  (),
    .button_negedge  (button1_negedge),
    .button_out      ()
);

wire [3:0] count_key2;
wire botton2_negedge;
wire t2;
count count_m2(
	.clk		(clk),
	.rst_n		(rst_n),
	.en			(button2_negedge),
	.clr		(1'b0),
	.data		(count_key2),
	.t			(t2)
);

ax_debounce ax_debounce_m2(
	.clk					(clk),
	.rst					(~rst_n),
	.button_in				(key2),
	.button_posedge			(),
	.button_negedge			(button2_negedge),
	.button_out				()
);

wire [3:0] count_key3;
wire botton3_negedge;
wire t3;
count count_m3(
	.clk		(clk),
	.rst_n		(rst_n),
	.en			(button3_negedge),
	.clr		(1'b0),
	.data		(count_key3),
	.t			(t3)
);

ax_debounce ax_debounce_m3(
	.clk					(clk),
	.rst					(~rst_n),
	.button_in				(key3),
	.button_posedge			(),
	.button_negedge			(button3_negedge),
	.button_out				()
);

sin Rom_sin(
	.clock		(clk), // input clka
	.address	(address), // input [7 : 0] addra
	.q			(sin_wave), // output [7 : 0] douta
	.rden		(rden)
);


square Rom_square(
	.clock		(clk), // input clka
	.address	(address), // input [7 : 0] addra
	.q			(square_wave), // output [7 : 0] douta
	.rden		(rden)
);

sawtooth Rom_sawtooth(
	.clock		(clk), // input clka
	.address	(address), // input [7 : 0] addra
	.q			(sawtooth_wave), // output [7 : 0] douta
	.rden		(rden)
);

triangular Rom_triangular(
	.clock		(clk), // input clka
	.address	(address), // input [7 : 0] addra
	.q			(triangular_wave), // output [7 : 0] douta
	.rden		(rden)
);

always @(negedge rst_n or posedge clk)
begin
	if(!rst_n)
		rden <= 0;
	else
		rden <= 1;
end

reg [7:0] dout_temp1;
always @(negedge rst_n or posedge clk)
begin
	case(count_key1)
		4'd0:dout_temp1 <= sin_wave;
		4'd1:dout_temp1 <= square_wave;
		4'd2:dout_temp1 <= sawtooth_wave;
		4'd3:dout_temp1 <= triangular_wave;
	endcase
end

reg [7:0] dout_temp2;
always @(negedge rst_n or posedge clk)
begin
	case(count_key2)
		4'd0:dout_temp2 <= sin_wave;
		4'd1:dout_temp2 <= square_wave;
		4'd2:dout_temp2 <= sawtooth_wave;
		4'd3:dout_temp2 <= triangular_wave;
	endcase
end

assign dout = dout_temp1 + dout_temp2;

always @(negedge rst_n or posedge clk)
begin
	if(!rst_n)
		address <= 0;
	else
		address <= address + 1;
end

endmodule
