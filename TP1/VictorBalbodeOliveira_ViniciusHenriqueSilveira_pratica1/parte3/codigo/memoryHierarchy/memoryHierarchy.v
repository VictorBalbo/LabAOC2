//Implementação de uma hierarquia de memória com dois níveis (cache L1 e memória RAM).
//A cache L1 é totalmente assiciativa e a memória RAM é diretamente mapeada.
//Endereços de memória de 8 bits e tamanho de palavra de 8 bits.

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

module memoriaCache(clock, address, dataIn, dataInRam, write, dataOut, hit, dirty, dataAux, addressRAM, memRead);
		input clock;//Clock;
		input [7:0]address;//Endereço de acesso à cache.
		input [7:0]dataIn;//Dado de entrada da cache.
		input [7:0]dataInRam;//Dado de entrada que vem da leitura da memória RAM.
		input write;//Bit que indica leitura e escrita (0 habilita leitura e 1 habilita escrita). 
		output reg [7:0]dataOut;//Dado de saída da cache.
		output reg hit;//Valor de saída (0 para miss e 1 para hit).
		output reg dirty;//Bit que irá indicar que o dado precisa ser atualizado na memória RAM.
		output reg [7:0]dataAux;//Registrador auxilixiar que irá gravar o dado a ser salvo na RAM em caso a cache estiver cheia e precisarmos de subsituir um bloco.
		output reg [7:0]addressRAM;//Registrador auxiliar que grava o endereço de memória do dado que precisa ser atualizado na memoria RAM.
		output reg memRead;
		integer g, h, i, j, k, l, m, n; //Variável contadora a ser utilizada dentro do laço for.
		
		reg flag;
		
		//[18] -> Bit de validade (quando ALTO indica que o dado presente na linha de cache é válido).
		//[17] -> Bit de sujeira (quando ALTO indica inconsistência entre o dado presente na cache e na memória RAM).
		//[16] -> Bit LRU usado para substituição de dados.
		//[15:8] -> Bits de tag.
		//[7:0] -> Dado presente na linha de cache.
		reg [18:0]MCache[1:0];//Declaração da memória cache (duas linhas de dados de 15 bits);
		
		//Carregamento da memória cache com os dados especificados no roteiro da prática.
		initial begin
			//Dados iniciais da primeira linha de cache
			MCache[0][18] = 1'b1;//Bit de validade é igual a 1.
			MCache[0][17] = 1'b0;//Bit de sujeira é igual a 0.
			MCache[0][16] = 1'b0;//Bit de LRU é igual a 0.
			MCache[0][15:8] = 8'b00000000;//Tag inicial do primeiro bloco de cache em binário.
			MCache[0][7:0] = 8'b00000000;//Dado inicial do primeiro bloco de cache em binário.
			
			//Dados iniciais da segunda linha de cache
			MCache[1][18] = 1'b1;//Bit de validade é igual a 1;
			MCache[1][17] = 1'b0;//Bit de sujeira é igual a zero.
			MCache[1][16] = 1'b1;//Bit de LRU é igual a 1.
			MCache[1][15:8] = 8'b00000001;//Tag inicial do primeiro bloco de cache em binário.
			MCache[1][7:0] = 8'b00000001;//Dado inicial da segunda linha de cache em binário.
		end
		
		//Escritas e leituras são realizadas quando temos uma mudança de clock. Bit write ativo indica escrita e desativo indica leitura.
		//Primeiro pesquisa por um dado inválido, se não encontrar substitui o dado menos recentemente usado (LRU).
		always @ (clock) begin	
			if(write) begin
				hit = 0;//Seta a variável "hit" inicialmente como 0 (miss).
				flag = 0;
				for(g=0; g<2 && hit==0; g=g+1) begin
					if(MCache[g][15:8]==address && MCache[g][18]==1'b1) begin
							dirty = 1'b0;//não precisa escrever o dado
							MCache[g][7:0] = dataIn;//Atualiza o dado na linha de cache; não precisa atualizar o endereço já que é o mesmo.
							MCache[g][18] = 1'b1;//Seta 1 no bit de validade.
							MCache[g][17] = 1'b1;//Seta 1 no bit de sujeira (indica que o dado deve ser escito na memória RAM).
							MCache[g][16] = 1'b1;//Seta 1 no Bit de LRU, indica que o dado foi acessado recentemente.
							hit = 1;
							for(h=0; h<2; h=h+1) begin
							   if(g!=h) begin
								    MCache[h][16] = 1'b0;//Atualiza o bit de LRU das outras posições da cache.
							   end
						  end
						end
				end
				for(i=0; i<2 && flag==0 && hit==0; i=i+1) begin
					if(MCache[i][18]==1'b0 || MCache[i][16]==1'b0) begin //Se o dado na cache for inválido ou for o último dado acessdo (LRU).
						dirty = MCache[i][17];//Indica se o dado precisa ser atualizado na memória RAM ou não.
						if(dirty==1'b1 && MCache[i][18]==1'b1) begin
						  addressRAM = MCache[i][15:8];//Salva o endereço para atualizar o dado na memória RAM.
						  dataAux = MCache[i][7:0];//Salva o dado para gravar na memória RAM.
						end
						MCache[i][15:8] = address;//Atualiza o endereço do dado na linha de cache.
						MCache[i][7:0] = dataIn;//Atualiza o dado na linha de cache.
						MCache[i][18] = 1'b1;//Seta 1 no bit de validade.
						MCache[i][17] = 1'b1;//Seta 1 no bit de sujeira (indica que o dado deve ser escito na memória RAM).
						MCache[i][16] = 1'b1;//Seta 1 no Bit de LRU, indica que o dado foi acessado recentemente.
						flag = 1;
						for(j=0; j<2; j=j+1) begin
							if(j!=i) begin
								MCache[j][16] = 1'b0;//Atualiza o bit de LRU das outras posições da cache.
							end
						end
					end
				end
			end
		if(!write) begin
		  memRead = 0;//memRad só vai ser ativado no caso de precisarmos de ler o dado da memória RAM.
			hit = 0;//Seta a variável "hit" inicialmente como 0 (miss).
			for(k=0; k<2; k=k+1) begin
				if(MCache[k][15:8]==address && MCache[k][18]==1'b1) begin
					dataOut = MCache[k][7:0];//Encontrou o dado na cache.
					MCache[k][16] = 1'b1;//Seta 1 no Bit de LRU, indica que o dado foi acessado recentemente.
					hit = 1;//Hit (o dado foi lido da cache).
					for(l=0; l<2; l=l+1) begin
						if(MCache[l][15:8]!=address) begin
							MCache[l][16] = 1'b0;//Atualiza o bit de LRU das outras posições da cache.
						end
					end
				end
			end
			//Se o dado não foi encontrado na cache é necessário buscá-lo na memória RAM.
			flag = 0;
			memRead = 1;//ativa a leitura na memória RAM.
			for(m=0; m<2 && flag==0 && hit==0; m=m+1) begin
					if(MCache[m][18]==1'b0 || MCache[m][16]==1'b0) begin //Se o dado na cache for inválido ou for o último dado acessdo (LRU).
						dirty = MCache[m][17];//Indica se o dado precisa ser atualizado na memória RAM ou não.
						if(dirty==1'b1 && MCache[m][18]==1'b1) begin
						  addressRAM = MCache[m][15:8];//Salva o endereço para atualizar o dado na memória RAM.
						  dataAux = MCache[m][7:0];//Salva o dado para gravar na memória RAM.
						end
						MCache[m][15:8] = address;//Atualiza o endereço do dado na linha de cache.
						MCache[m][7:0] = dataInRam;//Atualiza o dado na linha de cache.
						MCache[m][18] = 1'b1;//Seta 1 no bit de validade.
						MCache[m][17] = 1'b1;//Seta 1 no bit de sujeira (indica que o dado deve ser escito na memória RAM).
						MCache[m][16] = 1'b1;//Seta 1 no Bit de LRU, indica que o dado foi acessado recentemente.
						flag = 1;
						for(n=0; n<2; n=n+1) begin
							if(n!=m) begin
								MCache[n][16] = 1'b0;//Atualiza o bit de LRU das outras posições da cache.
							end
						end
					end
				end
			end
	 end
endmodule

module memoriaRAM(clock, address, dataIn, writeEnable, readEnable, dataOut, hit);
	input clock;//Clock.
	input [7:0]address;//Endereço de acesso à cache.
	input [7:0]dataIn;//Dado de entrada da cache.
	input writeEnable;//Habilita a escrita.
	input readEnable;//Habilita e escrita.
	output reg [7:0]dataOut;//Dado de saída da cache.
	output reg hit;//Valor de saída (0 para miss e 1 para hit).
	integer i, j;//Variável contadora a ser utilizada dentro do laço for.
	
	//[15:8] -> Endereço de acesso à RAM.
	//[7:0] -> Dado armazenado na linha de RAM.
	reg [15:0]MRAM[3:0];
	
	//Carregamento da memória RAM com os dados especificados no roteiro da prática.
	initial begin
	  for(i=0; i<4; i=i+1) begin
	    MRAM[i] = 0;
	  end
		//Dados iniciais da primeira linha de RAM
		MRAM[0][15:8] = 8'b00000000;//Endereço da primeira linha de RAM.
		MRAM[0][7:0] = 8'b00000101;//Dado da primeira linha de RAM (5 em decimal).
		
		//Dados iniciais da segunda linha de RAM
		MRAM[1][15:8] = 8'b00000001;//Endereço da segunda linha de RAM.
		MRAM[1][7:0] = 8'b00000011;//Dado da segunda linha de RAM (3 em decimal).
		
		//Dados iniciais da terceira linha de RAM
		MRAM[2][15:8] = 8'b00000010;//Endereço da terceira linha de RAM.
		MRAM[2][7:0] = 8'b00000001;//Dado da terceira linha de RAM (1 em decimal).
		
		//Dados iniciais da quarta linha de RAM
		MRAM[3][15:8] = 8'b00000011;//Endereço da quarta linha de RAM.
		MRAM[3][7:0] = 8'b00000000;//Dado da quarta linha de RAM (0 em decimal).
	end
	
	//Escritas e leituras são realizadas quando temos uma mudança de clock; writeEneble habilita escrita e readEnable habilita leitura.
	//A memória RAM é diretamente mapeada.
	always @ (clock) begin
		if(writeEnable) begin
		  hit = 0;//Seta a variável "hit" inicialmente como 0 (miss).
			for(i=0; i<4 && hit==0; i=i+1) begin
			 if(MRAM[i][15:8]==address) begin
				  MRAM[i][7:0] = dataIn;//Atualiza o dado na linha de RAM.
				  hit = 1;
			 end
			end
		end
		if(readEnable) begin
		  hit = 0;//Seta a variável "hit" inicialmente como 0 (miss).
			for(j=0; j<4 && hit==0; j=j+1) begin
				if(MRAM[j][15:8]==address) begin 
					dataOut = MRAM[j][7:0];//Encontrou o dado na RAM.
					hit = 1;
				end
			end
		end
	end
endmodule

module memoryHierarchy(SW, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDG);
	//SW[17] -> clock.
	//SW[16] -> write.
	//SW[15:7] -> endereço de acesso à memória.
	//SW[7:0] -> dado a ser escrito na memória.
	input [17:0]SW;
	output [0:6]HEX0;
	output [0:6]HEX1;
	output [0:6]HEX2;
	output [0:6]HEX3;
	output [0:6]HEX4;
	output [0:6]HEX5;
	output [1:0]LEDG;

	wire clock = SW[17];
	wire write = SW[16];
	wire [7:0]address = SW[15:7];
	wire [7:0]dataIn = SW[7:0];
	wire [7:0]dataOutC;//Dado de saída.
	wire [7:0]dataOutR;//Dado de saí­da.
	wire hitC, hitR;//Aceso indica hit e apagado miss.
	wire [7:0]dataAux;//Dado a ser escrito na memória RAM caso ele esteja cheia.
	wire [7:0]addressRAM;//Salva o endereço para atualizar o dado na memória RAM.
	wire dirty;//Bit que indica escrita na memória RAM (em caso de bloco sujo, ele precisa ser atualizado na memória RAM).
	wire memRead;//Bit que indica leitura na memória RAM.
	
	//Instanciação dos blocos de memória.
	memoriaCache MCache1(clock, address, dataIn, dataOutR, write, dataOutC, hitC, dirty, dataAux, addressRAM, memRead);
	memoriaRAM MRAM1(clock, addressRAM, dataAux, dirty, memRead, dataOutR, hitR);
	
	//Impressão dos dados de entrada e saída utilizando os displays de 7 segmentos.
	//Impressão do endereço se acesso à cache.
	display dispAddress1(address[7:4], HEX5);
	display dispAddress0(address[3:0], HEX4);
	
	//Impressão do dado de entrada da cache (dado a ser escrito).
	display dispDataInCache1(dataIn[7:4], HEX3);
	display dispDataInCache0(dataIn[3:0], HEX2);
	
	//Impressão do dado de saída da cache.
	display dispOutCache1(dataOutC[7:4], HEX1);
	display dispOutCache0(dataOutC[3:0], HEX0);
	
	//Impressão de hit/miss para a memória Cache e RAM utilizado o LEDG.
	assign LEDG[0] = hitC;//O led acenderá no caso de hit cache e apagará em caso de miss.
	assign LEDG[1] = hitR;//O led acenderá no caso de hit na RAM e apagará no caso de miss.
endmodule
