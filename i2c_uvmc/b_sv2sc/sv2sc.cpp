#include "uvmc.h"
using namespace uvmc;

#include "b_slave.h"

int sc_main( int argc, char* argv[] )
{
  i2c_slave i2c_slv_inst("i2c_slv_inst");
  uvmc_connect (i2c_slv_inst.s_socket,"foo");
  sc_start(-1);
  return 0;
}


