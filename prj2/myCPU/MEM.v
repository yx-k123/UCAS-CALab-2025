module MEM(
    input wire clk           ,
    input wire reset         ,

    input wire wb_allowin    ,
    output wire mem_allowin    ,

    input wire ex_to_mem_valid,
    input wire [103:0] ex_reg  ,

    output wire mem_to_wb_valid,
    output wire [69:0] mem_reg  ,

    input wire [31:0] data_sram_rdata
);

reg mem_valid;
wire mem_ready_go;

reg [103:0] ex_reg_r;
assign mem_ready_go    = 1'b1;
assign mem_allowin     = !mem_valid || mem_ready_go && wb_allowin;
assign mem_to_wb_valid = mem_valid && mem_ready_go;
always @(posedge clk) begin
    if (reset) begin
        mem_valid <= 1'b0;
    end
    else if (mem_allowin) begin
        mem_valid <= ex_to_mem_valid;
    end

    if (ex_to_mem_valid && mem_allowin) begin
        ex_reg_r <= ex_reg;
    end
end

wire res_from_mem;
wire mem_we;
wire gr_we;
wire [4:0] dest;
wire [31:0] ex_alu_result;
wire [31:0] rkd_value;
wire [31:0] mem_pc;

assign {
    res_from_mem,   // 是否是加载指令
    mem_we,         // 是否是存储指令
    gr_we,          // 是否写回寄存器堆
    dest,           // 目标寄存器编号
    ex_alu_result,  // ALU 计算结果（访存地址或写回数据）
    rkd_value,      // 存储指令的写入数据
    mem_pc           // 当前指令的 PC 值
} = ex_reg_r;

wire [31:0] mem_result;
wire [31:0] final_result;

assign mem_result   = data_sram_rdata;
assign final_result = res_from_mem ? mem_result : ex_alu_result;

assign mem_reg = {
    gr_we,          // 是否写回寄存器堆
    dest,           // 目标寄存器编号
    final_result,   // 最终写回寄存器堆的数据
    mem_pc           // 当前指令的 PC 值
};

endmodule
