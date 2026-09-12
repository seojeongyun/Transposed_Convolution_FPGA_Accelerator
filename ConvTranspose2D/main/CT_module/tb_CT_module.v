`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/03/2025 07:25:04 PM
// Design Name: 
// Module Name: tb_CT_module
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
//`define     WRITE
`define     VERIFICATION
//
//
//
//
`define     IW                  2
`define     IH                  2
//
`define     FW                  3
`define     FH                  3
//
`define     IN_C                2
`define     OUT_C               5
`define     S                   1
`define     PAD                 1
//
`define     IDX_BITS            20
`define     ENABLE_CNT_BITS     3
//
`define     BITS                9
`define     SIGNED_BITS         9
`define     MULT_BITS           50
`define     OFMAP_BITS          100
//
`define     ORIG_OW             ( `FW + `S * (`IW -1) )
`define     ORIG_OH             ( `FH + `S * (`IH -1) )
//                                        `
`define     PADDED_OW           ( `FW + `S * (`IW -1) - 2 * `PAD )
`define     PADDED_OH           ( `FH + `S * (`IH -1) - 2 * `PAD )
//                              `
`define     OW                  ( `PAD ? `FW + `S * (`IW -1) - 2 * `PAD : `FW + `S * (`IW-1) )
`define     OH                  ( `PAD ? `FH + `S * (`IH -1) - 2 * `PAD : `FH + `S * (`IH-1) )
//
`define     DELAY               1
`define     ENABLE_DELAY        2
`define     IN_PAD_REGION_DELAY 3
//
//`define     IFMAP_PATH          "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref_wo_channel/test32/ifmap.txt"
//`define     KERNEL_PATH         "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref_wo_channel/test32/kernel.txt"
//`define     LABEL_PATH          "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref_wo_channel/test32/output.txt"
//`define     OFMAP_PATH          "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref_wo_channel/test32/ofmap.txt"
//`define     VR_PATH             "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref_wo_channel/test32/VR.txt"
//`define     VISUAL_PATH         "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref_wo_channel/test32/visualization.txt"
//
`define     IFMAP_PATH          "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref_w_channel/test8/ifmap.txt"
`define     KERNEL_PATH         "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref_w_channel/test8/kernel.txt"
`define     LABEL_PATH          "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref_w_channel/test8/output.txt"
`define     OFMAP_PATH          "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref_w_channel/test8/ofmap.txt"
`define     VR_PATH             "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref_w_channel/test8/VR.txt"
`define     VISUAL_PATH         "/home/xilinx/xilinx_study/jyseo/ConvTranspose2D/gold_ref_w_channel/test8/visualization.txt"
//
//
//
//
//
`define     IFMAP_AWIDTH        20              // if an image size is 1024, the MEM_DEPTH is 2^20.
`define     IFMAP_DWIDTH        `SIGNED_BITS
`define     IFMAP_MEM_DEPTH     `IW * `IH * `IN_C
//
`define     WEIGHT_AWIDTH        10              // 
`define     WEIGHT_DWIDTH        `FW * `SIGNED_BITS
`define     WEIGHT_MEM_DEPTH     `IN_C * `OUT_C * `FH 
//
`define     OFMAP_AWIDTH        20
`define     OFMAP_DWIDTH        `OFMAP_BITS
`define     OFMAP_MEM_DEPTH     `PAD ? (`PADDED_OW * `PADDED_OH * `OUT_C) : (`ORIG_OW * `ORIG_OH * `OUT_C)
//

`default_nettype none

module tb_CT_module;
    reg     clk, reset_n, i_run;
    reg     signed [`SIGNED_BITS -1 : 0] ifmap_value;
    reg     signed [`BITS * `FW - 1 : 0] weight_vec;
    //
    wire    [`IDX_BITS -1 : 0] row_idx;
    wire    [`IDX_BITS -1 : 0] col_idx;
    wire    [`IDX_BITS -1 : 0] in_channel_idx;
    wire    [`IDX_BITS -1 : 0] out_channel_idx;
    //
    wire    signed [`FW * `FH * `MULT_BITS -1 : 0]  intermediate;
    //
    wire    [`IDX_BITS -1 : 0] captured_row;
    wire    [`IDX_BITS -1 : 0] captured_col;
    wire    [`IDX_BITS -1 : 0] captured_ifmap_in_channel;
    wire    [`IDX_BITS -1 : 0] captured_ifmap_out_channel;
    //
    wire    o_idle;
    wire    o_load;
    wire    o_calc;
    wire    o_save;
    wire    o_done;
    //
    wire    wegt_ce0;
    wire    ifmap_ce0;
    //
    wire    [`WEIGHT_AWIDTH -1 : 0] wegt_addr; // `IDX_BITS >> ??????????
    wire    [`IFMAP_AWIDTH -1 : 0] ifmap_addr; // `IDX_BITS >> ??????????
    //
    wire    signed [`OW * `OH * `OUT_C * `OFMAP_BITS -1 : 0] ofmap;
    wire    ofmap_generate_success;
    
    // -*-*-*-* DEBUG -*-*-*-*
    wire are_all_channel_calcs_done;
    
    //
    //
    
    CT_module#
    (
        .FW                 (`FW),
        .FH                 (`FH),
        //                   `
        .IW                 (`IW),
        .IH                 (`IH),
        //                   `
        .S                  (`S),
        .PAD                (`PAD),
        .IN_C               (`IN_C),
        .OUT_C              (`OUT_C),
        //                   `
        .IDX_BITS           (`IDX_BITS),
        .ENABLE_CNT_BITS    (`ENABLE_CNT_BITS),
        //                   `
        .BITS               (`BITS),
        .SIGNED_BITS        (`SIGNED_BITS),
        .MULT_BITS          (`MULT_BITS),
        .OFMAP_BITS         (`OFMAP_BITS),
        //                   `
        .ORIG_OW            (`ORIG_OW),
        .ORIG_OH            (`ORIG_OH),
        //                   `
        .PADDED_OW          (`PADDED_OW),
        .PADDED_OH          (`PADDED_OH),
        //                   `
        .OW                 (`OW),
        .OH                 (`OH),
        //                   `
        .DELAY              (`DELAY),
        .ENABLE_DELAY       (`ENABLE_DELAY),
        .IN_PAD_REGION_DELAY(`IN_PAD_REGION_DELAY),
        //                   `
        .IFMAP_AWIDTH       (`IFMAP_AWIDTH),
        //                   `
        .WEIGHT_AWIDTH      (`WEIGHT_AWIDTH),
        //                   `
        .OFMAP_AWIDTH       (`OFMAP_AWIDTH),
        .OFMAP_DWIDTH       (`OFMAP_DWIDTH),
        .OFMAP_MEM_DEPTH    (`OFMAP_MEM_DEPTH)
    )
    u0_CT_module
    (   
        .i_run              (i_run),
        .clk                (clk),
        .reset_n            (reset_n),
        //
        .ifmap_value        (ifmap_value),
        .weight_vec         (weight_vec),
        //
        .row_idx            (row_idx),
        .col_idx            (col_idx),
        .in_channel_idx     (in_channel_idx),
        .out_channel_idx    (out_channel_idx),
        //
        .intermediate       (intermediate),
        //
        .o_idle             (o_idle),
        .o_load             (o_load),
        .o_calc             (o_calc),
        .o_save             (o_save),
        .o_done             (o_done),
        //
        .wegt_ce0           (wegt_ce0),
        .ifmap_ce0          (ifmap_ce0),
        //
        .captured_ifmap_row         (captured_row),
        .captured_ifmap_col         (captured_col),
        .captured_ifmap_in_channel  (captured_ifmap_in_channel),
        .captured_ifmap_out_channel (captured_ifmap_out_channel),
        //
        .wegt_addr          (wegt_addr),
        .ifmap_addr         (ifmap_addr),
        //
        .ofmap                  (ofmap),
        .ofmap_generate_success (ofmap_generate_success),
        // DEBUG
        .are_all_channel_calcs_done   (are_all_channel_calcs_done)
    );


    initial clk = 0;
    always #5 clk = ~clk;
    
    initial begin
        i_run = 0;
        reset_n = 0;
        #20 reset_n = 1;
        #10 i_run = 1;
        #10 i_run = 0;
    end    




    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            ifmap_value <= 0;
            weight_vec <= 0;
        end
        
        else begin
            ifmap_value <= ifmap_value_;
            weight_vec <= weight_vec_;
        end
    end 
    
    
    
    // -*-*-*-*-*-*-* FILE READ AND WRITE -*-*-*-*-*-*-*
    integer ifmap_fd;
    integer kernel_fd;
    integer ofmap_fd;
    
    //
    integer r1,r2;
    //
    reg [`IW * `IH * `IN_C * `SIGNED_BITS - 1 : 0] ifmap;
    reg [`FH * `FH * `IN_C * `OUT_C * `SIGNED_BITS - 1 : 0] kernel;
    
    
    // -*-*-*-*-*-*-* IFMAP AND KERNEL READ -*-*-*-*-*-*-*
    initial begin
        ifmap_fd = $fopen(`IFMAP_PATH, "r"); // ?? ??
        if (ifmap_fd == 0) begin
            $display("FAIL");
            $finish;
        end
        //
        for(integer ifmap_idx = 0; ifmap_idx < `IH * `IW * `IN_C; ifmap_idx = ifmap_idx + 1) begin
            r1 = $fscanf(ifmap_fd, "%d\n", ifmap_dpbram.ram[ifmap_idx]);
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
        //
        for(integer kernel_out_channel_idx = 0; kernel_out_channel_idx < `OUT_C; kernel_out_channel_idx = kernel_out_channel_idx + 1) begin
            for(integer kernel_in_channel_idx = 0; kernel_in_channel_idx < `IN_C; kernel_in_channel_idx = kernel_in_channel_idx + 1) begin
                for(integer kernel_row_idx = 0; kernel_row_idx < `FH; kernel_row_idx = kernel_row_idx + 1) begin
                    for(integer kernel_col_idx = 0; kernel_col_idx < `FW; kernel_col_idx = kernel_col_idx + 1) begin
                        r2 = $fscanf(kernel_fd, "%d\n", kernel[(kernel_col_idx + kernel_row_idx * `FW + kernel_in_channel_idx * `FW * `FH + kernel_out_channel_idx * `FW * `FH * `IN_C) * `BITS +: `BITS]);
                    end
                    weight_dpbram.ram[kernel_row_idx + kernel_in_channel_idx * `FH + kernel_out_channel_idx * `FH * `IN_C] <= kernel[(kernel_row_idx + kernel_in_channel_idx * `FH + kernel_out_channel_idx * `FH * `IN_C) * `BITS * `FW +: `BITS * `FW];
                end
            end
        end
        //
        $fclose(kernel_fd); // ?? ??
    end  
    
    
    
    // -*-*-*-*-*-*-* OFMAP WRITE -*-*-*-*-*-*-*
`ifdef WRITE
    initial begin
        ofmap_fd = $fopen(`OFMAP_PATH, "w"); // ?? ??
        if (ofmap_fd == 0) begin
            $display("FAIL");
            $finish;
        end 
        //           
        wait(ofmap_generate_success);
        //
        for(integer kernel_out_channel_idx = 0; kernel_out_channel_idx < `OUT_C; kernel_out_channel_idx = kernel_out_channel_idx + 1) begin
            for(integer ofmap_idx = 0; ofmap_idx < `OH * `OW; ofmap_idx = ofmap_idx + 1) begin
                $fwrite(ofmap_fd, "%0d\n", $signed(ofmap[(`OH * `OW * `OUT_C - (ofmap_idx + kernel_out_channel_idx * `OW * `OH)) * `OFMAP_BITS -1 -: `OFMAP_BITS]));
            end
        end
        //
        #100
        $finish;
        $fclose(ofmap_fd);
    end
`endif
    
    
    //-*-*-*-*-*-*-* INSTANTIATION OF IFMAP BRAM -*-*-*-*-*-*-*
    reg we0 = 1'b0;

    wire signed [`SIGNED_BITS -1 : 0] ifmap_value_;
    wire signed [`SIGNED_BITS * `FW - 1 : 0] weight_vec_;
        
    dpbram#
    (
        .AWIDTH         (`IFMAP_AWIDTH),
        .DWIDTH         (`IFMAP_DWIDTH),
        .MEM_DEPTH      (`IFMAP_MEM_DEPTH)
    ) ifmap_dpbram
    (
        .clk           (clk),
        //
        .addr0          (ifmap_addr),
        .ce0            (ifmap_ce0),
        .we0            (we0),
        //
        .q0             (ifmap_value_)
    );
    
    
    dpbram#
    (
        .AWIDTH         (`WEIGHT_AWIDTH),
        .DWIDTH         (`WEIGHT_DWIDTH),
        .MEM_DEPTH      (`WEIGHT_MEM_DEPTH)
    ) weight_dpbram
    (
        .clk           (clk),
        //
        .addr0          (wegt_addr),
        .ce0            (wegt_ce0),
        .we0            (we0),
        //
        .q0             (weight_vec_)
    );
    
    
`ifdef VERIFICATION
    integer label_fd, read_ofmap_fd, ofmap_verification_fd, ofmap_visualization_fd;
    
    integer r3, r4;
    
    reg [`OW * `OH * `OUT_C * `OFMAP_BITS -1 : 0] label;
    reg [`OW * `OH * `OUT_C * `OFMAP_BITS -1 : 0] read_ofmap;
    reg  verification;
    
    // -*-*-*-*-* DEBUG -*-*-*-*-*
    initial begin
        label_fd = $fopen(`LABEL_PATH, "r"); // ?? ??
        if (label_fd == 0) begin
            $display("FAIL");
            $finish;
        end
        
        read_ofmap_fd = $fopen(`OFMAP_PATH, "r"); // ?? ??
        if (read_ofmap_fd == 0) begin
            $display("FAIL");
            $finish;
        end
                
        ofmap_verification_fd = $fopen(`VR_PATH, "w"); // ?? ??
        if (ofmap_verification_fd == 0) begin
            $display("FAIL");
            $finish;
        end
        
        ofmap_visualization_fd = $fopen(`VISUAL_PATH, "w"); // ?? ??
        if (ofmap_visualization_fd == 0) begin
            $display("FAIL");
            $finish;
        end       
        for(integer kernel_out_channel_idx = 0; kernel_out_channel_idx < `OUT_C; kernel_out_channel_idx = kernel_out_channel_idx + 1) begin
            for(integer ofmap_row = 0; ofmap_row < `OH; ofmap_row = ofmap_row + 1) begin
                for(integer ofmap_col = 0; ofmap_col < `OW; ofmap_col = ofmap_col + 1) begin
                    r3 = $fscanf(label_fd, "%d\n", label[(`OH * `OW * `OUT_C - (ofmap_col + ofmap_row * `OH + kernel_out_channel_idx * `OH * `OW)) * `OFMAP_BITS -1 -: `OFMAP_BITS]);
                    r4 = $fscanf(read_ofmap_fd, "%d\n", read_ofmap[(`OH * `OW * `OUT_C - (ofmap_col + ofmap_row * `OH + kernel_out_channel_idx * `OH * `OW)) * `OFMAP_BITS -1 -: `OFMAP_BITS]);
                    
                    
                    if(label[((`OH * `OW * `OUT_C - (ofmap_col + ofmap_row * `OH + kernel_out_channel_idx * `OH * `OW))) * `OFMAP_BITS -1 -: `OFMAP_BITS] == read_ofmap[((`OH * `OW * `OUT_C - (ofmap_col + ofmap_row * `OH + kernel_out_channel_idx * `OH * `OW))) * `OFMAP_BITS -1 -: `OFMAP_BITS])
                        $fwrite(ofmap_verification_fd, "0");
                    else                    
                        $fwrite(ofmap_verification_fd, "1");
                    $fwrite(ofmap_visualization_fd, "%10d", $signed(read_ofmap[(`OH * `OW * `OUT_C - (ofmap_col + ofmap_row * `OH + kernel_out_channel_idx * `OH * `OW)) * `OFMAP_BITS -1 -: `OFMAP_BITS]));
                end         
                $fwrite(ofmap_verification_fd, "\n");
                $fwrite(ofmap_visualization_fd, "\n");
            end
            for(integer i = 0; i < 4; i = i + 1) begin
                $fwrite(ofmap_verification_fd, "\n");
                $fwrite(ofmap_visualization_fd, "\n");
            end
        end
        #10;
        $fclose(label_fd); // ?? ??
        $fclose(read_ofmap_fd); // ?? ??
        $fclose(ofmap_verification_fd); // ?? ??
        $fclose(ofmap_visualization_fd);
        #10;
    end
`endif
endmodule
