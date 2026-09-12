`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/07/2025 12:49:00 PM
// Design Name: 
// Module Name: SAVE_module
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


module SAVE_module#
(
    parameter   FW = 3,
    parameter   FH = 3,
    //
    parameter   IW = 2,
    parameter   IH = 2,
    //
    parameter   S = 1,
    parameter   PAD = 0,
    parameter   IN_C = 1,
    parameter   OUT_C = 1,
    //
    parameter ORIG_OW = FW + S*(IW-1),
    parameter ORIG_OH = FH + S*(IH-1),
    //
    parameter PADDED_OW = FW + S*(IW-1) - 2*PAD,
    parameter PADDED_OH = FH + S*(IH-1) - 2*PAD,
    //
    parameter OW = PAD ? FW + S*(IW-1) - 2*PAD : FW + S*(IW-1),
    parameter OH = PAD ? FH + S*(IH-1) - 2*PAD : FH + S*(IH-1),
    //
    parameter MULT_BITS = 16,
    parameter OFMAP_BITS = 20,
    //
    parameter IDX_BITS = 10,
    //
    parameter IN_PAD_REGION_DELAY = 2,
    //
    parameter OFMAP_AWIDTH = 12,
    parameter OFMAP_DWIDTH = OFMAP_BITS,
    parameter OFMAP_MEM_DEPTH = PAD ? PADDED_OW * PADDED_OH * OUT_C : ORIG_OW * ORIG_OH * OUT_C 
)
(
    input   clk,
    input   reset_n,
    //
    input   [IDX_BITS -1 : 0] captured_ifmap_row,
    input   [IDX_BITS -1 : 0] captured_ifmap_col,
    input  [IDX_BITS -1 : 0] captured_ifmap_in_channel,
    input  [IDX_BITS -1 : 0] captured_ifmap_out_channel,
    //
    input   [FH -1 : 0] o_valid,
    input   signed [FW * FH * MULT_BITS -1 : 0]  intermediate,
    //
    input   i_idle_from_CT,
    input   i_load_from_CT,
    input   i_calc_from_CT,
    input   i_save_from_CT,
    input   i_done_from_CT,
    //
    output  o_idle,
    output  o_read,
    output  o_accum,
    output  o_write,
    output  o_done,
    //
    output  is_save_done,
    //
    output  [IDX_BITS -1 :0] mem_access_cnt,
    output  signed [OW * OH * OUT_C * OFMAP_BITS -1 : 0] ofmap,
    output  ofmap_generate_success
);
    
    // -*-*-*-*-*-* STATE CONTROL SIGNAL -*-*-*-*-*-*
//    reg start_save;
//    //
//    always @(posedge clk or negedge reset_n) begin
//        if(!reset_n) start_save <= 1'b0;
//        else start_save <= i_save_from_CT;
//    end

    wire start_save;
    wire is_read_done;
    wire is_write_done;
    
    assign start_save = i_save_from_CT;
    assign is_read_done = o_read && q0_valid;
    assign is_write_done = o_write && d0_valid;
    assign is_save_done = is_write_done && mem_access_cnt == FH * FW - 1;
    
    
    // -*-*-*-*-*-* FSM -*-*-*-*-*-*
    localparam IDLE = 3'b000, READ = 3'b001, ACCUM = 3'b010, WRITE = 3'b011, DONE = 3'b100;
    
    reg [1:0] c_state;
    reg [1:0] n_state;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) c_state <= IDLE;
        else c_state <= n_state;
    end
    
    always @(*) begin
        case(c_state)
            IDLE  : n_state = start_save ? READ : IDLE;
            READ  : n_state = is_read_done ? ACCUM : READ;
            ACCUM : n_state = WRITE;
            WRITE : n_state = is_write_done ? (is_save_done ? DONE : READ) : WRITE;    
            DONE  : n_state = IDLE;
        endcase
    end
    
    
    
    // -*-*-*-*-*-* STATE_SIGNAL -*-*-*-*-*-*
    wire o_idle, o_read, o_accum, o_write, o_done;
    
    assign o_idle = c_state == IDLE;
    assign o_read = c_state == READ;
    assign o_accum = c_state == ACCUM;
    assign o_write = c_state == WRITE;
    assign o_done = c_state == DONE;
    
    
    
    // -*-*-*-*-*-* SAVE_CNT -*-*-*-*-*-
    reg [IDX_BITS -1 : 0] mem_access_cnt;
    //
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) mem_access_cnt <= {IDX_BITS{1'b0}};
        else if(o_idle) mem_access_cnt <= {IDX_BITS{1'b0}};
        else if(is_write_done) begin
            if(mem_access_cnt == FW * FH -1) mem_access_cnt <= {IDX_BITS{1'b0}};
            else mem_access_cnt <= mem_access_cnt + 1'b1;
        end
    end
    
    // -*-*-*-*-*-* MAKE IDX -*-*-*-*-*-
    reg [IDX_BITS -1 : 0] intermediate_col_idx;
    reg [IDX_BITS -1 : 0] intermediate_row_idx;
    reg [IDX_BITS -1 : 0] intermediate_channel_idx;
    //
    wire [IDX_BITS -1 : 0] orig_ofmap_col_idx;
    wire [IDX_BITS -1 : 0] orig_ofmap_row_idx;
    
    assign orig_ofmap_col_idx = intermediate_col_idx + S * captured_ifmap_col;
    assign orig_ofmap_row_idx = intermediate_row_idx + S * captured_ifmap_row;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            intermediate_col_idx <= {IDX_BITS{1'b0}};
            intermediate_row_idx <= {IDX_BITS{1'b0}};
            intermediate_channel_idx <= {IDX_BITS{1'b0}};
        end
        //
        else if(o_read && !is_read_done) begin
            if(intermediate_col_idx == FW-1) begin
                intermediate_col_idx <= {IDX_BITS{1'b0}};
                if(intermediate_row_idx == FH-1) begin
                    intermediate_channel_idx <= intermediate_channel_idx + 1'b1;
                    intermediate_row_idx <= {IDX_BITS{1'b0}};
                end
                
                else intermediate_row_idx <= intermediate_row_idx + 1'b1;
            end
            
            else intermediate_col_idx <= intermediate_col_idx + 1'b1;
        end
    end
    
    
    // -*-*-*-*-*-* OFMAP_ADDR -*-*-*-*-*-
    reg [OFMAP_AWIDTH -1 : 0] ofmap_addr;
    reg [IN_PAD_REGION_DELAY -1 : 0] in_padding_region_buf;
    
    wire in_padding_region = 
    (orig_ofmap_row_idx >= PAD) && (orig_ofmap_row_idx <= PAD + PADDED_OH - 1) &&
    (orig_ofmap_col_idx >= PAD) && (orig_ofmap_col_idx <= PAD + PADDED_OW - 1);
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) in_padding_region_buf <= {IN_PAD_REGION_DELAY{1'b0}};
        else in_padding_region_buf <= {in_padding_region_buf[IN_PAD_REGION_DELAY -2 : 0], in_padding_region};
    end    
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) ofmap_addr <= {OFMAP_AWIDTH{1'b0}};
        else if(is_write_done && !PAD) 
            ofmap_addr <= (orig_ofmap_row_idx * ORIG_OW + orig_ofmap_col_idx) 
            + (ORIG_OW * ORIG_OH * captured_ifmap_out_channel);
        else if(is_write_done && PAD) begin
            if(in_padding_region)
            ofmap_addr <= (orig_ofmap_row_idx-PAD) * PADDED_OH + (orig_ofmap_col_idx-PAD) + (PADDED_OW * PADDED_OH * captured_ifmap_out_channel);     
            else ;  // intentionally left blank: no address update for out-of-bound padding
        end 
    end
    
    
    
    // -*-*-*-*-*-* OFMAP CE / WE  -*-*-*-*-*-
    wire ofmap_ce0;
    wire ofmap_we0;
    //
    assign ofmap_ce0 = (o_read && !is_read_done) || (o_write && !is_write_done);
    assign ofmap_we0 = (o_write && !is_write_done);
    
    
    
    // -*-*-*-*-*-* INTERMEDIATE BUFFER -*-*-*-*-*-*
    reg  signed [FW * FH * MULT_BITS -1 : 0]  intermediate_buf;
    //
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) intermediate_buf <= {FW * FH * MULT_BITS{1'b0}};
        else intermediate_buf <= &o_valid ? intermediate : intermediate_buf;
    end
    
    
    // DEBUG
    wire signed [OFMAP_BITS -1 : 0] a_pixel_of_intermediate = 
    {{OFMAP_BITS-MULT_BITS{intermediate_buf[((FW * FH) - ((intermediate_row_idx * FH + intermediate_col_idx))) * MULT_BITS -1]}}, intermediate_buf[((FW * FH) - ((intermediate_row_idx * FH + intermediate_col_idx))) * MULT_BITS  -1 -: MULT_BITS]};
    //
    reg signed  [OFMAP_BITS -1 : 0] a_pixel_of_intermediate_buf;
    //
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) a_pixel_of_intermediate_buf <= {OFMAP_BITS{1'b0}};
        else if(ofmap_ce0) a_pixel_of_intermediate_buf <= a_pixel_of_intermediate;
    end
    
    
    
    // -*-*-*-*-*-* ACCUMULATION OF INTERMEDIATE VEC AND OFMAP VEC FROM OFMAP MEM  -*-*-*-*-*-
    reg signed [OFMAP_BITS -1 : 0] a_target;
    reg accum_signal;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            a_target <= {OFMAP_BITS{1'b0}};
            accum_signal <= 1'b0;
        end
        
        else if(o_read) a_target <= read_ofmap_value;
        
        
        else if(o_accum && !PAD) begin
            a_target <= a_target + a_pixel_of_intermediate_buf;
            accum_signal <= 1'b1;
        end
        
        else if(o_accum && PAD) begin
            if(in_padding_region_buf[IN_PAD_REGION_DELAY-1]) a_target <= a_target + a_pixel_of_intermediate_buf;
            accum_signal <= 1'b1;
        end
        
        else accum_signal <= 1'b0;
    end    
    
    // -*-*-*-*-*-* GEN Q,D VALID SIGNAL -*-*-*-*-*-
    reg d0_valid;
    reg q0_valid;
    
    reg d_val_trig;
    reg q_val_trig;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            q0_valid <= 1'b0;
            q_val_trig <= 1'b0;
        end
        
        else if(o_read && !q_val_trig) begin
            q_val_trig <= 1'b1;
            q0_valid <= 1'b0;        
        end
        
        else if(o_read && q_val_trig) begin 
            q_val_trig <= 1'b0;
            q0_valid <= 1'b1;
        end
    end
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            d0_valid <= 1'b0;
            d_val_trig <= 1'b0;
        end
        
        else if(o_write && !d_val_trig) begin
            d_val_trig <= 1'b1;
            d0_valid <= 1'b0;        
        end
        
        else if(o_write && d_val_trig) begin 
            d_val_trig <= 1'b0;
            d0_valid <= 1'b1;
        end         
    end
    
    
        
    // -*-*-*-*-*-* INSTANTIATION OF OFMAP MEM -*-*-*-*-*-
    wire signed [OFMAP_BITS -1 : 0] read_ofmap_value;
    wire signed [OFMAP_BITS -1 : 0] write_ofmap_value;
    
    assign write_ofmap_value = a_target;    
     
    dpbram#
    (
        .AWIDTH         (OFMAP_AWIDTH),
        .DWIDTH         (OFMAP_DWIDTH),
        .MEM_DEPTH      (OFMAP_MEM_DEPTH)
    ) ofmap_memory
    (
        .clk            (clk),
        //
        .addr0          (ofmap_addr),
        .ce0            (ofmap_ce0),
        .we0            (ofmap_we0),
        //
        .d0             (write_ofmap_value),
        .q0             (read_ofmap_value)
    );
    
    
    
    // -*-*-*-*-*-* MAKE OFMAP -*-*-*-*-*-
    reg signed [OW * OH * OUT_C * OFMAP_BITS -1 : 0] ofmap_reg;
    reg [OFMAP_AWIDTH -1 : 0] ofmap_mem_addr;
    reg ofmap_mem_ce;
    reg ofmap_generate_success_reg;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            ofmap_reg <= {OW * OH * OFMAP_BITS{1'b0}};
            ofmap_mem_addr <= {OFMAP_AWIDTH{1'b0}};
            ofmap_mem_ce <= 1'b0;
            ofmap_generate_success_reg <= 1'b0;
        end
        //
        else if(i_done_from_CT) ofmap_mem_ce <= 1'b1;
        //
        else if(ofmap_mem_addr == OFMAP_MEM_DEPTH) begin
            ofmap_mem_ce <= 1'b0;
            ofmap_mem_addr <= {OFMAP_AWIDTH{1'b0}};
            ofmap_generate_success_reg <= 1'b1;
        end
        //
        else if(ofmap_mem_ce) begin
            ofmap_reg[((OW * OH * OUT_C) - ofmap_mem_addr) * OFMAP_BITS -1 -: OFMAP_BITS] <= $signed((ofmap_memory.ram[ofmap_mem_addr]));
            ofmap_mem_addr <= ofmap_mem_addr + 1'b1;
        end
    end
    
    assign ofmap = ofmap_reg;
    assign ofmap_generate_success = ofmap_generate_success_reg;
endmodule
