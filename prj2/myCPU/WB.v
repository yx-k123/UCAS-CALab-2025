module WB(
    input wire clk,
    input wire reset,

    output wire wb_allowin,

    input wire mem_to_wb_valid,
    input wire [69:0] mem_reg,

    output wire [37:0] wb_to_rf_reg,

    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,

    output wire        wb_valid_o,
    output wire        wb_gr_we_o,
    output wire [4:0]  wb_dest_o
);

reg         wb_valid;
wire        wb_ready_go;
reg [69:0] mem_reg_r;

assign wb_ready_go = 1'b1;
assign wb_allowin  = !wb_valid || wb_ready_go;
always @(posedge clk) begin
    if (reset) begin
        wb_valid <= 1'b0;
    end
    else if (wb_allowin) begin
        wb_valid <= mem_to_wb_valid;
    end

    if (mem_to_wb_valid && wb_allowin) begin
        mem_reg_r <= mem_reg;
    end
end

wire        wb_gr_we;
wire [ 4:0] wb_dest;
wire [31:0] wb_final_result;
wire [31:0] wb_pc;

assign {wb_gr_we       ,  //69:69
        wb_dest        ,  //68:64
        wb_final_result,  //63:32
        wb_pc             //31:0
       } = mem_reg_r;

wire        rf_we;
wire [4 :0] rf_waddr;
wire [31:0] rf_wdata;
assign wb_to_rf_reg = {rf_we   ,  //37:37
                       rf_waddr,  //36:32
                       rf_wdata   //31:0
                      };

assign rf_we    = wb_gr_we&&wb_valid;
assign rf_waddr = wb_dest;
assign rf_wdata = wb_final_result;

// debug info generate
assign debug_wb_pc       = wb_pc;
assign debug_wb_rf_we    = {4{rf_we}};
assign debug_wb_rf_wnum  = wb_dest;
assign debug_wb_rf_wdata = wb_final_result;

assign wb_valid_o  = wb_valid;
assign wb_gr_we_o  = wb_gr_we && wb_valid;
assign wb_dest_o   = wb_dest;

endmodule
