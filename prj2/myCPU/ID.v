module ID(
    input wire clk,
    input wire reset,

    input wire ex_allowin,
    output wire id_allowin,

    input wire if_to_id_valid,
    input wire [63:0] if_reg,

    output wire id_to_ex_valid,
    output wire [151:0] id_reg,

    output wire [32:0] branch_reg,
    output wire br_taken_cancel,

    input wire [37:0] wb_to_rf_reg,

    input wire        ex_valid_o,
    input wire        ex_gr_we_o,
    input wire [4:0]  ex_dest_o,

    input wire        mem_valid_o,
    input wire        mem_gr_we_o,
    input wire [4:0]  mem_dest_o,

    input wire        wb_valid_o,
    input wire        wb_gr_we_o,
    input wire [4:0]  wb_dest_o
);

reg id_valid;
wire id_ready_go;

assign id_allowin = !id_valid || id_ready_go && ex_allowin;
assign id_to_ex_valid = id_valid && id_ready_go;

wire [31:0] id_pc;
wire [31:0] id_inst;
assign {id_inst, id_pc} = if_reg_r;

wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;
assign {rf_we, rf_waddr, rf_wdata} = wb_to_rf_reg; // 37,36:32,31:0

wire        br_taken;
wire [31:0] br_target;
assign branch_reg = {br_taken, br_target};

reg [63:0] if_reg_r;
always @(posedge clk) begin
    if (reset) begin
        id_valid <= 1'b0;
    end else if (br_taken_cancel) begin
        id_valid <= 1'b0;
    end else if (id_allowin) begin
        id_valid <= if_to_id_valid;
    end
    if (if_to_id_valid && id_allowin) begin
        if_reg_r <= if_reg;
    end
end

wire [11:0] alu_op;
wire        src1_is_pc;
wire        src2_is_imm;
wire        res_from_mem;
wire        gr_we;
wire        mem_we;
wire [ 4:0] dest;
wire [31:0] imm;

wire        inst_add_w;
wire        inst_sub_w;
wire        inst_slt;
wire        inst_sltu;
wire        inst_nor;
wire        inst_and;
wire        inst_or;
wire        inst_xor;
wire        inst_slli_w;
wire        inst_srli_w;
wire        inst_srai_w;
wire        inst_addi_w;
wire        inst_ld_w;
wire        inst_st_w;
wire        inst_jirl;
wire        inst_b;
wire        inst_bl;
wire        inst_beq;
wire        inst_bne;
wire        inst_lu12i_w;

wire        dst_is_r31;  
wire        dst_is_rt;   

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;

assign id_reg = { alu_op       ,  //151:140  12b
                  res_from_mem ,  //139:139  1b  
                  need_ui5     ,  //138:138  1b 
                  src1_is_pc   ,  //137:137  1b
                  src2_is_imm  ,  //136:136  1b
                  src2_is_4    ,  //135:135  1b  
                  gr_we        ,  //134:134  1b
                  mem_we       ,  //133:133  1b
                  dest         ,  //132:128  5b
                  imm          ,  //127:96   32b 
                  rj_value     ,  //95 :64   32b
                  rkd_value    ,  //63 :32   32b
                  id_pc           //31 :0    32b
                };

wire [5:0]  op_31_26;
wire [3:0]  op_25_22;
wire [1:0]  op_21_20;
wire [4:0]  op_19_15;

wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [3:0]  op_21_20_d;
wire [31:0] op_19_15_d;

wire [4:0] rd;
wire [4:0] rj;
wire [4:0] rk;

wire [11:0] i12;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;

wire need_ui5;
wire need_si12;
wire need_si16;
wire need_si20;
wire need_si26;
wire src2_is_4;
wire src_reg_is_rd;
wire dst_is_r1;
wire rj_eq_rd;

wire [31:0] rj_value;
wire [31:0] rkd_value;

wire [31:0] br_offs;
wire [31:0] jirl_offs;

assign op_31_26  = id_inst[31:26];
assign op_25_22  = id_inst[25:22];
assign op_21_20  = id_inst[21:20];
assign op_19_15  = id_inst[19:15];

assign rd   = id_inst[ 4: 0];
assign rj   = id_inst[ 9: 5];
assign rk   = id_inst[14:10];

assign i12  = id_inst[21:10];
assign i20  = id_inst[24: 5];
assign i16  = id_inst[25:10];
assign i26  = {id_inst[ 9: 0], id_inst[25:10]};

decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
assign inst_jirl   = op_31_26_d[6'h13];
assign inst_b      = op_31_26_d[6'h14];
assign inst_bl     = op_31_26_d[6'h15];
assign inst_beq    = op_31_26_d[6'h16];
assign inst_bne    = op_31_26_d[6'h17];
assign inst_lu12i_w= op_31_26_d[6'h05] & ~id_inst[25];

assign alu_op[ 0] = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w
                    | inst_jirl | inst_bl;
assign alu_op[ 1] = inst_sub_w;
assign alu_op[ 2] = inst_slt;
assign alu_op[ 3] = inst_sltu;
assign alu_op[ 4] = inst_and;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or;
assign alu_op[ 7] = inst_xor;
assign alu_op[ 8] = inst_slli_w;
assign alu_op[ 9] = inst_srli_w;
assign alu_op[10] = inst_srai_w;
assign alu_op[11] = inst_lu12i_w;

assign need_ui5   =  inst_slli_w | inst_srli_w | inst_srai_w;
assign need_si12  =  inst_addi_w | inst_ld_w | inst_st_w;
assign need_si16  =  inst_jirl | inst_beq | inst_bne;
assign need_si20  =  inst_lu12i_w;
assign need_si26  =  inst_b | inst_bl;
assign src2_is_4  =  inst_jirl | inst_bl;

assign imm = src2_is_4 ? 32'h4                      :
             need_si20 ? {i20[19:0], 12'b0}         :
/*need_ui5 || need_si12*/{{20{i12[11]}}, i12[11:0]} ;

assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
                             {{14{i16[15]}}, i16[15:0], 2'b0} ;

assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

assign src_reg_is_rd = inst_beq | inst_bne | inst_st_w;

assign src1_is_pc    = inst_jirl | inst_bl;

assign src2_is_imm   = inst_slli_w |
                       inst_srli_w |
                       inst_srai_w |
                       inst_addi_w |
                       inst_ld_w   |
                       inst_st_w   |
                       inst_lu12i_w|
                       inst_jirl   |
                       inst_bl     ;

assign res_from_mem  = inst_ld_w;
assign dst_is_r1     = inst_bl;

assign gr_we         = ~inst_st_w & ~inst_beq & ~inst_bne & ~inst_b;
assign mem_we        = inst_st_w;
assign dest          = dst_is_r1 ? 5'd1 : rd;

assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd :rk;
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
    );

assign rj_value  = rf_rdata1;
assign rkd_value = rf_rdata2;

assign rj_eq_rd = (rj_value == rkd_value);
assign br_taken = (   inst_beq  &&  rj_eq_rd
                   || inst_bne  && !rj_eq_rd
                   || inst_jirl
                   || inst_bl
                   || inst_b
                  ) && id_valid;
assign br_target = (inst_beq || inst_bne || inst_bl || inst_b) ? (id_pc + br_offs) : (rj_value + jirl_offs);
assign br_taken_cancel = br_taken && id_valid && id_ready_go;

wire rs1_en;   // 是否真正使用 rj
wire rs2_en;   // 是否真正使用第二源寄存器
wire [4:0] rs1 = rj;
wire [4:0] rs2 = src_reg_is_rd ? rd : rk;

assign rs1_en =
       inst_add_w | inst_sub_w | inst_slt  | inst_sltu |
       inst_nor   | inst_and   | inst_or   | inst_xor  |
       inst_slli_w| inst_srli_w| inst_srai_w|
       inst_addi_w| inst_ld_w  | inst_st_w |
       inst_jirl  | inst_beq   | inst_bne;  // 不含 bl/b/lu12i_w

assign rs2_en =
       inst_add_w | inst_sub_w | inst_slt  | inst_sltu |
       inst_nor   | inst_and   | inst_or   | inst_xor  |
       inst_beq   | inst_bne   | inst_st_w; // 第二源（rk 或 rd）

wire hazard_ex  = ex_valid_o  && ex_gr_we_o  && (ex_dest_o  != 5'd0) &&
                  ((rs1_en && rs1 == ex_dest_o) || (rs2_en && rs2 == ex_dest_o));
wire hazard_mem = mem_valid_o && mem_gr_we_o && (mem_dest_o != 5'd0) &&
                  ((rs1_en && rs1 == mem_dest_o) || (rs2_en && rs2 == mem_dest_o));
wire hazard_wb = wb_valid_o && wb_gr_we_o && (wb_dest_o != 5'd0) &&
                  ((rs1_en && rs1 == wb_dest_o) || (rs2_en && rs2 == wb_dest_o));

assign id_ready_go =!(hazard_ex | hazard_mem | hazard_wb);

endmodule