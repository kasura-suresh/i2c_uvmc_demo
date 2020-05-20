//`timescale 1ns/1ns;
`include "uvm_macros.svh"
import uvm_pkg::*;
import uvmc_pkg::*;
`include "i2c_phases.svh";
`include "i2c_master.svh";

module sv_main;
  
  i2c_master i2c_m = new("i2c_m");
  
  initial begin
    
    uvmc_tlm#()::connect(i2c_m.initSocket, "sv2sc");
    
    run_test();
	
  end
endmodule
