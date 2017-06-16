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

// intrucao[4:0] - [4] opcode, [3] tag, [2:0] dado
// busMessage[7:0] - [7]existe em outras caches, [6:4]mensagem do bus, [3] tag, [2:0] dado
module processador(input clock, input [4:0]instrucao, input [7:0]msgBusIn, output reg [12:0]msgBusOut);
	reg [5:0]cache; // [5] tag, [4:3] estado, [2:0] dado
	reg writeback = 0;
	reg fromCPU; // enable para maquina de estado emissor
	reg fromBUS; // enable para maquina de estado receptor
	reg [2:0]request; // [2]opcode, [1]hit, [0]shared
	
	wire estadoOUT;
	
	parameter write = 1;
	parameter invalid = 00;
	parameter mensageRetorno = 3'b101;
	
	always @(posedge clock) begin
		fromBUS = 0;
		fromCPU = 0;
		if(instrucao >= 0) begin // Se existir uma intrucao
			fromCPU = 1;
			request[2] = instrucao[4]; // opcode
			if(cache[4:3] == invalid) begin
				request[1] = 0; // hit = 0
				fromCPU = 0; // É necessario verificar se outros processadores tem o dado antes de alterar o estado
			end
			else if(instrucao[3] == cache[5]) begin // verifica tag é igual
				request[1] = 1; // hit = 1
			end
			else begin
				request[1] = 0; //hit = 0
			end
		end 
		else if(msgBusIn >= 0) begin // se existir uma mensagem do BUS
			fromBUS = 1;
			if(msgBusIn[6:4] == mensageRetorno) begin
				if(cache[4:3] == invalid) begin // retorno de um estado invalido, chama a maquina de estado
					fromCPU = 1;
					fromBUS = 0;
				end
				cache[5] = msgBusIn[3];
				cache[2:0] = msgBusIn[2:0];
			end // mensagem de retorno
		end // if busMessage existe
		else begin // Sem intrucao e sem mensagem do bus
			cache[4:3] <= estadoOUT; // atualiza estado
		end
	end
	emissor_MESI(clock, fromCPU, cache[4:3], request[2], request[1], request[0], msgBusOut, estadoOUT);
	receptor_MESI(clock, fromBUS, );
endmodule


//bus 00 = read miss , 01 = write miss, 10  = invalidate.
//op 0 = read,  1 = write
//shared   0 = not shared , 1 = shared
//estado 00 = invalid , 01 = shared , 10 exclusive, 11 = modified
module emissor_MESI(input clock, input fromCPU, input [1:0]estado, input op, input hit, input shared, output reg [1:0]bus, output reg [1:0]estado_final);

	always @(op)begin
		if(fromCPU) begin
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
	end

endmodule

//bus 00 = read miss , 01 = write miss, 10  = invalidate.
//estado 00 = invalid , 01 = shared , 10 exclusive, 11 = modified
module receptor_MESI(input clock, input fromBUS, input [1:0]bus,input estado, output reg [1:0]estado_final, output reg writeback);

		always @(bus) begin
			if(fromBUS) begin 
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
	end

	

endmodule
