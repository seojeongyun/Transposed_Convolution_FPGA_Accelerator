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
    parameter ORIG_OW = FW + S*(IW-1),
    parameter ORIG_OH = FH + S*(IH-1),
    //
    parameter PADDED_OW = FW + S*(IW-1) - 2*PAD,
    parameter PADDED_OH = FH + S*(IH-1) - 2*PAD,
    //
    parameter IDX_BITS = 10, 
    parameter BITS     = 8
)
(
    input       clk,
    input       reset_n,
    input       in_wait,
    //
    input   [2:0] o_valid,
    input [FH*BITS-1:0] ofmap_vec_an_ifmap_value0,
    input [FH*BITS-1:0] ofmap_vec_an_ifmap_value1,
    input [FH*BITS-1:0] ofmap_vec_an_ifmap_value2
    //
    // input  [FH*8-1:0] ofmap_vec_an_ifmap_value [FW-1:0],
    //
//    output reg [OH - 1 : 0] final_ofmap [OW - 1 : 0]
);

    // -*-*-*-*-*-*-* FSM -*-*-*-*-*-*-*
    localparam IDLE = 2'b00, RESET = 2'b01, SAVE = 2'b10, DONE = 2'b11;

    reg [1:0] c_state, n_state;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) c_state <= IDLE;
        else c_state <= n_state;
    end

    always @(*) begin
        case(c_state)
            IDLE : n_state = in_wait ? RESET : IDLE;
            RESET : n_state = is_reset_done && &o_valid ? SAVE : RESET;
            SAVE : n_state = PAD == 0 ? (is_save_done ? DONE : SAVE) : (is_pad_done ? DONE : SAVE);
            DONE : n_state = IDLE;
        endcase
    end


    // -*-*-*-*-*-*-* other signal -*-*-*-*-*-*-*
    wire o_idle;
    wire o_reset;
    wire o_save;
    wire o_done;
    
    assign o_idle = c_state == IDLE;
    assign o_reset = c_state == RESET;
    assign o_save = c_state == SAVE;
    assign o_done = c_state == DONE;

    // -*-*-*-*-*-*-* make ofmap_vec array -*-*-*-*-*-*-*
    reg [FH*BITS-1:0] ofmap_vec_an_ifmap_value [0:2];  // FW = 3? ??

    always @(*) begin
        ofmap_vec_an_ifmap_value[0] = ofmap_vec_an_ifmap_value0;
        ofmap_vec_an_ifmap_value[1] = ofmap_vec_an_ifmap_value1;
        ofmap_vec_an_ifmap_value[2] = ofmap_vec_an_ifmap_value2;
    end

    //
    reg [IDX_BITS-1 : 0] ofmap_row_idx_rst;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) ofmap_row_idx_rst <= 0;
        else if(in_wait) ofmap_row_idx_rst <= 0;
        else if(o_reset && ofmap_row_idx_rst != ORIG_OH-1) ofmap_row_idx_rst <= ofmap_row_idx_rst + 1'b1;
        
    end
    // -*-*-*-*-*-*-* make j,k -*-*-*-*-*-*-*
    reg [IDX_BITS-1 : 0]  C_idx;
    reg [IDX_BITS-1 : 0] ofmap_col_idx;
    reg [IDX_BITS-1 : 0] ofmap_row_idx;
    reg [IDX_BITS-1 : 0] kernel_row_idx;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            // C_idx <= 0;
            ofmap_col_idx <= 0;
            ofmap_row_idx <= 0;
            kernel_row_idx <= 0;
        end

        else if(o_save && (!save_done_reg && !is_save_done)) begin
            if(kernel_row_idx == FH-1) begin
                if(ofmap_col_idx == IW-1) begin
                    ofmap_row_idx <= ofmap_row_idx + 1'b1;
                    ofmap_col_idx <= 0;
                end
                
                else ofmap_col_idx <= ofmap_col_idx + 1;
                
                kernel_row_idx <= 0;
                //
            end
            else kernel_row_idx <= kernel_row_idx + 1'b1;
        end

        else begin
            // C_idx <= 0;
            ofmap_col_idx <= 0;
            ofmap_row_idx <= 0;
            kernel_row_idx <= 0;
        end
    end

    //
    reg [ORIG_OW*BITS - 1 : 0] final_ofmap [ORIG_OH - 1 : 0];
    reg [PADDED_OW*BITS - 1 : 0] padded_ofmap [PADDED_OH - 1 : 0];
    always @(posedge clk) begin
        if(o_reset) begin
            padded_ofmap[ofmap_row_idx_rst] <= 0;
            final_ofmap[ofmap_row_idx_rst] <= 0;
        end
        
        else if(o_save) begin
            if(PAD && save_done_reg) padded_ofmap[padded_ofmap_row_idx] <= padded_ofmap[padded_ofmap_row_idx] + final_ofmap[target_ofmap_row_idx][BITS*(ORIG_OW-PAD)-1 -: PADDED_OW*BITS];
            else final_ofmap[kernel_row_idx+S*ofmap_row_idx][((ORIG_OW)-(S*ofmap_col_idx))*BITS-1 -: FW*BITS] <= final_ofmap[kernel_row_idx+S*ofmap_row_idx][((ORIG_OW)-(S*ofmap_col_idx))*BITS-1 -: FW*BITS] + ofmap_vec_an_ifmap_value[kernel_row_idx];
        end
    end
    
    //
    reg save_done_reg;
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) save_done_reg <= 0;
        else if(PAD) begin
            if(is_save_done) save_done_reg <= 1'b1;
            else if(is_pad_done) save_done_reg <= 1'b0;
        end
    end

    //
    reg [IDX_BITS-1 : 0] padded_ofmap_row_idx;
    reg [IDX_BITS-1 : 0] target_ofmap_row_idx;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            padded_ofmap_row_idx <= 0;
            target_ofmap_row_idx <= PAD;
        end

        else if(save_done_reg && o_save) begin 
            if(padded_ofmap_row_idx != PADDED_OH) begin
                padded_ofmap_row_idx <= padded_ofmap_row_idx + 1'b1;
                target_ofmap_row_idx <= target_ofmap_row_idx + 1'b1;
            end
        end
        
        else begin
            padded_ofmap_row_idx <= 0;
            target_ofmap_row_idx <= PAD;        
        end
    end
    //
    wire is_save_done;   
    wire is_reset_done;
    wire is_pad_done;
    
    assign is_save_done = (ofmap_col_idx == IW-1) && (ofmap_row_idx == IH-1) && (kernel_row_idx == FH-1);
    assign is_pad_done = o_save && padded_ofmap_row_idx == PADDED_OH; //
    assign is_reset_done = o_reset && ofmap_row_idx_rst == ORIG_OH-1;
    //
    
    
//    reg is_reset_done;
    
//    always @(posedge clk or negedge reset_n) begin
//        if(!reset_n) is_reset_done <= 1'b0;
//        else is_reset_done = o_reset && ofmap_row_idx_rst == OH-1;
//    end
endmodule