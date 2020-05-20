class i2c_slave extends uvm_component;
  `uvm_component_utils(i2c_slave)
  // declaring the generic payload and delay
  uvm_tlm_gp s_gp;
  uvm_tlm_time s_delay;
  uvm_tlm_sync_e  status;
  
  //SLAVE ADDRESS
  local bit [63:0] slave_addr = 5;
  byte unsigned sr_data[$],gp_data[]= new[1],sw_data[$]={6,7,8,9,10};
  
  uvm_tlm_b_target_socket #(i2c_slave , uvm_tlm_gp) tgSocket;
  
  function new(string name = "i2c_slave" , uvm_component parent = null);
    super.new(name,parent);
    tgSocket = new("tgSocket" , this, this);
  endfunction
  /*
  function void build_phase(uvm_phase phase); 
    super.build_phase(phase);
    tgSocket = new("tgSocket" , this, this);
  endfunction
  */
  task b_transport(uvm_tlm_gp gp, uvm_tlm_time delay);
    if(gp.get_address() == slave_addr) begin
      //#(delay.get_realtime(8ns));
      `uvm_info("INFO","..........ADDRESS_ACK...........",UVM_MEDIUM)
      //#(delay.get_realtime(1ns));
      // ack evnet
      if(gp.is_write()) begin 
        gp.get_data(gp_data);
        sr_data.push_front(gp_data[0]);
        `uvm_info("INFO",$sformatf("DATA WRITTEN IN SLAVE %d",gp_data[0]),UVM_MEDIUM)
        //#(delay.get_realtime(8ns));
        `uvm_info("INFO","..........DATA_ACK...........",UVM_MEDIUM)
        //#(delay.get_realtime(1ns));
        `uvm_info("INFO",$sformatf("delay before incr = %f",delay.get_realtime(1ns)),UVM_MEDIUM)
		// delay.incr(20ns,1ns,1e-9);
        #(delay.get_realtime(1ns, 1e-9));
        `uvm_info("INFO",$sformatf("delay after incr = %f",delay.get_realtime(1ns)),UVM_MEDIUM)
        delay.reset();
        return;//M_TLM_ACCEPTED;
      end
      else if(gp.is_read()) begin
        gp_data[0] = sw_data.pop_front();
        gp.set_data(gp_data);
        gp.set_data_length(gp_data.size());
        //#(delay.get_realtime(8ns));
        //Ack event
        `uvm_info("INFO","..........DATA_ACK...........",UVM_MEDIUM)
        //#(delay.get_realtime(1ns));
        `uvm_info("INFO",$sformatf("delay before incr = %f",delay.get_realtime(1ns)),UVM_MEDIUM)
		// delay.incr(20ns,1ns,1e-9);
        #(delay.get_abstime(1e-9));
        delay.reset();
        `uvm_info("INFO",$sformatf("delay after incr = %f",delay.get_realtime(1ns)),UVM_MEDIUM)
        return;//M_TLM_UPDATED;
      end
      else begin
        `uvm_error("ERROR","INVALID COMMAND")
        return;//M_TLM_COMPLETED;
      end
    end
    else begin
      `uvm_error("ERROR","SLAVE ADDRESS NOT MATCHED")
      return;//M_TLM_COMPLETED;
    end
  endtask
  
endclass
      
