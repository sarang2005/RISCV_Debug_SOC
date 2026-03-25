/* #################################################################################################
-- # RISC-V Debug Transport Module (DTM) - compatible to the RISC-V debug specification            #
-- # ********************************************************************************************* #
-- # Provides a JTAG-compatible TAP to access the DMI register interface.                          #
-- # ********************************************************************************************* #
-- # Designer T.Nikhitha									   #
-- # ********************************************************************************************* #*/
//Version 1.6.1

`timescale 1ns/1ns

// Length of the Instruction register
`define	IR_LENGTH	5
// Supported Instructions
`define IDCODE          5'b00001
`define DTMCS           5'b10000
`define DMI             5'b10001
`define BYPASS          5'b11111
`define IDCODE_VERSION  4'b0001
`define IDCODE_PARTID   16'h0418
`define IDCODE_MANID    11'h2ab
`define DMI_IDLE        3'b000
`define DMI_READ_WAIT   3'b001 
`define DMI_READ_BUSY   3'b010
`define DMI_WRITE_WAIT  3'b011
`define DMI_WRITE_BUSY  3'b100 

module jtag_dtm_tap_top #( parameter APB_ADDR_WIDTH = 32     ,
                           parameter APB_DATA_WIDTH = 32              
                        )(

// JTAG connection

input                               jtag_tms_i    ,      // JTAG test mode select
input                               jtag_tck_i    ,      // JTAG test clock 
input                               jtag_nreset_i ,   // JTAG test reset 
input                               jtag_tdi_i    ,      // JTAG test data input
output reg                          jtag_tdo_o    ,      // JTAG test data output

// debug module interface (DMI) 

input 	                            dmi_prstn_i   ,
input	                            dmi_pclk_i    ,
input                               dmi_pready_i  ,    //DMI is allowed to make new requests when set
input      [APB_DATA_WIDTH-1:0]     dmi_prdata_i  ,
input                               dmi_pslverr   ,
output reg                          dmi_penable_o ,
output reg                          dmi_psel_o    ,
output reg [APB_ADDR_WIDTH-1:0]     dmi_paddress_o,  //7bit address 
output reg                          dmi_pwrite_o  ,
output reg [APB_DATA_WIDTH-1:0]     dmi_pwdata_o );    //0=ok,1=error

parameter DMI_REG_WITDH = APB_ADDR_WIDTH + APB_DATA_WIDTH ;
// Registers
reg     test_logic_reset;
reg     run_test_idle;
reg     select_dr_scan;
reg     capture_dr;
reg     shift_dr;
reg     exit1_dr;
reg     pause_dr;
reg     exit2_dr;
reg     update_dr;
reg     select_ir_scan;
reg     capture_ir;
reg     shift_ir, shift_ir_neg; 
reg     exit1_ir;
reg     pause_ir;
reg     exit2_ir;
reg     update_ir;
reg     idcode_select;
reg 	dtmcs_select;
reg 	dmi_select;	
reg     bypass_select;
reg     tms_q1 =0, tms_q2 =0, tms_q3 =0, tms_q4=0;
wire    tms_reset;


always @ (posedge jtag_tck_i)
begin
  tms_q1 <= jtag_tms_i;
  tms_q2 <= tms_q1;
  tms_q3 <= tms_q2;
  tms_q4 <= tms_q3;
end


assign tms_reset = tms_q1 & tms_q2 & tms_q3 & tms_q4 & jtag_tms_i;    // 5 consecutive tms=1 causes reset

/**********************************************************************************
*   TAP State Machine: Fully JTAG compliant                                       *
**********************************************************************************/

// test_logic_reset state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      test_logic_reset <= 1'b1;
    else 
      begin
        if (tms_reset)
          test_logic_reset <= 1'b1;
        else
          begin
            if(jtag_tms_i && (test_logic_reset || select_ir_scan))
              test_logic_reset <= 1'b1;
            else
              test_logic_reset <= 1'b0;
          end
      end
  end

// run_test_idle state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
  if(!jtag_nreset_i)
    run_test_idle <= 1'b0;
  else 
    begin
      if (tms_reset)
        run_test_idle <= 1'b0;
      else
        begin
          if(~jtag_tms_i && (test_logic_reset || run_test_idle || update_dr || update_ir))
            run_test_idle <= 1'b1;
          else
            run_test_idle <= 1'b0;
        end
    end
