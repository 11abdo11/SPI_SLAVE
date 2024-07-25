module SPI_SLAVE_TB ();

reg           SS_n;
reg           MOSI;
reg           clk = 0;
reg           rst;
reg           tx_valid;
reg  [7:0]    tx_data;
wire [9:0]    rx_data;
wire          rx_valid;
wire          MISO;

SPI_SLAVE DUT (.*);

parameter     idle = 3'b000,
              check_cmd = 3'b001,
              writing = 3'b010,
              read_add = 3'b011,
              read_data = 3'b100;

parameter clk_period = 20;

always 
 begin
  clk = ~clk;  
  #10;
 end

task reset;
 begin
   SS_n = 1;
   rst = 0;
   #(2*clk_period);
   rst = 1;
 end
endtask

task data_from_master;
 input [9:0] data;
 integer i;
 begin
  for (i = 0 ; i < 10 ; i = i + 1)
   begin
     #(clk_period);
     MOSI = data [9 - i] ;
   end
 end
endtask

initial 
 begin
  reset;
  @(negedge clk);
  SS_n = 0;
  #(clk_period);
  MOSI = 0;
  data_from_master (10'b0010101011);
  @(posedge rx_valid)
  if ((rx_data != 10'b0010101011) || (DUT.cs != writing))
   $display ("error in performing writing cmd");
  #(0.5*clk_period);
  SS_n = 1;     
  wait(DUT.cs == idle);   //Writing CMD Completed
  
  @(negedge clk);
  SS_n = 0;
  #(clk_period);
  MOSI = 1;
  data_from_master (10'b1010101101);
  @(posedge rx_valid)
  if ((rx_data != 10'b1010101101) || (DUT.read_add_flag != 1) || (DUT.cs != read_add))
   $display ("error in performing read_add cmd");
  #(0.5*clk_period);
  SS_n = 1;     
  wait(DUT.cs == idle);   //read_add CMD Completed
  
  #70;
  
  $stop;  
 end

endmodule