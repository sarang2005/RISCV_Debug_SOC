//==============================================================
//  Testbench Skeleton for debug_module_top
//==============================================================
`timescale 1ns/1ps

module tb_debug_module_top;

    //----------------------------------------------------------
    // Clock and Reset
    //----------------------------------------------------------
    logic clk;
    logic rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 100 MHz
    end

    initial begin
        rst_n = 0;
        repeat (10) @(posedge clk);
        rst_n = 1;
    end

    //----------------------------------------------------------
    // APB Interface
    //----------------------------------------------------------
    logic         psel;
    logic         penable;
    logic         pwrite;
    logic [31:0]  paddr;
    logic [31:0]  pwdata;
    logic [31:0]  prdata;
    logic         pready;
    logic         pslverr;

    //----------------------------------------------------------
    // AXI Master 0 (Memory)
    //----------------------------------------------------------
    // Wish: You can replace AXI signals with a BFM wrapper.
    // For now: declare them as simple logic and drive minimal behavior.

    logic [63:0]  mem_awaddr;
    logic         mem_awvalid;
    logic         mem_awready;

    logic [63:0]  mem_wdata;
    logic [7:0]   mem_wstrb;
    logic         mem_wvalid;
    logic         mem_wready;

    logic [1:0]   mem_bresp;
    logic         mem_bvalid;
    logic         mem_bready;

    logic [63:0]  mem_araddr;
    logic         mem_arvalid;
    logic         mem_arready;

    logic [63:0]  mem_rdata;
    logic [1:0]   mem_rresp;
    logic         mem_rvalid;
    logic         mem_rready;

    //----------------------------------------------------------
    // AXI Master 1 (Core)
    //----------------------------------------------------------
    logic [63:0]  core_awaddr;
    logic         core_awvalid;
    logic         core_awready;

    logic [63:0]  core_wdata;
    logic [7:0]   core_wstrb;
    logic         core_wvalid;
    logic         core_wready;

    logic [1:0]   core_bresp;
    logic         core_bvalid;
    logic         core_bready;

    logic [63:0]  core_araddr;
    logic         core_arvalid;
    logic         core_arready;

    logic [63:0]  core_rdata;
    logic [1:0]   core_rresp;
    logic         core_rvalid;
    logic         core_rready;

    //----------------------------------------------------------
    // Debug Control Outputs
    //----------------------------------------------------------
    logic dmactive;
    logic core_halted;
    logic core_running;
    logic core_hreset;
    logic core_ndmreset;

    //----------------------------------------------------------
    // DUT Instantiation
    //----------------------------------------------------------
    debug_module_top dut (
        .clk(clk),
        .rst_n(rst_n),

        // APB
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),
        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr),

        // Memory AXI
        .axi_mem_awaddr(mem_awaddr),
        .axi_mem_awvalid(mem_awvalid),
        .axi_mem_awready(mem_awready),
        .axi_mem_wdata(mem_wdata),
        .axi_mem_wstrb(mem_wstrb),
        .axi_mem_wvalid(mem_wvalid),
        .axi_mem_wready(mem_wready),
        .axi_mem_bresp(mem_bresp),
        .axi_mem_bvalid(mem_bvalid),
        .axi_mem_bready(mem_bready),
        .axi_mem_araddr(mem_araddr),
        .axi_mem_arvalid(mem_arvalid),
        .axi_mem_arready(mem_arready),
        .axi_mem_rdata(mem_rdata),
        .axi_mem_rresp(mem_rresp),
        .axi_mem_rvalid(mem_rvalid),
        .axi_mem_rready(mem_rready),

        // Core AXI
        .axi_core_awaddr(core_awaddr),
        .axi_core_awvalid(core_awvalid),
        .axi_core_awready(core_awready),
        .axi_core_wdata(core_wdata),
        .axi_core_wstrb(core_wstrb),
        .axi_core_wvalid(core_wvalid),
        .axi_core_wready(core_wready),
        .axi_core_bresp(core_bresp),
        .axi_core_bvalid(core_bvalid),
        .axi_core_bready(core_bready),
        .axi_core_araddr(core_araddr),
        .axi_core_arvalid(core_arvalid),
        .axi_core_arready(core_arready),
        .axi_core_rdata(core_rdata),
        .axi_core_rresp(core_rresp),
        .axi_core_rvalid(core_rvalid),
        .axi_core_rready(core_rready),

        // Debug signals
        .dmactive(dmactive),
        .core_halted(core_halted),
        .core_running(core_running),
        .core_hreset(core_hreset),
        .core_ndmreset(core_ndmreset)
    );

    //----------------------------------------------------------
    // APB Tasks
    //----------------------------------------------------------
    task apb_write32(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            psel   = 1;
            pwrite = 1;
            penable= 0;
            paddr  = addr;
            pwdata = data;

            @(posedge clk);
            penable = 1;

            wait (pready);
            @(posedge clk);
            psel = 0;
            penable = 0;
        end
    endtask

    task apb_read32(input [31:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            psel   = 1;
            pwrite = 0;
            penable= 0;
            paddr  = addr;

            @(posedge clk);
            penable = 1;

            wait (pready);
            data = prdata;

            @(posedge clk);
            psel = 0;
            penable = 0;
        end
    endtask

    //----------------------------------------------------------
    // AXI Memory Stub Behavior
    //----------------------------------------------------------
    initial begin
        mem_awready = 1;
        mem_wready  = 1;
        mem_bvalid  = 0;
        mem_arready = 1;
        mem_rvalid  = 0;
        mem_rdata   = 64'h0;

        forever begin
            @(posedge clk);

            // Memory write ack
            if (mem_awvalid && mem_wvalid) begin
                mem_bvalid <= 1;
                mem_bresp  <= 2'b00; // OK
            end
            else if (mem_bready)
                mem_bvalid <= 0;

            // Memory read response
            if (mem_arvalid) begin
                mem_rvalid <= 1;
                mem_rdata  <= 64'hDEAD_BEEF_1234_5678;
                mem_rresp  <= 2'b00;
            end
            else if (mem_rready)
                mem_rvalid <= 0;
        end
    end

    //----------------------------------------------------------
    // AXI Core Stub Behavior
    //----------------------------------------------------------
    initial begin
        core_awready = 1;
        core_wready  = 1;
        core_bvalid  = 0;
        core_arready = 1;
        core_rvalid  = 0;

        forever begin
            @(posedge clk);

            // Core write response
            if (core_awvalid && core_wvalid) begin
                core_bvalid <= 1;
                core_bresp  <= 2'b00; // OK
            end
            else if (core_bready)
                core_bvalid <= 0;

            // Core register read response
            if (core_arvalid) begin
                core_rvalid <= 1;
                core_rdata  <= 64'hFACE_CAFE_0000_0005;
                core_rresp  <= 2'b00;
            end
            else if (core_rready)
                core_rvalid <= 0;
        end
    end

    //----------------------------------------------------------
    // Stimulus
    //----------------------------------------------------------
    initial begin
        @(posedge rst_n);

        $display("------ Starting Debug Module Test ------");

        // Example: write dmcontrol (activate DM)
        apb_write32(32'h10, 32'h00000001);  // dmcontrol.dmactive = 1

        // Example: read dmstatus
        logic [31:0] rd;
        apb_read32(32'h11, rd);
        $display("DMSTATUS = %h", rd);

        // Example: abstract command to read memory, abstractcmd = read
        apb_write32(32'h17, 32'h00000001);  // example command

        repeat (20) @(posedge clk);

        $display("------ Test Finished ------");
        $finish;
    end

endmodule


