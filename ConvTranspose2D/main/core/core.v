`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2025 12:42:44 PM
// Design Name: 
// Module Name: core
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


module core#
(
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
    input   signed [SIGNED_BITS - 1 : 0] weight,
    //
    output  reg o_valid,
    output  reg signed [MULT_BITS - 1 :0] mult
);
    
    // -*-*-*-*-*-*-* Enable Signal Capture -*-*-*-*-*-*-*
    // To make o_valid signal by calculating ifmap and kernel at only captured_enable == 1
    // If not use cpatured_enable signal, the o_valid signal is raised in every positive edge
    // Because the ifmap and kernel is calculated in every positive edge
    // i.g., else ifmap_value * wegt
//    reg captured_enable;
//    //
//    always @(posedge clk or negedge reset_n) begin
//        if(!reset_n) captured_enable <= 1'b0;
//        else if(o_calc) captured_enable <= enable;
//        else captured_enable <= 1'b0;
//    end
    
    //
    
    reg signed [BITS - 1 : 0] wegt;
    //
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            mult <= {MULT_BITS{1'b0}};
            wegt <= {BITS{1'b0}};
            o_valid <= 1'b0;
        end
        
        else if(enable) wegt <= weight;
        
        else begin
            if(core_run) begin
                mult <= ifmap_value * wegt;
                o_valid <= 1'b1;
            end
            
            else begin
                mult <= {MULT_BITS{1'b0}};
                o_valid <= 1'b0;
            end
        end
    end
endmodule
