module Snooping(input clock, input [6:0]instrucao);

	wire [9:0]bus1;
	wire [9:0]bus2;
	wire [9:0]bus3;
	wire [9:0]busWire;
	
	processador p1(clock, 2'b01, instrucao, busWire, bus1);
	processador p2(clock, 2'b10, instrucao, busWire, bus2);
	processador p3(clock, 2'b11, instrucao, busWire, bus3);
	bus b(clock, bus1, bus2, bus3, busWire);
endmodule

module bus(input clock, input [9:0]bus1, input [9:0]bus2, input [9:0]bus3, output reg [9:0]busWire);
	always @(clock) begin
		busWire = 10'b0000000000;
		if(bus1[7] == 1 || bus1[5:4] != 2'b00)  busWire = bus1;
		else if(bus2[7] == 1 || bus2[5:4] != 2'b00)  busWire = bus2;
		else if(bus3[7] == 1 || bus3[5:4] != 2'b00)  busWire = bus3;
	end
endmodule

// codigoProc - codigo do processador
// intrucao[4:0] - [6:5] processador, [4] opcode, [3] tag, [2:0] dado
// busMessageIn[9:0] - [9:8] cpu de origem, [7] writeback, [6] - tag Writeback, [5:4]mensagem do bus, [3] tag, [2:0] dado
// busMessageOut[9:0] - [9:8] cpu de origem, [7] writeback, [6] - tag Writeback, [5:4]mensagem do bus, [3] tag, [2:0] dado
module processador(input clock, input [1:0]codigoProc, input [6:0]instrucao, input [9:0]msgBusIn, output reg [9:0]msgBusOut);
	reg [5:0]cache = 6'b000000; // [5:4] estado, [3] tag, [2:0] dado
	reg writeback = 0;
	reg fromCPU; // enable para maquina de estado emissor
	reg fromBUS; // enable para maquina de estado receptor
	reg [2:0]request; // [2]opcode, [1]hit, [0]shared
	
	wire [1:0]estado;
	
	//opcode
	parameter read = 0;
	parameter write = 1;
	//estados
	parameter invalid = 00;
	parameter shared = 01;
	parameter exclusive = 10;
	parameter modified = 11;
	//Bus Message
	parameter readMissMsg = 2'b01; // Pede um dado aos outros processadores
	parameter invalidate = 2'b10; // Sinal para invalidar um dado
	parameter mensageRetorno = 2'b11; // Retorno de um pedido de dado (readMissMsg)
	
	always @(posedge clock) begin
		fromBUS = 0;
		fromCPU = 0;
		msgBusOut = 10'b0000000000;
		cache[5:4] = estado;
		if(instrucao[6:5] == codigoProc) begin // Se existir uma intrucao
			fromCPU = 1;
			request[2] = instrucao[4]; // opcode
			request[0] = 0; // shared
			if(instrucao[4] == read && instrucao[3] == cache[3] && cache[5:4] != invalid) begin // read hit
				// Retorna valor apenas
				msgBusOut[3] = cache[3];
				msgBusOut[2:0] = cache[2:0];
				request[1] = 1;
			end
			else if(instrucao[4] == read) begin // read miss
				// Busca valor da memoria
				msgBusOut[9:8] = codigoProc;
				msgBusOut[5:4] = readMissMsg;
				msgBusOut[3] = instrucao[3];
				fromCPU = 0; // Espera valor chegar para mudar a maquina
				if(cache[5:4] == modified) begin // Read miss em estado modified gera um writeback
					msgBusOut[6] = cache[3];
					msgBusOut[7] = 1;
					msgBusOut[2:0] = cache[2:0];
				end
			end
			else if(instrucao[4] == write && instrucao[3] == cache[3] && cache[5:4] != invalid) begin // write hit
				// Escreve valor na cache
				cache[2:0] = instrucao[2:0];
				request[1] = 1;
				if(cache[5:4] == shared) begin
					msgBusOut[9:8] = codigoProc;
					msgBusOut[5:4] = invalidate;
					msgBusOut[3] = cache[3];
				end
			end
			else if(instrucao[4] == write) begin // write miss
				if(cache[5:4] == modified) begin // Write miss em estado modified gera um writeback
					msgBusOut[7] = 1;
					msgBusOut[6] = cache[3];
					msgBusOut[2:0] = cache[2:0];
				end
				// Envia invalidate
				request[1] = 0;
				msgBusOut[9:8] = codigoProc;
				msgBusOut[5:4] = invalidate;
				msgBusOut[3] = instrucao[3];
				// Escreve valor na cache
				cache[3] = instrucao[3];
				cache[2:0] = instrucao[2:0];
			end
		end // if instrucao >= 0
		else if(msgBusIn[5:4] != 2'b00) begin // se existir uma mensagem do BUS
			if(msgBusIn[5:4] == invalidate && msgBusIn[3] == cache[3] && msgBusIn[9:8] != codigoProc) begin // Msg para invalidar a tag
				cache[5:4] = invalid;
			end
			else if(msgBusIn[5:4] == readMissMsg && msgBusIn[3] == cache[3] && cache[5:4] != invalid) begin // Msg buscando a tag
				if(cache[5:4]  == modified) begin // Se o estado for Modified, tambem ativa o writeback
					msgBusOut[7] = 1;
					msgBusOut[6] = cache[3];
				end
				// Retorna o dado pedido
				msgBusOut[9:8] = msgBusIn[9:8];
				msgBusOut[5:4] = mensageRetorno;
				msgBusOut[3] = cache[3];
				msgBusOut[2:0] = cache[2:0];
				cache[5:4] = shared;
			end
			else if(msgBusIn[5:4] == mensageRetorno && msgBusIn[9:8] == codigoProc) begin// Mensagem de retorno de um pedido deste processador
				cache[5:4] = shared;
				cache[3] = msgBusIn[3];
				cache[2:0] = msgBusIn[2:0];
			end
		end // if busMessage existe
	end
	
	emissor_MESI emissor(clock, fromCPU, cache[5:4], request[2], request[1], request[0], estado);
endmodule


//bus 00 = read miss , 01 = write miss, 10  = invalidate.
//op 0 = read,  1 = write
//shared   0 = not shared , 1 = shared
//estado 00 = invalid , 01 = shared , 10 exclusive, 11 = modified
module emissor_MESI(input clock, input fromCPU, input [1:0]estado, input op, input hit, input shared, output reg [1:0]estado_final);

	initial estado_final = 00;
	always @(negedge clock)begin
		estado_final = estado;
		if(fromCPU) begin
			case(estado)
			//invalid
				2'b00: begin
					if(op == 0 && shared ==1)begin
						estado_final = 2'b01;
					end
					else if (op == 0 && shared == 0)begin
						estado_final = 2'b10;
					end
					else if(op == 1)begin
						estado_final = 2'b11;
					end			
				end		
			//shared
				2'b01:  begin 
					if(op == 0 && hit ==1)begin
						estado_final = 2'b01;
					end
					else if (op == 1 && hit == 1)begin
						estado_final = 2'b11;
					end
					else if (op == 1 && hit == 0)begin
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
