module core
(
    input                clk,
    input                reset_n,
    //
    input   signed [IFMAP_BIT:0] ifmap_value,
    input   signed [WEIGHT_BIT:0] weight,
    //
    output         [OFMAP_VALUE_BIT:0] ofmap_value
);

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) ofmap_value <= 16'h0;
        else         ofmap_value <= ifmap_value * weight;
    end
endmodule



