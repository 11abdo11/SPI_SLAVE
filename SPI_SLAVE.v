module SPI_SLAVE (
 
 input                 SS_n,
 input                 MOSI,
 input                 clk, 
 input                 rst,
 input                 tx_valid,
 input        [7:0]    tx_data,
 output  reg  [9:0]    rx_data,
 output  reg           rx_valid,
 output  reg           MISO

);

parameter     idle = 3'b000,
              check_cmd = 3'b001,
              writing = 3'b010,
              read_add = 3'b011,
              read_data = 3'b100;

reg   [2:0]   cs, ns;
reg           read_add_flag;   //a flag to determine cmd is for reading data or sending address from Master
integer       count;

always @ (posedge clk , negedge rst)
 begin
  if (!rst)
    cs <= idle;
  else
    cs <= ns;
 end

always @ (posedge clk , negedge rst)
 begin
  if (!rst)
    begin
     count <= 0;
     read_add_flag <= 0;
     rx_valid <= 0;
     rx_data <= 0;
    end

  else if ((cs == read_data) && tx_valid)
   begin
     if (count == 'd7)
       begin
        count <= 0;
        MISO <= tx_data [0];
       end
     else
       begin
        MISO <= tx_data ['d7 - count];
        count <= count + 1 ;
       end  
   end

  else if ((cs == writing) || (cs == read_add) || (cs == read_data))
   begin
     if (count == 'd9)
       begin
         count <= 0;
         rx_valid <= 1;
         rx_data [0] <= MOSI ;
       end
     else
       begin
         count <= count + 1 ;
         rx_data ['d9 - count] <= MOSI ;
         rx_valid <= 0;
         if (cs == read_data)
           read_add_flag <= 0;
         else if (cs == read_add)
           read_add_flag <= 1;
        end
    end

  else if (cs == idle)
   begin
    count <= 0;
    rx_valid <= 0;
    rx_data <= 0;
   end

 end


always @ (*)
 begin

  case (cs)

   idle: begin
     if (!SS_n)
        ns = check_cmd;
     else
        ns = idle;
  end

   check_cmd: begin
    if (!SS_n)
      begin
       if (!MOSI)
         ns = writing;
       else if (MOSI && !read_add_flag)
         ns = read_add;
       else
         ns = read_data;
      end
    else
     ns = idle;
 
  end

   writing: begin
    if((!SS_n && count == 10) || SS_n)
      ns = idle;
    else
      ns = writing;
  end
   
   read_add: begin
    if((!SS_n && count == 10) || SS_n)
      ns = idle;
    else
      ns = read_add;
   end
   
   read_data: begin
    if(SS_n)
      ns = idle;
    else
      ns = read_data;
   end

  endcase
 end


endmodule