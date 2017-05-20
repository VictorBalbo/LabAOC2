// Selecionar a estacao de reserva
module seletor (input clock, input [15:0] inst, output reg opAdd=0, output reg opMul=0);
	always @(posedge clock)
	begin
		case(inst[15:12])
			4'b0000, 4'b0001: // add/sub
			begin
				opAdd = 1;
				opMul = 0;
			end
			4'b0010, 4'b0011: // mul/div
			begin
				opMul = 1;
				opAdd = 0;
			end
		endcase
	end
endmodule

module contador(input clock, input enable, output reg [3:0] address);
	initial address = 4'b0;
	always @(posedge clock)	begin
		if (enable)
			address = address + 1'b1;
	end
endmodule

module bancoInst (input clock, input[3:0] endereco, input addCheio, input mulCheio, output reg enablePC = 1, output reg[15:0] inst);
 	reg [15:0] bancoIntrucoes[15:0];	
	
	//op		    dest		 rx		 ry
	//[15:12]	[11:8]	[7:4]		[3:0]
	initial 
	begin
		bancoIntrucoes[0]	= 16'b0000000000000000;
		bancoIntrucoes[1]	= 16'b0001000000010001;
		bancoIntrucoes[2]	= 16'b0000000000010001;
		bancoIntrucoes[3]	= 16'b0001000000010001;
		bancoIntrucoes[4] = 16'b0000000000010001;
		bancoIntrucoes[5] = 16'b0010000000000000;
		bancoIntrucoes[6] = 16'b0011000000000000;
		bancoIntrucoes[7] = 16'b0011000000000000;
		bancoIntrucoes[8] = 16'b0011000000000000;
	end
	
	always @(posedge clock)	begin
		inst = bancoIntrucoes[endereco];
		enablePC = 1;
		
		case (inst[15:12]) // Switch opCode
			0000, 0001: // Add ou Sub
				if (addCheio) begin	//Estacao de reserva de soma cheia
					enablePC = 0; 
				end
			0010, 0011: // Mul ou Div
				if (mulCheio) begin
					enablePC = 0;
				end
		endcase
	end
	
endmodule

module controleCDB(input clock, input addDone, input [3:0]addTag, input [3:0]addResp, input mulDone, input [3:0]mulTag, input [3:0]mulResp, 
				output reg [3:0]dado, output reg [3:0]tag_dado);
	//Necessario tratar o caso em que o add e o mul ficam prontos ao mesmo tempo. Para isso deve se criar um buffer que guarde a intrucao 
	//mais recente ...
	reg [7:0] buffer; // buffer de resultados e tags
	reg armazenados;
	
	initial // inicializa o buffer vazio
	begin
		armazenados = 0;
		buffer = 8'b0;
	end
	
	always @(posedge clock)	begin
		if (armazenados == 0) begin // nenhum resultado armazenado
			if (addDone) begin
				dado = addResp;
				tag_dado = addTag;
				if (mulDone) begin // duas instrucoes prontas ao mesmo tempo
					// coloca mul/div no buffer
					buffer = {mulTag[3:0],mulResp[3:0]};
					armazenados = 1;
				end
			end
			else if (mulDone) begin // apenas instrução de mul/div pronta
				dado = mulResp;
				tag_dado = mulTag;
			end
		end
		else begin// buffer cheio
			// escolhe o primeiro registro do buffer
			tag_dado = buffer[7:4];
			dado = buffer[3:0];
			// esvazia o buffer
			armazenados = 0;
			
			// trata os dados recebidos
			if (addDone) begin
				// apenas instrução de add/sub pronta
				buffer = {addTag[3:0],addResp[3:0]};
				armazenados = 1;
			end
			else if (mulDone) // apenas instrução de mul/div pronta
			begin
				buffer = {mulTag[3:0],mulResp[3:0]};
				armazenados = 1;
			end	
		end
	end
endmodule