end

// select_dr_scan state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      select_dr_scan <= 1'b0;
    else 
      begin
        if (tms_reset)
          select_dr_scan <= 1'b0;
        else
          begin
            if(jtag_tms_i && (run_test_idle || update_dr || update_ir))
              select_dr_scan <= 1'b1;
            else
              select_dr_scan <= 1'b0;
          end
      end
  end

// capture_dr state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      capture_dr <= 1'b0;
    else 
      begin
        if (tms_reset)
          capture_dr <= 1'b0;
        else
          begin
            if(~jtag_tms_i && select_dr_scan)
              capture_dr <= 1'b1;
            else
              capture_dr <= 1'b0;
          end
      end
  end

// shift_dr state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      shift_dr <= 1'b0;
    else 
      begin
        if (tms_reset)
          shift_dr <= 1'b0;
        else
          begin
            if(~jtag_tms_i && (capture_dr || shift_dr || exit2_dr))
              shift_dr <= 1'b1;
            else
              shift_dr <= 1'b0;
          end
      end
  end

// exit1_dr state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      exit1_dr <= 1'b0;
    else 
      begin
        if (tms_reset)
          exit1_dr <= 1'b0;
        else
          begin
            if(jtag_tms_i && (capture_dr || shift_dr))
              exit1_dr <= 1'b1;
            else
              exit1_dr <= 1'b0;
          end
      end
  end

// pause_dr state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      pause_dr <= 1'b0;
    else 
      begin
        if (tms_reset)
          pause_dr <= 1'b0;
        else
          begin
            if(~jtag_tms_i && (exit1_dr || pause_dr))
              pause_dr <= 1'b1;
            else
              pause_dr <= 1'b0;
          end
      end
  end

// exit2_dr state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      exit2_dr <= 1'b0;
    else 
      begin
        if (tms_reset)
          exit2_dr <= 1'b0;
        else
          begin
            if(jtag_tms_i && pause_dr)
              exit2_dr <= 1'b1;
            else
              exit2_dr <= 1'b0;
          end
      end
  end

// update_dr state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      update_dr <= 1'b0;
    else
      begin 
        if (tms_reset)
          update_dr <= 1'b0;
        else
          begin
            if(jtag_tms_i && (exit1_dr || exit2_dr))
              update_dr <= 1'b1;
            else
              update_dr <= 1'b0;
          end
      end
  end

// select_ir_scan state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      select_ir_scan <= 1'b0;
    else 
      begin
        if (tms_reset)
          select_ir_scan <= 1'b0;
        else
          begin
            if(jtag_tms_i && select_dr_scan)
              select_ir_scan <= 1'b1;
            else
              select_ir_scan<= 1'b0;
          end
      end
  end

// capture_ir state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      capture_ir <= 1'b0;
    else
      begin 
        if (tms_reset)
          capture_ir <= 1'b0;
        else
          begin
            if(~jtag_tms_i && select_ir_scan)
              capture_ir <= 1'b1;
            else
              capture_ir <= 1'b0;
          end
      end
  end

// shift_ir state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      shift_ir <= 1'b0;
    else 
      begin
        if (tms_reset)
          shift_ir <= 1'b0;
        else
          begin          
            if(~jtag_tms_i && (capture_ir || shift_ir || exit2_ir))
              shift_ir <= 1'b1;
            else
              shift_ir <= 1'b0;
          end
      end
  end

// exit1_ir state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      exit1_ir <= 1'b0;
    else
      begin 
        if (tms_reset)
          exit1_ir <= 1'b0;
        else
          begin
            if(jtag_tms_i && (capture_ir || shift_ir))
              exit1_ir <= 1'b1;
            else
              exit1_ir <= 1'b0;
          end
      end
  end

// pause_ir state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      pause_ir <= 1'b0;
    else 
      begin
        if (tms_reset)
          pause_ir <= 1'b0;
        else
          begin
            if(~jtag_tms_i && (exit1_ir || pause_ir))
              pause_ir <= 1'b1;
            else
              pause_ir<= 1'b0;
          end
      end
  end

// exit2_ir state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      exit2_ir <= 1'b0;
    else 
      begin
        if (tms_reset)
          exit2_ir <= 1'b0;
        else
          begin
            if(jtag_tms_i && pause_ir)
              exit2_ir <= 1'b1;
            else
              exit2_ir <= 1'b0;
          end
      end
  end

