//Implementação de uma hierarquia de memória com dois níveis (cache L1 e memória RAM).
//A cache L1 é totalmente assiciativa e a memória RAM é diretamente mapeada.
//Endereços de memória de 8 bits e tamanho de palavra de 8 bits.

module memoriaCache(clock, address, dataIn, dataInRam, write, dataOut, hit, dirty, dataAux, addressRAM, memRead);
		input clock;//Clock;
		input [7:0]address;//Endere�o de acesso � cache.
		input [7:0]dataIn;//Dado de entrada da cache.
		input [7:0]dataInRam;//Dado de entrada que vem da leitura da mem�ria RAM.
		input write;//Bit que indica leitura e escrita (0 habilita leitura e 1 habilita escrita). 
		output reg [7:0]dataOut;//Dado de sa�da da cache.
		output reg hit;//Valor de sa�da (0 para miss e 1 para hit).
		output reg dirty;//Bit que ir� indicar que o dado precisa ser atualizado na mem�ria RAM.
		output reg [7:0]dataAux;//Registrador auxilixiar que ir� gravar o dado a ser salvo na RAM em caso a cache estiver cheia e precisarmos de subsituir um bloco.
		output reg [7:0]addressRAM;//Registrador auxiliar que grava o endere�o de mem�ria do dado que precisa ser atualizado na memoria RAM.
		output reg memRead;
		integer g, h, i, j, k, l, m, n; //Vari�vel contadora a ser utilizada dentro do la�o for.
		
		reg flag;
		
		//[18] -> Bit de validade (quando ALTO indica que o dado presente na linha de cache � v�lido).
		//[17] -> Bit de sujeira (quando ALTO indica inconsist�ncia entre o dado presente na cache e na mem�ria RAM).
		//[16] -> Bit LRU usado para substitui��o de dados.
		//[15:8] -> Bits de tag.
		//[7:0] -> Dado presente na linha de cache.
		reg [18:0]MCache[1:0];//Declara��o da mem�ria cache (duas linhas de dados de 15 bits);
		
		//Carregamento da mem�ria cache com os dados especificados no roteiro da pr�tica.
		initial begin
			//Dados iniciais da primeira linha de cache
			MCache[0][18] = 1'b1;//Bit de validade � igual a 1.
			MCache[0][17] = 1'b0;//Bit de sujeira � igual a 0.
			MCache[0][16] = 1'b0;//Bit de LRU � igual a 0.
			MCache[0][15:8] = 8'b00000000;//Tag inicial do primeiro bloco de cache em bin�rio.
			MCache[0][7:0] = 8'b00000000;//Dado inicial do primeiro bloco de cache em bin�rio.
			
			//Dados iniciais da segunda linha de cache
			MCache[1][18] = 1'b1;//Bit de validade � igual a 1;
			MCache[1][17] = 1'b0;//Bit de sujeira � igual a zero.
			MCache[1][16] = 1'b1;//Bit de LRU � igual a 1.
			MCache[1][15:8] = 8'b00000010;//Tag inicial do primeiro bloco de cache em bin�rio.
			MCache[1][7:0] = 8'b00000001;//Dado inicial da segunda linha de cache em bin�rio.
		end
		
		//Escritas e leituras s�o realizadas quando temos uma mudan�a de clock. Bit write ativo indica escrita e desativo indica leitura.
		//Primeiro pesquisa por um dado inv�lido, se n�o encontrar substitui o dado menos recentemente usado (LRU).
		always @ (clock) begin	
			if(write) begin
				hit = 0;//Seta a vari�vel "hit" inicialmente como 0 (miss).
				flag = 0;
				for(g=0; g<2 && hit==0; g=g+1) begin
					if(MCache[g][15:8]==address && MCache[g][18]==1'b1) begin
							dirty = 1'b0;//n�o precisa escrever o dado
							MCache[g][7:0] = dataIn;//Atualiza o dado na linha de cache; n�o precisa atualizar o endere�o j� que � o mesmo.
							MCache[g][18] = 1'b1;//Seta 1 no bit de validade.
							MCache[g][17] = 1'b1;//Seta 1 no bit de sujeira (indica que o dado deve ser escito na mem�ria RAM).
							MCache[g][16] = 1'b1;//Seta 1 no Bit de LRU, indica que o dado foi acessado recentemente.
							hit = 1;
							for(h=0; h<2; h=h+1) begin
							   if(g!=h) begin
								    MCache[h][16] = 1'b0;//Atualiza o bit de LRU das outras posi��es da cache.
							   end
						  end
						end
				end
				for(i=0; i<2 && flag==0 && hit==0; i=i+1) begin
					if(MCache[i][18]==1'b0 || MCache[i][16]==1'b0) begin //Se o dado na cache for inv�lido ou for o �ltimo dado acessdo (LRU).
						dirty = MCache[i][17];//Indica se o dado precisa ser atualizado na mem�ria RAM ou n�o.
						if(dirty==1'b1 && MCache[i][18]==1'b1) begin
						  addressRAM = MCache[i][15:8];//Salva o endere�o para atualizar o dado na mem�ria RAM.
						  dataAux = MCache[i][7:0];//Salva o dado para gravar na mem�ria RAM.
						end
						MCache[i][15:8] = address;//Atualiza o endere�o do dado na linha de cache.
						MCache[i][7:0] = dataIn;//Atualiza o dado na linha de cache.
						MCache[i][18] = 1'b1;//Seta 1 no bit de validade.
						MCache[i][17] = 1'b1;//Seta 1 no bit de sujeira (indica que o dado deve ser escito na mem�ria RAM).
						MCache[i][16] = 1'b1;//Seta 1 no Bit de LRU, indica que o dado foi acessado recentemente.
						flag = 1;
						for(j=0; j<2; j=j+1) begin
							if(j!=i) begin
								MCache[j][16] = 1'b0;//Atualiza o bit de LRU das outras posi��es da cache.
							end
						end
					end
				end
			end
		if(!write) begin
		  memRead = 0;//memRad s� vai ser ativado no caso de precisarmos de ler o dado da mem�ria RAM.
			hit = 0;//Seta a vari�vel "hit" inicialmente como 0 (miss).
			for(k=0; k<2; k=k+1) begin
				if(MCache[k][15:8]==address && MCache[k][18]==1'b1) begin
					dataOut = MCache[k][7:0];//Encontrou o dado na cache.
					MCache[k][16] = 1'b1;//Seta 1 no Bit de LRU, indica que o dado foi acessado recentemente.
					hit = 1;//Hit (o dado foi lido da cache).
					for(l=0; l<2; l=l+1) begin
						if(MCache[l][15:8]!=address) begin
							MCache[l][16] = 1'b0;//Atualiza o bit de LRU das outras posi��es da cache.
						end
					end
				end
			end
			//Se o dado n�o foi encontrado na cache � necess�rio busc�-lo na mem�ria RAM.
			flag = 0;
			memRead = 1;//ativa a leitura na mem�ria RAM.
			for(m=0; m<2 && flag==0 && hit==0; m=m+1) begin
					if(MCache[m][18]==1'b0 || MCache[m][16]==1'b0) begin //Se o dado na cache for inv�lido ou for o �ltimo dado acessdo (LRU).
						dirty = MCache[m][17];//Indica se o dado precisa ser atualizado na mem�ria RAM ou n�o.
						if(dirty==1'b1 && MCache[m][18]==1'b1) begin
						  addressRAM = MCache[m][15:8];//Salva o endere�o para atualizar o dado na mem�ria RAM.
						  dataAux = MCache[m][7:0];//Salva o dado para gravar na mem�ria RAM.
						end
						MCache[m][15:8] = address;//Atualiza o endere�o do dado na linha de cache.
						MCache[m][7:0] = dataInRam;//Atualiza o dado na linha de cache.
						MCache[m][18] = 1'b1;//Seta 1 no bit de validade.
						MCache[m][17] = 1'b1;//Seta 1 no bit de sujeira (indica que o dado deve ser escito na mem�ria RAM).
						MCache[m][16] = 1'b1;//Seta 1 no Bit de LRU, indica que o dado foi acessado recentemente.
						flag = 1;
						for(n=0; n<2; n=n+1) begin
							if(n!=m) begin
								MCache[n][16] = 1'b0;//Atualiza o bit de LRU das outras posi��es da cache.
							end
						end
					end
				end
			end
	 end
endmodule

module memoriaRAM(clock, address, dataIn, writeEnable, readEnable, dataOut, hit);
	input clock;//Clock.
	input [7:0]address;//Endere�o de acesso � cache.
	input [7:0]dataIn;//Dado de entrada da cache.
	input writeEnable;//Habilita a escrita.
	input readEnable;//Habilita e escrita.
	output reg [7:0]dataOut;//Dado de sa�da da cache.
	output reg hit;//Valor de sa�da (0 para miss e 1 para hit).
	integer i, j;//Vari�vel contadora a ser utilizada dentro do la�o for.
	
	//[15:8] -> Endere�o de acesso � RAM.
	//[7:0] -> Dado armazenado na linha de RAM.
	reg [15:0]MRAM[3:0];
	
	//Carregamento da mem�ria RAM com os dados especificados no roteiro da pr�tica.
	initial begin
	  for(i=0; i<4; i=i+1) begin
	    MRAM[i] = 0;
	  end
		//Dados iniciais da primeira linha de RAM
		MRAM[0][15:8] = 8'b00000000;//Endere�o da primeira linha de RAM (100 em decimal).
		MRAM[0][7:0] = 8'b00000101;//Dado da primeira linha de RAM (5 em decimal).
		
		//Dados iniciais da segunda linha de RAM
		MRAM[1][15:8] = 8'b00000001;//Endere�o da segunda linha de RAM (101 em decimal).
		MRAM[1][7:0] = 8'b00000011;//Dado da segunda linha de RAM (3 em decimal).
		
		//Dados iniciais da terceira linha de RAM
		MRAM[2][15:8] = 8'b00000010;//Endere�o da terceira linha de RAM (102 em decimal).
		MRAM[2][7:0] = 8'b00000001;//Dado da terceira linha de RAM (1 em decimal).
		
		//Dados iniciais da quarta linha de RAM
		MRAM[3][15:8] = 8'b00000011;//Endere�o da quarta linha de RAM (103 em decimal).
		MRAM[3][7:0] = 8'b00000000;//Dado da quarta linha de RAM (0 em decimal).
	end
	
	//Escritas e leituras s�o realizadas quando temos uma mudan�a de clock; bit write 1 indica escrita e 0 indica leitura.
	//A mem�ria RAM � diretamente mapeada.
	always @ (clock) begin
		if(writeEnable) begin
		  hit = 0;//Seta a vari�vel "hit" inicialmente como 0 (miss).
			for(i=0; i<4 && hit==0; i=i+1) begin
			 if(MRAM[i][15:8]==address) begin
				  MRAM[i][7:0] = dataIn;//Atualiza o dado na linha de RAM.
				  hit = 1;
			 end
			end
		end
		if(readEnable) begin
		  hit = 0;//Seta a vari�vel "hit" inicialmente como 0 (miss).
			for(j=0; j<4 && hit==0; j=j+1) begin
				if(MRAM[j][15:8]==address) begin 
					dataOut = MRAM[j][7:0];//Encontrou o dado na RAM.
					hit = 1;
				end
			end
		end
	end
endmodule

module hierarquia();
	//SW[17] -> clock.
	//SW[16] -> write.
	//SW[15:7] -> endereço de acesso �  memória.
	//SW[7:0] -> dado a ser escrito na memória.

	reg clock;
	reg write;
	reg [7:0]address;
	reg [7:0]dataIn;
	wire [7:0]dataOutC;//Dado de saída.
	wire [7:0]dataOutR;//Dado de saída.
	wire hitC, hitR;//Aceso indica hit e apagado miss.
	wire [7:0]dataAux;//Dado a ser escrito na mem�ria RAM caso ele esteja cheia.
	wire [7:0]addressRAM;//Salva o endere�o para atualizar o dado na mem�ria RAM.
	wire dirty;
	wire memRead;//Bit que indica leitura na mem�ria RAM.
	reg first;
	
	//Bloco de simulação.
	initial begin: init
		clock = 0;
		write = 0;
		address = 8'b00000000;
		dataIn = 8'b00000000;
		$display("Simulacao: ");
		$monitor("clock: %b, wrEnCache: %b, address: %b, dataInCache: %b, MCache[0]: %b, MCache[1]: %b, dataOutCache: %b, hitCache: %b, dirty: %b, dataInRAM: %b, MRAM[0]: %b, MRAM[1]: %b, MRAM[2]: %b, MRAM[3]: %b, dataOutRAM: %b addressRAM: %b, dataAux: %b, flag: %b", clock, write, address, dataIn, MCache1.MCache[0], MCache1.MCache[1], dataOutC, hitC, dirty, dataOutC, MRAM1.MRAM[0], MRAM1.MRAM[1], MRAM1.MRAM[2], MRAM1.MRAM[3], dataOutR, addressRAM, dataAux, MCache1.flag);
	end
	
	always begin: main_process
	   #1 clock = ~clock;
	   #1 write = ~write;
	 end
	
	always @ (dataOutC) begin
	  if(address>=8'b00000011)
	    address = 8'b00000000;
	end
	
	always @ (negedge clock)
	 address = address + 8'b00000001;
	
	initial begin: stop_at
	 #50 $stop;
	end
	
	//Instanciação do bloco de memória.
	memoriaCache MCache1(clock, address, dataIn, dataOutR, write, dataOutC, hitC, dirty, dataAux, addressRAM, memRead);
	memoriaRAM MRAM1(clock, addressRAM, dataAux, dirty, memRead, dataOutR, hitR);
	
endmodule