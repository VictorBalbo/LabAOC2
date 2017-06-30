module snooping(SW,LEDG, LEDR);
	input [17:0]SW;
	output [7:0]LEDG;
	output [7:0]LEDR;
	
	
	wire [1:0]estado = SW[17:16];
	wire op = SW[15]; 
	wire hit = SW[14]; 
	wire shared = SW[13]; 
	
	wire [1:0]bus;
	wire [1:0]estado_final;
	wire writeback;
	
	wire [1:0]estadoR = SW[17:16];
	wire [1:0]busR = SW[15:14];
	wire abortMemory;
	wire [1:0]estado_finalR;
	wire writebackR;
	
	
	
	emissor_MESI emissor(SW[0], estado,op, hit, shared, bus, estado_final, writeback);
	receptor_MESI receptor(SW[0], busR, estadoR, estado_finalR, writebackR, abortMemory);
	
	assign LEDG[7:6] = estado_final;
	assign LEDG[1:0] = bus;
	assign LEDG[4] = writeback;
	
	assign LEDR[7:6] = estado_finalR;
	assign LEDR[4] = writebackR;
	assign LEDR[5] = abortMemory;
	
endmodule


//bus 01 = read miss , 10 = write miss, 11  = invalidate.
//op 0 = read,  1 = write
//shared   0 = not shared , 1 = shared
//estado 00 = invalid , 01 = shared , 10 exclusive, 11 = modified
module emissor_MESI(input enable, input [1:0] estado, input op, input hit,input isShared, output reg [1:0]bus, output reg [1:0]estado_final, output reg writeback);

	parameter readMiss = 2'b01;
	parameter writeMiss = 2'b10;
	parameter invalidate = 2'b11;
	
	parameter read = 1'b0;
	parameter write = 1'b1;
	
	parameter invalid = 2'b00;
	parameter shared = 2'b01;
	parameter exclusive = 2'b10;
	parameter modified = 2'b11;
	

	always @(op)begin
		if(enable == 0) begin
			writeback = 0;
			bus = 0;
			case(estado)
			//invalid
				invalid: begin
					if(op == read && isShared == 1)begin
						bus = readMiss;
						estado_final = shared;
					end
					else if (op == read && isShared == 0)begin
						bus = readMiss;
						estado_final = exclusive;
					end
					else if(op == write)begin
						bus = writeMiss;
						estado_final = modified;
					end			
				end		
			//shared
				shared:  begin 
					if(op == read && hit ==1)begin
						estado_final = shared;
					end
					else if(op == read && hit == 0 && isShared == 1)begin
						estado_final = shared;
						bus = readMiss;
					end
					else if(op == read && hit == 0 && isShared == 0)begin
						estado_final = exclusive;
						bus = readMiss;
					end
					else if (op == write && hit == 1)begin
						bus = invalidate;
						estado_final = modified;
					end
					else if (op == write && hit == 0)begin
						bus = writeMiss;
						estado_final = modified;
					end
				end	
			//exclusive
				exclusive: begin
					if(op == read && hit == 1)begin
						estado_final = exclusive;
					end
					
					// Transição que estava faltando
					
					else if(op == read && hit == 0 && isShared == 1)begin
						estado_final = shared;
						bus = readMiss;
					end
					else if(op == read && hit == 0 && isShared == 0)begin
						estado_final = exclusive;
						bus = readMiss;
					end
					
					//
					else if (op == write && hit == 1)begin
						estado_final = modified;
					end
					else if (op == write && hit == 0)begin
						bus = writeMiss;
						estado_final = modified;
					end
				end 
			//modified
				modified: begin
					if(hit == 1)begin
						estado_final = modified;
					end
					else if(op == read && isShared == 0) begin
						estado_final = exclusive;
						writeback = 1;
						bus = readMiss;
					end
					else if(op == read && isShared == 1) begin
						estado_final = shared;
						writeback = 1;
						bus = readMiss;
					end
					else begin // write miss
						estado_final = modified;
						writeback = 1;
						bus = writeMiss;
					end
				end
			endcase
		end
	end

endmodule

module receptor_MESI(input enable, input [1:0]bus,input [1:0]estado, output reg [1:0]estado_final, output reg writeback, output reg abortMemory);

	parameter readMiss = 2'b01;
	parameter writeMiss = 2'b10;
	parameter invalidate = 2'b11;
	
	parameter read = 1'b0;
	parameter write = 1'b1;
	
	parameter invalid = 2'b00;
	parameter shared = 2'b01;
	parameter exclusive = 2'b10;
	parameter modified = 2'b11;
	
	always @(bus or estado)begin
		if(enable == 1) begin
			writeback = 0;
			abortMemory = 0;
			estado_final = estado;
			case(estado)
				invalid: begin 
					estado_final = invalid;
				end
				
				shared: begin 
					if(bus == writeMiss || bus == invalidate)begin
						estado_final = invalid;
					end
				end	
			
				exclusive: begin
					estado_final = exclusive;
					if(bus == writeMiss || bus == invalidate)begin
						estado_final = invalid;
					end
					else if (bus == readMiss)begin
						estado_final = shared;
					end
				end 
			//modified
				modified: begin
					estado_final = modified;
					if(bus == writeMiss)begin
						writeback = 1;
						abortMemory  = 1;
						estado_final = invalid;
					end
					else if (bus == readMiss)begin
						writeback = 1;
						abortMemory = 1;
						estado_final = shared;
					end
							
				end
			endcase
		end
	end

	

endmodule
