module any_wave_refactored (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       key1,
    input  wire       key2,
    input  wire       key3,
    output wire [7:0] dout
);

wire key1_pulse;
wire key2_pulse;
wire key3_pulse;

wire [1:0] wave_sel;
wire [1:0] amp_sel;
wire [1:0] freq_sel;
wire [2:0] freq_step;

reg  [7:0] address;
reg        rom_rden;
reg  [7:0] selected_wave;

wire [7:0] sin_data;
wire [7:0] square_data;
wire [7:0] sawtooth_data;
wire [7:0] triangular_data;

edge_pulse u_key1_edge (
    .clk        (clk),
    .rst_n      (rst_n),
    .signal_in  (key1),
    .rise_pulse (key1_pulse)
);

edge_pulse u_key2_edge (
    .clk        (clk),
    .rst_n      (rst_n),
    .signal_in  (key2),
    .rise_pulse (key2_pulse)
);

edge_pulse u_key3_edge (
    .clk        (clk),
    .rst_n      (rst_n),
    .signal_in  (key3),
    .rise_pulse (key3_pulse)
);

mod4_counter u_wave_counter (
    .clk   (clk),
    .rst_n (rst_n),
    .en    (key1_pulse),
    .value (wave_sel)
);

mod4_counter u_amp_counter (
    .clk   (clk),
    .rst_n (rst_n),
    .en    (key2_pulse),
    .value (amp_sel)
);

mod4_counter u_freq_counter (
    .clk   (clk),
    .rst_n (rst_n),
    .en    (key3_pulse),
    .value (freq_sel)
);

sin u_rom_sin (
    .address (address),
    .clock   (clk),
    .rden    (rom_rden),
    .q       (sin_data)
);

square u_rom_square (
    .address (address),
    .clock   (clk),
    .rden    (rom_rden),
    .q       (square_data)
);

sawtooth u_rom_sawtooth (
    .address (address),
    .clock   (clk),
    .rden    (rom_rden),
    .q       (sawtooth_data)
);

triangular u_rom_triangular (
    .address (address),
    .clock   (clk),
    .rden    (rom_rden),
    .q       (triangular_data)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rom_rden <= 1'b0;
    end else begin
        rom_rden <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        address <= 8'd0;
    end else begin
        address <= address + freq_step;
    end
end

always @(*) begin
    case (wave_sel)
        2'd0: selected_wave = sin_data;
        2'd1: selected_wave = square_data;
        2'd2: selected_wave = sawtooth_data;
        2'd3: selected_wave = triangular_data;
        default: selected_wave = sin_data;
    endcase
end

assign dout = selected_wave >> amp_sel;
assign freq_step = {1'b0, freq_sel} + 3'd1;

endmodule
