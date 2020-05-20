//I2C PROTOCOL PHASES 
/*	START_PHASE  -> Indicates start of the transaction from master
	START_ACK	 -> Start of transaction accepted from slave side
    ADDRESS_PHASE-> start of the address phase from master side
    ADDRESS_ACK  -> Slave sends the ACK to the ADDRESS_PHASE
    DATA_PHASE   -> Starts the Data transfer from the master
    DATA_ACK     ->slave sends the ACk to the DATA_PHASE
    STOP_PHASE   -> END of transaction
    */
// phase is of type i2c_phase 
typedef enum {
  START_PHASE=5,ADDRESS_PHASE,ADDRESS_ACK,
  DATA_PHASE,DATA_ACK,STOP_PHASE
} i2c_phase;