// update_ir state
always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
  begin
    if(!jtag_nreset_i)
      update_ir <= 1'b0;
    else
      begin
        if (tms_reset)
          update_ir <= 1'b0;
        else
          begin
            if(jtag_tms_i && (exit1_ir || exit2_ir))
              update_ir <= 1'b1;
            else
              update_ir <= 1'b0;
          end
      end  
  end

/**********************************************************************************
*   End: TAP State Machine                                                        *
**********************************************************************************/

/**********************************************************************************
*   TAP control FSM and Register access                                                               *
**********************************************************************************/
reg  [3:0]version = `IDCODE_VERSION;
reg  [15:0]part_number = `IDCODE_PARTID;
reg  [10:0]manufacturer_id = `IDCODE_MANID;
reg  [`IR_LENGTH-1:0]  jtag_ir;          // Instruction register
reg  [`IR_LENGTH-1:0]  latched_jtag_ir, latched_jtag_ir_neg;
reg  [31:0]idcode_reg;
reg  [31:0]dtmcs_reg,dtmcs_reg_nxt;
reg  [65:0]dmi_reg,dmi_reg_nxt;
reg        bypass_reg;
reg        dtmhardreset;
reg        dmireset;

reg        instruction_tdo;
reg        dmi_tdo;
reg        dtmcs_tdo;
reg        idcode_tdo;
reg        bypassed_tdo;


always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
begin
  if(!jtag_nreset_i)
    latched_jtag_ir <= `IDCODE;   // IDCODE selected after reset
  else
    begin
      if(tms_reset)
        latched_jtag_ir <= `IDCODE;   // IDCODE selected after reset
      else if(update_ir)
        latched_jtag_ir <= jtag_ir;
    end
end

always @ (negedge jtag_tck_i)
begin
  shift_ir_neg <=  shift_ir;
  latched_jtag_ir_neg <=  latched_jtag_ir;
end

// Updating jtag_ir (Instruction Register)
always @ (latched_jtag_ir)
begin
  idcode_select           = 1'b0;
  dtmcs_select  	  = 1'b0;
  dmi_select   	          = 1'b0;
  bypass_select           = 1'b0;

  case(latched_jtag_ir)    /* synthesis parallel_case */ 
    `IDCODE:            idcode_select           = 1'b1;    // IDCODE
    `DTMCS:             dtmcs_select  		= 1'b1;    // DTMCS
    `DMI:               dmi_select              = 1'b1;    // DMI
    `BYPASS:            bypass_select           = 1'b1;    // BYPASS
    default:            bypass_select           = 1'b1;    // BYPASS
  endcase
end

always @ (posedge jtag_tck_i or negedge jtag_nreset_i)
begin
  if(!jtag_nreset_i ) begin
    jtag_ir    <= 5'b00001;
    idcode_reg <= 32'd0;
    dtmcs_reg  <= 32'd0;
    dmi_reg    <= 66'd0;
    bypass_reg <= 1'b0;
  end
  else
  begin
      if(dtmhardreset)
        begin
        jtag_ir    <= 5'b00001;
        idcode_reg <= 32'd0;
        dtmcs_reg  <= 32'd0;
        dmi_reg    <= 66'd0;
        bypass_reg <= 1'b0;
        end
      else if( capture_ir)
        jtag_ir   <=  5'b00001;          // This value is fixed for easier fault detection
      else if(shift_ir)
        jtag_ir[`IR_LENGTH-1:0] <= {jtag_tdi_i, jtag_ir[`IR_LENGTH-1:1]};    
      else if(capture_dr) begin
         case(latched_jtag_ir)    /* synthesis parallel_case */ 
             `IDCODE:            idcode_reg       = {version,part_number,manufacturer_id,1'd1};    // IDCODE		  
             `DTMCS:             dtmcs_reg        = dtmcs_reg_nxt;    // DTMCS
             `DMI:               dmi_reg          = dmi_reg_nxt;    // DMI
             `BYPASS:            bypass_reg       = 1'b0;    // BYPASS
         default:                bypass_reg       = 1'b0;    // BYPASS
         endcase
       end
      else if(shift_dr) begin
         case(latched_jtag_ir)    /* synthesis serial_shift_case */ 
             `IDCODE:            idcode_reg = {jtag_tdi_i, idcode_reg[31:1]};    // IDCODE
             `DTMCS:             dtmcs_reg  = {jtag_tdi_i, dtmcs_reg[31:1]};     // DTMCS
             `DMI:               dmi_reg    = {jtag_tdi_i, dmi_reg[65:1]};       // DMI
             `BYPASS:            bypass_reg = jtag_tdi_i;                        // BYPASS
         default:                bypass_reg = jtag_tdi_i;                        // BYPASS
         endcase
       end
  end
end
   
always @ (negedge jtag_tck_i or negedge jtag_nreset_i)
begin
if(!jtag_nreset_i) begin 
    instruction_tdo <= 1'b0;
    idcode_tdo <=  1'b0;
    dtmcs_tdo <=  1'b0;
    dmi_tdo <=  1'b0;
    bypassed_tdo <= 1'b0;
end
else begin
    instruction_tdo <= jtag_ir[0];
    idcode_tdo <=  idcode_reg[0];
    dtmcs_tdo <=  dtmcs_reg[0];
    dmi_tdo <=  dmi_reg[0];
    bypassed_tdo <= bypass_reg;
end
end
/**********************************************************************************
*   End: TAP control FSM and Register access                                     *
**********************************************************************************/

/**********************************************************************************
*   Multiplexing tdo data                                                         *
**********************************************************************************/
always@(negedge jtag_tck_i  or negedge jtag_nreset_i)
begin
  if(!jtag_nreset_i)
     begin
        jtag_tdo_o <= 1'b0;
     end
  else
     begin
        if(shift_ir_neg)
          jtag_tdo_o <= instruction_tdo;
        else
          begin
            case(latched_jtag_ir_neg)    // synthesis parallel_case
              `IDCODE:            jtag_tdo_o <= idcode_tdo;       // Reading ID code
              `DTMCS:             jtag_tdo_o <= dtmcs_tdo;        // Debug transport module control and status 
              `DMI:               jtag_tdo_o <= dmi_tdo;          // Debug Module Interface
              `BYPASS:            jtag_tdo_o <= bypassed_tdo;     // BYPASS instruction
               default:           jtag_tdo_o <= bypassed_tdo;     // BYPASS instruction
            endcase
          end
    end
end

/**********************************************************************************
*   End: Multiplexing tdo data                                                    *
**********************************************************************************/

/**********************************************************************************
*   DMIlogic
**********************************************************************************/ 
reg [2:0] errinfo;               // 3 bit value represents error info
reg [2:0] idle    = 3'b000;      // -- no idle cycles required, vector(02 downto 0)
reg [1:0] dmistat;               // -- this represents OP of DMI
reg [5:0] abits   = 6'b000111;   // -- number of DMI address bits (7), vector(05 downto 0)
reg [3:0] dmi_version = 4'b0001;     //-- version (0.13), vector(03 downto 0)
reg [2:0] dmi_ctrl_state; 
reg       update_dr_samp1;
reg       update_dr_samp2;
wire      dmi_transfer;  


always@(posedge dmi_pclk_i  or negedge dmi_prstn_i)
  begin
    if(!dmi_prstn_i)
      begin
        update_dr_samp1 <= 1'b0;
      end
    else 
      begin
        update_dr_samp1 <= update_dr;
      end
end

always@(posedge dmi_pclk_i or negedge dmi_prstn_i)
  begin
    if(!dmi_prstn_i)
      begin
        update_dr_samp2 <= 1'b0;
      end
    else
      begin
        update_dr_samp2 <= update_dr_samp1;
      end
  end 

assign dmi_transfer = update_dr && !update_dr_samp2;

//dtmhardreset & dmireset logic
always@(posedge jtag_tck_i or negedge jtag_nreset_i)
   begin
      if(!jtag_nreset_i)
         begin
            dtmhardreset <= 1'b0;
            dmireset     <= 1'b0;
         end
      else
         begin
            if(dtmhardreset)
               begin
                  dtmhardreset <= 1'b0;
                  dmireset     <= 1'b0;
               end
            else if(update_dr && dtmcs_select)
               begin
                  dtmhardreset <= dtmcs_reg[17];
                  dmireset     <= dtmcs_reg[16];
               end
         end
   end


always @(posedge dmi_pclk_i or negedge  dmi_prstn_i)
begin
	if(!dmi_prstn_i) begin
	dmi_ctrl_state <= `DMI_IDLE;
        errinfo        <= 3'b000;
   	dmistat        <= 2'b00;
  	dmi_pwdata_o   <= 32'h00000000;
   	dmi_paddress_o <= 32'h0;
   	dmi_penable_o  <= 1'd0;
  	dmi_psel_o     <= 1'd0;
  	dmi_pwrite_o   <= 1'd0;
        end
   	else if(dtmhardreset)  begin
   	dmi_ctrl_state <= `DMI_IDLE;
	errinfo        <= 3'b000;
   	end
	else if (dmireset)
	errinfo        <= 3'b000;     
      	else begin
	case(dmi_ctrl_state)
        `DMI_IDLE:
	 if (update_dr && dmi_select && dmi_transfer) begin
              if (dmi_reg[1:0] ==2'b01) begin
                dmi_ctrl_state = `DMI_READ_WAIT;
		dmistat        = dmi_reg[1:0];
		dmi_pwrite_o   = 0;
	        dmi_psel_o     = 1;
                dmi_paddress_o = dmi_reg[65:34];
                dmi_pwdata_o   = 32'b0;
	      end
              else if (dmi_reg[1:0] == 2'b10 ) begin
                dmi_ctrl_state = `DMI_WRITE_WAIT;
		dmistat        = dmi_reg[1:0];
	        dmi_pwrite_o   = 1;
	        dmi_psel_o     = 1;
                dmi_paddress_o = dmi_reg[65:34];
                dmi_pwdata_o   = dmi_reg[33:02];
	      end
              else begin
	        dmi_pwrite_o    = 1'b0;
	        dmi_psel_o      = 1'b0;
                dmi_paddress_o  = 32'b0;
                dmi_pwdata_o    = 32'b0;
	        dmistat         = dmi_reg[1:0];
	      end
	 end
        `DMI_READ_WAIT :
         if (dmi_psel_o && ! dmi_pwrite_o) begin
              dmi_ctrl_state = `DMI_READ_BUSY;
	      dmi_penable_o  = 1;
	 end          
   
         `DMI_READ_BUSY : 
          if( dmi_pready_i && dmi_psel_o && dmi_penable_o && ! dmi_pwrite_o )begin
	      dmi_ctrl_state       = `DMI_IDLE;
	      dmi_psel_o           = 0; 
	      dmi_penable_o        = 0;
	      errinfo              = dmi_pslverr? 3'd1:3'd0;
	  end

         `DMI_WRITE_WAIT :
          if (dmi_pwrite_o && dmi_psel_o ) begin
              dmi_ctrl_state = `DMI_WRITE_BUSY;
	      dmi_penable_o  = 1;
	  end
            
            `DMI_WRITE_BUSY:
          if (dmi_pready_i && dmi_psel_o && dmi_penable_o &&  dmi_pwrite_o) begin	                
 	      dmi_ctrl_state       = `DMI_IDLE;
	      dmi_psel_o           = 0; 
	      dmi_penable_o        = 0;
	      errinfo              = dmi_pslverr? 3'd1:3'd0;	             
         end
      default dmi_ctrl_state     = `DMI_IDLE;
      endcase
     end
end

always@(posedge dmi_pclk_i or negedge dmi_prstn_i)
  begin
    if(!dmi_prstn_i)
       begin
         dmi_reg_nxt <= 66'b0;
       end
    else
      begin
	 if (dmi_pwrite_o && dmi_psel_o && dmi_penable_o) 
            dmi_reg_nxt <= {dmi_paddress_o,dmi_pwdata_o,dmistat};
	 else if(!dmi_pwrite_o && dmi_psel_o && dmi_penable_o)
            dmi_reg_nxt <= {dmi_paddress_o,dmi_prdata_i,dmistat};
         else
            dmi_reg_nxt <= dmi_reg_nxt;
      end
  end

always@(*)
  begin
    if(dmi_psel_o)
     	 dtmcs_reg_nxt = {11'd0,errinfo,dtmcs_reg[17:16],1'b0,idle,dmi_reg_nxt[1:0],abits,dmi_version};
    else
     	 dtmcs_reg_nxt = {11'd0,errinfo,dtmcs_reg[17:16],1'b0,idle,2'b00,abits,dmi_version};
  end
            
/**********************************************************************************
*   End: DMI logic                                                                *
***********************************************************************************/

endmodule
