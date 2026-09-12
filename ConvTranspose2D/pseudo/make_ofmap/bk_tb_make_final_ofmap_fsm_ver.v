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
//`define     IW  2
//`define     IH  2
////
//`define     FW  3
//`define     FH  3
////
//`define     C  1
//`define     S  1
//`define     PAD  0
//
`define     ORIG_OW (`FW + `S*(`IW-1))            // 3 + 63 = 66
`define     ORIG_OH (`FH + `S*(`IH-1))
//
`define     PADDED_OW (`FW + `S*(`IW-1) - 2*`PAD) // 3 + 2*63 - 2 = 127
`define     PADDED_OH (`FH + `S*(`IH-1) - 2*`PAD)
//
`define     BITS 8
`define     MULT_BITS 16
//
`define     IDX_BITS  10
//
//

//
//
`define     IFMAP_PATH "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref/test3_ver2/ifmap.txt"
`define     KERNEL_PATH "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref/test3_ver2/kernel.txt"
`define     OFMAP_PATH "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref/test3_ver2/ofmap.txt"
`define     PADDED_OFMAP_PATH "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref/test3_ver2/padded_ofmap.txt"
//
//

module tb_make_ofmap;
    reg clk, reset_n, in_wait;
    reg [2:0] o_valid;
    reg [`FH * `MULT_BITS -1 : 0] ofmap_vec_an_ifmap_value [`FW -1 : 0];
    //
    wire valid_change_col;
    wire valid_change_row;
    //
    wire [`MULT_BITS * `ORIG_OW * `ORIG_OH -1 : 0] final_ofmap_flat;
    wire is_save_done;
    wire is_pad_done;
    
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
        .IDX_BITS(`IDX_BITS),
        //
        .BITS(`BITS),
        .MULT_BITS(`MULT_BITS)
    ) u0_make_ofmap (
        .clk        (clk),
        .reset_n    (reset_n),
        .in_wait    (in_wait),
        .o_valid    (o_valid),
        .ofmap_vec_an_ifmap_value0   (ofmap_vec_an_ifmap_value[0]),
        .ofmap_vec_an_ifmap_value1   (ofmap_vec_an_ifmap_value[1]),
        .ofmap_vec_an_ifmap_value2   (ofmap_vec_an_ifmap_value[2]),
        //
        .valid_change_col   (valid_change_col),
        .is_save_done   (is_save_done),
        .is_pad_done    (is_pad_done),
        .final_ofmap_flat    (final_ofmap_flat),
        .o_done         (o_done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

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

    // -*-*-*-*-*-*-* ofmap_vec_col_idx -*-*-*-*-*-*-*
    // To capture the signal when a ofmap_vec_an_ifmap_value changes.
    reg [`IDX_BITS-1 :0] ofmap_vec_col_idx;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) ofmap_vec_col_idx <= 0;
        else if(valid_change_col) ofmap_vec_col_idx <= ofmap_vec_col_idx + 1'b1;
        else if(is_save_done) ofmap_vec_col_idx <= 0;
    end
    
    
    
    // -*-*-*-*-*-*-* data initialization -*-*-*-*-*-*-*
    initial begin
        for (integer i = 0; i < `FH; i = i + 1) begin
            ofmap_vec_an_ifmap_value[i] = 0;
        end
    end
    
    
    // -*-*-*-*-*-*-* MAIN phrase for input of make_ofmap Module -*-*-*-*-*-*-*
    // ofmap_vec == intermediate, Matrix - [row : IW * IH, col : FW * FH * BITS]
    always @(posedge clk) begin
        for (integer i = 0; i < `FH; i = i + 1) begin
            ofmap_vec_an_ifmap_value[`FH - 1 - i] = ofmap_vec[ofmap_vec_col_idx][`MULT_BITS * `FW * i +: `MULT_BITS * `FW];
        end
    end



    //
    reg [`ORIG_OW * `ORIG_OH * `MULT_BITS-1:0] final_ofmap_flat_;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            final_ofmap_flat_ <= 0;
        end else if(is_save_done) begin
            final_ofmap_flat_ <= final_ofmap_flat;
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
    reg [`IW * `IH * `BITS - 1 : 0] ifmap;
    reg [`FH * `FH * `BITS - 1 : 0] kernel;
    
    // -*-*-*-*-*-*-* IFMAP AND KERNEL READ -*-*-*-*-*-*-*
    initial begin
        ifmap_fd = $fopen(`IFMAP_PATH, "r"); // ?? ??
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
   


    // -*-*-*-*-*-*-* IFMAP * KERNEL -*-*-*-*-*-*-*
    reg [`MULT_BITS * `FH * `FW - 1 : 0] ofmap_vec [`IW*`IH -1 : 0];
    reg [`MULT_BITS * `FW - 1 : 0] intermediate [`FH - 1 : 0];
    initial begin
        for(integer i = `IH * `IW-1; i>=0; i= i-1) begin
            for(integer j=0; j<`FW*`FH; j=j+1) begin
                ofmap_vec[i][`MULT_BITS * j +: `MULT_BITS] <= kernel[`BITS * (`FW * `FH - j) -1 -: `BITS] * ifmap[`BITS * i +: `BITS];
            end
        end
        #10;


    end
    
    
    
    // -*-*-*-*-*-*-* OFMAP WRITE -*-*-*-*-*-*-*
    initial begin
        if(`PAD) begin
            padded_ofmap_fd = $fopen(`PADDED_OFMAP_PATH, "w"); // ?? ??
            if (padded_ofmap_fd == 0) begin
                $display("FAIL");
                $finish;
        end
            wait(is_pad_done);
            for(integer row_idx = `PADDED_OH-1; row_idx >= 0; row_idx = row_idx - 1) begin
                for(integer col_idx = `PADDED_OW-1; col_idx >= 0; col_idx = col_idx - 1) begin
                    $fwrite(padded_ofmap_fd, "%0d\n", final_ofmap_flat_[(`ORIG_OW * row_idx + (`PAD * `ORIG_OW + `PAD) + col_idx) * `MULT_BITS +: `MULT_BITS]);
                end
            end
            #300;
            $finish;
        end
        
        else if(`PAD == 0) begin
            ofmap_fd = $fopen(`OFMAP_PATH, "w"); // ?? ??
            if (ofmap_fd == 0) begin
                $display("FAIL");
                $finish;
        end
            wait(o_done);
            for(integer q=0; q<`ORIG_OH * `ORIG_OW; q=q+1) begin
                $fwrite(ofmap_fd, "%0d\n", final_ofmap_flat_[(`ORIG_OH * `ORIG_OW - q) * `MULT_BITS -1 -: `MULT_BITS]);
            end
            #300;
            $finish;
        end
            //(`ORIG_OH * `ORIG_OW - q) * `BITS - 1 -: `ORIG_OH * `ORIG_OW * `BITS]
        $fclose(ofmap_fd); // ?? ??
        $fclose(padded_ofmap_fd);
    end
endmodule
