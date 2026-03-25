//  Copyright 2025 Sarang Purnaye <sarang.p@acldigital.com>
// Copyright and related rights are reserved with ACLK Digital 
// you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// www.acldigital.com
// Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Wrapper for a riscv_soc_wrapper for testbench, containing core and Debug Module 
// Contributor: Sarang Purnaye <sarang.p@acldigital.com>
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-0.51

//
//                +-------------------+
//                |   Debug Module    |
//                |                   |
// JTAG---------->|  DM Registers     |
//                |                   |
//                |  core_axi_m_* ----+----+
//                +-------------------+    |
//                                             AXI
//                +-------------------+    | Interconnect
//                |   RISC-V Core     |    |
//                |                   |    |
//                | data_* ---------- +----+
//                +-------------------+
//                         |
//                      Instruction IF
//                         |
//                       Memory
//
//------------------------------------------------------------------------------------------
`timescale 1ns/1ps
module riscv_soc_wrapper #(
//CORE PARAMETERS
parameter           INSTR_RDATA_WIDTH = 32                               ,
parameter           RAM_ADDR_WIDTH    = 20                               ,
parameter           BOOT_ADDR         = 'h80                             ,
parameter           DM_HALTADDRESS    = 32'h1A11_0800                    ,
parameter           HART_ID           = 32'h0000_0000                    ,
// Parameters used by DUT
parameter           PULP_XPULP        = 0                                ,
parameter           PULP_CLUSTER      = 0                                ,
parameter           FPU               = 0                                ,
parameter           PULP_ZFINX        = 0                                ,
parameter           NUM_MHPMCOUNTERS  = 1                                ,
//DM PARAMETERS
parameter           AXI_ADDR_WIDTH    = 32                               ,
parameter           AXI_DATA_WIDTH    = 32                               ,
parameter           APB_ADDR_WIDTH    = 32                               ,
parameter           APB_DATA_WIDTH    = 32                               , 
parameter           DBG_ADDR_WIDTH    = 32                               , 
parameter           DBG_DATA_WIDTH    = 32                               
)(
   // Clock and Reset
    input logic clk_i,
    input logic rst_ni,


    // Core ID, Cluster ID, debug mode halt address and boot address are considered more or less static
    input logic [31:0] mtvec_addr_i,
    input logic [31:0] dm_exception_addr_i,

    // Instruction memory interface
    output logic        instr_req_o,
    input  logic        instr_gnt_i,
    input  logic        instr_rvalid_i,
    output logic [31:0] instr_addr_o,
    input  logic [31:0] instr_rdata_i,

 
//    // core apu-interconnect
//    // handshake signals
//    output logic                              apu_req_o,
//    input  logic                              apu_gnt_i,
//    // request channel
//    output logic [   APU_NARGS_CPU-1:0][31:0] apu_operands_o,
//    output logic [     APU_WOP_CPU-1:0]       apu_op_o,
//    output logic [APU_NDSFLAGS_CPU-1:0]       apu_flags_o,
//    // response channel
//    input  logic                              apu_rvalid_i,
//    input  logic [                31:0]       apu_result_i,
//    input  logic [APU_NUSFLAGS_CPU-1:0]       apu_flags_i,

    // core Interrupt inputs
    input  logic [31:0] irq_i,  // CLINT interrupts + CLINT extension interrupts
    output logic        irq_ack_o,
    output logic [ 4:0] irq_id_o,

    // core Debug Interface
    //input  logic debug_req_i,
    output logic debug_havereset_o,
    output logic debug_running_o,
    output logic debug_halted_o,

    // core CPU Control Signals
    input  logic fetch_enable_i,
    output logic core_sleep_o,
///////////////////////////////////////////////
//  DM  Signals
////////////////////////////////////////////////  
    // JTAG connection
      
      input             jtag_tms_i                                 ,      // JTAG test mode select
      input             jtag_tck_i                                 ,      // JTAG test clock 
      input             jtag_nreset_i                              ,      // JTAG test reset 
      input             jtag_tdi_i                                 ,      // JTAG test data input
      output reg        jtag_tdo_o                                 ,      // JTAG test data output


 //AXI Master Interface signals to Memory
     input                            aclk                       ,
     input                            aresetn                    ,
     input                            mem_axi_m_awready          ,
     output                           mem_axi_m_awvalid          ,
     output [3:0]                     mem_axi_m_awid             , 
     output [AXI_ADDR_WIDTH-1:0]      mem_axi_m_awaddr           , 
     output [7:0]                     mem_axi_m_awlen            , 
     output [2:0]                     mem_axi_m_awsize           , 
     output [1:0]                     mem_axi_m_awburst          , 
     output                           mem_axi_m_awlock           , 
     output [3:0]                     mem_axi_m_awcache          ,
     output [2:0]                     mem_axi_m_awprot           ,
     output [3:0]                     mem_axi_m_awqos            ,
     input                            mem_axi_m_wready           ,
     output                           mem_axi_m_wvalid           ,
     output [AXI_DATA_WIDTH-1:0]      mem_axi_m_wdata            ,
     output [(AXI_DATA_WIDTH/8)-1:0]  mem_axi_m_wstrb            ,
     output                           mem_axi_m_wlast            ,
     input [3:0]                      mem_axi_m_bid              , 
     input [1:0]                      mem_axi_m_bresp            , 
     input                            mem_axi_m_bvalid           ,
     output                           mem_axi_m_bready           ,
     input                            mem_axi_m_arready          ,
     output                           mem_axi_m_arvalid          ,
     output [3:0]                     mem_axi_m_arid             , 
     output [AXI_ADDR_WIDTH-1:0]      mem_axi_m_araddr           ,
     output [7:0]                     mem_axi_m_arlen            ,
     output [2:0]                     mem_axi_m_arsize           ,
     output [1:0]                     mem_axi_m_arburst          ,
     output                           mem_axi_m_arlock           ,
     output [3:0]                     mem_axi_m_arcache          ,
     output [2:0]                     mem_axi_m_arprot           ,
     output [3:0]                     mem_axi_m_arqos            ,
     input [3:0]                      mem_axi_m_rid              , 
     input [AXI_DATA_WIDTH-1:0]       mem_axi_m_rdata            ,
     input [1:0]                      mem_axi_m_rresp            , 
     input                            mem_axi_m_rlast            ,
     input                            mem_axi_m_rvalid           ,
     output                           mem_axi_m_rready           
 
);

///////////////////////////////////////////////////////////////////////////////////////
//logic         clk_i ;
//logic         rst_ni;


//logic         fetch_enable_i ;
logic         tests_passed_o ;
logic         tests_failed_o ;
logic [31:0]  exit_value_o   ;
logic         exit_valid_o   ;

// signals connecting core to memory
logic                         instr_req;
logic                         instr_gnt;
logic                         instr_rvalid;
logic [31:0]                  instr_addr;
logic [INSTR_RDATA_WIDTH-1:0] instr_rdata;

logic                         data_req;
logic                         data_gnt;
logic                         data_rvalid;
logic [31:0]                  data_addr;
logic                         data_we;
logic [3:0]                   data_be;
logic [31:0]                  data_rdata;
logic [31:0]                  data_wdata;

// signals to debug unit
logic                         debug_req;

// irq signals (not used)
logic [0:31]                  irq;
logic [0:4]                   irq_id_in;
logic                         irq_ack;
logic [0:4]                   irq_id_out;
logic                         irq_sec;

// interrupts (only timer for now)
assign irq_sec     = '0;

////////////////////////////////////////////////////////////
// instantiate the core
    cv32e40p_core #(
                 .PULP_XPULP       (PULP_XPULP),
                 .PULP_CLUSTER     (PULP_CLUSTER),
                 .FPU              (FPU),
                 .PULP_ZFINX       (PULP_ZFINX),
                 .NUM_MHPMCOUNTERS (NUM_MHPMCOUNTERS)
                )
    cv32e40p_core_i
        (
         .clk_i                  ( clk_i                 ),
         .rst_ni                 ( rst_ni                ),

         .pulp_clock_en_i        ( '1                    ),
         .scan_cg_en_i           ( '0                    ),
   // Core ID, Cluster ID, debug mode halt address and boot address are considered more or less static
         .boot_addr_i            ( BOOT_ADDR             ),
         .dm_halt_addr_i         ( DM_HALTADDRESS        ),
         .hart_id_i              ( HART_ID               ),
    // Instruction memory interface

         .instr_req_o            ( instr_req_o           ),
         .instr_gnt_i            ( instr_gnt_i           ),
         .instr_rvalid_i         ( instr_rvalid_i        ),
         .instr_addr_o           ( instr_addr_o          ),
         .instr_rdata_i          ( instr_rdata_i         ),
    // Data memory interface

         .data_req_o             ( data_req              ),
         .data_gnt_i             ( data_gnt              ),
         .data_rvalid_i          ( data_rvalid           ),
         .data_we_o              ( data_we               ),
         .data_be_o              ( data_be               ),
         .data_addr_o            ( data_addr             ),
         .data_wdata_o           ( data_wdata            ),
         .data_rdata_i           ( data_rdata            ),
    // apu-interconnect
    // handshake signals

         .apu_req_o              (                       ),
         .apu_gnt_i              ( 1'b0                  ),
    // request channel
         .apu_operands_o         (                       ),
         .apu_op_o               (                       ),
         .apu_flags_o            (                       ),
    // response channel
         .apu_rvalid_i           ( 1'b0                  ),
         .apu_result_i           ( {32{1'b0}}            ),
         .apu_flags_i            ( {5{1'b0}}             ), // APU_NUSFLAGS_CPU

         // Interrupts verified in UVM environment
         .irq_i                  ( {32{1'b0}}            ),
         .irq_ack_o              ( irq_ack_o               ),
         .irq_id_o               ( irq_id_out            ),
    // Debug Interface

         .debug_req_i            ( debug_req             ),
    // CPU Control Signals

         .fetch_enable_i         ( fetch_enable_i        ),
         .core_sleep_o           ( core_sleep_o          )
       );

////////////////////////////////////////////////////////////

logic         core_axi_m_awready;
logic        core_axi_m_awvalid;
logic  [3:0] core_axi_m_awid; 
logic  [AXI_ADDR_WIDTH-1:0]core_axi_m_awaddr;
logic  [7:0] core_axi_m_awlen;
logic  [2:0] core_axi_m_awsize;
logic  [1:0] core_axi_m_awburst; 
logic        core_axi_m_awlock; 
logic  [3:0] core_axi_m_awcache;
logic  [2:0] core_axi_m_awprot;
logic  [3:0] core_axi_m_awqos;
logic         core_axi_m_wready;
logic        core_axi_m_wvalid;
logic  [AXI_DATA_WIDTH-1:0]core_axi_m_wdata;
logic  [(AXI_DATA_WIDTH/8)-1:0] core_axi_m_wstrb;
logic        core_axi_m_wlast;
logic [3:0]   core_axi_m_bid;
logic [1:0]   core_axi_m_bresp; 
logic         core_axi_m_bvalid;
logic        core_axi_m_bready;          
logic         core_axi_m_arready;
logic        core_axi_m_arvalid;
logic  [3:0] core_axi_m_arid; 
logic  [AXI_ADDR_WIDTH-1:0]core_axi_m_araddr;
logic  [7:0] core_axi_m_arlen;
logic  [2:0] core_axi_m_arsize;
logic  [1:0] core_axi_m_arburst; 
logic        core_axi_m_arlock; 
logic  [3:0] core_axi_m_arcache;
logic  [2:0] core_axi_m_arprot;
logic  [3:0] core_axi_m_arqos;
logic [3:0]   core_axi_m_rid;
logic [AXI_DATA_WIDTH-1:0]  core_axi_m_rdata;
logic [1:0]   core_axi_m_rresp;
logic         core_axi_m_rlast;
logic         core_axi_m_rvalid;
logic        core_axi_m_rready;

logic dmactive;
logic core_hart_ndmreset;
logic core_hart_running;
logic core_hart_halted;
logic core_hart_hreset;
////////////////////////////////////////////////////////////

debug_module_top dut (
 // JTAG connection

       .jtag_tms_i             (jtag_tms_i   ) ,      // JTAG test mode select
       .jtag_tck_i             (jtag_tck_i   ) ,      // JTAG test clock 
       .jtag_nreset_i          (jtag_nreset_i) ,   // JTAG test reset 
       .jtag_tdi_i             (jtag_tdi_i   ) ,      // JTAG test data input
       .jtag_tdo_o             (jtag_tdo_o   ) ,      // JTAG test data output

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
      .core_hart_hreset(core_hart_hreset) 
);
////////////////////////////////////////////////////////////
assign debug_req = core_hart_halted;

//? Limitations (Acceptable for Debug & Core)
//Feature	        Supported
//Single-beat	       Yes
//Byte enable	       Yes
//Outstanding txns	   NO
//Bursts	           NO
//Unaligned access	   NO (memory dependent)

cv32e40p_data2axi u_data2axi (
  .clk        ( clk_i ),
  .rst_n      ( rst_ni ),

  .data_req   ( data_req ),
  .data_we    ( data_we ),
  .data_be    ( data_be ),
  .data_addr  ( data_addr ),
  .data_wdata ( data_wdata ),
  .data_gnt   ( data_gnt ),
  .data_rvalid( data_rvalid ),
  .data_rdata ( data_rdata ),

  // AXI ? Interconnect
  .axi_awvalid( core_axi_m_awvalid ),
  .axi_awready( core_axi_m_awready ),
  .axi_awaddr ( core_axi_m_awaddr ),

  .axi_wvalid ( core_axi_m_wvalid ),
  .axi_wready ( core_axi_m_wready ),
  .axi_wdata  ( core_axi_m_wdata ),
  .axi_wstrb  ( core_axi_m_wstrb ),

  .axi_bvalid ( core_axi_m_bvalid ),
  .axi_bready ( core_axi_m_bready ),

  .axi_arvalid( core_axi_m_arvalid ),
  .axi_arready( core_axi_m_arready ),
  .axi_araddr ( core_axi_m_araddr ),

  .axi_rvalid ( core_axi_m_rvalid ),
  .axi_rready ( core_axi_m_rready ),
  .axi_rdata  ( core_axi_m_rdata )
);
// DM and CORE Interconnection
//data_we_o // output from core 
//data_be_o // output from core
//assign data_gnt_i          =  core_axi_m_wready;// valid logic adress
//assign core_axi_m_wvalid    = data_req_o ;
//assign core_axi_m_awaddr   = data_addr_o ;
//assign core_axi_m_wdata    = data_wdata_o ;
//
//assign data_rvalid_i =  core_axi_m_rvalid;
//assign data_rdata_i =   core_axi_m_rdata;
 
////////////////////////////////////////////////////////////
/*
 Core side connections 
.debug_req_i     ( debug_req            ), // from DM
.core_sleep_o    ( core_sleep_o         ),

Debug module side connections
.core_hart_running ( core_hart_running ),
.core_hart_halted  ( core_hart_halted  ),
.core_hart_hreset  ( core_hart_hreset  ),
.core_hart_ndmreset( core_hart_ndmreset)

*/ /*
        Debug Module (DM)                     Core / Hart
   +------------------------+          +------------------------+
   ¦                        ¦          ¦                        ¦
   ¦  dmactive              +---------?¦ (debug logic enable)   ¦
   ¦  core_hart_ndmreset    +---------?¦ reset input            ¦
   ¦  core_hart_hreset      +---------?¦ reset input            ¦
   ¦  core_hart_running     ?---------¦ debug_running_o        ¦
   ¦  core_hart_halted      ?---------¦ debug_halted_o         ¦
   ¦                        ¦          ¦                        ¦
   ¦                        ¦?---------¦ debug_havereset_o      ¦
   ¦                        ¦          ¦                        ¦
   ¦  debug_req_i (from DM) +---------?¦ debug_req_i            ¦
   +------------------------+          +------------------------+
*/


//assign core_hart_running = fetch_enable_i & ~debug_req;
//assign core_hart_halted  = debug_req;
//assign core_hart_hreset  = ~rst_ni;
////////////////////////////////////////////////////////////
/*
 Reset & Halt Rules
|Signal               | Meaning            |
| ------------------- | ------------------ |
| dmactive`           | Debug module alive |
| debug_req`          | Halt core          |
| core_hart_ndmreset` | Reset core only    |
| rst_ni`             | Global reset       |
 
assign debug_req = dmactive & debug_halt_req;


 
 */
  ////////////////////////////////////////////////////////////   
endmodule // riscv_soc_wrapper
