class i2c_master extends uvm_component;
 `uvm_component_utils(i2c_master)   // registering the class with uvm factory
  // nb_trabsports_* return type variable declaration
  uvm_tlm_sync_e status;
  
  // declaring the generic payload and delay
  uvm_tlm_gp gp;
  uvm_tlm_time delay;
  
  //slave address
  bit [63:0] slave_addr = 5;
  byte unsigned mw_data[$] = {1,2,3,4,5}, gp_data[]= new[1];
  
  //master reads the data from slave and store in the mr_data;
  byte unsigned mr_data[$];
  
  // declaring nb_initiator scocket object 
  uvm_tlm_b_initiator_socket #(uvm_tlm_gp) initSocket; 
	
	function new(string name = "i2c_master" , uvm_component parent = null);
      super.new(name,parent);
      initSocket = new("initSocket" , this);// initialising the initSocket
      delay = new("delay",1e-12);
	endfunction
  //BUILD_PHASE	
	function void build_phase(uvm_phase phase);
      super.build_phase(phase);
	endfunction
	
	task run_phase(uvm_phase phase);
      phase.raise_objection(this); 
      gp = uvm_tlm_gp::type_id::create("gp",this);
    //  delay.set_abstime(1ns,1e-9);
      repeat(10) begin
      delay.set_abstime(1ns,1e-9);
        `uvm_info("INFO","..........STATING TRANSACTION...........",UVM_MEDIUM)
        gp.set_address(slave_addr);
        if($urandom_range(2,1)%2 == 0)
          gp.set_write();
        if($urandom_range(2,1)%2 == 1)
          gp.set_read();
        `uvm_info("INFO",$sformatf("ADDRESS COMMAND = %s", gp.get_command()),UVM_MEDIUM)
        if(gp.is_write()) begin
          gp_data[0] = mw_data.pop_front();
          gp.set_data(gp_data);
          gp.set_data_length(gp_data.size());
          `uvm_info("INFO",$sformatf("DATA WRITTINGN TO SLAVE %d",gp_data[0]),UVM_MEDIUM)
          initSocket.b_transport(gp , delay);
          `uvm_info("INFO",$sformatf("DATA WRITE TO SLAVE Delay = %t", delay.get_abstime(1e-9)),UVM_MEDIUM)
            #(delay.get_realtime(1ns));
        end
        else if(gp.is_read()) begin 
          initSocket.b_transport(gp ,delay);
         // if(status == UVM_TLM_UPDATED)begin
            gp.get_data(gp_data);
          `uvm_info("INFO",$sformatf("DATA READ FROM SLAVE %d, Delay = %t",gp_data[0], delay.get_abstime(1e-9)),UVM_MEDIUM)
          mr_data.push_front(gp_data[0]);
          #(delay.get_realtime(1ns));
         // end
        end
        else begin
          `uvm_error("ERROR","INVALID COMMAND")
        end
        `uvm_info("INFO","..........END OF TRANSACTION...........",UVM_MEDIUM)
      end
      phase.drop_objection(this); 
    endtask
endclass
  
  
