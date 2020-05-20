#pragma once
#include<systemc.h>
#include<tlm.h>
#include<list>
#include<bitset>
//using namespace std;
//using namespace tlm;
#include<tlm_utils/tlm_quantumkeeper.h>		  
#include <tlm_utils/simple_initiator_socket.h>
//#include <tlm_utils/simple_target_socket.h>
//using namespace tlm_utils;
#define info std::cout << " [ " << sc_time_stamp() << "  : "<< name() <<  " ] "

// I2C_MASTER

struct i2c_master : public sc_module 
{
  tlm_utils::simple_initiator_socket<i2c_master> m_socket;
  sc_event done;

  SC_CTOR(i2c_master) : m_socket("m_socket")
  {
    m_qk.set_global_quantum(sc_time(100, SC_NS));
		m_qk.reset();
    SC_THREAD(process);// read or write process
  }


  void process()
  {
    uint8_t data, read_data;
    unsigned long addr = 5;
    int count = 0;
    while(true)
    {
      if(m_list.size() > 0)
      {
        data = m_list.front();
        info << "Master sends data value : " << std::bitset<8>(data) << std::endl;
        m_list.pop_front();
        gp->set_write();
        gp->set_data_length(sizeof(data));
        gp->set_data_ptr((unsigned char*)&data);
        count ++;
        info << "write Command by the master and count value " << count << std::endl; 
      }
      else
      {
        info << "Read Command by the master and count value " << count << std::endl; 
        gp->set_read();
        count--;
        if(count == 0)
          sc_stop();
      }

      gp->set_address(addr);

      delay = m_qk.get_local_time();
      delay = sc_time(10, SC_NS);
      info << "Before b_transport : delay = " << delay << endl;
      m_socket->b_transport( *gp, delay );  // Blocking transport call
      wait(10, SC_NS);
      info << "After b_transport : delay = " << delay << endl;


      if(gp->is_read())
      {
        memcpy(&read_data, gp->get_data_ptr(), sizeof(uint8_t ));
        info << "Read data " << std::bitset<8>(read_data) <<  std::endl;
        s_list.push_back(read_data);
      }
      m_qk.set(delay);
      if(m_qk.need_sync())
      {
        info << "Current Time :" << m_qk.get_current_time() << "\t Local Time" << m_qk.get_local_time() << std::endl;
        m_qk.sync();
        info << "Current Time :" << m_qk.get_current_time() << "\t Local Time" << m_qk.get_local_time() << std::endl;
      }

    
      info << "======================== XXX ==================" << std::endl;
    }
    done.notify();
  }

  private:
  tlm::tlm_generic_payload* gp = new tlm::tlm_generic_payload;
  tlm_utils::tlm_quantumkeeper m_qk;
  std::list<uint8_t> m_list{5,10,15,20,25,30,35,40,152,255};
  std::list<uint8_t> s_list;
  sc_time delay;
  

};
