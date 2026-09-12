module a
(
    input enable,

    input ifmap,
    input weight

    output mult
);

    reg wegt;

    always @(posege clk or negedge reset_n) begin
        if(!reset_n) begin
            mult <= 0;
            wegt <= 0; end
        
        else if (enable)
            wegt <= weight;

        else mult <= ifmap * wegt;
    end

    
endmodule