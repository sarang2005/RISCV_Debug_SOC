// Project: RISC-V Debug
// Company: ACL Digital
// Domain : RTL Design
// Author : Vinay Chowdary
// File   : debug_module file
// Version: 1.0

`timescale 1ns/1ps
module debug_module 
    #(
     parameter ADDR_WIDTH = 32,                         // 32 bit address width
     parameter DATA_WIDTH = 32                          // 32 bit data width
     )
     (
     //System Clock and Reset
     input                        clock                      ,
     input                        resetn                     ,
     
     //IO signals coming from/to APB slave
     input                        apb_write                  ,
     input                        apb_read                   ,
     input [ADDR_WIDTH-1:0]       apb_addr                   ,
     input [DATA_WIDTH-1:0]       apb_wdata                  ,
     output wire [DATA_WIDTH-1:0] apb_rdata                  ,
     output wire                  data_rd_valid              ,

     //output signals going out of DM to the core
     output wire                  core_hart_ndmreset         ,
     output wire                  core_hart_running          ,
     output wire                  core_hart_halted           ,
     output wire                  core_hart_hreset           ,

     //output reset signal going to the DTM 
     output wire                  dmactive                   ,
     
     //IO signals to the CPU core registers
     output wire [15:0]           core_cpu_regno             ,
     output wire                  access_cpu_reg             ,
     output wire                  core_cpu_reg_write         , 
     output wire [2:0]            aarsize                    ,
     input [63:0]                 core_data_in               ,
     input                        core_data_in_valid         ,
     output wire [63:0]           core_data_out              ,
     output wire                  core_data_out_valid        ,
     input                        bus_error                  ,

     //IO signals to ACCESS Memory
     input [63:0]                 access_mem_data_in         ,
     input                        access_mem_data_in_valid   ,
     output wire                  access_memory              ,
     output wire                  access_mem_read            ,
     output wire [63:0]           access_mem_addr            ,
     output wire [2:0]            aamsize                    ,
     output wire [63:0]           access_mem_data_out        ,
     output wire                  access_mem_data_out_valid );

     //declaration of wires
     wire [DATA_WIDTH-1:0]        data0_reg ;
     wire [DATA_WIDTH-1:0]        data1_reg ;
     wire [DATA_WIDTH-1:0]        data2_reg ;
     wire [DATA_WIDTH-1:0]        data3_reg ;
     wire [DATA_WIDTH-1:0]        data4_reg ;
     wire [DATA_WIDTH-1:0]        data5_reg ;
     wire [DATA_WIDTH-1:0]        data6_reg ;
     wire [DATA_WIDTH-1:0]        data7_reg ;
     wire [DATA_WIDTH-1:0]        data8_reg ;
     wire [DATA_WIDTH-1:0]        data9_reg ;
     wire [DATA_WIDTH-1:0]        data10_reg ;
     wire [DATA_WIDTH-1:0]        data11_reg ;
     wire [DATA_WIDTH-1:0]        dmcontrol_reg ;
     wire [DATA_WIDTH-1:0]        dmstatus_reg ;
     wire [DATA_WIDTH-1:0]        command_reg ;
     wire [DATA_WIDTH-1:0]        abstractcs_reg ;
    
     wire                         hartreset ;
     wire                         resumereq ;
     wire                         haltreq ;
     wire                         setresethaltreq ;
     wire                         clrresethaltreq ;
     wire                         access_reg_cmd ;
     wire                         access_mem_cmd ;
     wire                         access_reg_command_done;
     wire                         access_mem_command_done ;
     wire [2:0]                   cmderr ;


//dm_register_file instantiation
dm_register_file  #(
     .ADDR_WIDTH                     (ADDR_WIDTH                 ),
     .DATA_WIDTH                     (DATA_WIDTH)                )
     dm_reg_inst
     (
     .clock                          (clock                      ),
     .resetn                         (resetn                     ),
     .apb_write                      (apb_write                  ),
     .apb_read                       (apb_read                   ),
     .apb_addr                       (apb_addr                   ),
     .apb_wdata                      (apb_wdata                  ), 
     .running                        (core_hart_running          ),
     .halted                         (core_hart_halted           ),
     .hreset                         (core_hart_hreset           ),
     .dmcontrol_reg                  (dmcontrol_reg              ),
     .dmstatus_reg                   (dmstatus_reg               ),
     .command_reg                    (command_reg                ),
     .abstractcs_reg                 (abstractcs_reg             ),
     .data0_reg                      (data0_reg                  ),   
     .data1_reg                      (data1_reg                  ),   
     .data2_reg                      (data2_reg                  ),   
     .data3_reg                      (data3_reg                  ),   
     .data4_reg                      (data4_reg                  ),   
     .data5_reg                      (data5_reg                  ),   
     .data6_reg                      (data6_reg                  ),   
     .data7_reg                      (data7_reg                  ),   
     .data8_reg                      (data8_reg                  ),   
     .data9_reg                      (data9_reg                  ),   
     .data10_reg                     (data10_reg                 ),   
     .data11_reg                     (data11_reg                 ), 
     .dmactive                       (dmactive                   ),
     .ndmreset                       (core_hart_ndmreset         ),
     .clrresethaltreq                (clrresethaltreq            ),
     .setresethaltreq                (setresethaltreq            ),
     .hartreset                      (hartreset                  ),
     .resumereq                      (resumereq                  ),
     .haltreq                        (haltreq                    ),
     .access_reg_cmd                 (access_reg_cmd             ),
     .access_mem_cmd                 (access_mem_cmd             ),
     .access_reg_command_done        (access_reg_command_done    ),
     .access_mem_command_done        (access_mem_command_done    ),
     .cmderr                         (cmderr                     ),
     .aarsize                        (aarsize                    ),
     .aamsize                        (aamsize                    ),
     .bus_error                      (bus_error                  ),
     .regno                          (core_cpu_regno             ),
     .access_cpu_reg                 (access_cpu_reg             ),
     .core_cpu_reg_write             (core_cpu_reg_write         ),
     .core_data_in                   (core_data_in               ),
     .core_data_in_valid             (core_data_in_valid         ),
     .core_data_out                  (core_data_out              ),    
     .core_data_out_valid            (core_data_out_valid        ),
     .access_mem_data_in             (access_mem_data_in         ),
     .access_mem_data_in_valid       (access_mem_data_in_valid   ),
     .access_memory                  (access_memory              ),
     .access_mem_addr                (access_mem_addr            ),
     .access_mem_read                (access_mem_read            ),
     .access_mem_data_out            (access_mem_data_out        ),
     .access_mem_data_out_valid      (access_mem_data_out_valid) );


//dm_register_mux instantiation
dm_register_mux #(
     .ADDR_WIDTH                     (ADDR_WIDTH                 ),
     .DATA_WIDTH                     (DATA_WIDTH)                )
     dm_reg_mux_inst
     (
     .clock                          (clock                      ),
     .resetn                         (resetn                     ),
     .apb_read                       (apb_read                   ),
     .apb_addr                       (apb_addr                   ),
     .dmcontrol_reg                  (dmcontrol_reg              ),
     .dmstatus_reg                   (dmstatus_reg               ),
     .command_reg                    (command_reg                ),
     .abstractcs_reg                 (abstractcs_reg             ),
     .data0_reg                      (data0_reg                  ),   
     .data1_reg                      (data1_reg                  ),   
     .data2_reg                      (data2_reg                  ),   
     .data3_reg                      (data3_reg                  ),   
     .data4_reg                      (data4_reg                  ),   
     .data5_reg                      (data5_reg                  ),   
     .data6_reg                      (data6_reg                  ),   
     .data7_reg                      (data7_reg                  ),   
     .data8_reg                      (data8_reg                  ),   
     .data9_reg                      (data9_reg                  ),   
     .data10_reg                     (data10_reg                 ),   
     .data11_reg                     (data11_reg                 ),
     .data_rd_valid                  (data_rd_valid              ),
     .reg_data_out                   (apb_rdata)                 ); 

//debug module FSM instantiation
debug_module_fsm dm_fsm_inst (
     .clock                          (clock                      ),
     .resetn                         (resetn                     ),
     .dmactive                       (dmactive                   ),
     .clrresethaltreq                (clrresethaltreq            ),
     .setresethaltreq                (setresethaltreq            ),
     .hartreset                      (hartreset                  ),
     .resumereq                      (resumereq                  ),
     .haltreq                        (haltreq                    ),
     .access_reg_cmd                 (access_reg_cmd             ),
     .access_mem_cmd                 (access_mem_cmd             ),
     .access_reg_command_done        (access_reg_command_done    ),
     .access_mem_command_done        (access_mem_command_done    ),
     .cmderr                         (cmderr                     ),
     .running                        (core_hart_running          ),
     .halted                         (core_hart_halted           ),
     .hreset                         (core_hart_hreset)          );


endmodule

