`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/03/2025 04:46:50 PM
// Design Name: 
// Module Name: tb_core_block
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

`define     IW  5
`define     IH  5
//
`define     FW  3
`define     FH  3
//
`define     C  1
`define     S  1
`define     PAD  0
//
`define     ORIG_OW (`FW + `S*(`IW-1))            // 3 + 63 = 66
`define     ORIG_OH (`FH + `S*(`IH-1))
//
`define     PADDED_OW (`FW + `S*(`IW-1) - 2*`PAD) // 3 + 2*63 - 2 = 127
`define     PADDED_OH (`FH + `S*(`IH-1) - 2*`PAD)
//
`define     SIGNED_BITS 9
`define     BITS 8
`define     MULT_BITS 16
//
`define     IDX_BITS  10

`define     IFMAP_PATH "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref/test3_ver2/ifmap.txt"
`define     KERNEL_PATH "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref/test3_ver2/kernel.txt"
`define     OFMAP_PATH "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref/test3_ver2/ofmap.txt"
`define     PADDED_OFMAP_PATH "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref/test3_ver2/padded_ofmap.txt"

`default_nettype none

module tb_core_block;
    
    reg clk, reset_n, enable, core_run;
    reg [`SIGNED_BITS : 0] ifmap_value;
    reg [`BITS * `FW -1 : 0] weight_vec;
    
    wire    o_valid;
    wire    [`FW * `MULT_BITS -1 : 0]  intermediate_vec;
    
    core_block#
    (
        .FW     (`FW),
        .FH     (`FH),
        //
        .BITS       (`BITS),
        .SIGNED_BITS(`SIGNED_BITS),
        .MULT_BITS  (`MULT_BITS)
    ) u0_core_block
    (
        .clk            (clk),
        .reset_n        (reset_n),
        //
        .enable         (enable),
        .core_run       (core_run),
        //
        .ifmap_value    (ifmap_value),
        .weight_vec     (weight_vec),
        //
        .o_valid        (o_valid),
        .intermediate_vec   (intermediate_vec)
    );

    initial clk = 0;
    always #5 clk = ~clk;
    
    initial begin
        reset_n = 0;
        core_run = 0;
        enable   = 0;
        #20 reset_n = 1;
        #30 enable = 1;
        #10 enable = 0;
        #25 core_run = 1;
        #10 core_run = 0; 
    end
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            ifmap_value <= 0;
            weight_vec <= 0;
        end
        
        else begin
            ifmap_value <= ifmap[`SIGNED_BITS :0];
            weight_vec <= kernel[`BITS * `FW -1 :0];
        end
    end    
    
    // -*-*-*-*-*-*-* FILE READ AND WRITE -*-*-*-*-*-*-*
    integer ifmap_fd;
    integer kernel_fd;
    integer ofmap_fd;
    integer padded_ofmap_fd;
    //
    integer r1,r2;
    //
    reg [`IW * `IH * `SIGNED_BITS -1 : 0] ifmap;
    reg [`FH * `FH * `BITS - 1 : 0] kernel;
    
    
    // -*-*-*-*-*-*-* IFMAP AND KERNEL READ -*-*-*-*-*-*-*
    initial begin
        ifmap_fd = $fopen(`IFMAP_PATH, "r"); // ?? ??
        if (ifmap_fd == 0) begin
            $display("FAIL");
            $finish;
        end
        
        for(integer q=0; q<`IH*`IW; q=q+1) begin
            r1 = $fscanf(ifmap_fd, "%d\n", ifmap[`SIGNED_BITS * q +: `SIGNED_BITS]);
            $display("READ_IFMAP: %d", ifmap[`SIGNED_BITS * q +: `SIGNED_BITS]);
        end
        #10;
        $fclose(ifmap_fd); // ?? ??
    end

    initial begin
        kernel_fd = $fopen(`KERNEL_PATH, "r"); // ?? ??
        if (kernel_fd == 0) begin
            $display("FAIL");
            $finish;
        end

        for(integer q=0; q<`FH*`FW; q=q+1) begin
            r2 = $fscanf(kernel_fd, "%d\n", kernel[`BITS * q +: `BITS]);
            $display("READ_KERNEL: %d", kernel[`BITS * q +: `BITS]);
        end

        $fclose(kernel_fd); // ?? ??
    end
endmodule
