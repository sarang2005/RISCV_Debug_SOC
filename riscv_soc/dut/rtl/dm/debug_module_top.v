// Project: RISC-V Debug
// Company: ACL Digital
// Domain : RTL Design
// Author : Vinay Chowdary
// File   : debug_module_top file
// VErsion: 1.0

`timescale 1ns/1ps
module debug_module_top 
    #(
     parameter AXI_ADDR_WIDTH = 32                               ,
     parameter AXI_DATA_WIDTH = 32                               ,
     parameter APB_ADDR_WIDTH = 32                               ,
     parameter APB_DATA_WIDTH = 32                               , 
     parameter DBG_ADDR_WIDTH = 32                               , 
     parameter DBG_DATA_WIDTH = 32                               ) 
     (
      // JTAG connection
      
      input             jtag_tms_i,      // JTAG test mode select
      input             jtag_tck_i,      // JTAG test clock 
      input             jtag_nreset_i,   // JTAG test reset 
      input             jtag_tdi_i,      // JTAG test data input
      output reg        jtag_tdo_o,      // JTAG test data output

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
     output                           mem_axi_m_rready           ,
     
     //AXI Master Interface signals to RISC-V Core    
     input                            core_axi_m_awready         ,
     output                           core_axi_m_awvalid         ,
     output [3:0]                     core_axi_m_awid            , 
     output [AXI_ADDR_WIDTH-1:0]      core_axi_m_awaddr          , 
     output [7:0]                     core_axi_m_awlen           , 
     output [2:0]                     core_axi_m_awsize          , 
     output [1:0]                     core_axi_m_awburst         , 
     output                           core_axi_m_awlock          , 
     output [3:0]                     core_axi_m_awcache         ,
     output [2:0]                     core_axi_m_awprot          ,
     output [3:0]                     core_axi_m_awqos           ,
     input                            core_axi_m_wready          ,
     output                           core_axi_m_wvalid          ,
     output [AXI_DATA_WIDTH-1:0]      core_axi_m_wdata           ,
     output [(AXI_DATA_WIDTH/8)-1:0]  core_axi_m_wstrb           ,
     output                           core_axi_m_wlast           ,
     input [3:0]                      core_axi_m_bid             , 
     input [1:0]                      core_axi_m_bresp           , 
     input                            core_axi_m_bvalid          ,
     output                           core_axi_m_bready          ,
     input                            core_axi_m_arready         ,
     output                           core_axi_m_arvalid         ,
     output [3:0]                     core_axi_m_arid            , 
     output [AXI_ADDR_WIDTH-1:0]      core_axi_m_araddr          ,
     output [7:0]                     core_axi_m_arlen           ,
     output [2:0]                     core_axi_m_arsize          ,
     output [1:0]                     core_axi_m_arburst         ,
     output                           core_axi_m_arlock          ,
     output [3:0]                     core_axi_m_arcache         ,
     output [2:0]                     core_axi_m_arprot          ,
     output [3:0]                     core_axi_m_arqos           ,
     input [3:0]                      core_axi_m_rid             , 
     input [AXI_DATA_WIDTH-1:0]       core_axi_m_rdata           ,
     input [1:0]                      core_axi_m_rresp           , 
     input                            core_axi_m_rlast           ,
     input                            core_axi_m_rvalid          ,
     output                           core_axi_m_rready          ,

     //Dbug module top outgoing signals
     output wire                      dmactive                   , //reset signal for the DM,DTM and DMI Interface
     output wire                      core_hart_ndmreset         , //core-hart reset signal which resets the selecetd hart
     output wire                      core_hart_running          , //core-hart running signal
     output wire                      core_hart_halted           , //core-hart debug mode signal
     output wire                      core_hart_hreset          ); //core-hart reset signal

    //APB Slave signals
   wire                             pclock               ; //    input 
   wire                             presetn              ; //    input 
   wire                             psel                 ; //    input 
   wire                             pwrite               ; //    input 
   wire                             penable              ; //    input 
   wire  [APB_ADDR_WIDTH-1:0]       paddr                ; //    input 
   wire  [APB_DATA_WIDTH-1:0]       pwdata               ; //    input 
   wire    [APB_DATA_WIDTH-1:0]     prdata               ; //    output
   wire                             pready                ; //    output  
   wire                             pslverr               ; //    output 
    
     //Declaration of wires
     wire                             apb_write                  ;
     wire                             apb_read                   ;
     wire [APB_ADDR_WIDTH-1:0]        apb_addr                   ;
     wire [APB_DATA_WIDTH-1:0]        apb_wdata                  ;
     wire [APB_DATA_WIDTH-1:0]        apb_rdata                  ;
     wire                             access_memory              ;
     wire                             access_core                ;
     wire                             mem_write_en               ;
     wire                             mem_read_en                ;
     wire                             access_mem_read            ;
     wire [AXI_ADDR_WIDTH-1:0]        mem_write_addr             ;
     wire [AXI_ADDR_WIDTH-1:0]        mem_read_addr              ;
     wire [63:0]                      access_mem_addr            ;
     wire                             core_write_en              ;
     wire                             core_read_en               ;
     wire                             core_cpu_reg_write         ;
     wire [AXI_ADDR_WIDTH-1:0]        core_write_addr            ;
     wire [AXI_ADDR_WIDTH-1:0]        core_read_addr             ;
     wire [15:0]                      core_cpu_regno             ;
     wire [2:0]                       aarsize                    ;
     wire [2:0]                       aamsize                    ;
     wire [2:0]                       mem_write_size             ;
     wire [2:0]                       mem_read_size              ;
     wire [2:0]                       core_write_size            ;
     wire [2:0]                       core_read_size             ;
     wire [63:0]                      access_mem_data_out        ;
     wire                             access_mem_data_out_valid  ;
     wire [AXI_DATA_WIDTH-1:0]        mem_write_data             ;
     wire [63:0]                      core_data_out              ;
     wire                             core_data_out_valid        ;
     wire [AXI_DATA_WIDTH-1:0]        core_write_data            ;
     wire [AXI_DATA_WIDTH-1:0]        mem_read_data              ;
     wire                             mem_read_data_valid        ;
     wire [AXI_DATA_WIDTH-1:0]        core_read_data             ;
     wire                             core_read_data_valid       ;
     wire [1:0]                       access_mem_error           ;
     wire [1:0]                       access_core_error          ;
     wire                             data_rd_valid              ;

     //reg declarations
     reg [(AXI_DATA_WIDTH/8)-1:0]     mem_write_strb             ;
     reg [(AXI_DATA_WIDTH/8)-1:0]     core_write_strb            ;
     reg                              bus_error                  ;

assign mem_write_en = access_memory ? (access_mem_read == 1'b0) ? 1'b1 : 1'b0 : 1'b0;
assign mem_read_en  = access_memory ? (access_mem_read == 1'b1) ? 1'b1 : 1'b0 : 1'b0;
assign mem_write_addr = access_memory ? access_mem_addr : 64'b0;
assign mem_read_addr = access_memory ? access_mem_addr : 64'b0; 
assign core_write_en = access_core ? (core_cpu_reg_write == 1'b1) ? 1'b1 : 1'b0 : 1'b0;
assign core_read_en  = access_core ? (core_cpu_reg_write == 1'b0) ? 1'b1 : 1'b0 : 1'b0;
assign core_write_addr = access_core ? {48'b0,core_cpu_regno} : 64'b0;
assign core_read_addr = access_core ? {48'b0,core_cpu_regno} : 64'b0;
assign mem_write_size = access_memory ? aamsize : 3'b0;
assign mem_read_size = access_memory ? aamsize : 3'b0;
assign core_write_size = access_core ? aarsize : 3'b0;
assign core_read_size = access_core ? aarsize : 3'b0;
assign mem_write_data = mem_write_en ? (access_mem_data_out_valid ? access_mem_data_out : 64'b0) : 64'b0;
assign core_write_data = core_write_en ? (core_data_out_valid ? core_data_out : 64'b0) : 64'b0;

//Bus error logic
always@(*)
   begin
      if(access_memory)
         begin
            if(access_mem_error != 2'b00)
               bus_error = 1'b1;
            else
               bus_error = 1'b0;
         end
      else if(access_core)
         begin
            if(access_core_error != 2'b00)
               bus_error = 1'b1;
            else
               bus_error = 1'b0;
         end
      else 
         bus_error = 1'b0;
   end

//write strobe logic for memory
always@(*)
   begin
      if(mem_write_en)
         begin
            if(aamsize == 3'b000)
               mem_write_strb = 8'b00000001; 
            else if(aamsize == 3'b001)
               mem_write_strb = 8'b00000011;
            else if(aamsize ==3'b010)
               mem_write_strb = 8'b00001111;
            else if(aamsize ==3'b011)
               mem_write_strb = 8'b11111111;
            else
               mem_write_strb = 8'b00000000;
         end
      else
         mem_write_strb = 8'b00000000;
   end

//write strobe logic for core
always@(*)
   begin
      if(core_write_en)
         begin
            if(aarsize == 3'b010)
              core_write_strb = 8'b00001111; 
            else if(aarsize == 3'b011)
               core_write_strb = 8'b11111111; 
            else
               core_write_strb = 8'b00000000;
         end
      else
         core_write_strb = 8'b00000000;
   end

 jtag_dtm_tap_top jtag_dtm_tap_top_inst (

// JTAG connection

       .jtag_tms_i             (jtag_tms_i   ) ,      // JTAG test mode select
       .jtag_tck_i             (jtag_tck_i   ) ,      // JTAG test clock 
       .jtag_nreset_i          (jtag_nreset_i) ,   // JTAG test reset 
       .jtag_tdi_i             (jtag_tdi_i   ) ,      // JTAG test data input
       .jtag_tdo_o             (jtag_tdo_o   ) ,      // JTAG test data output

// debug module interface (DMI)() 

       .dmi_pclk_i             (pclock    ) ,
       .dmi_prstn_i            (presetn   ) ,
       .dmi_psel_o             (psel      ) ,
       .dmi_pwrite_o           (pwrite    ) ,
       .dmi_penable_o          (penable   ) ,
       .dmi_paddress_o         (paddr     ) ,  //7bit address 
       .dmi_pwdata_o           (pwdata    ) ,
       .dmi_prdata_i           (prdata    ) ,
       .dmi_pready_i           (pready    ) ,    //DMI is allowed to make new requests when set
       .dmi_pslverr            (pslverr   ) 
       );    //0=ok,1=error




//APB Slave Instantiation
apb_slave #(
     .ADDR_WIDTH                     (APB_ADDR_WIDTH             ),
     .DATA_WIDTH                     (APB_DATA_WIDTH)            )
     apb_slave_inst
     (
     .pclock                         (pclock                     ),
     .presetn                        (presetn                    ),
     .psel                           (psel                       ),
     .pwrite                         (pwrite                     ),
     .penable                        (penable                    ),
     .paddr                          (paddr                      ),
     .pwdata                         (pwdata                     ),
     .prdata                         (prdata                     ),
     .pready                         (pready                     ),
     .pslverr                        (pslverr                    ),
     .apb_rdata                      (apb_rdata                  ),
     .apb_read                       (apb_read                   ),
     .apb_write                      (apb_write                  ),
     .apb_addr                       (apb_addr                   ),
     .apb_wdata                      (apb_wdata                  ),
     .data_rd_valid                  (data_rd_valid)             );

debug_module #(
     .ADDR_WIDTH                     (DBG_ADDR_WIDTH             ),
     .DATA_WIDTH                     (DBG_DATA_WIDTH)            )
     debug_module_inst
     (
     .clock                          (pclock                     ),
     .resetn                         (presetn                    ),
     .apb_write                      (apb_write                  ),
     .apb_read                       (apb_read                   ),
     .apb_addr                       (apb_addr                   ),
     .apb_wdata                      (apb_wdata                  ),
     .apb_rdata                      (apb_rdata                  ),
     .data_rd_valid                  (data_rd_valid              ),
     .dmactive                       (dmactive                   ),
     .core_hart_ndmreset             (core_hart_ndmreset         ),
     .core_hart_running              (core_hart_running          ),
     .core_hart_halted               (core_hart_halted           ),
     .core_hart_hreset               (core_hart_hreset           ),
     .access_mem_data_in             (mem_read_data              ),
     .access_mem_data_in_valid       (mem_read_data_valid        ),
     .access_memory                  (access_memory              ),
     .access_mem_read                (access_mem_read            ),
     .access_mem_addr                (access_mem_addr            ),
     .aamsize                        (aamsize                    ),
     .access_mem_data_out            (access_mem_data_out        ),
     .access_mem_data_out_valid      (access_mem_data_out_valid  ),
     .core_cpu_regno                 (core_cpu_regno             ),
     .access_cpu_reg                 (access_core                ),
     .core_cpu_reg_write             (core_cpu_reg_write         ),
     .aarsize                        (aarsize                    ),
     .bus_error                      (bus_error                  ),
     .core_data_in                   (core_read_data             ),
     .core_data_in_valid             (core_read_data_valid       ),
     .core_data_out                  (core_data_out              ),
     .core_data_out_valid            (core_data_out_valid)       );


//AXI Master Instantiation for Memory Interface
axi_master #(
     .ADDR_WIDTH                     (AXI_ADDR_WIDTH             ),
     .DATA_WIDTH                     (AXI_DATA_WIDTH)            )
     axi_master_memory_inst
     (
     .aclk                           (aclk                       ),
     .aresetn                        (aresetn                    ),
     .awready                        (mem_axi_m_awready          ),
     .awvalid                        (mem_axi_m_awvalid          ),
     .awid                           (mem_axi_m_awid             ),
     .awaddr                         (mem_axi_m_awaddr           ),
     .awlen                          (mem_axi_m_awlen            ),
     .awsize                         (mem_axi_m_awsize           ),
     .awburst                        (mem_axi_m_awburst          ),
     .awlock                         (mem_axi_m_awlock           ),
     .awcache                        (mem_axi_m_awcache          ),
     .awprot                         (mem_axi_m_awprot           ),
     .awqos                          (mem_axi_m_awqos            ),
     .wready                         (mem_axi_m_wready           ),
     .wvalid                         (mem_axi_m_wvalid           ),
     .wdata                          (mem_axi_m_wdata            ),
     .wstrb                          (mem_axi_m_wstrb            ),
     .wlast                          (mem_axi_m_wlast            ),
     .bid                            (mem_axi_m_bid              ),
     .bresp                          (mem_axi_m_bresp            ),
     .bvalid                         (mem_axi_m_bvalid           ),
     .bready                         (mem_axi_m_bready           ),
     .arready                        (mem_axi_m_arready          ),
     .arvalid                        (mem_axi_m_arvalid          ),
     .arid                           (mem_axi_m_arid             ),
     .araddr                         (mem_axi_m_araddr           ),
     .arlen                          (mem_axi_m_arlen            ),
     .arsize                         (mem_axi_m_arsize           ), 
     .arburst                        (mem_axi_m_arburst          ),
     .arlock                         (mem_axi_m_arlock           ),
     .arcache                        (mem_axi_m_arcache          ),
     .arprot                         (mem_axi_m_arprot           ),
     .arqos                          (mem_axi_m_arqos            ),
     .rid                            (mem_axi_m_rid              ),
     .rdata                          (mem_axi_m_rdata            ),
     .rresp                          (mem_axi_m_rresp            ),
     .rlast                          (mem_axi_m_rlast            ),
     .rvalid                         (mem_axi_m_rvalid           ),
     .rready                         (mem_axi_m_rready           ),
     .transfer                       (access_memory              ),
     .write_en                       (mem_write_en               ),
     .read_en                        (mem_read_en                ),
     .write_addr                     (mem_write_addr             ),
     .read_addr                      (mem_read_addr              ),
     .write_len                      (8'b0                       ),
     .write_size                     (mem_write_size             ),
     .write_burst                    (2'b0                       ),
     .write_data                     (mem_write_data             ),
     .write_strb                     (mem_write_strb             ),
     .read_data_out                  (mem_read_data              ),
     .read_data_out_valid            (mem_read_data_valid        ),
     .error                          (access_mem_error           ),
     .read_len                       (8'b0                       ),
     .read_size                      (mem_read_size              ),
     .read_burst                     (2'b0)                      ); 

   
//AXI Master Instantiation for RISC-V Core Interface
axi_master #(
     .ADDR_WIDTH                     (AXI_ADDR_WIDTH             ),
     .DATA_WIDTH                     (AXI_DATA_WIDTH)            )
     axi_master_core_inst
     (
     .aclk                           (aclk                       ),
     .aresetn                        (aresetn                    ),
     .awready                        (core_axi_m_awready         ),
     .awvalid                        (core_axi_m_awvalid         ),
     .awid                           (core_axi_m_awid            ),
     .awaddr                         (core_axi_m_awaddr          ),
     .awlen                          (core_axi_m_awlen           ),
     .awsize                         (core_axi_m_awsize          ),
     .awburst                        (core_axi_m_awburst         ),
     .awlock                         (core_axi_m_awlock          ),
     .awcache                        (core_axi_m_awcache         ),
     .awprot                         (core_axi_m_awprot          ),
     .awqos                          (core_axi_m_awqos           ),
     .wready                         (core_axi_m_wready          ),
     .wvalid                         (core_axi_m_wvalid          ),
     .wdata                          (core_axi_m_wdata           ),
     .wstrb                          (core_axi_m_wstrb           ),
     .wlast                          (core_axi_m_wlast           ),
     .bid                            (core_axi_m_bid             ),
     .bresp                          (core_axi_m_bresp           ),
     .bvalid                         (core_axi_m_bvalid          ),
     .bready                         (core_axi_m_bready          ),
     .arready                        (core_axi_m_arready         ),
     .arvalid                        (core_axi_m_arvalid         ),
     .arid                           (core_axi_m_arid            ),
     .araddr                         (core_axi_m_araddr          ),
     .arlen                          (core_axi_m_arlen           ),
     .arsize                         (core_axi_m_arsize          ), 
     .arburst                        (core_axi_m_arburst         ),
     .arlock                         (core_axi_m_arlock          ),
     .arcache                        (core_axi_m_arcache         ),
     .arprot                         (core_axi_m_arprot          ),
     .arqos                          (core_axi_m_arqos           ),
     .rid                            (core_axi_m_rid             ),
     .rdata                          (core_axi_m_rdata           ),
     .rresp                          (core_axi_m_rresp           ),
     .rlast                          (core_axi_m_rlast           ),
     .rvalid                         (core_axi_m_rvalid          ),
     .rready                         (core_axi_m_rready          ),
     .transfer                       (access_core                ),
     .write_en                       (core_write_en              ),
     .read_en                        (core_read_en               ),
     .write_addr                     (core_write_addr            ),
     .read_addr                      (core_read_addr             ),
     .write_len                      (8'b0                       ),
     .write_size                     (core_write_size            ),
     .write_burst                    (2'b0                       ),
     .write_data                     (core_write_data            ),
     .write_strb                     (core_write_strb            ),
     .read_data_out                  (core_read_data             ),
     .read_data_out_valid            (core_read_data_valid       ),
     .error                          (access_core_error          ),
     .read_len                       (8'b0                       ),
     .read_size                      (core_read_size             ),
     .read_burst                     (2'b0)                      );


endmodule 

     
