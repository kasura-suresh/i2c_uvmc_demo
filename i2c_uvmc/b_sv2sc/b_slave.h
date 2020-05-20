#pragma once
#include<systemc.h>
#include<tlm.h>
#include<list>
#include<bitset>
//using namespace std;
//using namespace tlm;
#include<tlm_utils/tlm_quantumkeeper.h>		  
//#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>
//using namespace tlm_utils;
#define info std::cout << "SC :: [ " << sc_time_stamp() << "  : "<< name() <<  " ] "

struct i2c_slave : public sc_module 
{
  tlm_utils::simple_target_socket<i2c_slave> s_socket;

  SC_CTOR(i2c_slave) : s_socket("s_socket")
  {
    s_socket.register_b_transport(this, &i2c_slave::b_transport);
  }

  void b_transport(tlm::tlm_generic_payload& gp , sc_time& delay)
  {
    //wait(delay);
    delay += sc_time(19, SC_NS);

    info << "-------------- SLAVE SIDE DETAILS ------------------ " << std::endl; 
    

    info << " Slave address by the Master : " << gp.get_address() << std::endl;
    info << "Command :  " <<  (gp.is_write()? "Write" : "Read") << std::endl;

    if( gp.get_address()  == slave_addr )
    {
      info << " Address Matched with Slave  and ready to do operation" << std::endl;
      if ( gp.is_write() )
      {
        info << "TO CHECK (write date) : DATA \t : " << (unsigned int )*gp.get_data_ptr() << std::endl;
         //       delay += (sc_time(20, SC_NS));// START + ADDR(R/W) + data + ACK + STOP = 1+8+1+8+1+1 =20
        uint8_t w_dat;
         memcpy(&w_dat, gp.get_data_ptr(), sizeof(uint8_t ));
       s_list.push_back(w_dat); 
        info << "writing completed" << std::endl;
        gp.set_response_status(tlm::TLM_OK_RESPONSE);
      }
      else if( gp.is_read() )
      {
        sc_assert( (s_list.empty() == 0) && "No data in the slave side ");
       auto r_dat = s_list.front();
       s_list.pop_front();
        gp.set_data_length(sizeof(r_dat));
        gp.set_data_ptr((unsigned char*)& (r_dat));
        delay += (sc_time(20, SC_NS));// START + ADDR(R/W) + data + ACK + STOP = 1+8+1+8+1+1 =20
        info << "READ DATA  : " <<(unsigned int) r_dat << std::endl;

        gp.set_response_status(tlm::TLM_OK_RESPONSE);
      }
      else  
      {
        SC_REPORT_ERROR ("TLM-2"," Command Error " );
        gp.set_response_status(tlm::TLM_COMMAND_ERROR_RESPONSE); 
      }
      

    }
    else
    {
      SC_REPORT_ERROR ("TLM-2"," Address Error "); 
      gp.set_response_status( tlm::TLM_ADDRESS_ERROR_RESPONSE ); // address error
    }
  }
  private:
  std::list<uint8_t> s_list{10,15,20};
  const unsigned long slave_addr = 5;
};


