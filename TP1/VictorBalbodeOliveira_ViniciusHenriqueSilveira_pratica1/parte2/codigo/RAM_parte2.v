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

module RAM_parte2(SW, HEX0, HEX1, HEX4, HEX5, HEX6, HEX7, LEDG);
input [14:0]SW;
output [0:6]HEX0;
output [0:6]HEX1;
output [0:6]HEX4;
output [0:6]HEX5;
output [0:6]HEX6;
output [0:6]HEX7;
output [0:0]LEDG;

wire [4:0]address = SW[12:8];
wire clock = SW[14];
wire [7:0]data = SW[7:0];
wire write = SW[13];
wire [7:0]dataOut;

ramlpm ramlpm1(address, clock, data, write, dataOut);//Este módulo utiliza a implementacao de memória do arquivo ramlpm.v

//As funções display mostram os dados abaixo em hexadecimal
display disp_address1(address[3:0],HEX6);	       //endereco
display disp_address2({3'b000,address[4]},HEX7);
display disp_data1(data[3:0],HEX4);					 //dado de entrada
display disp_data2(data[7:4],HEX5);
display disp_dataOut1(dataOut[3:0],HEX0);			 //dado de saida
display disp_dataOut2(dataOut[7:4],HEX1);

assign LEDG[0] = clock;//Se e somente se write esta ligado(=1) LEDG[0] acendera

endmodule