class i2c_slave extends uvm_component;
  `uvm_component_utils(i2c_slave)
  
  // declaring the generic payload and delay
  uvm_tlm_gp s_gp;
  uvm_tlm_time s_delay;
  
   //declaring i2c_phase variable
  i2c_phase phase;
  // nb_trabsports_* return type variable declaration
  uvm_tlm_sync_e  status;
  // uvm_events 
  uvm_event#() s_addr_ev,s_data_ev,s_start_ev;
  uvm_event_pool s_ev_pool= uvm_event_pool::get_global_pool();
  
  //SLAVE ADDRESS
  local bit [63:0] slave_addr = 5;
  byte unsigned sr_data[$],gp_data[]= new[1],sw_data[$]={6,7,8,9,10};
  
  uvm_tlm_nb_target_socket #(i2c_slave , uvm_tlm_gp ,i2c_phase) tgSocket;
  
  function new(string name = "i2c_slave" , uvm_component parent = null);
    super.new(name,parent);
  endfunction
	
  function void build_phase(uvm_phase phase); 
    super.build_phase(phase);
    tgSocket = new("tgSocket" , this, this);
    s_start_ev = s_ev_pool.get("s_start_ev");
    s_addr_ev = s_ev_pool.get("s_addr_ev");
    s_data_ev = s_ev_pool.get("s_data_ev");
  endfunction
  
  task run_phase(uvm_phase phase);
    forever begin
      start_tx;
    end
  endtask
  
  function nb_transport_fw(ref uvm_tlm_gp gp ,ref i2c_phase ph, uvm_tlm_time delay);
    if(ph == START_PHASE) begin // start phase
      s_gp = gp;
      s_delay = delay;
      s_start_ev.trigger();
      return UVM_TLM_ACCEPTED;
    end
    
    else if (ph == ADDRESS_PHASE) begin // address phase
        s_delay = delay;
        s_addr_ev.trigger();
        return UVM_TLM_ACCEPTED;
    end
    
    else if (ph ==  DATA_PHASE) begin
      `uvm_info("INFO","DATA PHASE",UVM_LOW)
      s_delay = delay;
      if(s_gp.is_write()) begin
        s_data_ev.trigger();
        return UVM_TLM_ACCEPTED;
      end
      else if(gp.is_read()) begin  
        s_data_ev.trigger();
        gp_data[0] = sw_data.pop_front();
        s_gp.set_data(gp_data);
        return UVM_TLM_UPDATED;
      end
    end
    
    else if (ph == STOP_PHASE) begin
      s_delay = delay;
      `uvm_info("INFO","STOP_PHASE",UVM_LOW)
      `uvm_info("INFO","END OF TRANSACTION ....\n##########\n#########",UVM_LOW)
       return UVM_TLM_COMPLETED;
    end 
    
    else begin
      `uvm_error("ERROR FROM SLAVE",$sformatf("UNEXPECTED PHASE"))
    end
    
    return UVM_TLM_COMPLETED;	
    
  endfunction
  
  
  task start_tx;
    s_start_ev.wait_ptrigger();
    //#(s_delay.get_realtime(1ns));
    address;
  endtask
  
  
  task address;
    `uvm_info("INFO","inside slave address task",UVM_LOW)
    s_addr_ev.wait_ptrigger();
    if(s_gp.get_address() == slave_addr) begin   // checking  with slave address
      `uvm_info("INFO","ADDRESS RECEIVED AND MATCHED WITH SLAVE",UVM_LOW)
      #(s_delay.get_realtime(9));
      phase = ADDRESS_ACK;
      status = tgSocket.nb_transport_bw(s_gp , phase , s_delay);
      data;
    end
    else begin
        `uvm_error("ERROR",$sformatf("SLAVE ADDRESS NOT MATCHED"))
      end
  endtask
  
  task data;
    s_data_ev.wait_ptrigger();
    if(s_gp.is_write()) begin
      s_gp.get_data(gp_data);
      sr_data.push_front(gp_data[0]);
      `uvm_info("INFO_SLAVE",$sformatf("DATA RECEIVED FROM MASTER %d",gp_data[0]),UVM_MEDIUM)
      #(s_delay.get_realtime(9ns));
      phase = DATA_ACK;
      status = tgSocket.nb_transport_bw(s_gp , phase , s_delay);
    end
    else if(s_gp.is_read()) begin  
      #(s_delay.get_realtime(8ns));
      phase = DATA_ACK;
      status = tgSocket.nb_transport_bw(s_gp , phase , s_delay);
    end
    else
      `uvm_info("INFO","INVALID COMMAND",UVM_MEDIUM)
  endtask
  
endclass
	