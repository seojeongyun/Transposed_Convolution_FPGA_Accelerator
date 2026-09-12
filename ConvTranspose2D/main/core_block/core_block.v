`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2025 01:20:04 PM
// Design Name: 
// Module Name: core_block
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


module core_block#
(
    parameter   FW = 3,
    parameter   FH = 3,
    //
    parameter BITS     = 8,
    parameter SIGNED_BITS = 9,
    parameter MULT_BITS = 16
)
(
    input           clk,
    input           reset_n,
    //
    input           core_run,
    input           enable,
    //
    input   signed [SIGNED_BITS -1 : 0] ifmap_value,
    input   signed [BITS * FW - 1 : 0] weight_vec,     // A weight in the kernel(0,0) fills the MSB of this vector.
    //
    output          o_valid,
    output  signed [FW * MULT_BITS -1 : 0]  intermediate_vec
);
    wire [FW -1 : 0] o_valid_;
    
    genvar i;
    generate
        for(i = 1; i <= FW; i = i + 1) begin
        core#
        (
            .BITS               (BITS),
            .SIGNED_BITS        (SIGNED_BITS),
            .MULT_BITS          (MULT_BITS)
        )
        u0_core
        (
            .clk                (clk),
            .reset_n            (reset_n),
            //
            .core_run           (core_run),
            .enable             (enable),
            //
            .ifmap_value        (ifmap_value),
            .weight             (weight_vec[BITS * i -1 -: BITS]),
            // output
            .o_valid            (o_valid_[i-1]),      
            .mult               (intermediate_vec[(FW - i) * MULT_BITS +: MULT_BITS])
        );
        // A mult from core0(kernel(0,0) fills the MSB of intermediate_vec
    end
    endgenerate
    
    assign o_valid = &o_valid_;
endmodule