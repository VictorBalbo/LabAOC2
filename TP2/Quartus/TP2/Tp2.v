//Módulo para utilização do display de 7 segmentos como saída (implementado na terceira prova da disciplina de Sistemas Digitais para Computação)
module display(num, disp);
	input [3:0]num;
	output reg [6:0]disp;
	
	always @ (num)
		case (num)
			4'b0000: disp = 7'b0000001;//0
			4'b0001: disp = 7'b1001111;//1
			4'b0010: disp = 7'b0010010;//2
			4'b0011: disp = 7'b0000110;//3
			4'b0100: disp = 7'b1001100;//4
			4'b0101: disp = 7'b0100100;//5
			4'b0110: disp = 7'b0100000;//6
			4'b0111: disp = 7'b0001111;//7
			4'b1000: disp = 7'b0000000;//8
			4'b1001: disp = 7'b0000100;//9
			4'b1010: disp = 7'b0001000;//A
			4'b1011: disp = 7'b1100000;//B
			4'b1100: disp = 7'b0110001;//C
			4'b1101: disp = 7'b1000010;//D
			4'b1110: disp = 7'b0110000;//E
			4'b1111: disp = 7'b0111000;//F
		endcase
endmodule

module Processor(input [15:0]DIN, input Resetn, input Clock, input Run, output reg Done, output [15:0]BusWires, output reg imediato);
	reg Gout; // Controle para saida do registrador G
	reg Gin; // Controle para entrada no registrador G
	reg DINout; // Controle para saida do input DIN
	reg Ain; // Controle para entrada no registrador A
	reg [7:0] Rin, Rout; // Controle de leitura e escrita para dos registradores
	
	wire [7:0] RegX, RegY; // Endereço dos resgistradores usados
	
	reg [8:0] IR; // Instruction register
	wire [2:0] OpCode; // Op code
	wire [1:0]step; // Estado atual da instrução
	wire [15:0] R0,R1, R2, R3, R4, R5, R6, R7, A, G; // Registradores
	
	dec3to8 decX (IR[5:3], 1'b1, RegX); // Decodifica endereço do primeiro registrador usado
	dec3to8 decY (IR[2:0], 1'b1, RegY); // Decodifica endereço do segundo registrador usado
	
	Counter Tstep (Clock, Resetn, Done, Run, step); // Contador de passos da instrução
	
	assign OpCode = IR[8:6];

	always @	(step or OpCode or RegX or RegY) begin
		imediato = 1'b0;
		Done = 1'b0;
		Rout = 8'b00000000;
		Rin = 8'b00000000;
		DINout = 1'b0;
		Ain = 1'b0;
		Gin = 1'b0;
		Gout = 1'b0;
		case (step)
			2'b00: //step 0
			begin
				IR = DIN[8:0]; //Os 9 bits menos significativos são a instrucao
			end
			2'b01: //step 1
				case (OpCode)
					3'b000: // mv
						begin
							Rin = RegX;
							Rout = RegY;
							Done = 1'b1;
						end
					3'b001: // mvi
						begin
							Rin = RegX;
							DINout = 1'b1;
							Done = 1'b1;
							imediato = 1'b1;
						end
					default: // add, sub, and, slt, sll, srl
						begin
							Rout = RegX;
							Ain = 1'b1;
						end
				endcase
			2'b10: //step 2
				if (OpCode != 3'b000 & OpCode != 3'b001) begin // OpCode não for mv or mvi
					Rout = RegY;
					Gin = 1'b1;
				end
			2'b11: //step 3
				if (OpCode !=3'b000 & OpCode!=3'b001) begin // OpCode não for mv or mvi
					Gout = 1'b1;
					Rin = RegX;
					Done = 1'b1;
				end
		endcase
	end
	
	regn reg_0 (BusWires, Rin[0], Clock, R0);
	regn reg_1 (BusWires, Rin[1], Clock, R1);
	regn reg_2 (BusWires, Rin[2], Clock, R2);
	regn reg_3 (BusWires, Rin[3], Clock, R3);
	regn reg_4 (BusWires, Rin[4], Clock, R4);
	regn reg_5 (BusWires, Rin[5], Clock, R5);
	regn reg_6 (BusWires, Rin[6], Clock, R6);
	regn reg_7 (BusWires, Rin[7], Clock, R7);
	regn reg_A (BusWires, Ain, Clock, A);
	
	ALU alu (A, BusWires, OpCode, Gin, Clock, G);
	
	mux m (Rout, DINout, Gout, R0, R1, R2, R3, R4, R5, R6, R7, G, DIN, BusWires);

endmodule

module mux (Rout, DINout, Gout, R0, R1, R2, R3, R4, R5, R6, R7, G, DIN, Bus);
	input [7:0]Rout;
	input DINout, Gout;
	input [15:0]R0, R1, R2, R3, R4, R5, R6, R7, G, DIN;
	output reg [15:0]Bus;
	
	always @(Rout, DINout, Gout) begin
		if (Rout != 8'b00000000) begin
			case (Rout)
				8'b00000001: Bus = R0;
				8'b00000010: Bus = R1;
				8'b00000100: Bus = R2;
				8'b00001000: Bus = R3;
				8'b00010000: Bus = R4;
				8'b00100000: Bus = R5;
				8'b01000000: Bus = R6;
				8'b10000000: Bus = R7;
			endcase
		end 
		else if (DINout == 1'b1) begin
			Bus = DIN;
		end
		else if (Gout == 1'b1) begin
			Bus = G;
		end
	end
	
endmodule

module dec3to8(W, En, Y);
	input [2:0] W;
	input En;
	output reg[7:0] Y;
	
	always @(W or En)
	begin
		if (En == 1)
			case (W)
				3'b000: Y = 8'b00000001;
				3'b001: Y = 8'b00000010;
				3'b010: Y = 8'b00000100;
				3'b011: Y = 8'b00001000;
				3'b100: Y = 8'b00010000;
				3'b101: Y = 8'b00100000;
				3'b110: Y = 8'b01000000;
				3'b111: Y = 8'b10000000;
			endcase
		else
			Y = 8'b00000000;
	end
endmodule

module ALU(input [15:0]a, input [15:0]b, input [2:0] operacao, input Gin, input Clock, output reg[15:0]result);
	always @(negedge Clock) begin
		if(Gin == 1'b1) begin
			case (operacao)
				3'b010: result = a + b;  //add
				3'b011: result = a - b;  //sub
				3'b100: result = a & b;  //and  
				3'b101: 
					if (a < b) // slt
						result = 16'b0000000000000001;
					else 
						result = 16'b0000000000000000;
				3'b110: result = a << b;  //sll
				3'b111: result = a >> b;  //srl	
			endcase
		end
	end
endmodule

module regn(R, Rin, Clock, Q);
	parameter n = 16;
	input [n-1:0] R;
	input Rin, Clock;
	output Q;
	reg[n-1:0] Q = 0;
	always @(negedge Clock)
		if (Rin)
		begin
			Q <= R;
		end 
endmodule 

module Counter(input clock, input clear, input Done, input Run, output reg[1:0] out);
	initial 
		out = 2'b11; // Garante que o primeiro pulso de clock deixe o contador com 00
	always @(posedge clock) begin 
		if(Run) begin // Only change step if run is active
			if (clear == 1 || Done == 1)
				out <= 2'b00;
			else
				out <= out + 1'b1;
		end
	end
endmodule

module InstCounter(input MClock, input Resetn, output reg [4:0]out);
	initial
		out = 5'b00000;// Inicia o contador de instruções com zero
	always @ (posedge MClock) begin
		if(Resetn)
			out <= 5'b00000;
		else
			out <= out + 5'b00001;
		end
endmodule

module Tp2(SW, HEX0, HEX1, HEX2, HEX3, LEDR, LEDG);
	input [3:0]SW;
	output [15:0]LEDR;
	output [0:6]HEX0;
	output [0:6]HEX1;
	output [0:6]HEX2; 
	output [0:6]HEX3;
	output [4:0]LEDG;
	
	wire Run = SW[0];// Sinal que habilita a execução do processador
	wire Resetn = SW[1];//Reset do processador e da memória
	wire PClock = SW[2]; //Clock do processador
	wire MClock = PClock & (Done | imediato);
	wire imediato;
	wire Done; //Sinal de controle que indica que a instrução terminou de executar
	wire [15:0]BusWires;//Barramento
	wire [15:0]mem_out;// Saída da memória (instrução)
	wire [4:0]inst_address;// Endereço da instrução
	
	Processor p (mem_out, Resetn, PClock, Run, Done, BusWires, imediato);
	InstCounter ic (MClock, Resetn, inst_address);
	inst_mem mem (inst_address, MClock, mem_out);

	assign LEDR[15:0] = mem_out[15:0];
	
	display d3(BusWires[15:12], HEX3);//BusWires
	display d2(BusWires[11:8], HEX2);//BusWires
	display d1(BusWires[7:4], HEX1);//BusWires
	display d0(BusWires[3:0], HEX0);//BusWires
	
	assign LEDG[0] = Run;// Acende quando Run está ativo
	assign LEDG[1] = Resetn;// Acende quando o Resetn está ativo
	assign LEDG[2] = MClock;// Acende quando MClock está ativo
	//MClock = PClock&(Done|imediato)
	assign LEDG[3] = PClock;// Acende quando PClock está ativo
	assign LEDG[4] = Done;// Acende quando o Done está ativo
	//Quando KEY não é apertado ele tem valor lógico 1
endmodule
