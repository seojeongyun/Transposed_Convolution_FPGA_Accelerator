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
    parameter BITS     = 8,
    parameter MULT_BITS = 16
)
(
    input       clk,
    input       reset_n,
    input       in_wait,
    //
    input   [2:0] o_valid,
    input   [FH * MULT_BITS -1 : 0] ofmap_vec_an_ifmap_value0,
    input   [FH * MULT_BITS -1 : 0] ofmap_vec_an_ifmap_value1,
    input   [FH * MULT_BITS -1 : 0] ofmap_vec_an_ifmap_value2,
    //
    output  is_save_done,
    output  is_pad_done,
    output  valid_change_col,
    
    output  [ORIG_OW * ORIG_OH * MULT_BITS - 1 : 0] final_ofmap_flat,
    //
    output  o_done
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
    reg [FH * MULT_BITS -1 : 0] ofmap_vec_an_ifmap_value [0:2];  // FW = 3? ??

    always @(*) begin
        ofmap_vec_an_ifmap_value[0] = ofmap_vec_an_ifmap_value0;
        ofmap_vec_an_ifmap_value[1] = ofmap_vec_an_ifmap_value1;
        ofmap_vec_an_ifmap_value[2] = ofmap_vec_an_ifmap_value2;
    end



    // -*-*-*-*-*-*-* ofmap_row_idx_rst (To initialize ofmap to zero) -*-*-*-*-*-*-*
    reg [IDX_BITS-1 : 0] ofmap_row_idx_rst;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) ofmap_row_idx_rst <= 0;
        else if(in_wait) ofmap_row_idx_rst <= 0;
        else if(o_reset && ofmap_row_idx_rst != ORIG_OH-1) ofmap_row_idx_rst <= ofmap_row_idx_rst + 1'b1;
        
    end
    
    
    
    
    // -*-*-*-*-*-*-* make various idx signal -*-*-*-*-*-*-*
    //          To replace "for loop" to "FSM"
    reg [IDX_BITS-1 : 0]  C_idx;
    reg [IDX_BITS-1 : 0] ifmap_col_idx;
    reg [IDX_BITS-1 : 0] ifmap_row_idx;
    reg [IDX_BITS-1 : 0] kernel_row_idx;
    //
    reg valid_change_col;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            // C_idx <= 0;
            ifmap_col_idx <= 0;
            ifmap_row_idx <= 0;
            kernel_row_idx <= 0;
            valid_change_col <= 0;
        end

        else if(o_save && (!save_done_reg && !is_save_done)) begin
            if(kernel_row_idx == FH-1) begin
                if(ifmap_col_idx == IW-1) begin
                    ifmap_row_idx <= ifmap_row_idx + 1'b1;
                    ifmap_col_idx <= 0;
                end
                
                else ifmap_col_idx <= ifmap_col_idx + 1;
                kernel_row_idx <= 0;
                //
            end
            
            else kernel_row_idx <= kernel_row_idx + 1'b1;
            
            if (kernel_row_idx == 0) valid_change_col <= 1'b1;
            else valid_change_col <= 1'b0;
        end

        else begin
            // C_idx <= 0;
            ifmap_col_idx <= 0;
            ifmap_row_idx <= 0;
            kernel_row_idx <= 0;
        end
    end





    // -*-*-*-*-*-*-* MAKE OFMAP -*-*-*-*-*-*-*
    reg [ORIG_OW * MULT_BITS - 1 : 0] final_ofmap [ORIG_OH - 1 : 0];
    reg [PADDED_OW * MULT_BITS - 1 : 0] padded_ofmap [PADDED_OH - 1 : 0];
    always @(posedge clk) begin
        if(o_reset) begin
            padded_ofmap[ofmap_row_idx_rst] <= 0;
            final_ofmap[ofmap_row_idx_rst] <= 0;
        end
        
        else if(o_save) begin
            if(PAD && save_done_reg) padded_ofmap[padded_ofmap_row_idx] <= padded_ofmap[padded_ofmap_row_idx] + final_ofmap[target_ofmap_row_idx][MULT_BITS*(ORIG_OW-PAD)-1 -: PADDED_OW*MULT_BITS];
            else final_ofmap[kernel_row_idx+S*ifmap_row_idx][((ORIG_OW)-(S*ifmap_col_idx))*MULT_BITS-1 -: FW*MULT_BITS] <= final_ofmap[kernel_row_idx+S*ifmap_row_idx][((ORIG_OW)-(S*ifmap_col_idx))*MULT_BITS-1 -: FW*MULT_BITS] + ofmap_vec_an_ifmap_value[kernel_row_idx];
        end
    end
            //  for idx row
            //      for idx col
            //          for kernel row
    
    
    
    
    // -*-*-*-*-*-*-* make save_done_reg -*-*-*-*-*-*-*
    // For pad idx
    reg save_done_reg;
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) save_done_reg <= 0;
        else if(PAD) begin
            if(is_save_done) save_done_reg <= 1'b1;
            else if(is_pad_done) save_done_reg <= 1'b0;
        end
    end





    // -*-*-*-*-*-*-* padded ofmap idx -*-*-*-*-*-*-*
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
    
    
    
    
    // -*-*-*-*-*-*-* generate done signal -*-*-*-*-*-*-*
    wire is_save_done;   
    wire is_reset_done;
    wire is_pad_done;
    
    // assign is_save_done = (ifmap_col_idx == IW-1) && (ifmap_row_idx == IH-1) && (kernel_row_idx == FH-1);
    assign is_save_done = ifmap_row_idx == IH;
    assign is_pad_done = o_save && padded_ofmap_row_idx == PADDED_OH; //
    assign is_reset_done = o_reset && ofmap_row_idx_rst == ORIG_OH-1;
    //

    
    // -*-*-*-*-*-*-* flatten ofmap for only not padded ofmap -*-*-*-*-*-*-*
    //                  not implemented yet for padded ofmap
    wire [ORIG_OW*ORIG_OH*MULT_BITS-1:0] final_ofmap_flat;
    
    genvar i;
    generate
        for (i = 0; i < ORIG_OH; i = i + 1) begin : expand_flat
            assign final_ofmap_flat[(ORIG_OH - i) * ORIG_OW * MULT_BITS-1 -: ORIG_OW * MULT_BITS] = final_ofmap[i];
        end
    endgenerate
endmodule