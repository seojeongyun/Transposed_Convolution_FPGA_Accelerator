`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/03/2025 05:13:21 PM
// Design Name: 
// Module Name: tb_core_cluster
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

module tb_core_cluster;
    
    reg clk, reset_n;
    reg o_wait;
    reg is_save_done;
    reg i_run;
    //
    reg [`SIGNED_BITS : 0] ifmap_value;
    reg [`BITS * `FW *`FH -1 : 0] weight_vec;
    
    wire    [`FH -1 : 0]o_valid;
    wire    [`FW * `FH * `MULT_BITS -1 : 0]  intermediate;    
    
    
    core_cluster#
    (
        .FW     (`FW),
        .FH     (`FH),
        //
        .BITS       (`BITS),
        .SIGNED_BITS(`SIGNED_BITS),
        .MULT_BITS  (`MULT_BITS)        
    )   u0_core_cluster
    (
        .clk            (clk),
        .reset_n        (reset_n),
        //
        .o_wait         (o_wait),
        .is_save_done   (is_save_done),
        //
        .ifmap_value    (ifmap_value),
        .weight_vec     (weight_vec),
        //
        .o_valid        (o_valid),
        .intermediate   (intermediate)      
    );

    initial clk = 0;
    always #5 clk = ~clk;
    
    initial begin
        i_run = 0;
        reset_n = 0;
        o_wait = 0;
        is_save_done = 0;
        #20 reset_n = 1;
        #10 i_run = 1;
        #10 i_run = 0;
        #20 o_wait = 1;
        #10 o_wait = 0;
        wait(&o_valid);
        #100 is_save_done = 1;
    end

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            ifmap_value <= 0;
            weight_vec <= 0;
        end
        
        else begin
            ifmap_value <= ifmap[`SIGNED_BITS -1 : 0];
            weight_vec <= kernel;
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
