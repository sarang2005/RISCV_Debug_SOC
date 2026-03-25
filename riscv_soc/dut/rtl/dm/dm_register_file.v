// Project: RISC-V Debug
// Company: ACL Digital
// Domain : RTL Design
// Author : Vinay Chowdary
// File   : dm_register_file write file
// Version:1.0

`timescale 1ns/1ps
module dm_register_file
    #(  
     parameter ADDR_WIDTH = 32,                         // 32 bit address width
     parameter DATA_WIDTH = 32                          // 32 bit data width
     )
     (
     //DMI AMBA APB Interface signals
     input                                 clock                      ,
     input                                 resetn                     ,
     input                                 apb_write                  ,
     input                                 apb_read                   ,
     input [ADDR_WIDTH-1 : 0]              apb_addr                   ,
     input [DATA_WIDTH-1 : 0]              apb_wdata                  ,

     //inputs coming from Debug Module FSM
     input                                 running                    ,
     input                                 halted                     ,
     input                                 hreset                     ,

     //dm registers output signals 
     output wire [DATA_WIDTH-1 : 0]        dmcontrol_reg              ,
     output wire [DATA_WIDTH-1 : 0]        dmstatus_reg               ,
     output wire [DATA_WIDTH-1 : 0]        command_reg                ,
     output wire [DATA_WIDTH-1 : 0]        abstractcs_reg             ,
     output wire [DATA_WIDTH-1 : 0]        data0_reg                  ,
     output wire [DATA_WIDTH-1 : 0]        data1_reg                  ,
     output wire [DATA_WIDTH-1 : 0]        data2_reg                  ,
     output wire [DATA_WIDTH-1 : 0]        data3_reg                  ,
     output wire [DATA_WIDTH-1 : 0]        data4_reg                  ,
     output wire [DATA_WIDTH-1 : 0]        data5_reg                  ,
     output wire [DATA_WIDTH-1 : 0]        data6_reg                  ,
     output wire [DATA_WIDTH-1 : 0]        data7_reg                  ,
     output wire [DATA_WIDTH-1 : 0]        data8_reg                  ,
     output wire [DATA_WIDTH-1 : 0]        data9_reg                  ,
     output wire [DATA_WIDTH-1 : 0]        data10_reg                 ,
     output wire [DATA_WIDTH-1 : 0]        data11_reg                 ,
   
     //output signals going to the debug module FSM
     output wire                           dmactive                   ,
     output wire                           ndmreset                   ,
     output wire                           clrresethaltreq            ,
     output wire                           setresethaltreq            ,
     output wire                           hartreset                  ,
     output wire                           resumereq                  ,
     output wire                           haltreq                    ,
     output reg                            access_reg_cmd             ,
     output reg                            access_mem_cmd             ,
     output wire                           access_reg_command_done    ,
     output wire                           access_mem_command_done    ,
     output wire [2:0]                     cmderr                     ,
     output wire [2:0]                     aarsize                    ,
     output wire [2:0]                     aamsize                    ,
    
     //IO ports to/from Core 
     output reg [15:0]                     regno                      , 
     input [63:0]                          core_data_in               ,
     input                                 core_data_in_valid         ,
     output wire [63:0]                    core_data_out              ,
     output wire                           core_data_out_valid        ,
     output wire                           access_cpu_reg             ,
     output wire                           core_cpu_reg_write         ,
     input                                 bus_error                  ,
     
     //IO ports to/from Memory
     input [63:0]                          access_mem_data_in         ,
     input                                 access_mem_data_in_valid   ,
     output wire                           access_memory              ,
     output wire [63:0]                    access_mem_addr            ,
     output wire                           access_mem_read            ,
     output wire [63:0]                    access_mem_data_out        ,
     output wire                           access_mem_data_out_valid );
         
     //declaration of wires
     wire                                  ackhavereset               ;
     wire                                  ackunavail                 ;

     wire                                  cmd_written                ;
     wire                                  cmd_not_supported          ;
     wire                                  aarpostincrement           ;
     wire                                  transfer                   ;
     wire                                  write                      ; 
     wire                                  aampostincrement           ;
     wire                                  busy                       ; 


// assign access_reg_cmd   = access_reg_command_done ? 1'b0 : (cmd_written ? ((command_reg[31:24]==8'h00) ? 1'b1 : 1'b0) : access_reg_cmd );
// assign access_mem_cmd   = access_mem_command_done ? 1'b0 : (cmd_written ? ((command_reg[31:24]==8'h02) ? 1'b1 : 1'b0) : access_mem_cmd );

assign busy             = (access_reg_command_done || access_mem_command_done) ? 1'b0 : ( cmd_written ? 1'b1 : busy) ; //TODO

assign aarsize          = cmd_written ? ((command_reg[31:24]==8'h00) ? command_reg[22:20] : 3'b0) : aarsize;
assign aamsize          = cmd_written ? ((command_reg[31:24]==8'h02) ? command_reg[22:20] : 3'b0) : aamsize;
assign aarpostincrement = cmd_written ? ((command_reg[31:24]==8'h00) ? command_reg[19] : 1'b0) : aarpostincrement;
assign aampostincrement = cmd_written ? ((command_reg[31:24]==8'h02) ? command_reg[19] : 1'b0) : aampostincrement;
assign transfer         = cmd_written ? ((command_reg[31:24]==8'h00) ? command_reg[17] : 1'b0) : transfer;
assign write            = cmd_written ? ((command_reg[31:24]==8'h00 || command_reg[31:24]==8'h02 ) ? command_reg[16] : 1'b0) : write;
// assign regno            = cmd_written ? ((command_reg[31:24]==8'h00) ? command_reg[15:0] : 16'b0) : 16'b0; //TODO

//access_reg_cmd logic
always@(posedge clock or negedge resetn)
   begin
      if(!resetn)
         begin
            access_reg_cmd <= 1'b0;
         end
      else
         begin
            if(access_reg_command_done)
               begin
                  access_reg_cmd <= 1'b0;
               end
            else
               begin
                  if(cmd_written)
                     begin
                        if(command_reg[31:24]==8'h00)
                           begin
                              access_reg_cmd <= 1'b1;
                           end
                        else
                           begin
                              access_reg_cmd <= 1'b0;
                           end
                     end
               end 
         end
   end

//access_mem_cmd logic
always@(posedge clock or negedge resetn)
   begin
      if(!resetn)
         begin
            access_mem_cmd <= 1'b0;
         end
      else
         begin
            if(access_mem_command_done)
               begin
                  access_mem_cmd <= 1'b0;
               end
            else
               begin
                  if(cmd_written)
                     begin
                        if(command_reg[31:24]==8'h02)
                           begin
                              access_mem_cmd <= 1'b1;
                           end
                        else
                           begin
                              access_mem_cmd <= 1'b0;
                           end
                     end
               end 
         end
   end


//logic for regno (core_cpu_regno)
always@(posedge clock or negedge resetn)
   begin
      if(!resetn)
         begin
            regno <= 16'b0;
         end
      else
         begin
           if(cmd_written)
              begin
                 if(command_reg[31:24]==8'b0)
                    begin
                       regno <= command_reg[15:0];
                    end
              end
           else if(access_reg_command_done && aarpostincrement)
              begin
                 regno <= regno+1'b1;
              end
           else
              begin
                 regno <= regno ;
              end
        end
  end

//assign aamvirtual       = cmd_written ? ((command_reg[31:24]==8'h02) ? command_reg[23] : 1'b0) : 1'b0;
//assign postexec         = cmd_written ? ((command_reg[31:24]==8'h00) ? command_reg[18] : 1'b0) : 1'b0; 

assign haltreq           = dmcontrol_reg[31];
assign resumereq         = dmcontrol_reg[30];
assign hartreset         = dmcontrol_reg[29];
assign ackhavereset      = dmcontrol_reg[28];
assign ackunavail        = dmcontrol_reg[27]; 
assign setresethaltreq   = dmcontrol_reg[3];
assign clrresethaltreq   = dmcontrol_reg[2];
assign ndmreset          = dmcontrol_reg[1];
assign dmactive          = dmcontrol_reg[0];

// abstractcs register instantiation
      abstractcs #(
                 .ADDR_WIDTH         (ADDR_WIDTH         ),
                 .DATA_WIDTH         (DATA_WIDTH)        )
                 abstractcs_inst
                 (
                 .clock              (clock              ),
                 .resetn             (resetn             ),
                 // .transfer           (transfer           ),
                 .write              (apb_write          ),
                 .read               (apb_read           ),
                 .addr               (apb_addr           ),
                 .data               (apb_wdata          ),
                 .dmactive           (dmactive           ),
                 .busy               (busy               ),
                 .regno              (regno              ),
                 .aarsize            (aarsize            ),
                 .aamsize            (aamsize            ),
                 .halted             (halted             ),
                 .bus_error          (bus_error          ),
               //  .cmd_written        (cmd_written        ),
                 .cmd_not_supported  (cmd_not_supported  ),
                 .access_reg_cmd     (access_reg_cmd     ),
                 .access_mem_cmd     (access_mem_cmd     ),
                 .cmderr             (cmderr             ),
                 .abstractcs_reg     (abstractcs_reg)    );

// dmcontrol register instantiation
      dmcontrol  #(
                 .ADDR_WIDTH         (ADDR_WIDTH         ),
                 .DATA_WIDTH         (DATA_WIDTH)        )
                 dmcontrol_inst
                 (
                 .clock              (clock              ),
                 .resetn             (resetn             ),
                 .write              (apb_write          ),
                 .addr               (apb_addr           ),
                 .data               (apb_wdata          ),
                 .dmcontrol_reg      (dmcontrol_reg)     );

// command register instantiation
      command    #(
                 .ADDR_WIDTH         (ADDR_WIDTH         ),
                 .DATA_WIDTH         (DATA_WIDTH)        )
                 command_inst
                 (
                 .clock              (clock              ),
                 .resetn             (resetn             ),
                 .write              (apb_write          ),
                 .addr               (apb_addr           ),
                 .data               (apb_wdata          ),
                 .dmactive           (dmactive           ),
                 .cmderr             (cmderr             ),
                 .cmd_written        (cmd_written        ),
                 .cmd_not_supported  (cmd_not_supported  ),
                 .command_reg        (command_reg)       );

// dmstatus register instantiation
      dmstatus   #(
                 .ADDR_WIDTH         (ADDR_WIDTH         ),
                 .DATA_WIDTH         (DATA_WIDTH)        )
                 dmstatus_inst
                 (
                 .clock              (clock              ), 
                 .resetn             (resetn             ),
                 .ndmreset           (ndmreset           ),
                 .dmactive           (dmactive           ),
                 .resumereq          (resumereq          ),
                 .ackhavereset       (ackhavereset       ),
                 .ackunavail         (ackunavail         ),                     
                 .halted             (halted             ),
                 .running            (running            ),
                 .hreset             (hreset             ),
                 .dmstatus_reg       (dmstatus_reg)      );

// data registers instantiation
     data_reg    #(
                 .ADDR_WIDTH                 (ADDR_WIDTH                ),
                 .DATA_WIDTH                 (DATA_WIDTH)               ) 
                 data_reg_inst
                 (
                 .clock                      (clock                     ),
                 .resetn                     (resetn                    ),
                 .apb_write                  (apb_write                 ),
                 .apb_addr                   (apb_addr                  ),
                 .apb_wdata                  (apb_wdata                 ),
                 .dmactive                   (dmactive                  ),
                 .halted                     (halted                    ),
                 .cmderr                     (cmderr                    ),
                 .write                      (write                     ),
                 .transfer                   (transfer                  ),
                 .aarsize                    (aarsize                   ),
                 .access_reg_cmd             (access_reg_cmd            ),
                 .core_data_in               (core_data_in              ),
                 .core_data_in_valid         (core_data_in_valid        ),
                 .core_data_out              (core_data_out             ),
                 .core_data_out_valid        (core_data_out_valid       ),
                 .access_cpu_reg             (access_cpu_reg            ),
                 .core_cpu_reg_write         (core_cpu_reg_write        ),
                 .access_reg_command_done    (access_reg_command_done   ),
                 .access_mem_cmd             (access_mem_cmd            ),
                 .aamsize                    (aamsize                   ),
                 .aampostincrement           (aampostincrement          ),
                 .access_mem_data_in         (access_mem_data_in        ),
                 .access_mem_data_in_valid   (access_mem_data_in_valid  ),
                 .access_memory              (access_memory             ),
                 .access_mem_addr            (access_mem_addr           ),
                 .access_mem_read            (access_mem_read           ),
                 .access_mem_data_out        (access_mem_data_out       ),
                 .access_mem_data_out_valid  (access_mem_data_out_valid ),
                 .access_mem_command_done    (access_mem_command_done   ),
                 .data0_reg                  (data0_reg                 ),  
                 .data1_reg                  (data1_reg                 ),
                 .data2_reg                  (data2_reg                 ),
                 .data3_reg                  (data3_reg                 ),
                 .data4_reg                  (data4_reg                 ),
                 .data5_reg                  (data5_reg                 ),
                 .data6_reg                  (data6_reg                 ),
                 .data7_reg                  (data7_reg                 ),
                 .data8_reg                  (data8_reg                 ),
                 .data9_reg                  (data9_reg                 ),
                 .data10_reg                 (data10_reg                ),
                 .data11_reg                 (data11_reg)               );
                                

endmodule


///////////////////////// Debug Module Control register Implementation ////////////////////////////////////////////

module dmcontrol
     #(  
      parameter ADDR_WIDTH = 32,                         // 32 bit address width
      parameter DATA_WIDTH = 32                          // 32 bit data width
      ) 
      (
      input                         clock          ,
      input                         resetn         ,
      input                         write          ,
      input [ADDR_WIDTH-1 : 0]      addr           ,
      input [DATA_WIDTH-1 : 0]      data           ,

      output reg [DATA_WIDTH-1 : 0] dmcontrol_reg );

	
      //local parameter for dmcontrol address	
      localparam DMCONTROL_ADDR = 32'h00000010;          

      //dmcontrol register write part		
      always@(posedge clock or negedge resetn)
         begin
            if(!resetn)
               begin
                  dmcontrol_reg[31:0] <= 32'b0;
               end
            else
               begin
                  if(write)
                     begin
                        if(addr == DMCONTROL_ADDR)
                           begin
                              dmcontrol_reg[31]    <= data[31];     //haltreq bit
                              dmcontrol_reg[30]    <= data[30];     //resumereq bit
                              dmcontrol_reg[29]    <= data[29];     //hartreset bit
                              dmcontrol_reg[28]    <= data[28];     //ackhavereset bit
                              dmcontrol_reg[27]    <= data[27];     //ackunavail bit
                              dmcontrol_reg[26]    <= 1'b0    ;     //hasel ---> we are supporting only single hart
                              dmcontrol_reg[25:16] <= 10'b0   ;     //hartselhi bits
                              dmcontrol_reg[15:6]  <= 10'b0   ;     //hartsello bits
                              dmcontrol_reg[5]     <= 1'b0    ;     //setkeepalive bits --> keepalive feature is opt and we are not using it 
                              dmcontrol_reg[4]     <= 1'b0    ;     //clrkeepalive bits --> keepalive feature is opt and we are not using it
                              dmcontrol_reg[3]     <= data[3] ;     //setresethaltreq   --> hasresethaltreq feature is implemeneted
                              dmcontrol_reg[2]     <= data[2] ;     //clrresethaltreq   --> hasresethaltreq feature is implemeneted
                              dmcontrol_reg[1]     <= data[1] ;     //ndmreset
                              dmcontrol_reg[0]     <= data[0] ;     //dmactive
                           end
                     end 
               end
         end

endmodule 

//////////////////////////// End of Debug Module Control register Implementation /////////////////////////////////

///////////////////////// Debug Module Status register Implementation ////////////////////////////////////////////

module dmstatus
     #(  
      parameter ADDR_WIDTH = 32,                         // 32 bit address width
      parameter DATA_WIDTH = 32                          // 32 bit data width
      )
      ( 
      input                          clock          ,
      input                          resetn         ,

      input                          ndmreset       ,
      input                          dmactive       ,
      input                          ackhavereset   , 
      input                          ackunavail     , 
      input                          resumereq      ,                    
   
      input                          halted         ,   
      input                          running        , 
      input                          hreset         ,
      output reg [DATA_WIDTH-1 : 0]  dmstatus_reg  );


      //dmstatus register implementation part
      always@(posedge clock or negedge resetn)
         begin
            if(!resetn)
               begin
                  dmstatus_reg[31:25] <= 7'b0;
                  dmstatus_reg[24]    <= 1'b0;
                  dmstatus_reg[23]    <= 1'b1;
                  dmstatus_reg[22]    <= 1'b0;
                  dmstatus_reg[21:20] <= 2'b0;
                  dmstatus_reg[19:8]  <= 12'b0;
                  dmstatus_reg[7]     <= 1'b1;
                  dmstatus_reg[6]     <= 1'b0;
                  dmstatus_reg[5]     <= 1'b1;
                  dmstatus_reg[4]     <= 1'b0;
                  dmstatus_reg[3:0]   <= 4'b0011;
               end
            else
               begin 
                  if(dmactive==1'b0)
                     begin
                        dmstatus_reg[31:25] <= 7'b0;
                        dmstatus_reg[24]    <= 1'b0;
                        dmstatus_reg[23]    <= 1'b1;
                        dmstatus_reg[22]    <= 1'b0;
                        dmstatus_reg[21:20] <= 2'b0;
                        dmstatus_reg[19:8]  <= 12'b0;
                        dmstatus_reg[7]     <= 1'b1;
                        dmstatus_reg[6]     <= 1'b0;
                        dmstatus_reg[5]     <= 1'b1;
                        dmstatus_reg[4]     <= 1'b0;
                        dmstatus_reg[3:0]   <= 4'b0011;
                     end
                 else
                     begin
                        dmstatus_reg[31:25] <= 7'b0;                     //hardwired to 0 as per spec
                        dmstatus_reg[24]    <= ndmreset ? 1'b1 : 1'b0;   //ndmresetpending
                        dmstatus_reg[23]    <= 1'b1 ;                    //stickyunavail per-hart unavail bits are sticky 
                        dmstatus_reg[22]    <= 1'b0;                     //impebreak --> program buffer not exists as of now
                        dmstatus_reg[21:20] <= 2'b0;                     //Hard wired to 0 as per spec
                        dmstatus_reg[19]    <= ackhavereset ? 1'b0 : (hreset ? 1'b1 : dmstatus_reg[19] );  //allhavereset
                        dmstatus_reg[18]    <= ackhavereset ? 1'b0 : (hreset ? 1'b1 : dmstatus_reg[18] );  //anyhavereset
                        dmstatus_reg[17]    <= resumereq ? 1'b0 : (running ? 1'b1 : dmstatus_reg[17] );    //allresumeack
                        dmstatus_reg[16]    <= resumereq ? 1'b0 : (running ? 1'b1 : dmstatus_reg[16] );    //anyresumeack
                        dmstatus_reg[15]    <= 1'b1;                     // As Core-hart is not yet available in hardware platform
                        dmstatus_reg[14]    <= 1'b1;                     // As Core-hart is not yet available in Hardware platform
                        dmstatus_reg[13]    <= ackunavail ? 1'b0 : (hreset ? 1'b1 : dmstatus_reg[13] ); //allunavail
                        dmstatus_reg[12]    <= ackunavail ? 1'b0 : (hreset ? 1'b1 : dmstatus_reg[12] ); //anyunavail 
                        dmstatus_reg[11]    <= running ? 1'b1 : 1'b0;    //allrunning all the selected harts were running
                        dmstatus_reg[10]    <= running ? 1'b1 : 1'b0;    //anyrunning any of the selected harts were running
                        dmstatus_reg[9]     <= halted ? 1'b1 : 1'b0;     //allhalted all the selected harts were halted
                        dmstatus_reg[8]     <= halted ? 1'b1 : 1'b0;     //anyhalted anyone of the selected hart is halted
                        dmstatus_reg[7]     <= 1'b1;                     //authentication not implemented
                        dmstatus_reg[6]     <= 1'b0;                     //authbusy is reset value as auth data is not implemented 
                        dmstatus_reg[5]     <= 1'b1;                     //hasresethaltreq is 1 as halt on reset feature is implemented 
                        dmstatus_reg[4]     <= 1'b0;                     //configuration structure pointer were not implemented
                        dmstatus_reg[3:0]   <= 4'b0011;                  //version for the 1.0.0 risc-v document
                     end
               end
         end

endmodule

//////////////////////////// End of Debug Module Status register Implementation //////////////////////////////////     

//////////////////////////// Abstract command register implementation ////////////////////////////////////////////

module command
     #(  
      parameter ADDR_WIDTH = 32,                         // 32 bit address width
      parameter DATA_WIDTH = 32                          // 32 bit data width
      )
      (
      input                         clock             ,
      input                         resetn            ,
      input                         write             ,
      input [ADDR_WIDTH-1 : 0]      addr              ,
      input [DATA_WIDTH-1 : 0]      data              ,

      input                         dmactive          ,
      input [2:0]                   cmderr            ,

      output reg [DATA_WIDTH-1 : 0] command_reg       ,
      output reg                    cmd_not_supported ,
      output reg                    cmd_written      );

      //local parameter declaration for command reg
      localparam COMMAND_ADDR = 32'h00000017          ;

      //command register write part
      always@(posedge clock or negedge resetn)
         begin
            if(!resetn)
               begin
                  command_reg[31:24] <= 8'b0 ;
                  command_reg[23:0]  <= 24'b0;
                  cmd_written        <= 1'b0 ;
                  cmd_not_supported  <= 1'b0;
               end
            else
               begin 
                  if(dmactive == 1'b0)
                     begin
                        command_reg[31:24] <= 8'b0 ;
                        command_reg[23:0]  <= 24'b0;
                        cmd_written        <= 1'b0 ;
                        cmd_not_supported  <= 1'b0;
                     end
                  else
                     begin
                        if(write)
                           begin
                              if(addr == COMMAND_ADDR)
                                 begin
                                    if(cmderr == 3'b000)
                                       begin
                                          if(data[31:24]==8'h02)
                                             begin
                                                command_reg[31:24] <= data[31:24];
                                                command_reg[23]    <= 1'b0;         //aamvirtual is tied to zero as address are physical
                                                command_reg[22:19] <= data[22:19];
                                                command_reg[18:17] <= 2'b0;         
                                                command_reg[16]    <= data[16];
                                                command_reg[15:0]  <= 16'b0; 
                                                cmd_written        <= 1'b1;
                                                cmd_not_supported  <= 1'b0;
                                             end
                                          else if(data[31:24]==8'h00)
                                             begin
                                                command_reg[31:24] <= data[31:24];
                                                command_reg[23]    <= 1'b0;         
                                                command_reg[22:19] <= data[22:19];
                                                command_reg[18]    <= 1'b0; 
                                                command_reg[17:16] <= data[17:16];        
                                                command_reg[15:0]  <= data[15:0];  //regno
                                                cmd_written        <= 1'b1;
                                                cmd_not_supported  <= 1'b0;
                                             end
                                          else
                                             begin
                                                command_reg[31:0]  <= data[31:0];
                                                cmd_written        <= 1'b0;
                                                cmd_not_supported  <= 1'b1;
                                             end
                                       end
                                    else
                                       begin
                                          command_reg[31:24] <= command_reg[31:24];
                                          command_reg[23:0]  <= command_reg[23:0];
                                          cmd_written        <= 1'b0;
                                          cmd_not_supported  <= 1'b0;
                                       end
                                 end
                              else
                                 begin
                                    cmd_written <= 1'b0;
                                    cmd_not_supported <= 1'b0;
                                 end
                           end
                        else
                           begin
                              cmd_written <= 1'b0;
                              cmd_not_supported <= 1'b0;
                           end
                     end
               end
         end

endmodule

////////////////////////////End of Abstract command register implementation ///////////////////////////////////


///////////////////////////start of Abstract control and status register //////////////////////////////////////

module abstractcs
     #(  
      parameter ADDR_WIDTH = 32,                         // 32 bit address width
      parameter DATA_WIDTH = 32                          // 32 bit data width
      )
      (
      input                          clock              ,
      input                          resetn             ,
      input                          write              ,
      input                          read               ,
      input [ADDR_WIDTH-1 : 0]       addr               ,
      input [DATA_WIDTH-1 : 0]       data               ,
     
      input                          dmactive           , 
      input                          busy               ,
      input [15:0]                   regno              ,
      input [2:0]                    aarsize            ,
      input [2:0]                    aamsize            ,
      input                          halted             ,
     // input                          cmd_written        ,
      input                          bus_error          ,
      input                          cmd_not_supported  ,
      input                          access_reg_cmd     ,
      input                          access_mem_cmd     ,

      output reg [2:0]               cmderr             ,
      output wire [DATA_WIDTH-1 : 0] abstractcs_reg    );

      reg busy_bit                            ;

      //local paramter declaration for registers
      localparam ABSTRACTCS_ADDR  = 32'h00000016;  
      localparam COMMAND_ADDR     = 32'h00000018;
      localparam DATA0_ADDR       = 32'h00000004;
      localparam DATA1_ADDR       = 32'h00000005;
      localparam DATA2_ADDR       = 32'h00000006;
      localparam DATA3_ADDR       = 32'h00000007;
      localparam DATA4_ADDR       = 32'h00000008;
      localparam DATA5_ADDR       = 32'h00000009;
      localparam DATA6_ADDR       = 32'h0000000a;
      localparam DATA7_ADDR       = 32'h0000000b;
      localparam DATA8_ADDR       = 32'h0000000c;
      localparam DATA9_ADDR       = 32'h0000000d;
      localparam DATA10_ADDR      = 32'h0000000e;
      localparam DATA11_ADDR      = 32'h0000000f;

      //busy logic
      always@(posedge clock or negedge resetn)
         begin
            if(!resetn)
               begin
                   busy_bit <= 1'b0;
               end
            else
               begin
                  if(dmactive==1'b0)
                     begin
                        busy_bit <= 1'b0;
                     end
                  else
                     begin
                        if(busy)
                           begin
                              busy_bit <= 1'b1;
                           end
                        else
                           begin
                               busy_bit <= 1'b0;
                           end
                     end
               end
         end

      //cmderr logic
      always@(posedge clock or negedge resetn)
         begin
            if(!resetn)
               begin
                  cmderr <= 3'b000;
               end
            else
               begin
                  if(dmactive==1'b0)
                     begin
                        cmderr <= 3'b000;
                     end
                  else
                     begin
                        if(access_reg_cmd && !halted)
                           begin
                              cmderr <= 3'b100;
                           end
                        else if(access_mem_cmd && !halted)
                           begin
                              cmderr <= 3'b100;
                           end
                       // else if(cmd_written && (access_reg_cmd==1'b0) && (access_mem_cmd==1'b0))
                        else if(cmd_not_supported)
                           begin
                              cmderr <= 3'b010;
                           end
                        else if( ((aarsize!=3'b010 && aarsize!=3'b011) && access_reg_cmd) || (aamsize>3'b011 && access_mem_cmd) )
                           begin
                              cmderr <= 3'b101;  //Access size failure
                           end
                        else if(bus_error)
                           begin
                              cmderr <= 3'b101;
                           end
                        else if(access_reg_cmd && (regno>16'h103f && regno<16'hc000))
                           begin
                                 cmderr <= 3'b011; //exception --> register that is not present in the hart
                           end
                        else if(write)
                           begin
                             $display(" after write \n write=%b ", write);
                              if(busy)
                                 begin
                                   //$display(" after busy \n busy=%b ", busy);
                                    if(addr==ABSTRACTCS_ADDR || addr==COMMAND_ADDR || DATA0_ADDR || DATA1_ADDR ||
                                       addr==DATA2_ADDR      || addr==DATA3_ADDR   || DATA4_ADDR || DATA5_ADDR ||
                                       addr==DATA6_ADDR      || addr==DATA7_ADDR   || DATA8_ADDR || DATA9_ADDR ||
                                       addr==DATA10_ADDR     || addr==DATA11_ADDR   )
                                       begin
                                         //$display("cmderr 1 bug");
                                         //cmderr <= 3'b001;
                                         if(cmderr==3'b000)
                                             begin
                                               //$display(" after cmderr if statement");
                                                cmderr <= 3'b001; //busy
                                             end
                                         //$display(" after cmderr if statement");
                                          else
                                             begin
                                                cmderr <= cmderr;
                                             end
                                       end
                                    else 
                                       begin   
                                          cmderr <= cmderr ;
                                       end
                                 end
                              else 
                                 begin               
                                    if(addr==ABSTRACTCS_ADDR)
                                       begin
                                          if(data[10:8]==3'b111)
                                             cmderr <= 3'b000;   //clearing command error
                                          else
                                             cmderr <= cmderr ;
                                       end
                                 end
                           end
                        else if(read)
                           begin
                              if(busy)
                                 begin
                                    if(addr==DATA0_ADDR || addr==DATA1_ADDR || addr==DATA2_ADDR  || addr==DATA3_ADDR ||
                                       addr==DATA4_ADDR || addr==DATA5_ADDR || addr==DATA6_ADDR  || addr==DATA7_ADDR ||
                                       addr==DATA8_ADDR || addr==DATA9_ADDR || addr==DATA10_ADDR || addr==DATA11_ADDR )
                                       begin
                                         //cmderr <= 3'b001;
                                          if(cmderr==3'b000)
                                             cmderr <= 3'b001;  //busy
                                          else
                                             cmderr <= cmderr;
                                       end
                                 end
                              else
                                 cmderr <= cmderr;
                           end
                        else 
                           begin
                              cmderr <= cmderr;
                           end
                     end
               end   
         end   
             
     assign abstractcs_reg = {19'b0,busy_bit,1'b0,cmderr,4'b0,4'b1100} ;

endmodule
        
///////////////////////////End of Abstract control and status register //////////////////////////////////////


///////////////////////////Start of the DARA registers  /////////////////////////////////////////////////////                 

module data_reg
     #(  
      parameter ADDR_WIDTH = 32,                         // 32 bit address width
      parameter DATA_WIDTH = 32                          // 32 bit data width
      )
      (
      input clock                             ,
      input resetn                            ,
      input apb_write                         ,
      input [ADDR_WIDTH-1 : 0] apb_addr       ,
      input [DATA_WIDTH-1 : 0] apb_wdata      ,
  
      input dmactive                          ,
      input halted                            ,
      input  [2:0] cmderr                     ,
      input write                             ,
      input transfer                          ,
      input [2:0] aarsize                     ,
      input access_reg_cmd                    ,
      input [63:0] core_data_in               ,
      input core_data_in_valid                ,
      output reg access_cpu_reg               ,
      output reg core_cpu_reg_write           ,
      output reg [63:0] core_data_out         ,
      output reg core_data_out_valid          ,
      output reg access_reg_command_done      ,

      input access_mem_cmd                    ,
      input aampostincrement                  ,
      input [2:0]aamsize                      ,
      input [63:0] access_mem_data_in         ,
      input access_mem_data_in_valid          ,
      output reg [63:0] access_mem_addr       ,
      output reg access_mem_read              ,
      output reg [63:0] access_mem_data_out   ,
      output reg access_mem_data_out_valid    ,
      output reg access_mem_command_done      ,
      output reg access_memory                ,

      output reg [DATA_WIDTH-1:0] data0_reg   ,   
      output reg [DATA_WIDTH-1:0] data1_reg   , 
      output reg [DATA_WIDTH-1:0] data2_reg   , 
      output reg [DATA_WIDTH-1:0] data3_reg   , 
      output reg [DATA_WIDTH-1:0] data4_reg   ,
      output reg [DATA_WIDTH-1:0] data5_reg   , 
      output reg [DATA_WIDTH-1:0] data6_reg   , 
      output reg [DATA_WIDTH-1:0] data7_reg   , 
      output reg [DATA_WIDTH-1:0] data8_reg   , 
      output reg [DATA_WIDTH-1:0] data9_reg   , 
      output reg [DATA_WIDTH-1:0] data10_reg  , 
      output reg [DATA_WIDTH-1:0] data11_reg );
      
      //local parameters declarations for DM DATA registers  
      localparam DATA0_ADDR       = 32'h00000004;
      localparam DATA1_ADDR       = 32'h00000005;
      localparam DATA2_ADDR       = 32'h00000006;
      localparam DATA3_ADDR       = 32'h00000007;
      localparam DATA4_ADDR       = 32'h00000008;
      localparam DATA5_ADDR       = 32'h00000009;
      localparam DATA6_ADDR       = 32'h0000000a;
      localparam DATA7_ADDR       = 32'h0000000b;
      localparam DATA8_ADDR       = 32'h0000000c;
      localparam DATA9_ADDR       = 32'h0000000d;
      localparam DATA10_ADDR      = 32'h0000000e;
      localparam DATA11_ADDR      = 32'h0000000f;

      always@(posedge clock or negedge resetn)
         begin
            if(!resetn)
               begin
                  data0_reg  <= 32'b0;
                  data1_reg  <= 32'b0;
                  data2_reg  <= 32'b0;
                  data3_reg  <= 32'b0;
                  data4_reg  <= 32'b0;
                  data5_reg  <= 32'b0;
                  data6_reg  <= 32'b0;
                  data7_reg  <= 32'b0;
                  data8_reg  <= 32'b0;
                  data9_reg  <= 32'b0;
                  data10_reg <= 32'b0;
                  data11_reg <= 32'b0;
                  access_reg_command_done <= 1'b0;
                  access_cpu_reg <= 1'b0;
                  core_cpu_reg_write <= 1'b0;
                  core_data_out_valid <= 1'b0;
                  core_data_out <= 64'b0;
                  access_mem_read <= 1'b0;
                  access_mem_addr <= 64'b0;
                  access_mem_data_out <= 64'b0;
                  access_mem_data_out_valid <= 1'b0;
                  access_mem_command_done <= 1'b0;
                  access_memory <= 1'b0;
               end
            else 
               begin
                  if(!dmactive)
                     begin
                        data0_reg  <= 32'b0;
                        data1_reg  <= 32'b0;
                        data2_reg  <= 32'b0;
                        data3_reg  <= 32'b0;
                        data4_reg  <= 32'b0;
                        data5_reg  <= 32'b0;
                        data6_reg  <= 32'b0;
                        data7_reg  <= 32'b0;
                        data8_reg  <= 32'b0;
                        data9_reg  <= 32'b0;
                        data10_reg <= 32'b0;
                        data11_reg <= 32'b0;
                        access_reg_command_done <= 1'b0;
                        access_cpu_reg <= 1'b0;
                        core_cpu_reg_write<= 1'b0;
                        core_data_out_valid <= 1'b0;
                        core_data_out <= 64'b0;
                        access_mem_read <= 1'b0;
                        access_mem_addr <= 64'b0;
                        access_mem_data_out <= 64'b0;
                        access_mem_data_out_valid <= 1'b0;
                        access_mem_command_done <= 1'b0;
                        access_memory <= 1'b0;
                     end
                  else 
                     begin
                        if(apb_write && access_reg_cmd==1'b0 && access_mem_cmd==1'b0)
                           begin
                              access_cpu_reg <= 1'b0;
                              access_memory <= 1'b0;
                              access_reg_command_done <= 1'b0;
                              access_mem_command_done <= 1'b0;
                              core_cpu_reg_write <= 1'b0;
                              access_mem_read <= 1'b0;
                              access_mem_addr <= 64'b0;
                              core_data_out <= 64'b0;
                              core_data_out_valid <= 1'b0;
                              access_mem_data_out <= 64'b0;
                              access_mem_data_out_valid <= 1'b0;
                              if(apb_addr==DATA0_ADDR)
                                 begin
                                    data0_reg <= apb_wdata;
                                 end
                              else if(apb_addr==DATA1_ADDR)
                                 begin
                                    data1_reg <= apb_wdata;
                                 end
                              else if(apb_addr==DATA2_ADDR)
                                 begin
                                    data2_reg <= apb_wdata;
                                 end
                              else if(apb_addr==DATA3_ADDR)
                                 begin
                                    data3_reg <= apb_wdata;
                                 end
                              else if(apb_addr==DATA4_ADDR)
                                 begin
                                    data4_reg <= apb_wdata;
                                 end
                              else if(apb_addr==DATA5_ADDR)
                                 begin
                                    data5_reg <= apb_wdata;
                                 end
                              else if(apb_addr==DATA6_ADDR)
                                 begin
                                    data6_reg <= apb_wdata;
                                 end
                              else if(apb_addr==DATA7_ADDR)
                                 begin
                                    data7_reg <= apb_wdata;
                                 end
                              else if(apb_addr==DATA8_ADDR)
                                 begin
                                    data8_reg <= apb_wdata;
                                 end
                              else if(apb_addr==DATA9_ADDR)
                                 begin
                                    data9_reg <= apb_wdata;
                                 end
                              else if(apb_addr==DATA10_ADDR)
                                 begin
                                    data10_reg <= apb_wdata;
                                 end
                              else if(apb_addr==DATA11_ADDR)
                                 begin
                                    data11_reg <= apb_wdata;
                                 end
                           end
                        else if(access_reg_cmd && halted && cmderr!=3'b011)
                           begin
                              access_memory <= 1'b0;
                              access_mem_command_done <= 1'b0;
                              if(write==1'b0 && transfer==1'b1)
                                 begin
                                    core_cpu_reg_write <= 1'b0;
                                    if(aarsize==3'b010)
                                       begin
                                          access_cpu_reg <= 1'b1;
                                          if(core_data_in_valid)
                                             begin
                                                data0_reg <= core_data_in[31:0] ;
                                                access_reg_command_done <= 1'b1;
                                             end
                                          else
                                             begin
                                                data0_reg <= data0_reg ;
                                                access_reg_command_done <= 1'b0;
                                             end
                                       end
                                    else if(aarsize==3'b011)
                                       begin
                                          access_cpu_reg <= 1'b1;
                                          if(core_data_in_valid)
                                             begin
                                                data0_reg <= core_data_in[63:32];
                                                data1_reg <= core_data_in[31:0] ;
                                                access_reg_command_done <= 1'b1;
                                             end
                                          else
                                             begin
                                                data0_reg <= data0_reg ;
                                                data1_reg <= data1_reg ;
                                                access_reg_command_done <= 1'b0;
                                             end
                                       end
                                    else
                                       begin
                                          access_cpu_reg <= 1'b0;
                                          data0_reg <= data0_reg;
                                          data1_reg <= data1_reg;
                                          access_reg_command_done <= 1'b0;
                                       end
                                 end
                              else if(write==1'b1 && transfer==1'b1)
                                 begin
                                    core_cpu_reg_write <= 1'b1;
                                    if(aarsize==3'b010)
                                       begin
                                          access_cpu_reg <= 1'b1 ;
                                          core_data_out <= {32'b0,data0_reg};
                                          core_data_out_valid <= 1'b1;
                                          access_reg_command_done <= 1'b1;
                                       end
                                    else if(aarsize==3'b011)
                                       begin
                                          access_cpu_reg <= 1'b1;
                                          core_data_out <= {data0_reg, data1_reg};
                                          core_data_out_valid <= 1'b1;
                                          access_reg_command_done <= 1'b1;
                                       end
                                    else
                                       begin
                                          access_cpu_reg <= 1'b0;
                                          core_data_out <= 64'b0;
                                          core_data_out_valid <= 1'b0;
                                          access_reg_command_done <= 1'b0;
                                       end
                                 end
                              else
                                 begin
                                    core_cpu_reg_write <= 1'b0;
                                    access_cpu_reg <= 1'b0;
                                    core_data_out <= 64'b0;
                                    core_data_out_valid <= 1'b0;
                                    access_reg_command_done <= 1'b0;
                                 end
                           end
                        else if(access_mem_cmd && halted)
                           begin
                              access_cpu_reg <= 1'b0;
                              access_reg_command_done <= 1'b0;
                              if(aamsize == 3'b000)
                                 begin
                                    access_memory <= 1'b1 ;
                                    if(write==1'b0)
                                       begin
                                          access_mem_addr <= {32'b0,data1_reg} ;
                                          access_mem_read <= 1'b1 ;
                                          if(access_mem_data_in_valid)
                                             begin
                                                data0_reg <= {24'b0,access_mem_data_in[7:0]} ;
                                                access_mem_command_done <= 1'b1;
                                                if(aampostincrement && access_mem_command_done)
                                                   begin
                                                      data1_reg <= data1_reg + 4'b1000;
                                                   end
                                             end
                                          else
                                             begin
                                                access_mem_command_done <= 1'b0;
                                             end
                                       end
                                    else
                                       begin
                                          access_mem_addr <= {32'b0,data1_reg} ;
                                          access_mem_read <= 1'b0 ;
                                          access_mem_data_out <= {56'b0,data0_reg[7:0]} ;
                                          access_mem_data_out_valid <= 1'b1;
                                          access_mem_command_done <= 1'b1;
                                          if(aampostincrement && access_mem_command_done)
                                             begin
                                                data1_reg <=data1_reg + 4'b1000;
                                             end
                                       end
                                 end
                              else if(aamsize == 3'b001)
                                 begin
                                    access_memory <= 1'b1 ;
                                    if(write==1'b0)
                                       begin
                                          access_mem_addr <= {32'b0,data1_reg} ;
                                          access_mem_read <= 1'b1 ;
                                          if(access_mem_data_in_valid)
                                             begin
                                                data0_reg <= {16'b0,access_mem_data_in[15:0]} ;
                                                access_mem_command_done <= 1'b1;
                                                if(aampostincrement && access_mem_command_done)
                                                   begin
                                                      data1_reg <= data1_reg + 5'b10000;
                                                   end
                                             end
                                          else
                                             begin
                                                access_mem_command_done <= 1'b0;
                                             end 
                                       end      
                                    else
                                       begin
                                          access_mem_addr <= {32'b0,data1_reg} ;
                                          access_mem_read <= 1'b0 ;
                                          access_mem_data_out <= {48'b0,data0_reg[15:0]} ;
                                          access_mem_data_out_valid <= 1'b1;
                                          access_mem_command_done <= 1'b1;
                                          if(aampostincrement && access_mem_command_done)
                                             begin
                                                data1_reg <= data1_reg + 5'b10000 ;
                                             end
                                       end
                                 end
                              else if(aamsize == 3'b010)
                                 begin
                                    access_memory <= 1'b1 ;
                                    if(write==1'b0)
                                       begin
                                          access_mem_addr <= {32'b0,data1_reg} ;
                                          access_mem_read <= 1'b1 ;
                                          if(access_mem_data_in_valid)
                                             begin
                                                data0_reg <= access_mem_data_in[31:0] ;
                                                access_mem_command_done <= 1'b1;
                                                if(aampostincrement && access_mem_command_done)
                                                   begin
                                                      data1_reg <= data1_reg + 6'b100000;
                                                   end
                                             end
                                          else
                                             begin
                                                access_mem_command_done <= 1'b0;
                                             end 
                                       end
                                    else
                                       begin
                                          access_mem_addr <= {32'b0,data1_reg} ;
                                          access_mem_read <= 1'b0 ;
                                          access_mem_data_out <= {32'b0,data0_reg} ;
                                          access_mem_data_out_valid <= 1'b1;
                                          access_mem_command_done <= 1'b1;
                                          if(aampostincrement && access_mem_command_done)
                                             begin
                                                data1_reg <= data1_reg + 6'b100000 ;
                                             end 
                                       end
                                 end
                              else if(aamsize == 3'b011)
                                 begin
                                    access_memory <= 1'b1 ;
                                    if(write==1'b0)
                                       begin
                                          access_mem_addr <= {data0_reg,data1_reg} ;
                                          access_mem_read <= 1'b1 ;
                                          if(access_mem_data_in_valid)
                                             begin
                                                data2_reg <= access_mem_data_in[63:32];
                                                data3_reg <= access_mem_data_in[31:0] ;
                                                access_mem_command_done <= 1'b1;
                                                if(aampostincrement && access_mem_command_done)
                                                   begin
                                                      {data3_reg,data2_reg} <= {data3_reg,data2_reg} + 7'b1000000 ;
                                                   end
                                             end
                                          else
                                             begin
                                                access_mem_command_done <= 1'b0;
                                             end 
                                       end
                                    else
                                       begin
                                          access_mem_addr <= {data0_reg,data1_reg} ;
                                          access_mem_read <= 1'b0 ;
                                          access_mem_data_out <= {data2_reg,data3_reg} ;
                                          access_mem_data_out_valid <= 1'b1;
                                          access_mem_command_done <= 1'b1;
                                          if(aampostincrement && access_mem_command_done)
                                             begin
                                                {data3_reg,data2_reg} <= {data3_reg,data2_reg} + 7'b1000000 ;
                                             end 
                                       end
                                 end
                              else
                                 begin
                                    access_memory <= 1'b0 ;
                                    access_mem_addr <= 64'b0 ;
                                    access_mem_data_out <= 64'b0 ;
                                    access_mem_data_out_valid <= 1'b0;
                                    access_mem_read <= 1'b0 ;
                                    access_mem_command_done <= 1'b0;
                                 end
                           end
                        else
                           begin
                              access_memory <= 1'b0;
                              access_mem_command_done <= 1'b0;
                              access_cpu_reg <= 1'b0;
                              access_reg_command_done <= 1'b0;
                           end
                     end
               end
         end


endmodule
