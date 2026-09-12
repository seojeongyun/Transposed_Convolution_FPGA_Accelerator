`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2025 02:00:15 PM
// Design Name: 
// Module Name: core_cluster
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


module core_cluster#
(
    parameter   FW = 3,
    parameter   FH = 3,
    //
    parameter   BITS     = 8,
    parameter   SIGNED_BITS = 9,
    parameter   MULT_BITS = 16
)
(
    input           clk,
    input           reset_n,
    //
    input           [FH -1 :0] enable,
    input           core_run,
    //
    input   signed [SIGNED_BITS -1 : 0] ifmap_value,
    input   signed [BITS * FW - 1 : 0] weight_vec,
    //
    output  [FH -1 : 0]     o_valid,
    output  signed [FW * FH * MULT_BITS -1 : 0]  intermediate
);
    
    
    // -*-*-*-*-*-*-* instantiation of core_block -*-*-*-*-*-*-*
    genvar i;
    generate
        for(i = 1; i <= FH; i = i + 1) begin
            core_block#
            (
                .FW         (FW),
                .FH         (FH),
                //
                .BITS       (BITS),
                .SIGNED_BITS(SIGNED_BITS),
                .MULT_BITS  (MULT_BITS)
            )
            u0_core_block
            (
                .clk                        (clk),
                .reset_n                    (reset_n),
                //
                .enable                     (enable[i-1]),
                .core_run                   (core_run),
                //
                .ifmap_value                (ifmap_value),
                .weight_vec                 (weight_vec),     // A weight in the kernel(0,0) fills the MSB of this vector.
                //
                .o_valid                    (o_valid[i-1]),
                .intermediate_vec           (intermediate[(FH - i) * FW * MULT_BITS +: FW * MULT_BITS])
            );
        end
    endgenerate
endmodule
