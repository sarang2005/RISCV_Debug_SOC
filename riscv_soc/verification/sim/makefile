#**************************************************************************************
#Project: RISC V and DM integration
#Company: ACL Digital
#Domain: Design Verification
#File_name: makefile
#Description: The following file provides all the phases info
#***************************************************************************************

#export TEST_PATH = /scratch/semi_projects/RISC_V_Debug/akshay/riscv_debug/verification/sim
#----------------------------------------------------------------------------------------#
# apb_master tests
#----------------------------------------------------------------------------------------#
#include ${TEST_PATH}/makefile.apb_master

clean:
	@echo "Cleaning up..."
	rm -rf cds.lib RUN_XM xcelium.d xmprep.history xmvlog.args hdl.var dm.log xmelab.args xmprep.log compile_xm.log Debug_module_log xmsim.args xmvlog.log simvision138398.diag xmelab.log xmsim.key xmsim.log dump.vcd run.tcl waves.shm xmvlog_sv.args xrun.history worklib_-3_0.args xmvlog_ver.args xrun.log   

all:translate compile elaborate simulation waveform_viewer

translate:	
	xmprep -64bit +overwrite -timescale 1ns/1ns -uvm -f file_list.f +debug  | tee  compile.log

compile:
	xrun -64bit -access +rwc -timescale 1ns/1ns -uvm -f file_list.f 

elaborate:
	xmelab -64bit  -mess -f xmelab.args -access +r    | tee -a compile_xm.log

#// simulation:
#// 	xmsim -64bit -unbuffered -status -LICQUEUE -f xmsim.args -cdslib cds.lib -hdlvar hdl.var -NBASYNC -input run.tcl | tee sim.log ;
#// 
#// waveform_viewer:
#// 	simvision -64bit waves.shm/waves.trn &
#// 
#// run_test%:
#// 	@echo +UVM_TESTNAME=${TEST$*} 
#// 	xrun -64bit -f dm_flist.f -timescale 1ns/1ns -sysv -access  +rw +UVM_TESTNAME=${TEST$*} 
#// 	
