`timescale 1ns / 1ps

module Rover_Code(
    input clock,
    //8 switches
    input [7:0] SW, //SW[0] TO SW[7]
    //three ips sensors
    input IPS_M, 
    input IPS_M_L,
    input IPS_M_R,
    //IR sensor
    input IR, 
    //IN1-In4 outputs for direction controls
    output[3:0] IN,
    //Enable A/B for motors 
    output ENA,
    output ENB,
    //LEDs 
    output LED0,
    output LED1,
    output LED2,
    output LED3,
    output LED4,
    output LED5,
    output LED6,
    output LED7,
    output LED15,
    
//7-Segment initialization   
    output reg [3:0] an,      // DIGITS
    output reg [6:0] seg

    );
    
//fsm parameters
    parameter   S0          =     6'b0000001, //State 0, Initial State 
                S1          =     6'b0000010,
                S2          =     6'b0000100,
                S3          =     6'b0001000, 
                S4          =     6'b0010000,
                S5          =     6'b0100000;
                
// Must do the state initialization to a known state  
//Synchronous FSM. Only need to have one state variable 
    reg [6:0]   state  =     S0; 	
    
// temporary registers for always @ statement
    reg [20:0] count;// 2^(21) - 1 = 2,097,151
    reg [20:0] width;//controls the PWM
    reg ENA_PWM; //temp ENA
    reg ENB_PWM; //temp ENB
    reg [3:0] IN_LAST; //temp register to control the last direction of the rover
    
    //temp IN
    reg [3:0] IN_1;
    
//initializes all temp registers to 0
    initial begin
        count = 0;
        width = 0;
        ENA_PWM = 0;
        ENB_PWM = 0;
        IN_1 = 0;
        state = S0;
     end 

 always @(posedge clock) begin
  case(state)
    S0: begin // Case state 0
      if (~IPS_M || ~IPS_M_L || ~IPS_M_R) state <= S1; // if any IPS detects tape, go to state 1
      else    state <= S0; // if no IPS is detected, stay in state 0
    end
    S1: begin // travels the track normally  
          if (IR && ~IPS_M && ~IPS_M_R) state <= S2; //controls when to turn right on alternate track
        else    state <= S1; 
    end
    S2: begin  //only turns right onto alternate track 
        if (~IPS_M_L && IPS_M && IPS_M_R) state <= S3; //if only the left IPS is on, go to state S3
      else    state <= S2; 
    end
    S3: begin //ensures the robot always gets onto the alternate path
          if (~IPS_M && ~IPS_M_R) state <= S4; //if middle IPS on go to turn state S4
        else    state <= S3; 
    end
    S4: begin //turns right to face forward on the alternate path 
          if (~IPS_M_L && IPS_M && IPS_M_R) state <= S5;
        else    state <= S4; 
    end
    S5: begin //navigates the alternate path and converges back onto normal track
        if (~IPS_M_L || ~IPS_M || ~IPS_M_R) state <= S5; //stays in S5
        else state <= S5;
    end
    default: begin // default case to avoid error for unreachable state
      state = S0; // always go to state 0
    end
  endcase
end

always @(posedge clock) begin
  case(state)
    S0: begin // state 0 
         IN_1 <= 4'b0000;   //if s0, rover direction is not moving 
    end
    S1: begin // state 1  where the rover will navigate the perimeter normally with the 3 main IPS sensors  
        if (~IPS_M)
            IN_1 <= 4'b1001;    
        else if (~IPS_M_L)
            IN_1 <= 4'b0101;
        else if (~IPS_M_R)
            IN_1 <= 4'b1010;
        else 
            IN_1 <= IN_LAST; 
     end
    S2: begin         
        IN_1 <= 4'b1010;
    end
	 S3: begin    //use this implementation always stay on the alternate path
        if (~IPS_M_R)
            IN_1 <= 4'b1010;
        else if (~IPS_M)
            IN_1 <= 4'b1001;
        else 
            IN_1 <= 4'b1001;
      end
     S4: begin            
         IN_1 <= 4'b1010;
     end
     S5: begin
          if (~IPS_M_L && ~IPS_M && ~IPS_M_R)
            IN_1 <= 4'b1010;
          else if ((~IPS_M_L && IPS_M) || (~IPS_M && ~IPS_M_L))
            IN_1 <= 4'b0101;
          else if (~IPS_M_L)
            IN_1 <= 4'b0101;  
          else if (~IPS_M_R)
            IN_1 <= 4'b1010;
          else if (~IPS_M)
            IN_1 <= 4'b1001;  
          else 
            IN_1 <= IN_LAST;  
     end
    default: begin // default for unreacheable state
        IN_1 <= IN_LAST;  
    end
  endcase
end
    	     
   
always@(posedge clock)begin          
        
            if(count > 2097151) //resets the counter to 0 or increments
                count <= 0;
            else
                count <= count +1;
            if(count < width) begin      
                ENA_PWM <= 1;
                ENB_PWM <= 1;
            end                         
            
            else begin     
                ENA_PWM <=0;
                ENB_PWM <=0;
            end                       
            end           
  
    always@(*)begin
    
        case(SW)             
                 //90% Duty Cycle
                //forward:
                8'b10010001: width = 21'd2097151; 
                //right
                8'b10100001: width = 21'd2097151; 
                //left
                8'b01010001: width = 21'd2097151; 
                //Backwards
                8'b01100001: width = 21'd2097151; 
                
                8'b00100001: width = 21'd2097151; 
                
                8'b01000001: width = 21'd2097151; 
                

                //50% Duty Cycle
                //forward
                8'b10010010: width = 21'd1048575; 
                //right
                8'b10100010: width = 21'd1048575; 
                //left
                8'b01010010: width = 21'd1048575; 
                
                //Backwards
                8'b01100010: width = 21'd1048575; 
                
                8'b00100010: width = 21'd1048575; // Back Left 50%
                
                8'b01000010: width = 21'd1048575; // Back Right 50%
                
                //60% Duty Cycle          
                //forward
                8'b10010100: width = 21'd1258290; 
                //right
                8'b10100100: width = 21'd1258290; 
                //left
                8'b01010100: width = 21'd1258290; 
                
                //backwards
                8'b01100100: width = 21'd1258290; 
                
                8'b00100100: width = 21'd1258290; // Back Left 60%
                
                8'b01000100: width = 21'd1258290; // Back Right 60%
                
                //75% Duty cycle           
                //forward
                8'b10011000: width = 21'd1572864; 
                //right
                8'b10101000: width = 21'd1572864; 
                //left
                8'b01011000: width = 21'd1572864; 
                //backwards
                8'b01101000: width = 21'd1572864; 
                
                8'b00101000: width = 21'd1572864; // Back Left 85%
                
                8'b01001000: width = 21'd1572864; // Back Right 85%
                
                default: width = 21'd0;
        endcase 
 end
 //7 Segment Display 
      always @ (*) begin
          case(SW)
          
   // FORWARD:
   // SPEED 1:         
              
                     8'b10010001:
                  
                              begin
                    an = 4'b0111;
                    seg = 7'b0001110; //Display F

               end
               
    // SPEED 2 :           
                 8'b10010010:
                  
                              begin
                    an = 4'b0111;
                    seg = 7'b0001110; //Display F

               end
               
     //SPEED 3:          
               8'b10010100:
               
                                     begin
                    an = 4'b0111;
                    seg = 7'b0001110; //Display F

               end   
               
     //SPEED 4:
         
               8'b10011000:
                           begin
                    an = 4'b0111;
                    seg = 7'b0001110; //Display F

               end   
               
               
     //Backwards:
        
               
     // SPEED 1:
               8'b01100001:
               
                             begin
                    an = 4'b0111;
                    seg = 7'b0000011; //Display B

               end

    // SPEED 2:

                8'b01100010:


                                 begin
                    an = 4'b0111;
                    seg = 7'b0000011; //Display B

               end

    //SPEED 3: 

                8'b01100100:

                               begin
                    an = 4'b0111;
                    seg = 7'b0000011; //Display B

               end



    //SPEED4: 

                8'b01101000:
    
                               begin
                    an = 4'b0111;
                    seg = 7'b0000011; //Display B

               end 
               
               
               default: seg = 7'b1111111;

endcase
end
			 	
    always @(posedge clock)begin
        IN_LAST <= IN;           //the last IN1-4 state is kept when no IPS sensor is on
    end
   
    assign IN[3:0] = IN_1[3:0];
    //turns LED on when IR is detecting something    
    assign LED15 = IR;
    //Sending PWM to Enables to make motors move
    assign ENA = ENA_PWM;
    assign ENB = ENB_PWM;
    
//LEDs lighting up when corresponding Switches are turned ON
    assign LED0 = SW[0];
    assign LED1 = SW[1];
    assign LED2 = SW[2];
    assign LED3 = SW[3];
    assign LED4 = SW[4];
    assign LED5 = SW[5];
    assign LED6 = SW[6];
    assign LED7 = SW[7];
    
    
endmodule