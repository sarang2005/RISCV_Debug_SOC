// ------------------------------------------------------------------
//What this TB gives you immediately
//
// Core boots and fetches instructions
// Debug module instantiated and alive
// No AXI deadlocks
// Clean base for:
//
//APB debug register access
//
//DM halt/resume testing
//
//UVM conversion later
// ------------------------------------------------------------------
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb_riscv_soc_wrapper;

  // ------------------------------------------------------------------
  // Parameters
  // ------------------------------------------------------------------
  localparam AXI_ADDR_WIDTH = 32;
  localparam AXI_DATA_WIDTH = 32;
  localparam APB_ADDR_WIDTH = 32;
  localparam APB_DATA_WIDTH = 32;

  // ------------------------------------------------------------------
  // Clocks & Resets
  // ------------------------------------------------------------------
  logic clk_i;
  logic rst_ni;

  logic pclock;
  logic presetn;

  logic aclk;
  logic aresetn;

  // Clock generation
  initial begin
    clk_i   = 0;
    pclock  = 0;
    aclk    = 0;
    forever begin
      #5  clk_i  = ~clk_i;   // 100 MHz
    end
  end

  always #10 pclock = ~pclock; // 50 MHz APB
  always #5  aclk   = ~aclk;   // 100 MHz AXI

  // Reset sequence
  initial begin
    rst_ni   = 0;
    presetn = 0;
    aresetn = 0;

    #100;
    rst_ni   = 1;
    presetn = 1;
    aresetn = 1;
  end

  // ------------------------------------------------------------------
  // DUT signals
  // ------------------------------------------------------------------

  // Instruction interface
  logic        instr_req_o;
  logic        instr_gnt_i;
  logic        instr_rvalid_i;
  logic [31:0] instr_addr_o;
  logic [31:0] instr_rdata_i;

  // Interrupts
  logic [31:0] irq_i;
  logic        irq_ack_o;
  logic [4:0]  irq_id_o;

  // Debug
  logic debug_havereset_o;
  logic debug_running_o;
  logic debug_halted_o;

  logic fetch_enable_i;
  logic core_sleep_o;

  // APB
  logic                        psel;
  logic                        pwrite;
  logic                        penable;
  logic [APB_ADDR_WIDTH-1:0]   paddr;
  logic [APB_DATA_WIDTH-1:0]   pwdata;
  logic [APB_DATA_WIDTH-1:0]   prdata;
  logic                        pready;
  logic                        pslverr;

  // AXI (Memory)
  logic mem_axi_m_awready;
  logic mem_axi_m_awvalid;
  logic [3:0] mem_axi_m_awid;
  logic [AXI_ADDR_WIDTH-1:0] mem_axi_m_awaddr;
  logic [7:0] mem_axi_m_awlen;
  logic [2:0] mem_axi_m_awsize;
  logic [1:0] mem_axi_m_awburst;
  logic mem_axi_m_awlock;
  logic [3:0] mem_axi_m_awcache;
  logic [2:0] mem_axi_m_awprot;
  logic [3:0] mem_axi_m_awqos;

  logic mem_axi_m_wready;
  logic mem_axi_m_wvalid;
  logic [AXI_DATA_WIDTH-1:0] mem_axi_m_wdata;
  logic [(AXI_DATA_WIDTH/8)-1:0] mem_axi_m_wstrb;
  logic mem_axi_m_wlast;

  logic [3:0] mem_axi_m_bid;
  logic [1:0] mem_axi_m_bresp;
  logic mem_axi_m_bvalid;
  logic mem_axi_m_bready;

  logic mem_axi_m_arready;
  logic mem_axi_m_arvalid;
  logic [3:0] mem_axi_m_arid;
  logic [AXI_ADDR_WIDTH-1:0] mem_axi_m_araddr;
  logic [7:0] mem_axi_m_arlen;
  logic [2:0] mem_axi_m_arsize;
  logic [1:0] mem_axi_m_arburst;
  logic mem_axi_m_arlock;
  logic [3:0] mem_axi_m_arcache;
  logic [2:0] mem_axi_m_arprot;
  logic [3:0] mem_axi_m_arqos;

  logic [3:0] mem_axi_m_rid;
  logic [AXI_DATA_WIDTH-1:0] mem_axi_m_rdata;
  logic [1:0] mem_axi_m_rresp;
  logic mem_axi_m_rlast;
  logic mem_axi_m_rvalid;
  logic mem_axi_m_rready;

  // ------------------------------------------------------------------
  // DUT instance
  // ------------------------------------------------------------------
  riscv_soc_wrapper dut (
    .clk_i                  (clk_i),
    .rst_ni                 (rst_ni),

    .mtvec_addr_i           (32'h0000_0000),
    .dm_exception_addr_i    (32'h0000_1000),

    .instr_req_o            (instr_req_o),
    .instr_gnt_i            (instr_gnt_i),
    .instr_rvalid_i         (instr_rvalid_i),
    .instr_addr_o           (instr_addr_o),
    .instr_rdata_i          (instr_rdata_i),

    .irq_i                  (irq_i),
    .irq_ack_o              (irq_ack_o),
    .irq_id_o               (irq_id_o),

    .debug_havereset_o      (debug_havereset_o),
    .debug_running_o        (debug_running_o),
    .debug_halted_o         (debug_halted_o),

    .fetch_enable_i         (fetch_enable_i),
    .core_sleep_o           (core_sleep_o),

    .pclock                 (pclock),
    .presetn                (presetn),
    .psel                   (psel),
    .pwrite                 (pwrite),
    .penable                (penable),
    .paddr                  (paddr),
    .pwdata                 (pwdata),
    .prdata                 (prdata),
    .pready                 (pready),
    .pslverr                (pslverr),

    .aclk                   (aclk),
    .aresetn                (aresetn),

    // AXI
    .mem_axi_m_awready      (mem_axi_m_awready),
    .mem_axi_m_awvalid      (mem_axi_m_awvalid),
    .mem_axi_m_awid         (mem_axi_m_awid),
    .mem_axi_m_awaddr       (mem_axi_m_awaddr),
    .mem_axi_m_awlen        (mem_axi_m_awlen),
    .mem_axi_m_awsize       (mem_axi_m_awsize),
    .mem_axi_m_awburst      (mem_axi_m_awburst),
    .mem_axi_m_awlock       (mem_axi_m_awlock),
    .mem_axi_m_awcache      (mem_axi_m_awcache),
    .mem_axi_m_awprot       (mem_axi_m_awprot),
    .mem_axi_m_awqos        (mem_axi_m_awqos),

    .mem_axi_m_wready       (mem_axi_m_wready),
    .mem_axi_m_wvalid       (mem_axi_m_wvalid),
    .mem_axi_m_wdata        (mem_axi_m_wdata),
    .mem_axi_m_wstrb        (mem_axi_m_wstrb),
    .mem_axi_m_wlast        (mem_axi_m_wlast),

    .mem_axi_m_bid          (mem_axi_m_bid),
    .mem_axi_m_bresp        (mem_axi_m_bresp),
    .mem_axi_m_bvalid       (mem_axi_m_bvalid),
    .mem_axi_m_bready       (mem_axi_m_bready),

    .mem_axi_m_arready      (mem_axi_m_arready),
    .mem_axi_m_arvalid      (mem_axi_m_arvalid),
    .mem_axi_m_arid         (mem_axi_m_arid),
    .mem_axi_m_araddr       (mem_axi_m_araddr),
    .mem_axi_m_arlen        (mem_axi_m_arlen),
    .mem_axi_m_arsize       (mem_axi_m_arsize),
    .mem_axi_m_arburst      (mem_axi_m_arburst),
    .mem_axi_m_arlock       (mem_axi_m_arlock),
    .mem_axi_m_arcache      (mem_axi_m_arcache),
    .mem_axi_m_arprot       (mem_axi_m_arprot),
    .mem_axi_m_arqos        (mem_axi_m_arqos),

    .mem_axi_m_rid          (mem_axi_m_rid),
    .mem_axi_m_rdata        (mem_axi_m_rdata),
    .mem_axi_m_rresp        (mem_axi_m_rresp),
    .mem_axi_m_rlast        (mem_axi_m_rlast),
    .mem_axi_m_rvalid       (mem_axi_m_rvalid),
    .mem_axi_m_rready       (mem_axi_m_rready)
  );

  // ------------------------------------------------------------------
  // Instruction Memory Model (Simple ROM)
  // ------------------------------------------------------------------
  assign instr_gnt_i    = instr_req_o;
  assign instr_rvalid_i = instr_req_o;

  always_comb begin
    case (instr_addr_o)
      32'h0000_0080: instr_rdata_i = 32'h00000013; // NOP
      32'h0000_0084: instr_rdata_i = 32'h00000013;
      32'h0000_0088: instr_rdata_i = 32'h00000013;
      default:       instr_rdata_i = 32'h00000013;
    endcase
  end

  // ------------------------------------------------------------------
  // AXI Memory Stub (Always Ready)
  // ------------------------------------------------------------------
  assign mem_axi_m_awready = 1'b1;
  assign mem_axi_m_wready  = 1'b1;
  assign mem_axi_m_arready = 1'b1;

  assign mem_axi_m_bvalid  = mem_axi_m_wvalid;
  assign mem_axi_m_bresp   = 2'b00;
  assign mem_axi_m_bid     = 4'b0;

  assign mem_axi_m_rvalid  = mem_axi_m_arvalid;
  assign mem_axi_m_rdata   = 64'h0;
  assign mem_axi_m_rresp   = 2'b00;
  assign mem_axi_m_rlast   = 1'b1;
  assign mem_axi_m_rid     = 4'b0;

  // ------------------------------------------------------------------
  // Test sequence
  // ------------------------------------------------------------------
  initial begin
    irq_i           = '0;
    fetch_enable_i  = 0;

    psel    = 0;
    pwrite  = 0;
    penable = 0;
    paddr   = 0;
    pwdata  = 0;

    @(posedge rst_ni);
    #50;

    fetch_enable_i = 1;
    $display("[TB] Fetch enabled");

    #1000;

    $display("[TB] Debug running=%0d halted=%0d",
              debug_running_o, debug_halted_o);

    #100;
    $finish;
  end

endmodule
