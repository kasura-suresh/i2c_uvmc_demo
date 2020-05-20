`timescale 1ns/1ns;
`include "uvm_macros.svh"
import uvm_pkg::*;
import uvmc_pkg::*;
`include "i2c_slave.svh";

module sv_main;
  
  i2c_slave i2c_s = new("i2c_s");
  
  initial begin
    
	
    uvmc_tlm#()::connect(i2c_s.tgSocket,"foo");
    
    run_test();
	
  end
endmodule



