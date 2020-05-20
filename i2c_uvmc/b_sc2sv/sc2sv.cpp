#include "b_master.h"
#include "uvmc.h"
using namespace uvmc;

class i2c_master_uvm : public i2c_master {

  public:

  i2c_master_uvm(sc_module_name nm) : i2c_master(nm) {
    SC_THREAD(objector);
  }

  SC_HAS_PROCESS(i2c_master_uvm);

  void objector() {
    uvmc_raise_objection("run");
    wait(done);
    uvmc_drop_objection("run");
  }

};


int sc_main( int argc, char* argv[] )
{
  i2c_master_uvm i2c_mst("i2c_mst");
  uvmc_connect (i2c_mst.m_socket,"foo");
  sc_start(-1);
  return 0;
}


