`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2025 09:36:25 PM
// Design Name: 
// Module Name: dpbram
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


module dpbram#
(
    parameter AWIDTH = 12,
    parameter DWIDTH = 16,
    parameter MEM_DEPTH = 3840
)
(
    input           clk,
    //
    input           [AWIDTH -1 : 0] addr0,
    input           [DWIDTH -1 : 0] d0,
    input           ce0,
    input           we0,
    //
    input           [AWIDTH -1 : 0] addr1,
    input           [DWIDTH -1 : 0] d1,
    input           ce1,
    input           we1,
    //
    output    reg   [DWIDTH -1 : 0] q0,
    output    reg   [DWIDTH -1 : 0] q1,
    //
    output    reg   d0_valid,
    output    reg   d1_valid,
    //
    output    reg   q0_valid,
    output    reg   q1_valid
);
    //
    (* ram_style = "block" *)reg [DWIDTH-1:0] ram[0:MEM_DEPTH-1];
    
    
    integer ram_index;
    
    generate
        initial 
            for(ram_index = 0; ram_index < MEM_DEPTH; ram_index = ram_index + 1)
                ram[ram_index] = {DWIDTH{1'b0}};
    endgenerate
    
    
    // Normal Operation
    always @(posedge clk)  
    begin 
        if (ce0) begin
            if (we0) begin
                ram[addr0] <= d0;
            end
            
            else begin
                q0 <= ram[addr0];
            end
        end
    end
    
endmodule
