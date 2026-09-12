module core_block
(
    input   clk,
    input   reset_n,
    //
    input   signed  [IFMAP_BIT-1 : 0]   ifmap_value,
    input   signed  [WEIGHT_BIT * FW * FH -1 : 0]    weight_vector,
    //
    output  signed  [OFMAP_VALUE_BIT * FW * FH - 1 : 0]    ofmap_vector
);
    /*
    대충 어쩌고 저쩌고
    */

    genvar i;
    generate
        for(i = 0; i < FW * FH; i = i + 1) begin
            core u0_core
            (
                .clk(clk),
                .reset_n(reset_n),
                //
                .ifmap_value(ifmap_value),
                .weight(weight_vector[WEIGHT_BIT * i +: WEIGHT_BIT]),
                //
                .ofmap_value(ofmap_vector[OFMAP_VALUE_BIT * i +: OFMAP_VALUE_BIT])
            );
        end
    endgenerate
endmodule


