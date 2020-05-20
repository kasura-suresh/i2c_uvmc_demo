#include "nb_slave.h"
#include "uvmc.h"
using namespace uvmc;

int sc_main( int argc, char* argv[] )
{
  i2c_slave i2c_sin ("i2c_sin");
  uvmc_connect (i2c_sin.socket, "sv2sc");
  sc_start(-1);
  return 0;
}

