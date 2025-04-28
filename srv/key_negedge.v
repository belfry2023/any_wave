module key_negedge(
    clk,key,rst_n,q
);

input clk;
input key;
input rst_n;
output reg q;
reg def1;
reg def2;
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        def1 <= 1'b0;
        def2 <= 1'b0;
    end
    else
    begin
        def2 <= def1;
        def1 <= key;
        if(def1)
            if(!def2)
                q <= 1'b1;
            else
            q <= 1'b0;
        else
            q <= 1'b0;
    end
end

endmodule