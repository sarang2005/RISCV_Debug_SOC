//Version 1.0

module tb();
  // JTAG connection
      
reg    jtag_tms_i     ; // JTAG test mode select
reg    jtag_tdi_i     ; // JTAG test data input
wire    jtag_tdo_o     ; // JTAG test data output

reg  jtag_tck_i     ; // JTAG test clock 
reg    jtag_nreset_i  ; // JTAG test reset 


reg pclock;
reg presetn;
reg psel;
reg pwrite;
reg penable;
reg [31:0] paddr;
reg [31:0] pwdata;
wire [31:0] prdata;
wire pready;
wire pslverr;

reg aclk;
reg aresetn;
reg         mem_axi_m_awready;
wire        mem_axi_m_awvalid;
wire  [3:0] mem_axi_m_awid; 
wire  [63:0]mem_axi_m_awaddr;
wire  [7:0] mem_axi_m_awlen;
wire  [2:0] mem_axi_m_awsize;
wire  [1:0] mem_axi_m_awburst; 
wire        mem_axi_m_awlock; 
wire  [3:0] mem_axi_m_awcache;
wire  [2:0] mem_axi_m_awprot;
wire  [3:0] mem_axi_m_awqos;
reg         mem_axi_m_wready;
wire        mem_axi_m_wvalid;
wire  [63:0]mem_axi_m_wdata;
wire  [7:0] mem_axi_m_wstrb;
wire        mem_axi_m_wlast;
reg [3:0]   mem_axi_m_bid;
reg [1:0]   mem_axi_m_bresp; 
reg         mem_axi_m_bvalid;
wire        mem_axi_m_bready;          
reg         mem_axi_m_arready;
wire        mem_axi_m_arvalid;
wire  [3:0] mem_axi_m_arid; 
wire  [63:0]mem_axi_m_araddr;
wire  [7:0] mem_axi_m_arlen;
wire  [2:0] mem_axi_m_arsize;
wire  [1:0] mem_axi_m_arburst; 
wire        mem_axi_m_arlock; 
wire  [3:0] mem_axi_m_arcache;
wire  [2:0] mem_axi_m_arprot;
wire  [3:0] mem_axi_m_arqos;
reg [3:0]   mem_axi_m_rid;
reg [63:0]  mem_axi_m_rdata;
reg [1:0]   mem_axi_m_rresp;
reg         mem_axi_m_rlast;
reg         mem_axi_m_rvalid;
wire        mem_axi_m_rready;
reg         core_axi_m_awready;
wire        core_axi_m_awvalid;
wire  [3:0] core_axi_m_awid; 
wire  [63:0]core_axi_m_awaddr;
wire  [7:0] core_axi_m_awlen;
wire  [2:0] core_axi_m_awsize;
wire  [1:0] core_axi_m_awburst; 
wire        core_axi_m_awlock; 
wire  [3:0] core_axi_m_awcache;
wire  [2:0] core_axi_m_awprot;
wire  [3:0] core_axi_m_awqos;
reg         core_axi_m_wready;
wire        core_axi_m_wvalid;
wire  [63:0]core_axi_m_wdata;
wire  [7:0] core_axi_m_wstrb;
wire        core_axi_m_wlast;
reg [3:0]   core_axi_m_bid;
reg [1:0]   core_axi_m_bresp; 
reg         core_axi_m_bvalid;
wire        core_axi_m_bready;          
reg         core_axi_m_arready;
wire        core_axi_m_arvalid;
wire  [3:0] core_axi_m_arid; 
wire  [63:0]core_axi_m_araddr;
wire  [7:0] core_axi_m_arlen;
wire  [2:0] core_axi_m_arsize;
wire  [1:0] core_axi_m_arburst; 
wire        core_axi_m_arlock; 
wire  [3:0] core_axi_m_arcache;
wire  [2:0] core_axi_m_arprot;
wire  [3:0] core_axi_m_arqos;
reg [3:0]   core_axi_m_rid;
reg [63:0]  core_axi_m_rdata;
reg [1:0]   core_axi_m_rresp;
reg         core_axi_m_rlast;
reg         core_axi_m_rvalid;
wire        core_axi_m_rready;

