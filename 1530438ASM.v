`define IDLE        0
`define LOADfROM    1
`define ST_LOtROM   2
`define CMP_LO_RO   3
`define posRAMp1    4
`define ST_ROtBUF   5
`define ST_LOtRAM   6
`define posROMp1    7
`define WAIT        8
`define Waitsync    9
`define CheckposROM 10
`define ST_BUFtoLO  11
`define INIT        12


module  sort(start,clk);
  input start;
  input clk;
  
  wire clk;
  wire start;



  reg [15:0] ROM [0:15];
  reg [15:0] RAM [0:15];
  reg [15:0] ROM_Add;
  reg [15:0] RAM_Add;
  reg [15:0] LO;
  reg [15:0] Buffer;
  
  reg [3:0] present_state;
  
  // Das ISE-Modell

  always
    begin
      @(posedge clk) enter_new_state(`INIT);
      while(1)
        begin
          @(posedge clk) enter_new_state(`IDLE); // INIT
          ROM_Add <= @(posedge clk) 0;
          RAM_Add <= @(posedge clk) 0;
          LO <= @(posedge clk) 1;
          if (start == 1)
            begin
              while(LO != 0)
                begin
                  @(posedge clk) enter_new_state(`LOADfROM);
                  LO <= @(posedge clk) ROM[ROM_Add];

                  @(posedge clk) enter_new_state(`Waitsync);
                  if (LO != 0)
                    begin
                      @(posedge clk) enter_new_state(`CheckposROM);
                      if (ROM_Add != 0)
                        begin
                          @(posedge clk) enter_new_state(`CMP_LO_RO);
                          while (RAM[RAM_Add] != 0)
                            begin
                              if(LO > RAM[RAM_Add])
                                begin
                                  RAM_Add = RAM_Add + 1; 
                                end // if(LO > RAM[RAM_Add])
                              
                              else
                                begin 
                                  @(posedge clk) enter_new_state(`ST_ROtBUF);
                                  Buffer <= @(posedge clk) RAM[RAM_Add]; 
                                    
                                  @(posedge clk) enter_new_state(`ST_LOtRAM);
                                  RAM[RAM_Add] <= @(posedge clk) LO; 
                                    
                                  @(posedge clk) enter_new_state(`ST_BUFtoLO);
                                  LO <= @(posedge clk) Buffer;
                                  
                                  @(posedge clk) enter_new_state(`posRAMp1);
                                  RAM_Add = RAM_Add + 1; 
                                end //else
                            end //while (LO > RAM[RAM_Add])
                          
                          if (RAM[RAM_Add] == 0)
                            begin
                              @(posedge clk) enter_new_state(`ST_LOtRAM);
                              RAM[RAM_Add] <= @(posedge clk) LO; 
                              
                              @(posedge clk) enter_new_state(`posROMp1);
                              ROM_Add <= ROM_Add + 1;
                              RAM_Add <= @(posedge clk) 0;
                            end //if (RAM[RAM_Add] == 0)
                        end //(ROM_Add != 0)
                      
                      else
                        begin
                          @(posedge clk) enter_new_state(`ST_LOtRAM);
                          RAM[RAM_Add] <= @(posedge clk) LO; 
                          
                          @(posedge clk) enter_new_state(`posROMp1);
                          ROM_Add <= @(posedge clk) ROM_Add + 1; 
                          RAM_Add <= @(posedge clk) 0; 
                        end //else
                    end //if (LO != 0)
                    
                  else
                    begin
                      @(posedge clk) enter_new_state(`WAIT);
                    end  //else              
              end //while(1) //anpassugn parameter !!
            end//if  start == 1
            
          while(start == 1)
           begin
           @(posedge clk) enter_new_state(`WAIT);
           end // while(start == 1)
        end //while(1)
    end //always

  // Dritter Teil für den Output auf der Konsole
  task enter_new_state;
    input [3:0] this_state;
    begin
      present_state = this_state;
      #1;
      print_state_name(present_state);
    end
  endtask

  task print_state_name;
    input [3:0] state_code;
    integer i;
    begin
      case(state_code)
        `IDLE:        $write("IDLE        ");
        `LOADfROM:    $write("LOADfROM    ");
        `ST_LOtROM:   $write("ST_LOtROM   ");
        `CMP_LO_RO:   $write("CMP_LO_RO   ");
        `posRAMp1:    $write("posRAMp1    ");
        `ST_ROtBUF:   $write("ST_ROtBUF   ");
        `ST_LOtRAM:   $write("ST_LOtRAM   ");
        `posROMp1:    $write("posROMp1    ");
        `WAIT:        $write("WAIT        ");
        `Waitsync:    $write("Waitsync    ");
        `CheckposROM: $write("CheckposROM ");
        `ST_BUFtoLO:  $write("ST_BUFtoLO  ");
        `INIT:        $write("INIT        ");
      endcase
      $display("Start = %d ||ROM_Add = %d ||RAM_Add = %d ||LO = %d ||BUF = %d ||",start,ROM_Add,RAM_Add,LO,Buffer);
 
       $write("RAM: ");
      for (i = 0; i < 16; i = i + 1) 
        begin
          $write("%0d: %0d||",i,RAM[i]);
        end
      $write("\n\n");
    end
  endtask

  task print_RAM_ROM;
    integer i;
    begin
      $write("ROM: ");
      for (i = 0; i < 16; i = i + 1) 
        begin
          $write("%02d: %02d||",i,ROM[i]);
        end
      $write("\n");
      
       $write("RAM: ");
      for (i = 0; i < 16; i = i + 1) 
        begin
          $write("%02d: %02d||",i,RAM[i]);
        end
      $write("\n\n");
    end
  endtask

endmodule

//-------------------------------------------------------------
// testbed
module top;
  reg clk;
  reg start;
  
  integer i;
  integer j;
  integer seed;

  // clock signal
  initial clk = 0;
  always  #50 clk = ~clk;  
  
        sort RUN1(start,clk);
initial
  begin

       seed = 65; //Number to define randome.
        for (j = 0; j < 15; j = j + 1) 
          begin
            RUN1.ROM[j] = $random(seed) % 'hffff;
          end
          RUN1.ROM[15] = 0; 
        for (j = 0; j < 16; j = j + 1) 
          begin
            RUN1.RAM[j] = 0;
          end
              
        start = 0;
        $display("----- RUN -----");
        $display("BEGIN RUN :");
        RUN1.print_RAM_ROM;
            
        #200;
        start = 1;
        #30000
        start = 0;
        #200
            
        $display("END RUN :");
        RUN1.print_RAM_ROM;
     start = 0;
    $finish;
  end
endmodule


