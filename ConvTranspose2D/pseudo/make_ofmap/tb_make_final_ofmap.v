`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2025 11:47:47 AM
// Design Name: 
// Module Name: tb_make_ofmap
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


`define     FW  3
`define     FH  3
//
`define     IW  2
`define     IH  2
//
`define     S  2
`define     C  1
`define     PAD  1
//
`define     ORIG_OW (`FW + `S*(`IW-1))
`define     ORIG_OH (`FH + `S*(`IH-1))
//
`define     PADDED_OW (`FW + `S*(`IW-1) - 2*`PAD)
`define     PADDED_OH (`FH + `S*(`IH-1) - 2*`PAD)
//
`define     BITS 8
//
`define     IW_idx_BITS  10
`define     IH_idx_BITS  10
`define     C_idx_BITS   10

module tb_make_ofmap;
    reg clk, reset_n, in_wait;
    reg [2:0] o_valid;
    reg [`FH * `BITS -1 : 0] ofmap_vec_an_ifmap_value [`FW -1 : 0];
    //
//    wire [`OW * `BITS - 1 : 0] final_ofmap [`OH- 1 : 0];
//    wire [`OW * `BITS - 1 : 0] final_ofmap0;
//    wire [`OW * `BITS - 1 : 0] final_ofmap1;
//    wire [`OW * `BITS - 1 : 0] final_ofmap2;
//    wire [`OW * `BITS - 1 : 0] final_ofmap3;
    
    make_ofmap #(
        .FW(`FW),
        .FH(`FH),
        //
        .IW(`IW),
        .IH(`IH),
        //
        .S(`S),
        .PAD(`PAD),
        .C(`C),
        //
        .ORIG_OW(`ORIG_OW),
        .ORIG_OH(`ORIG_OH),
        //
        .PADDED_OW(`PADDED_OW),
        .PADDED_OH(`PADDED_OH),
        //
        .IW_idx_BITS(`IW_idx_BITS),
        .IH_idx_BITS(`IH_idx_BITS),
        .C_idx_BITS(`C_idx_BITS),
        //
        .BITS(`BITS)
    ) u0_make_ofmap (
        .clk        (clk),
        .reset_n    (reset_n),
        .in_wait    (in_wait),
        .o_valid    (o_valid),
        .ofmap_vec_an_ifmap_value0   (ofmap_vec_an_ifmap_value[0]),
        .ofmap_vec_an_ifmap_value1   (ofmap_vec_an_ifmap_value[1]),
        .ofmap_vec_an_ifmap_value2   (ofmap_vec_an_ifmap_value[2])
        //
//        .final_ofmap                 (final_ofmap)
    );

    // ?? ??
    initial clk = 0;
    always #5 clk = ~clk;

    // ?? ? o_valid ??
    initial begin
        reset_n = 1;
        o_valid = 0;
        in_wait = 0;
        #20 reset_n = 0;
        #10 reset_n = 1;
        #10 in_wait = 1;
        #15 in_wait = 0;
        #100 o_valid = 3'b111;
//        #400 in_wait = 1;
//        #10   in_wait = 0;
    end

    // ?? ??? ???
    integer j, k;
    initial begin
        #120
        for (j = 0; j < `FW; j = j + 1) begin
            for (k = 0; k < `FH; k = k + 1) begin
                ofmap_vec_an_ifmap_value[j][(`FH - 1 - k) * `BITS +: `BITS] = k + `FH * j;
                $display("ofmap_vec[%0d][%0d] = %d", j, k, ofmap_vec_an_ifmap_value[j][(`FH - 1 - k) * `BITS +: `BITS]);
            end
        end
    end


    integer ifmap_fd;
    integer kernel_fd;
    //
    integer r1,r2;
    //
    reg [`IW * `IH * `BITS - 1 : 0] ifmap;
    reg [`FH * `FH * `BITS - 1 : 0] kernel;

    initial begin
        ifmap_fd = $fopen("/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref/ifmap.txt", "r"); // ?? ??
        if (ifmap_fd == 0) begin
            $display("FAIL");
            $finish;
        end
        
        for(integer q=0; q<`IH*`IW; q=q+1) begin
            r1 = $fscanf(ifmap_fd, "%d\n", ifmap[`BITS * q +: `BITS]);
            $display("READ_IFMAP: %d", ifmap[`BITS * q +: `BITS]);
        end
        #10;
        $fclose(ifmap_fd); // ?? ??
    end

    initial begin
        kernel_fd = $fopen("/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref/kernel.txt", "r"); // ?? ??
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

    reg [`BITS * `FH * `FW - 1 : 0] ofmap_vec [`IW*`IH -1 : 0];
    reg [`BITS * `FW - 1 : 0] intermediate [`FH - 1 : 0];
    initial begin
        for(integer i = `IH * `IW-1; i>=0; i= i-1) begin
            for(integer j=0; j<`FW*`FH; j=j+1) begin
                ofmap_vec[i][`BITS * j +: `BITS] <= kernel[`BITS * j +: `BITS] * ifmap[`BITS * i +: `BITS];
            end
            // for(integer k=0; k<`FH; k=k+1) begin
            //     intermediate[i][`BITS * `FW * -1 -: `BITS * `FW] <= ofmap_vec[i][`BITS * `FH * k +: `BITS * `FH];
            // end
        end
        #10;


    end
//    // ?? ??
//    integer x;
//    initial begin
//        #200
//        $display("==== Final ofmap ?? ====");
//        for (x = 0; x < `OW; x = x + 1) begin
//            $display("final_ofmap[%0d] = %0d", x, final_ofmap[x]);
//        end
//        $finish;
//    end
endmodule
