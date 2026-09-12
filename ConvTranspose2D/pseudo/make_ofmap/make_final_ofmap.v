`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2025 11:47:21 AM
// Design Name: 
// Module Name: make_ofmap
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module make_ofmap
#(
    parameter   FW = 3,
    parameter   FH = 3,
    //
    parameter   IW = 2,
    parameter   IH = 2,
    //
    parameter   S = 1,
    parameter   PAD = 0,
    parameter   C = 1,
    //
    parameter OW = FW + S*(IW-1) - 2*PAD,
    parameter OH = FH + S*(IH-1) - 2*PAD
)
(
    input       clk,
    input       reset_n,
    //
    input   [2:0] o_valid,
    input [FH*8-1:0] ofmap_vec_an_ifmap_value0,
    input [FH*8-1:0] ofmap_vec_an_ifmap_value1,
    input [FH*8-1:0] ofmap_vec_an_ifmap_value2
    //
    // input  [FH*8-1:0] ofmap_vec_an_ifmap_value [FW-1:0],
    //
//    output reg [OH - 1 : 0] final_ofmap [OW - 1 : 0]
);

    integer y;
    integer i, j, k;
    
    reg [OW*8 - 1 : 0] final_ofmap [OH - 1 : 0];
    reg [FH*8-1:0] ofmap_vec_an_ifmap_value [0:2];  // FW = 3? ??

    always @(*) begin
        ofmap_vec_an_ifmap_value[0] = ofmap_vec_an_ifmap_value0;
        ofmap_vec_an_ifmap_value[1] = ofmap_vec_an_ifmap_value1;
        ofmap_vec_an_ifmap_value[2] = ofmap_vec_an_ifmap_value2;
    end
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            for(y = 0; y < OH; y = y + 1)
                final_ofmap[y] <= 0;
        end
        else if(&o_valid) begin
//            for(i=0; i<C; i=i+1) begin
                for(j=0; j<IW; j=j+1) begin
                    for(k=0; k<IH; k=k+1) begin
                        final_ofmap[k+S*j][((OW)-(S*j))*8-1 -: FW*8] <= final_ofmap[k+S*j][((OW)-(S*j))*8-1 -: FW*8] + ofmap_vec_an_ifmap_value[k];
                    end
                end
            end
//        end
    end
endmodule


`define   FW  3
`define   FH  3
//
`define   IW  2
`define   IH  2
//
`define   S  1
`define   C  1
`define   PAD  3
//
`define OW (FW + S*(IW-1) - 2*PAD)
`define OH (FH + S*(IH-1) - 2*PAD)

module tb_make_ofmap;
    reg clk, reset_n;
    reg [2:0] o_valid;
    reg [`FH*8-1:0] ofmap_vec_an_ifmap_value [`FW-1:0]
    //
    wire [`OH - 1 : 0] final_ofmap [`OW - 1 : 0];

    make_ofmap u0_make_ofmap
    #(
        parameter   FW  (`FW),
        parameter   FH  (`FH),
        //
        parameter   IW  (`IW),
        parameter   IH  (`IH),
        //
        parameter   S   (`S),
        parameter   PAD (`PAD),
        parameter   C   (`C),
        //
        parameter OW (`FW + `S*(`IW-1) - 2*`PAD),
        parameter OH (`FH + `S*(`IH-1) - 2*`PAD),
    )
    (
        .clk        (clk),
        .reset_n    (reset_n),
        //
        .o_valid    (o_valid),
        .ofmap_vec_an_ifmap_value   (ofmap_vec_an_ifmap_value),
        //
        .final_ofmap    (final_ofmap)
    );

    initial clk = 0, reset_n = 1;
    always #5 clk = ~clk;

    initial begin
        #10     reset_n = 0;
        #200    o_valid = 3'b111;
    end

    integer i,j,k;

    initial begin
        #230
        for(j=0; j<`IH; j=j+1) begin
            for(k=0; k<`IW; k=k+1) begin
                ofmap_vec_an_ifmap_value[j][8*k +: 8] = k + `IH*j;
                $display("ofmap_vec: (%0d, %0d) --> %d", j,k,ofmap_vec_an_ifmap_value[j][k]);
            end
        end
    end
endmodule