#pragma once
#include <iostream>
#include <list>
#include <systemc.h>
#include <tlm.h>
#include <bitset>

//#include <tlm_utils/simple_initiator_socket.h> 
#include <tlm_utils/simple_target_socket.h>    
#include <tlm_utils/peq_with_cb_and_phase.h>

#define info cout << " SC :: [ " << sc_time_stamp() <<  " @ " << name() << " ] "


// START_PHASE  (fw)  // Indicates start of the transaction from master
DECLARE_EXTENDED_PHASE(START_PHASE);

// START_ACK    (bw) // Start of transaction accepted from slave side
//DECLARE_EXTENDED_PHASE(START_ACK); //change

// ADDRESS_PHASE(fw)  // start of the address phase from master side
DECLARE_EXTENDED_PHASE(ADDRESS_PHASE);

// ADDRESS_ACK  (bw)  // For that address slave is present
DECLARE_EXTENDED_PHASE(ADDRESS_ACK);

// DATA_PHASE   (fw)  // Data start 
DECLARE_EXTENDED_PHASE(DATA_PHASE);

// DATA_ACK     (bw)  // Data accepted
DECLARE_EXTENDED_PHASE(DATA_ACK);

// STOP_PHASE   (fw)  // stop the transaction
DECLARE_EXTENDED_PHASE(STOP_PHASE);


//TARGET : i2c_slave
//
//
SC_MODULE(i2c_slave)
{

  tlm_utils::simple_target_socket<i2c_slave> socket;
  //sc_event done;
  SC_CTOR(i2c_slave) :socket("socket")
  {
    socket.register_nb_transport_fw(this, &i2c_slave::nb_transport_fw);
    SC_THREAD(address_check);
    SC_THREAD(write_process);
    SC_THREAD(read_process);
  }
  tlm::tlm_sync_enum nb_transport_fw(tlm::tlm_generic_payload &gp, tlm::tlm_phase &ph, sc_time &mdelay)
  {
    info << " SC_TLM @ SLAVE :: PHASE  :" << ph <<  endl;
    if (ph == START_PHASE)
    {
        info << " Slave recived :" << ph << "\tand accepted" << endl;
      gp_pointer = &gp;
      return tlm::TLM_ACCEPTED;
    }
    if (ph == ADDRESS_PHASE)
    {
      addr_event.notify(SC_ZERO_TIME); 
      info << " Address Phase recived to I2C SLAVE" << endl;
      //delay = mdelay;
      return tlm::TLM_ACCEPTED;
    }
    if (ph == DATA_PHASE)
    {
        info << " Data Phase recived to the I2C SLAVE " << endl;
      s_write_event.notify(SC_ZERO_TIME); 
      //delay = mdelay;
      return tlm::TLM_ACCEPTED; 

    }
    if (ph == DATA_ACK)
    {
      
      //delay = mdelay;
       info << "READ : Data Ack by Master to the I2C SLAVE " << endl;
       std::cout << " -------------------------------------------- " << endl;
      if(c_s_data.size() == 0) 
        return tlm::TLM_ACCEPTED;
     // else
      //  read_event.notify(SC_ZERO_TIME); 


      return tlm::TLM_ACCEPTED; 

    }

    if (ph == STOP_PHASE)
    {
      info << " ************* Transaction is completed I2C Master *************** \n " << endl;
      is_slave_free = true;
      return tlm::TLM_COMPLETED;
      //done.notify();
    }
      return tlm::TLM_COMPLETED;

  }


  void address_check()
  {
    while(true)
    {
      wait(addr_event);
      wait(8,SC_NS);
      //wait(8,SC_NS);
        info << " Master called slave with address " << hex << gp_pointer -> get_address() << endl;
        info << " TLM COMMAND :" << (gp_pointer->is_read() ? "READ" : "WRITE") << endl;
      if( gp_pointer->get_address() == slave_addr)
      {
        is_slave_free = false;
        if(gp_pointer -> is_read() )
        {
          info << "TLM_READ_COMMAND" << endl;
          c_s_data=slave_data;
          read_event.notify(SC_ZERO_TIME);
          std::cout << " \n calling from addr read_event \n " << endl;
        }
        phase = ADDRESS_ACK;
        //delay  = sc_time(1,SC_NS);
        socket->nb_transport_bw(*gp_pointer, phase, delay);
      }
      else if ( gp_pointer-> get_command() == tlm::TLM_IGNORE_COMMAND )
        SC_REPORT_ERROR("TLM 2.0 :","TLM_IGNORE_COMMAND So, Please set proper command");
      else
        SC_REPORT_ERROR("TLM 2.0 :","Address mismatched");
    }
  }

  void write_process()
  {
    while(true)
    {
      wait(s_write_event );
      info << "Inside write process " << endl;
      info << " TLM COMMAND :" << (gp_pointer->is_read() ? "READ" : "WRITE") << endl;
      info << " TLM COMMAND " << gp_pointer -> get_command() << endl;
      sc_assert( (gp_pointer-> get_command() == tlm::TLM_WRITE_COMMAND) && " Set it to Write Command " );

      if( gp_pointer-> is_write() )
      {
        info " Write operation" << endl;
        wait(8,SC_NS);
        memcpy(&w_data, gp_pointer->get_data_ptr(), sizeof(uint8_t) );
        slave_data.push_front(w_data);
        info << "Data from Master   " << std::bitset<8>(w_data)<< endl; 
        phase = DATA_ACK;
        //wait(8,SC_NS);
        info << " Sending DATA_ACK from slave" << endl;
        socket->nb_transport_bw(*gp_pointer, phase, delay);
      }
    }
  }

  void read_process()
  {
    while(true)
    {
      wait( read_event );
      info << "Inside read process " << endl;
      //wait(SC_ZERO_TIME);
      wait(8,SC_NS);
      info << " TLM COMMAND " << gp_pointer -> get_command() << endl;
      info << " TLM COMMAND :" << (gp_pointer->is_read() ? "READ" : "WRITE") << endl;
      sc_assert( (gp_pointer-> get_command() == tlm::TLM_READ_COMMAND) && " Set it to Read Command " );
      if(gp_pointer-> is_read() )
      {
        info << " Read operation " << endl;
        uint8_t read_data = c_s_data.front();
        c_s_data.pop_front();
        info << " read data " << std::bitset<8>(read_data) << endl;
        //gp_pointer -> set_data_length(sizeof(read_data)*(c_s_data.size()));
        gp_pointer -> set_data_length(sizeof(read_data));
        gp_pointer->set_data_ptr((unsigned char*)& (read_data));
        phase = DATA_PHASE;
        //wait(1,SC_NS);
        //delay = sc_time(8,SC_NS);
        socket->nb_transport_bw(*gp_pointer, phase, delay);
      }
    }
  }

  private:
  tlm::tlm_generic_payload *gp_pointer;
  tlm::tlm_phase phase ;
  sc_time delay;
  //sc_time clock=sc_time(1,SC_NS);
  sc_event s_write_event,read_event,addr_event;
  bool is_slave_free {true};
  unsigned long slave_addr = 5;
  tlm::tlm_sync_enum status;
  uint8_t x=0,w_data=0;
  std::list<uint8_t> slave_data{7},c_s_data{0};

};

