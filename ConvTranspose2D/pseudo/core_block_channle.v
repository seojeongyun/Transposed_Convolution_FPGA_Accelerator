module core_block_channel
(
    input   clk,
    input   reset_n,
    //
    input   signed  [IFMAP_BIT * CHANNELS -1 : 0]   ifmap_vector_channel,
    input   signed  [WEIGHT_BIT * FW * FH  * CHANNELS -1 : 0]    weight_vector_channel,
    //
    output  signed  [OFMAP_VALUE_BIT * FW * FH * CHANNELS - 1 : 0]    ofmap_vector_channel
);
    /*
    대충 어쩌고 저쩌고
    */

    genvar i;
    generate
        for(i = 0; i < CHANNELS; i = i + 1) begin
            core u0_core
            (
                .clk(clk),
                .reset_n(reset_n),
                //
                .ifmap_value(ifmap_value),
                .weight(weight_vector[WEIGHT_BIT * FW * FH * i +: WEIGHT_BIT * FW * FH]),
                //
                .ofmap_value(ofmap_vector[OFMAP_VALUE_BIT * FW * FH * i +: OFMAP_VALUE_BIT * FW * FH])
            );
        end
    endgenerate
endmodule