wire dmactive;
wire core_hart_ndmreset;
wire core_hart_running;
wire core_hart_halted;
wire core_hart_hreset;


debug_module_top dut (
//.pclock(pclock),
//.presetn(presetn),
//.psel(psel),
//.pwrite(pwrite),
//.penable(penable),
//.paddr(paddr),
//.pwdata(pwdata),
//.prdata(prdata),
//.pready(pready),
//.pslverr(pslverr),
//JTAG
    .jtag_tms_i    (jtag_tms_i    ), 
    .jtag_tck_i    (jtag_tck_i    ), 
    .jtag_nreset_i (jtag_nreset_i ), 
    .jtag_tdi_i    (jtag_tdi_i    ), 
    .jtag_tdo_o    (jtag_tdo_o    ), 










.aclk(aclk),
.aresetn(aresetn),
.mem_axi_m_awready(mem_axi_m_awready),
.mem_axi_m_awvalid(mem_axi_m_awvalid),
.mem_axi_m_awid(mem_axi_m_awid), 
.mem_axi_m_awaddr(mem_axi_m_awaddr),
.mem_axi_m_awlen(mem_axi_m_awlen),
.mem_axi_m_awsize(mem_axi_m_awsize),
.mem_axi_m_awburst(mem_axi_m_awburst),
.mem_axi_m_awlock(mem_axi_m_awlock), 
.mem_axi_m_awcache(mem_axi_m_awcache),
.mem_axi_m_awprot(mem_axi_m_awprot),
.mem_axi_m_awqos(mem_axi_m_awqos),
.mem_axi_m_wready(mem_axi_m_wready),
.mem_axi_m_wvalid(mem_axi_m_wvalid),
.mem_axi_m_wdata(mem_axi_m_wdata),
.mem_axi_m_wstrb(mem_axi_m_wstrb),
.mem_axi_m_wlast(mem_axi_m_wlast),
.mem_axi_m_bid(mem_axi_m_bid),
.mem_axi_m_bresp(mem_axi_m_bresp), 
.mem_axi_m_bvalid(mem_axi_m_bvalid),
.mem_axi_m_bready(mem_axi_m_bready),          
.mem_axi_m_arready(mem_axi_m_arready),
.mem_axi_m_arvalid(mem_axi_m_arvalid),
.mem_axi_m_arid(mem_axi_m_arid), 
.mem_axi_m_araddr(mem_axi_m_araddr),
.mem_axi_m_arlen(mem_axi_m_arlen),
.mem_axi_m_arsize(mem_axi_m_arsize),
.mem_axi_m_arburst(mem_axi_m_arburst), 
.mem_axi_m_arlock(mem_axi_m_arlock), 
.mem_axi_m_arcache(mem_axi_m_arcache),
.mem_axi_m_arprot(mem_axi_m_arprot),
.mem_axi_m_arqos(mem_axi_m_arqos),
.mem_axi_m_rid(mem_axi_m_rid),
.mem_axi_m_rdata(mem_axi_m_rdata),
.mem_axi_m_rresp(mem_axi_m_rresp),
.mem_axi_m_rlast(mem_axi_m_rlast),
.mem_axi_m_rvalid(mem_axi_m_rvalid),
.mem_axi_m_rready(mem_axi_m_rready),
.core_axi_m_awready(core_axi_m_awready),
.core_axi_m_awvalid(core_axi_m_awvalid),
.core_axi_m_awid(core_axi_m_awid),
.core_axi_m_awaddr(core_axi_m_awaddr),
.core_axi_m_awlen(core_axi_m_awlen),
.core_axi_m_awsize(core_axi_m_awsize),
.core_axi_m_awburst(core_axi_m_awburst),
.core_axi_m_awlock(core_axi_m_awlock), 
.core_axi_m_awcache(core_axi_m_awcache),
.core_axi_m_awprot(core_axi_m_awprot),
.core_axi_m_awqos(core_axi_m_awqos),
.core_axi_m_wready(core_axi_m_wready),
.core_axi_m_wvalid(core_axi_m_wvalid),
.core_axi_m_wdata(core_axi_m_wdata),
.core_axi_m_wstrb(core_axi_m_wstrb),
.core_axi_m_wlast(core_axi_m_wlast),
.core_axi_m_bid(core_axi_m_bid),
.core_axi_m_bresp(core_axi_m_bresp), 
.core_axi_m_bvalid(core_axi_m_bvalid),
.core_axi_m_bready(core_axi_m_bready),         
.core_axi_m_arready(core_axi_m_arready),
.core_axi_m_arvalid(core_axi_m_arvalid),
.core_axi_m_arid(core_axi_m_arid),
.core_axi_m_araddr(core_axi_m_araddr),
.core_axi_m_arlen(core_axi_m_arlen),
.core_axi_m_arsize(core_axi_m_arsize),
.core_axi_m_arburst(core_axi_m_arburst), 
.core_axi_m_arlock(core_axi_m_arlock), 
.core_axi_m_arcache(core_axi_m_arcache),
.core_axi_m_arprot(core_axi_m_arprot),
.core_axi_m_arqos(core_axi_m_arqos),
.core_axi_m_rid(core_axi_m_rid),
.core_axi_m_rdata(core_axi_m_rdata),
.core_axi_m_rresp(core_axi_m_rresp),
.core_axi_m_rlast(core_axi_m_rlast),
.core_axi_m_rvalid(core_axi_m_rvalid),
.core_axi_m_rready(core_axi_m_rready),
.dmactive(dmactive),
.core_hart_ndmreset(core_hart_ndmreset),
.core_hart_running(core_hart_running),
.core_hart_halted(core_hart_halted),
.core_hart_hreset(core_hart_hreset) );

