#///////////////////////////////////////////////////////////////////////////////
#// Manifest for the CV32E40P RTL model.
#//   - Intended to be used by both synthesis and simulation.
#//   - Relevent synthesis and simulation scripts/Makefiles must set the shell
#//     ENV variable DESIGN_RTL_DIR as required.
#//#Project: RISC V CV32E40P
#//Company: ACL Digital
#//File_name: file_flist
#//Description: The following provides paths of all project files to be compiled

#///////////////////////////////////////////////////////////////////////////////
#//  /scratch/semi_projects/Riscv_core/sarang/RISCV_12NOV/core-v-verif/core-v-cores/cv32e40p
#//export RISCV_DESIGN_RTL_DIR = /scratch/semi_projects/Riscv_core/sarang/RISCV_12NOV/core-v-verif/core-v-cores/cv32e40p/rtl
#//export RISCV_DESIGN_RTL_DIR =/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core


+incdir+/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/include
+incdir+/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/bhv
+incdir+/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/bhv/include
+incdir+/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/sva

/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/include/cv32e40p_apu_core_pkg.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/include/cv32e40p_fpu_pkg.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/include/cv32e40p_pkg.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/bhv/include/cv32e40p_tracer_pkg.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_if_stage.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_cs_registers.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_register_file_ff.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_load_store_unit.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_id_stage.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_aligner.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_decoder.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_compressed_decoder.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_fifo.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_prefetch_buffer.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_hwloop_regs.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_mult.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_int_controller.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_ex_stage.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_alu_div.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_alu.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_ff_one.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_popcnt.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_apu_disp.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_controller.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_obi_interface.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_prefetch_controller.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_sleep_unit.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/cv32e40p_core.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/bhv/cv32e40p_sim_clock_gate.sv
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/core/bhv/cv32e40p_wrapper.sv

#**************************************************************************************
#//Project: RISC V Debug
#//Company: ACL Digital
#//File_name: dm_flist
#//Description: The following provides paths of all project files to be compiled
#***************************************************************************************
#//export DM_HOME_DIR =  /scratch/semi_projects/RISC_V_Debug/sarang/riscv_debug
#export DM_RTL_DIR =  /scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/dm
#+incdir+${DM_HOME_DIR}/verification/testbench
#+incdir+${DM_HOME_DIR}/verification/testbench/sequences
#+incdir+${DM_HOME_DIR}/verification/testcases

+incdir+/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/dm
#***************************************************************************************
#// Note: Include all RTL files below
#//       Include all verification components in dm_pkg.sv 
#//       Include all tests in dm_test_lib.svh library
#//       Include all sequences in dm_sequence_lib.svh library
#***************************************************************************************
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/dm/apb_slave.v
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/dm/axi_master.v
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/dm/debug_module.v
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/dm/debug_module_fsm.v
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/dm/debug_module_top.v
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/dm/dm_register_file.v
/scratch/semi_projects/RISC_V_Integration/sarang/riscv_soc/dut/rtl/dm/dm_register_mux.v

#${DM_HOME_DIR}/verification/testbench/dm_testbench_top.sv
#${DM_HOME_DIR}/verification/testbench/dut_intf.sv
#${DM_HOME_DIR}/verification/testbench/dm_pkg.sv
#${DM_HOME_DIR}/verification/testbench/dm_assertions.sv
#***************************************************************************************
#// INTEGRATION FILES 
../../dut/rtl/cv32e40p_data2axi.sv
../../dut/rtl/soc_wrapper.sv
soc_wrapper_tb.sv
#***************************************************************************************


