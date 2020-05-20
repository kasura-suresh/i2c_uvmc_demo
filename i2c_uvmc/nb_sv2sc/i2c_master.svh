class i2c_master extends uvm_component;
  `uvm_component_utils(i2c_master)   // registering the class with uvm factory
  //declaring i2c_phase variable
  //i2c_phase enum_phase;
  // nb_trabsports_* return type variable declaration
  uvm_tlm_sync_e status;
  // uvm_events 
  uvm_event start_ev,addr_ev,data_w_ev,data_r_ev,stop_ev;
  uvm_event_pool ev_pool = uvm_event_pool::get_global_pool();
  
  // declaring the generic payload and delay
  uvm_tlm_gp gp;
  uvm_tlm_phase_e phase;
  uvm_phase tmp_phase;
  uvm_tlm_time delay;
  
  //slave address
  bit [63:0] slave_addr = 5;
  bit command = 1; /// default write command 
  int unsigned data_length;
  static int s=5; // variable to generate read write command
  byte unsigned mw_data[$] = {1,2,3,4,5}, gp_data[]= new[1],gp_data_m;
  
  //master reads the data from slave and store in the mr_data;
  byte unsigned mr_data[$];
  
  // declaring nb_initiator scocket object 
  uvm_tlm_nb_initiator_socket #(i2c_master,uvm_tlm_gp,uvm_tlm_phase_e) initSocket; 
	
	function new(string name = "i2c_master" , uvm_component parent = null);
      super.new(name,parent);
	  initSocket = new("initSocket" , this , this);// initialising the initSocket
      //ack_ev = ev_pool.get("ack_ev");
      start_ev = ev_pool.get("start_ev");
      addr_ev = ev_pool.get("addr_ev");
      data_w_ev = ev_pool.get("data_w_ev");
      data_r_ev = ev_pool.get("data_r_ev");
      stop_ev = ev_pool.get("stop_ev");
      tmp_phase = new();
	endfunction
  
  /*/BUILD_PHASE	
	function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      initSocket = new("initSocket" , this , this);// initialising the initSocket
      //ack_ev = ev_pool.get("ack_ev");
      start_ev = ev_pool.get("start_ev");
      addr_ev = ev_pool.get("addr_ev");
      data_ev = ev_pool.get("data_ev");
      stop_ev = ev_pool.get("stop_ev");
	endfunction
	*/
	
	task run_phase(uvm_phase phase);
      //super.run_phase(phase);
      phase.raise_objection(this); 
      tmp_phase = phase;
      gp = uvm_tlm_gp::type_id::create("gp",this);
      delay = new("delay",1e-12);
      phase = new("phase");
      delay.set_abstime(1ns , 1.0e-9);

      repeat(10) begin
        start_tx;
      end
      `uvm_info("TX","MSATER COMPLETED 10 TX",UVM_MEDIUM)
       #2000;
      phase = tmp_phase;
      phase.drop_objection(this); 
    endtask
  
  task start_tx;
    phase = uvm_tlm_phase_e'(START_PHASE);
    `uvm_info("PHASE", $sformatf("uvm_tlm_phase_e = %s",phase),UVM_MEDIUM)
    `uvm_info("INFO","STARTING THE TRANSACTION ....",UVM_LOW)
    status = initSocket.nb_transport_fw(gp , phase , delay);
    if(status == UVM_TLM_ACCEPTED) begin
      #1000;
      address;
    end
  endtask
  
  task address;
    gp.set_address(slave_addr);
    //if($urandom_range(2,1)%2 == 0)
    if(command)
      gp.set_write();
   // if($urandom_range(2,1)%2 == 1)
    else
      gp.set_read();
    phase = uvm_tlm_phase_e'(ADDRESS_PHASE);
    `uvm_info("PHASE", $sformatf("uvm_tlm_phase_e = %s",phase),UVM_MEDIUM)
    `uvm_info("COMMAND",$sformatf(" gp_command = %s",gp.get_command()),UVM_MEDIUM)
    status = initSocket.nb_transport_fw(gp , phase , delay);
    if (status == UVM_TLM_ACCEPTED) begin
      `uvm_info("ADDR STATUS",$sformatf("ADDRESS STATUS = %s",status),UVM_MEDIUM)
      #8000;
      data;
    end
  endtask
  
  task data;
    `uvm_info("INFO","INSIDE DATA TASK",UVM_LOW)
    if(gp.is_write()) begin
       data_w_ev.wait_ptrigger();
       phase =  uvm_tlm_phase_e'(DATA_PHASE);
      `uvm_info("PHASE", $sformatf("uvm_tlm_phase_e = %s",phase),UVM_MEDIUM)
      //gp_data_m = mw_data.pop_front();
      //`uvm_info("MST DATA",$sformatf("master data = %d",gp_data_m),UVM_MEDIUM)
      gp_data = {mw_data.pop_front()}; 
      gp.set_data(gp_data);
      gp.set_data_length(gp_data.size()); 
      `uvm_info("INFO_MASTER",$sformatf("DATA WRITTEN TO SLAVE 0x%d ## gp_data_length=%d",gp_data[0],gp_data.size()),UVM_MEDIUM)
      status = initSocket.nb_transport_fw(gp , phase , delay); //calling the nb_transport_fw() 
      if(status == UVM_TLM_ACCEPTED) begin
        #8000; 
        command = ~command;
        stop_tx;
      end
    end
    if(gp.is_read()) begin
        data_r_ev.wait_ptrigger();
        //#8000;
        gp.get_data(gp_data);
        mr_data.push_front(gp_data[0]);
        data_length = gp.get_data_length();
        `uvm_info("INFO_MASTER",$sformatf("PAYLOAD_UPDATED DATA READ FROM SLAVE %d ## Data_length=%d",gp_data[0],data_length),UVM_MEDIUM)
        phase =  uvm_tlm_phase_e'(DATA_ACK);
        `uvm_info("PHASE", $sformatf("uvm_tlm_phase_e = %s",phase),UVM_MEDIUM)
        status = initSocket.nb_transport_fw(gp , phase , delay);  //calling the nb_transport_fw()                                                             
        if(status == UVM_TLM_ACCEPTED) begin
           stop_ev.trigger();
           command = ~command;
           stop_tx;
        end
    end
  endtask
  
  task stop_tx;
    stop_ev.wait_ptrigger();
    #1000;
    phase =  uvm_tlm_phase_e'(STOP_PHASE);
    `uvm_info("PHASE","uvm_tlm_phase_e = STOP_PHASE",UVM_MEDIUM)
    status = initSocket.nb_transport_fw(gp , phase , delay); //calling the nb_transport_fw() 
  endtask
  
  function uvm_tlm_sync_e nb_transport_bw(ref uvm_tlm_gp gp, ref uvm_tlm_phase_e ph, uvm_tlm_time delay);
    if (ph ==  uvm_tlm_phase_e'(ADDRESS_ACK)) begin
      `uvm_info("ACK",".....ADDRESS ACK.....",UVM_MEDIUM)
      data_w_ev.trigger();          // triggering the ack_ev
      return UVM_TLM_ACCEPTED;
    end
    else if (ph == uvm_tlm_phase_e'(DATA_PHASE)) begin
    `uvm_info("INFO","-----DATA_PHASE------",UVM_MEDIUM)
    data_r_ev.trigger();
    return UVM_TLM_ACCEPTED;
    end
    else if(ph ==  uvm_tlm_phase_e'(DATA_ACK)) begin
      `uvm_info("ACK",".....DATA ACK.....",UVM_MEDIUM)
      stop_ev.trigger();
      return UVM_TLM_ACCEPTED;
    end
    else begin
      `uvm_error("ERROR FROM MASTER",$sformatf("UNEXPECTED PHASE"))
    end
    return UVM_TLM_COMPLETED;
  endfunction
  
endclass
