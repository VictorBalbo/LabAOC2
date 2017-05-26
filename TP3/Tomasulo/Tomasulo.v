// Selecionar a estacao de reserva
module seletor (input clock, input [15:0] instr, output reg opAdd=0, output reg opMul=0, output reg[15:0] opcode  = 0);
	always @(posedge clock)
	begin
		case(instr[15:12])
			4'b0000, 4'b0001: // add/sub
			begin
				opAdd = 1;
				opMul = 0;
				opcode = instr;
			end
			4'b0010, 4'b0011: // mul/div
			begin
				opMul = 1;
				opAdd = 0;
				opcode = instr;
			end
		endcase
	end
endmodule

module contador(input clock, input enable, output reg [3:0] address);
	initial address = 4'b0;
	always @(posedge clock)	begin
		if (enable && address != 4'b0010)
			address = address + 1'b1;
	end
endmodule

module bancoInst (input clock, input[3:0] endereco, input addCheio, input mulCheio, output reg enablePC = 1, output reg[15:0] inst);
 	reg [15:0] bancoIntrucoes[15:0];	
	
	//op		    dest		 rx		 ry
	//[15:12]	[11:8]	[7:4]		[3:0]
	initial 
	begin
		bancoIntrucoes[0]	= 16'b0000000000000000; // R0 = R0 + R0 // R0 = 2
		bancoIntrucoes[1]	= 16'b0001000100100000; // R1 = R2 - R0; // R1 = 1
		bancoIntrucoes[2]	= 16'b0000000000010010; // R0 = R1 + R2 // R0 = 4
		bancoIntrucoes[3]	= 16'b0001000000010011;
		bancoIntrucoes[4] = 16'b0000000000010100;
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
			else if (mulDone) begin // apenas instrucao de mul/div pronta
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
				// apenas instruÃƒÂ§ÃƒÂ£o de add/sub pronta
				buffer = {addTag[3:0],addResp[3:0]};
				armazenados = 1;
			end
			else if (mulDone) // apenas instruÃƒÂ§ÃƒÂ£o de mul/div pronta
			begin
				buffer = {mulTag[3:0],mulResp[3:0]};
				armazenados = 1;
			end	
		end
	end
endmodule

module regStatus (input clock, input [7:0]destino, input [3:0]CDBtag, input [3:0]CDBResult, 
						output reg [3:0] destino_result, output reg [3:0]result, output reg [15:0] regStatus = 0);
	
	always @(negedge clock)	begin
		destino_result = CDBtag;
		result = CDBResult;
		// Limpa dependencia com valor do CDB
		case (CDBtag)
			4'b0000: regStatus[3:0] = 4'b0000; 
			4'b0001: regStatus[7:4] = 4'b0000; 
			4'b0010: regStatus[11:8] = 4'b0000; 
			4'b0011: regStatus[15:12] = 4'b0000; 
		endcase
		
		// Adiciona dependencia
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

module bancoReg(input clock, input [15:0]instr, input [3:0]destino, input [3:0]dado, input [3:0]regDestino, output reg[3:0] A, output reg[3:0] B);
	reg [3:0] Reg[3:0];
	
	initial 
	begin
		Reg[0] = 4'b0001;
		Reg[1] = 4'b0010;
		Reg[2] = 4'b0011;
		Reg[3] = 4'b0100;
	end
	
	always @(posedge clock)	begin
		case(regDestino)
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

module addSub (input clock, input exec, input [3:0] dataA, input [3:0] dataB, input op, input [3:0] addTag, input [3:0]regDest,
					output reg [3:0] result, output reg [3:0]tag_out, output reg [3:0]regOut, output reg sumOcup = 0, output reg addDone = 0);
	
	reg [1:0]estado = 2'b00;
	
	always @(negedge clock)	begin
		if(exec == 0) estado = 2'b00;
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
					estado = 2'b11;
					tag_out = addTag;
					addDone = 1;
					regOut = regDest;
					case (op)
						1'b0: begin //Add
							result = dataA + dataB;
						end
						1'b1:	begin //Sub
							result = dataA - dataB;
						end
					endcase
				end
			endcase
		end
	end
endmodule

module mulDiv (input clock, input exec, input [3:0] dataa, input [3:0] datab, input op, input [3:0] mulTag,
					output reg [3:0] result, output reg [3:0]tag_out, output reg mulOcup = 0, output reg mulDone = 0);
	
	integer estado = 4'b0000;
	
	always @(posedge clock)	begin
		if (exec) begin
			case (estado)
				4'b0000, 4'b0001, 4'b0010, 4'b0011, 4'b0100, 4'b0110, 4'b0111, 4'b1000, 4'b1001: begin
					// stall
					mulDone = 0;
					mulOcup = 1;
					estado = estado + 1'b1;
				end
				4'b0101: begin
					if(op == 1'b0) begin // Mul 
						mulDone = 1;
						mulOcup = 0;
						estado = 4'b0000;
						result = dataa * datab;
						tag_out = mulTag;
					end
					else begin
						mulDone = 0;
						mulOcup = 1;
						estado = estado + 1'b1;
					end
				end
				4'b1010: begin
					if(op == 1'b1) begin // Div 
						mulDone = 1;
						mulOcup = 0;
						estado = 4'b0000;
						result = dataa / datab;
						tag_out = mulTag;
					end
				end
			endcase
		end
	end
endmodule

module RSadd(input clock, input opAdd, input [15:0]instr, input [3:0]opA, input [3:0]opB, input [15:0] regStatus, 
				 input [3:0]CDBResult, input [3:0] CDBResultTag, input sumOcup, input addDone,
				 output reg addCheio = 0, output reg op, output reg [7:0] destino, output reg [3:0]regDest, output reg [3:0] valorA,
				 output reg [3:0]valorB, output reg [3:0]tag=0, output reg exec=0);
	integer cont = 0; // Conta estaÃƒÂ§ÃƒÂµes disponiveis
	integer	i;
	
	reg [29:0] estacao [2:0];
	reg [3:0] statusRegDestino;
	reg [15:0] regStatusDespachado;
	integer posicao;
	
	initial begin
		estacao[0] = 30'b000000000000000000000000000010;		//RSAdd1
		estacao[1] = 30'b000000000000000000000000000100;		//RSAdd2
		estacao[2] = 30'b000000000000000000000000000110;		//RSAdd3
	end
	
	always @(posedge clock)	begin
		regStatusDespachado = regStatus;
		if(addDone == 1) exec = 0;
		//Verifica se algum resultado esta pronto no CDB
		for(i=0; i<3; i=i+1) begin
			if (estacao[i][11:8] == CDBResultTag) begin
				estacao[i][11:8] = 0;			//limpa o Q
				estacao[i][19:16] = CDBResult;	//Salva o valor em Va
				estacao[i][20] = 1;				//Seta a tagVa
			end
			if (estacao[i][15:12] == CDBResultTag) begin
				estacao[i][15:12] = 0;			//limpa o Q
				estacao[i][24:21] = CDBResult;	//Salva o valor em Va
				estacao[i][25] = 1;				//Seta a tagVa
			end
		end
		
		//Verificacoes de Vb e Va, para despachar as intrucoes
		for(i=0; i<3 && exec == 0; i=i+1) begin
			case (estacao[i][29:26])
				4'b0000: statusRegDestino = regStatus[3:0];
				4'b0001: statusRegDestino = regStatus[7:4];
				4'b0010: statusRegDestino = regStatus[11:8];
				4'b0011: statusRegDestino = regStatus[15:12];
			endcase
			if (estacao[i][20] == 1 && estacao[i][25] == 1 && sumOcup == 0 && statusRegDestino == 4'b0000) begin
				cont = cont - 1;
				if(estacao[i][7:5] == 3'b000) op = 0;
				if(estacao[i][7:5] == 3'b001) op = 1;
				
				valorA = estacao[i][19:16];	//saida A
				valorB = estacao[i][24:21];	//saida B
				//seleciona tag para o registrador de destino
				destino[7:4] = estacao[posicao][4:1];	//nome da estacao
				destino[3:0] = estacao[i][29:26];		//registrador a ser renomeado
				regDest = estacao[i][29:26];
				case (i)
					0: tag = 4'b0001;
					1: tag = 4'b0010;
					2: tag = 4'b0011;
				endcase
				case (estacao[i][29:26])
					4'b0000: regStatusDespachado[3:0] = tag;
					4'b0001: regStatusDespachado[7:4] = tag;
					4'b0010: regStatusDespachado[11:8] = tag;
					4'b0011: regStatusDespachado[15:12] = tag;
				endcase
				estacao[i] = 30'b0;		//Reseta estacao
				estacao[i][4:1] = tag; // Seta tag da estaÃƒÂ§ÃƒÂ£o de reserva
				addCheio = 0;	 //determina estacao com espaco vazio
				exec = 1; // Apenas um despacho por vez
			end
		end
		
		// Escreve instrucao na estacao de reserva
		if (opAdd) begin
			//procura por posicao vazia
			if (!estacao[0][0]) begin
				posicao = 0;
			end
			else if (!estacao[1][0]) begin
				posicao = 1;
			end
			else if (!estacao[2][0]) begin
				posicao = 2;
			end
			
			if (cont < 2) begin // Existe uma estacao vazia
				cont = cont + 1;
				estacao[posicao][0] = 1;					//seta o busy
				estacao[posicao][7:5] = instr[15:12];	//guarda o tipo de operacao na estacao 
				estacao[posicao][29:26] = instr[11:8];
				//Salva RX na estacao, verificando se o registrador possui ou nao dependencia de dados
				case (instr[7:4])
					4'b0000:	begin //R0
						if(regStatusDespachado[3:0] == 4'b0000) begin
							estacao[posicao][19:16] = opA;	//salva va
							estacao[posicao][20] = 1;			//seta tagVa como 1
						end
						else begin
							estacao[posicao][11:8] = regStatusDespachado[3:0];	//Salva o registro esperado em Qa
						end
					end
					4'b0001: begin//R1
						if(regStatusDespachado[7:4] == 4'b0000) begin
							estacao[posicao][19:16] = opA;	//salva valor
							estacao[posicao][20] = 1;			//seta como usado
						end
						else begin
							estacao[posicao][11:8] = regStatusDespachado[7:4];	//Salva o registro esperado
						end
					end
					4'b0010:	begin//R2
						if(regStatusDespachado[11:8] == 4'b0000) begin
							estacao[posicao][19:16] = opA;	//salva valor
							estacao[posicao][20] = 1;			//seta como usado
						end
						else begin
							estacao[posicao][11:8] = regStatusDespachado[11:8];	//Salva o registro esperado
						end
					end
					4'b0011:	begin//R3
						if(regStatusDespachado[15:12] == 4'b0000) begin
							estacao[posicao][19:16] = opA;	//salva valor
							estacao[posicao][20] = 1;			//seta como usado
						end
						else begin
							estacao[posicao][11:8] = regStatusDespachado[15:12];	//Salva o registro esperado
						end
					end
				endcase
				//Salva RY na estacao, verificando se o registrador possui ou nao dependencia de dados
				case (instr[3:0])
					4'b0000:	begin//R0
						if(regStatusDespachado[3:0] == 4'b0000) begin
							estacao[posicao][24:21] = opB;	//salva valor
							estacao[posicao][25] = 1;			//seta como usado
						end
						else begin
							estacao[posicao][15:12] = regStatusDespachado[3:0];	//Salva o registro esperado
						end
					end
					4'b0001: begin//R1
						if(regStatusDespachado[7:4] == 4'b0000) begin
							estacao[posicao][24:21] = opB;	//salva valor
							estacao[posicao][25] = 1;			//seta como usado
						end
						else begin
							estacao[posicao][15:12] = regStatusDespachado[7:4];	//Salva o registro esperado
						end
					end
					4'b0010:	begin //R2
						if(regStatusDespachado[11:8] == 4'b0000)begin
							estacao[posicao][24:21] = opB;	//salva valor
							estacao[posicao][25] = 1;			//seta como usado
						end
						else begin
							estacao[posicao][15:12] = regStatusDespachado[11:8];	//Salva o registro esperado
						end
					end
					4'b0011:	begin //R3
						if(regStatusDespachado[15:12] == 4'b0000) begin
							estacao[posicao][24:21] = opB;	//salva valor
							estacao[posicao][25] = 1;			//seta como usado
						end
						else begin
							estacao[posicao][15:12] = regStatusDespachado[15:12];	//Salva o registro esperado
						end
					end
				endcase
			end
			if (cont == 2) begin
				addCheio = 1;
			end
		end
	end
endmodule

module RSmul(input clock, input opMul, input [15:0]opcode, input [3:0]opA, input [3:0]opB, input [15:0] regStatus, 
				 input [3:0]CDBResult, input [3:0] CDBResultTag, input mulOcup,
				 output reg mulCheio = 0, output reg R, output reg [7:0] destino, output reg [3:0] valorA,
				 output reg [3:0]valorB, output reg [3:0]tag);
	integer i;
	reg [25:0] estacao [1:0];
	integer vazio = 0, posicao;
	
	initial begin
		estacao[1] = 26'b00000000000000000000001000;		//RSAdd2
		estacao[2] = 26'b00000000000000000000001010;		//RSAdd3
	end
	
	always @(posedge clock)	begin
		//Verifica se algum resultado esta pronto no CDB
		for(i=0; i<2; i=i+1) begin
			if (estacao[i][11:8] == CDBResultTag) begin
				estacao[i][11:8] = 0;			//limpa o Q
				estacao[i][19:16] = CDBResult;	//Salva o valor em Va
				estacao[i][20] = 1;				//Seta a tagVa
			end
			if (estacao[i][15:12] == CDBResultTag) begin
				estacao[i][15:12] = 0;			//limpa o Q
				estacao[i][24:21] = CDBResult;	//Salva o valor em Va
				estacao[i][25] = 1;				//Seta a tagVa
			end
		end
		
		//Verificacoes de Vb e Va, para que a execucao seja feita
		if (estacao[0][20] == 1 && estacao[0][25] == 1 && mulOcup == 0)
		begin
			case (opcode[15:12])	//seleciona operacao
				4'b0000:	//add
					R = 0;
				4'b0001: //sub
					R = 1;
			endcase
			valorA = estacao[0][19:16];	//saida A
			valorB = estacao[0][24:21];	//saida B
			tag = 4'b0001;						//mul1
			estacao[0] = 26'b00000000000000000000001000;		//Reseta estacao
			mulCheio = 0;												//determina estacao com espaco vazio
		end
		else if (estacao[1][20] == 1 && estacao[1][25] == 1 && mulOcup == 0)
		begin
			case (opcode[15:12])	//seleciona operacao
				4'b0000:	//add
					R = 0;
				4'b0001: //sub
					R = 1;
			endcase
			valorA = estacao[1][19:16];	//saida A
			valorB = estacao[1][24:21];	//saida B
			tag = 4'b0010;						//add2
			estacao[1] = 26'b00000000000000000000001010;		//Reseta estacao
			mulCheio = 0;												//determina estacao com espaco vazio
		end
		vazio = 0;
		//Escrita na estacao de reserva
		if (opMul)
		begin
			//procura por posicao vazia
			if (!estacao[0][0]) 
			begin
				vazio = 1;
				posicao = 0;
			end
			else if (!estacao[1][0]) 
			begin
				vazio = 1;
				posicao = 1;
			end
			if (vazio)
			begin	//salva os dados na estacao
				estacao[posicao][0] = 1;					//seta o busy
				estacao[posicao][7:5] = opcode[15:12];	//guarda o tipo de operacao na estacao 
				//seleciona tag para o registrador de destino
				destino[7:4] = estacao[posicao][4:1];	//nome da estacao
				destino[3:0] = opcode[11:8];				//registrador a ser renomeado
				//Salva RX na estacao, verificando se o registrador possui ou nao dependencia de dados
				case (opcode[7:4])
					4'b0000:	//R0
					begin
						if(regStatus[3:0] == 4'b0000)
						begin
							estacao[posicao][19:16] = opA;	//salva valor
							estacao[posicao][20] = 1;			//seta como usado
						end
						else
						begin
							estacao[posicao][11:8] = regStatus[3:0];	//Salva o registro esperado
						end
					end
					4'b0001: //R1
					begin
						if(regStatus[7:4] == 4'b0000)
						begin
							estacao[posicao][19:16] = opA;	//salva valor
							estacao[posicao][20] = 1;			//seta como usado
						end
						else
						begin
							estacao[posicao][11:8] = regStatus[7:4];	//Salva o registro esperado
						end
					end
					4'b0010:	//R2
					begin
						if(regStatus[11:8] == 4'b0000)
						begin
							estacao[posicao][19:16] = opA;	//salva valor
							estacao[posicao][20] = 1;			//seta como usado
						end
						else
						begin
							estacao[posicao][11:8] = regStatus[11:8];	//Salva o registro esperado
						end
					end
					4'b0011:	//R3
					begin
						if(regStatus[15:12] == 4'b0000)
						begin
							estacao[posicao][19:16] = opA;	//salva valor
							estacao[posicao][20] = 1;			//seta como usado
						end
						else
						begin
							estacao[posicao][11:8] = regStatus[15:12];	//Salva o registro esperado
						end
					end
				endcase
				//Salva RY na estacao, verificando se o registrador possui ou nao dependencia de dados
				case (opcode[3:0])
					4'b0000:	//R0
					begin
						if(regStatus[3:0] == 4'b0000)
						begin
							estacao[posicao][24:21] = opB;	//salva valor
							estacao[posicao][25] = 1;			//seta como usado
						end
						else
						begin
							estacao[posicao][15:12] = regStatus[3:0];	//Salva o registro esperado
						end
					end
					4'b0001: //R1
					begin
						if(regStatus[7:4] == 4'b0000)
						begin
							estacao[posicao][24:21] = opB;	//salva valor
							estacao[posicao][25] = 1;			//seta como usado
						end
						else
						begin
							estacao[posicao][15:12] = regStatus[7:4];	//Salva o registro esperado
						end
					end
					4'b0010:	//R2
					begin
						if(regStatus[11:8] == 4'b0000)
						begin
							estacao[posicao][24:21] = opB;	//salva valor
							estacao[posicao][25] = 1;			//seta como usado
						end
						else
						begin
							estacao[posicao][15:12] = regStatus[11:8];	//Salva o registro esperado
						end
					end
					4'b0011:	//R3
					begin
						if(regStatus[15:12] == 4'b0000)
						begin
							estacao[posicao][24:21] = opB;	//salva valor
							estacao[posicao][25] = 1;			//seta como usado
						end
						else
						begin
							estacao[posicao][15:12] = regStatus[15:12];	//Salva o registro esperado
						end
					end
				endcase
			end
			else
			begin
				mulCheio = 1;
			end
		end
	end
endmodule

module Tomasulo(input clock);

	wire [3:0]endereco, saidaA, saidaB, tag;
	wire [15:0] instr, opcode;
	//fios de controle
	wire enablePC;
	//fios para RS add
	wire opAdd, addCheio, op, sumOcup, exec;
	wire [3:0] addResult, addSaidaA, addSaidaB, addTag;
	wire [7:0] destinoAdd;
	//fios para RS mul
	wire opMul, mulCheio, Rmul;
	wire [3:0] mulResult, mulSaidaA, mulSaidaB, mulTag;
	wire [7:0] destinoMul;
	
	//fios para alu
	wire addDone, mulOk;
	
	//fios para CDB
	wire [15:0]regStatus;
	wire [3:0] CDBResult, CDBTag, cdbAddTag;
	
	//fios para regStatus
	wire [7:0]destino;
	wire [3:0] destino_result, result, regDest, regOut;
	
	//fios para bancoInst
	wire [3:0] A, B;
	
	contador cont(clock, enablePC, endereco);										//calcula endereco
	bancoInst banco1(clock, endereco, addCheio, mulCheio, enablePC, instr);		//Seleciona intrucao
	seletor select(clock, instr, opAdd, opMul, opcode);									//Seleciona Estacao de reserva
	
	RSadd s1(clock, opAdd, opcode, A, B, regStatus, CDBResult, CDBTag, sumOcup, addDone, addCheio, op, destino, regDest, addSaidaA, addSaidaB, addTag, exec);
	//RSmul r2(clock, opMul, I, I[7:4], I[3:0], registradores, bus, busTag, mulCheio, Rmul, destinoMul, mulSaidaA, mulSaidaB, tag);
	
	addSub alu1(clock, exec, addSaidaA, addSaidaB, op, addTag, regDest, addResult, cdbAddTag, regOut, sumOcup, addDone);	//Calculo do resultado para a estacao add
	//mulDiv...
	
	controleCDB c1(clock, addDone, cdbAddTag, addResult, 1'b0, 4'b0000, 4'b0000, CDBResult, CDBTag);
	regStatus status(clock, destino, CDBTag, CDBResult, destino_result, result, regStatus);
	bancoReg banco2(clock, instr, CDBTag, CDBResult, regOut, A, B);
endmodule