always
#5 pclock = ~pclock;

always
#2 aclk = ~aclk;

initial
begin
presetn = 1'b0;
#5;
presetn = 1'b1;
end

initial
begin
aresetn = 1'b0;
#2;
aresetn = 1'b1;
end


initial
begin
pclock = 1'b0;
presetn = 1'b0;
psel = 1'b0;
pwrite = 1'b0;
penable = 1'b0;
paddr =- 32'b0;
pwdata = 32'b0;
aclk = 1'b0;
aresetn = 1'b0;
mem_axi_m_awready = 1'b0;
mem_axi_m_wready = 1'b0;
mem_axi_m_bid = 4'b0;
mem_axi_m_bresp = 2'b0;
mem_axi_m_bvalid = 1'b0;
mem_axi_m_arready = 1'b0;
mem_axi_m_rid = 4'b0;
mem_axi_m_rresp = 2'b0;
mem_axi_m_rdata = 64'b0;
mem_axi_m_rlast = 1'b0;
mem_axi_m_rvalid = 1'b0;
core_axi_m_awready = 1'b0;
core_axi_m_wready = 1'b0;
core_axi_m_bid = 4'b0;
core_axi_m_bresp = 2'b0;
core_axi_m_bvalid = 1'b0;
core_axi_m_arready = 1'b0;
core_axi_m_rid = 4'b0;
core_axi_m_rresp = 2'b0;
core_axi_m_rdata = 64'b0;
core_axi_m_rlast = 1'b0;
core_axi_m_rvalid = 1'b0;
#20;
psel = 1'b1;
pwrite = 1'b1;
paddr = 32'h00000010;
pwdata = 32'h00000003;
#10;
penable = 1'b1;
#30;
pwdata = 32'h20000003;
#30;
pwdata = 32'h0000000b;
#10;
pwrite = 1'b0;
#100;
$finish;
end


initial
begin
$dumpfile("wave.vcd");
$dumpvars(0,tb);
end

endmodule