module regStatus (input clock, input [7:0]destino, input [3:0]CDBtag, input [3:0]CDBResult, 
						output reg [3:0] destino_result, output reg [3:0]result, output reg [15:0] regStatus = 0);
	
	always @(posedge clock)	begin
		destino_result = CDBtag;
		result = CDBResult;
		if (destino[3:0] == 0000) begin
			regStatus[3:0] = destino[7:4]; 
		end
		else if (destino[3:0] == 0001) begin
			regStatus[7:4] = destino[7:4]; 
		end
		else if (destino[3:0] == 0010) begin
			regStatus[11:8] = destino[7:4]; 
		end
		else if (destino[3:0] == 0011) begin
			regStatus[15:12] = destino[7:4]; 
		end
	end

endmodule

module bancoReg(input clock, input [15:0]instr, input [3:0]destino, input [3:0]dado,
					 output reg[3:0] A, output reg[3:0] B);
	reg [3:0] Reg[3:0];
	
	initial 
	begin
		Reg[0] = 4'b0000;
		Reg[1] = 4'b0000;
		Reg[2] = 4'b0000;
		Reg[3] = 4'b0000;
	end
	
	always @(posedge clock)	begin
		case(destino)
			4'b0000:
				Reg[0] = dado;
			4'b0001:
				Reg[1] = dado;
			4'b0010:
				Reg[2] = dado;
			4'b0011:
				Reg[3] = dado;
		endcase
		case(instr[7:4])
			4'b0000:
				A = Reg[0];
			4'b0001:
				A = Reg[1];
			4'b0010:
				A = Reg[2];
			4'b0011:
				A = Reg[3];
		endcase
		case(instr[3:0])
			4'b0000:
				B = Reg[0];
			4'b0001:
				B = Reg[1];
			4'b0010:
				B = Reg[2];
			4'b0011:
				B = Reg[3];
		endcase
	end
endmodule

module addSub (input clock, input exec, input [3:0] dataa, input [3:0] datab, input op, input [3:0] addTag,
					output reg [3:0] result, output reg [3:0]tag_out, output reg sumOcup = 0, output reg addDone = 0);
	
	integer estado = 2'b0;
	
	always @(posedge clock)	begin
		if (exec) begin
			case (estado)
				2'b00, 2'b01: begin
					// stall
					addDone = 0;
					sumOcup = 1;
					estado = estado + 1'b1;
				end
				2'b10: begin
					sumOcup = 0;
					estado = 2'b0;
					tag_out = addTag;
					addDone = 1;
					case (op)
						1'b0: begin //Add
							result = dataa + datab;
						end
						1'b1:	begin //Sub
							result = dataa - datab;
						end
					endcase
				end
			endcase
		end
	end
endmodule

module mulDiv (input clock, input exec, input [3:0] dataa, input [3:0] datab, input op, input [3:0] mulTag,
					output reg [3:0] result, output reg [3:0]tag_out, output reg mulOcup = 0, output reg mulDone = 0);
	
	integer estado = 4'b0;
	
	always @(posedge clock)	begin
		if (exec) begin
			case (estado)
				4'b00, 4'b01, 4'b10, 4'b11, 4'b100, 4'b110, 4'b111, 4'b1000, 4'b1001, 4'b1010: begin
					// stall
					mulDone = 0;
					mulOcup = 1;
					estado = estado + 1'b1;
				end
				4'b101: begin
					if(op == 1'b1) begin // Mul 
						mulDone = 1;
						mulOcup = 0;
						estado = 4'b0;
						result = dataa * datab;
						tag_out = mulTag;
					end
				end
				4'b1011: begin
					if(op == 1'b0) begin // Div 
						mulDone = 1;
						mulOcup = 0;
						estado = 4'b0;
						result = dataa / datab;
						tag_out = mulTag;
					end
				end
			endcase
		end
	end
endmodule

module Tomasulo(input SW);
endmodule
