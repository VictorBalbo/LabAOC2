module Processor(input [15:0]DIN, input Resetn, input Clock, input Run, output reg Done, output [15:0]BusWires);
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

module Tp2(SW, LEDR, KEY);
	input [17:0]SW; // SW 15:0 para DIN, SW 17 para Run
	input [17:0]LEDR; // LEDR 15:0 para Bus, LEG 17 para Done
	input [1:0]KEY; // Key 0 para Reset, Key 1 para Clock
	
	Processor p (SW[15:0], KEY[0], KEY[1], SW[17], LEDR[17], LEDR[15:0]);
	
endmodule
