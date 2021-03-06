//Implementação de uma hierarquia de memória com dois níveis (cache L1 e memória RAM).
//A cache L1 é totalmente assiciativa e a memória RAM é diretamente mapeada.
//Endereços de memória de 8 bits e tamanho de palavra de 8 bits.

//Módulo para utilização do display de 7 segmentos como saída (implementado na terceira prova da disciplina de Sistemas Digitais para Computação).
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

module memoriaCache(clock, address, dataIn, write, dataOut, hit, dirty);
		input clock;//Clock.
		input [7:0]address;//Endereço de acesso à cache.
		input [7:0]dataIn;//Dado de entrada da cache.
		input write;//Bit que indica leitura e escrita (0 habilita leitura e 1 habilita escrita). 
		output reg [7:0]dataOut;//Dado de saída da cache.
		output reg hit;//Valor de saída (0 para miss e 1 para hit).
		output reg dirty;//Bit que indica se o valor precisa ser salvo na memória.
		integer h, i, j, k, l;//Variáveis contadoras a serem utilizadas dentro dos laços for.
		
		//[18] -> Bit de validade (quando ALTO indica que o dado presente na linha de cache é válido).
		//[17] -> Bit de sujeira (quando ALTO indica inconsistência entre o dado presente na cache e na memória RAM).
		//[16] -> Bit LRU usado para substituição de dados.
		//[15:8] -> Bits de tag.
		//[7:0] -> Dado presente na linha de cache.
		reg [18:0]MCache[1:0];//Declaração da memória cache (duas linhas de dados de 15 bits);
		
		//Carregamento da memória cache com os dados especificados no roteiro da prática.
		initial begin
			//Dados iniciais da primeira linha de cache
			MCache[0][18] <= 1'b1;//Bit de validade é igual a 1.
			MCache[0][17] <= 1'b0;//Bit de sujeira é igual a 0.
			MCache[0][16] <= 1'b0;//Bit de LRU é igual a 0.
			MCache[0][15:8] <= 8'b00000100;//Tag inicial do primeiro bloco de cache em binário.
			MCache[0][7:0] <= 8'b00000101;//Dado inicial do primeiro bloco de cache em binário.
			
			//Dados iniciais da segunda linha de cache
			MCache[1][18] <= 1'b1;//Bit de validade é igual a 1;
			MCache[1][17] <= 1'b0;//Bit de sujeira é igual a zero.
			MCache[1][16] <= 1'b1;//Bit de LRU é igual a 1.
			MCache[1][15:8] <= 8'b00000101;//Tag inicial do primeiro bloco de cache em binário.
			MCache[1][7:0] <= 8'b00000011;//Dado inicial da segunda linha de cache em binário.
		end
		
		//Escritas e leituras são realizadas quando temos uma mudança de clock; bit write 1 indica escrita e 0 indica leitura.
		//Primeiro pesquisa por um dado inválido, se não encontrar substitui o dado menos recentemente usado (LRU).
	always @ (clock) begin	
		if(write) begin
			hit <= 0;//Seta a variável "hit" inicialmente como 0 (miss).
			for(h=0; h<2 && hit==0; h=h+1) begin
				if(MCache[h][15:8]==address) begin
					dirty <= MCache[h][17];//Atualiza o bit dirty que indica se o dado precisa ser escrito na memória ou não.
					MCache[h][7:0] <= dataIn;//Atualiza o dado na linha de cache; não precisa atualizar o endereço já que é o mesmo.
					MCache[h][18] <= 1'b1;//Seta 1 no bit de validade.
					MCache[h][17] <= 1'b1;//Seta 1 no bit de sujeira (indica que o dado deve ser escito na memória RAM).
					MCache[h][16] <= 1'b1;//Seta 1 no Bit de LRU, indica que o dado foi acessado recentemente.
							hit <= 1;
				end
			end
			for(i=0; i<2 && hit==0; i=i+1) begin
				if(MCache[i][18]==1'b0 || MCache[i][16]==1'b0) begin //Se o dado na cache for inválido.
					MCache[i][15:8] <= address;//Atualiza o endereço do dado na linha de cache.
					dirty <= MCache[i][17];//Atualiza o bit dirty que indica se o dado precisa ser escrito na memória ou não.
					MCache[i][7:0] <= dataIn;//Atualiza o dado na linha de cache.
					MCache[i][18] <= 1'b1;//Seta 1 no bit de validade.
					MCache[i][17] <= 1'b1;//Seta 1 no bit de sujeira (indica que o dado deve ser escito na memória RAM).
					MCache[i][16] <= 1'b1;//Seta 1 no Bit de LRU, indica que o dado foi acessado recentemente.
					hit <= 1;
					for(j=0; j<2; j=j+1) begin
						if(j!=i) begin
							MCache[j][16] <= 1'b0;//Atualiza o bit de LRU das outras posições da cache.
						end
					end
				end
			end
		end
		if(!write) begin	
			hit <= 0;//Seta a variável "hit" inicialmente como 0 (miss).
			for(k=0; k<2; k=k+1) begin
				if(MCache[k][15:8]==address && MCache[k][18]==1'b1) begin
					dataOut <= MCache[k][7:0];//Encontrou o dado na cache.
					MCache[k][16] <= 1'b1;//Seta 1 no Bit de LRU, indica que o dado foi acessado recentemente.
					hit <= 1;//Hit (o dado foi lido da cache).
					for(l=0; l<2; l=l+1) begin
						if(MCache[l][15:8]!=address) begin
							MCache[l][16] <= 1'b0;//Atualiza o bit de LRU das outras posições da cache.
						end
					end
				end
			end
		end
	end
endmodule

module memoriaRAM(clock, address, dataIn, write, dataOut, hit);
	input clock;//Clock.
	input [7:0]address;//Endereço de acesso à cache.
	input [7:0]dataIn;//Dado de entrada da cache.
	input write;//Bit que indica leitura e escrita (0 habilita leitura e 1 habilita escrita). 
	output reg [7:0]dataOut;//Dado de saída da cache.
	output reg hit;//Valor de saída (0 para miss e 1 para hit).
	integer i, j, l;//Variáveis contadoras a serem utilizadas dentro dos laços for.
	
	//[15:8] -> Endereço de acesso à RAM.
	//[7:0] -> Dado armazenado na linha de RAM.
	reg [15:0]MRAM[3:0];
	
	//Carregamento da memória RAM com os dados especificados no roteiro da prática.
	initial begin
		//Dados iniciais da primeira linha de RAM
		MRAM[0][15:8] <= 8'b00000000;//Endereço da primeira linha de RAM (100 em decimal).
		MRAM[0][7:0] <= 8'b00000101;//Dado da primeira linha de RAM (5 em decimal).
		
		//Dados iniciais da segunda linha de RAM
		MRAM[1][15:8] <= 8'b01100101;//Endereço da segunda linha de RAM (101 em decimal).
		MRAM[1][7:0] <= 8'b00000011;//Dado da segunda linha de RAM (3 em decimal).
		
		//Dados iniciais da terceira linha de RAM
		MRAM[2][15:8] <= 8'b01100110;//Endereço da terceira linha de RAM (102 em decimal).
		MRAM[2][7:0] <= 8'b00000001;//Dado da terceira linha de RAM (1 em decimal).
		
		//Dados iniciais da quarta linha de RAM
		MRAM[3][15:8] <= 8'b01100111;//Endereço da quarta linha de RAM (103 em decimal).
		MRAM[3][7:0] <= 8'b00000000;//Dado da quarta linha de RAM (0 em decimal).
	end
	
	//Escritas e leituras são realizadas quando temos uma mudança de clock; bit write 1 indica escrita e 0 indica leitura.
	//A memória RAM é diretamente mapeada.
	always @ (clock) begin
		if(write) begin
		  hit <= 0;//Seta a variável "hit" inicialmente como 0 (miss).
			for(i=0; i<4 && hit==0; i=i+1)
			if(MRAM[i][15:8]==address) begin
				MRAM[i][7:0] <= dataIn;//Atualiza o dado na linha de RAM.
				hit <= 1;
			end
		end
		if(!write) begin
		  hit <= 0;//Seta a variável "hit" inicialmente como 0 (miss).
			for(l=0; l<4 && hit==0; l=l+1)
				if(MRAM[l][15:8]==address) begin 
					dataOut <= MRAM[l][7:0];//Encontrou o dado na RAM.
					hit <= 1;
				end
		end
	end
endmodule

module hierarquiaMemoria(SW, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDG, hitC, hitR);
	//SW[17] -> clock;
	//SW[16] -> writeC (write enable da memória cache, utilizado para switch entre modo de escrita e de leitura na cache).
	//SW[15:7] -> endereço de acesso à memória.
	//SW[7:0] -> dado a ser escrito na memória.
	input [17:0]SW;
	output [0:6]HEX0;
	output [0:6]HEX1;
	output [0:6]HEX2;
	output [0:6]HEX3;
	output [0:6]HEX4;
	output [0:6]HEX5;
	output [3:0]LEDG;
	output hitC;//Indica acerto (1) ou falha (0) na cache. 
	output hitR;//Indica acerto (1) ou falha (0) na RAM.

	wire clock = SW[17];
	wire write = SW[16];
	wire [7:0]address = SW[15:7];
	wire [7:0]dataIn = SW[7:0];
	wire [7:0]dataOutC;//Dado de saída da Cache.
	wire [7:0]dataOutR;//Dado de saída da RAM.
	wire dirty;//Bit que indica se um bloco sujo deve ser escrito na RAM ou não. Este bit é utilizado como write enable da RAM.

	//Instanciação dos blocos de memória.
	memoriaCache MCache1(clock, address, dataIn, writeC, dataOutC, hitC, dirty);
	memoriaRAM MRAM1(clock, address, dataOutC, dirty, dataOutR, hitR);
	
	//Impressão do endereço de acesso no dislay de 7 segmentos.
	display dispAddress1(SW[15:12], HEX5);
	display dispAddress0(SW[11:8], HEX4);
	
	//Impressão do dado de entrada no display de 7 segmentos.
	display dispDataIn1(SW[7:4], HEX3);
	display dispDataIn0(SW[3:0], HEX2);
	
	//Impressão do dado de saida no display de 7 segmentos.
	display dispDataOut1(dataOutC[7:4], HEX1);
	display dispDataOut0(dataOutC[3:0], HEX0);
endmodule
