module Snooping(SW,KEY,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7, LEDG);
	input [17:0]SW;
	input[7:0]KEY;
	output [0:6]HEX0;
	output [0:6]HEX1;
	output [0:6]HEX2; 
	output [0:6]HEX3;
	output [0:6]HEX4;
	output [0:6]HEX5;
	output [0:6]HEX6;
	output [0:6]HEX7;
	output [7:0]LEDG;
	
	
	wire [1:0]estado = SW[17:16];
	wire op = SW[15]; 
	wire hit = SW[14]; 
	wire shared = SW[13]; 
	wire [1:0]bus;
	wire [1:0]estado_final;
	wire writeback;
	

	
	emissor_MESI emissor(estado,op, hit, shared, bus, estado_final);
	// receptor_MESI receptor(bus,estado,estado_final,writeback);
	
	assign LEDG[7:6] = estado_final;
	assign LEDG[1:0] = bus;
	assign LEDG[4] = writeback;
	
endmodule


//bus 00 = read miss , 01 = write miss, 10  = invalidate.
//op 0 = read,  1 = write
//shared   0 = not shared , 1 = shared
//estado 00 = invalid , 01 = shared , 10 exclusive, 11 = modified
module emissor_MESI(input [1:0]estado, input op, input hit,input shared, output reg [1:0]bus, output reg [1:0]estado_final);

	always @(op)begin
		case(estado)
		//invalid
			2'b00: begin
				if(op == 0 && shared ==1)begin
					bus = 2'b00;
					estado_final = 2'b01;
				end
				else if (op == 0 && shared == 0)begin
					bus = 2'b00;
					estado_final = 2'b10;
				end
				else if(op == 1)begin
					bus = 2'b01;
					estado_final = 2'b11;
				end			
			end		
		//shared
			2'b01:  begin 
				if(op == 0 && hit ==1)begin
					estado_final = 2'b01;
				end
				else if (op == 1 && hit == 1)begin
					bus = 2'b10;
					estado_final = 2'b11;
				end
				else if (op == 1 && hit == 0)begin
					bus = 2'b01;
					estado_final = 2'b11;
				end
			end	
		//exclusive
			2'b10: begin
				if(op == 0 && hit ==1)begin
					estado_final = 2'b10;
				end
				else if (op == 1 && hit == 1)begin
					estado_final = 2'b11;
				end
				else if (op == 1 && hit == 0)begin
					bus = 2'b01;
					estado_final = 2'b11;
				end
			end 
		//modified
			2'b11: begin
				if(hit ==1)begin
					estado_final = 2'b11;
				end	
			end
		endcase
	end

endmodule

module receptor_MESI(input [1:0]bus,input estado, output reg [1:0]estado_final, output reg writeback);

		always @(bus)begin
		writeback = 0;
		case(estado)
		//invalid
			2'b00: begin  

			end		
		//shared
			2'b01:  begin 
				if(bus == 2'b01 || bus == 2'b10)begin
					estado_final = 2'b00;
				end
			end	
		//exclusive
			2'b10: begin
				if(bus == 2'b01 || bus == 2'b10)begin
					estado_final = 2'b00;
				end
				else if (bus == 2'b00)begin
					estado_final = 2'b01;
				end
			end 
		//modified
			2'b11: begin
				if(bus == 2'b01)begin
					estado_final = 2'b00;
					writeback = 1;
				end
				else if (bus == 2'b00)begin
					estado_final = 2'b01;
					writeback = 1;
				end
				
						
			end
		endcase
	end

	

endmodule
