//ImplementaÃ§Ã£o de uma hierarquia de memÃ³ria com dois nÃ­veis (cache L1 e memÃ³ria RAM).
//A cache L1 Ã© totalmente assiciativa e a memÃ³ria RAM Ã© diretamente mapeada.
//EndereÃ§os de memÃ³ria de 8 bits e tamanho de palavra de 8 bits.

module memoriaCache(clock, address, dataIn, write, dataOut, hit);
		input clock;//Clock;
		input [7:0]address;//Endereço de acesso à cache.
		input [7:0]dataIn;//Dado de entrada da cache.
		input write;//Bit que indica leitura e escrita (0 habilita leitura e 1 habilita escrita). 
		output reg [7:0]dataOut;//Dado de saída da cache.
		output reg hit;//Valor de saída (0 para miss e 1 para hit).
		integer h, i, j, k, l; //Variável contadora a ser utilizada dentro do laço for.
		reg controle = 1;
		
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
		
		//Escritas e leituras são realizadas quando temos uma mudança de clock. Bit write ativo indica escrita e desativo indica leitura.
		//Primeiro pesquisa por um dado inválido, se não encontrar substitui o dado menos recentemente usado (LRU).
		always @ (clock) begin	
			if(write) begin
				hit = 0;//Seta a variável "hit" inicialmente como 0 (miss).
				for(h=0; h<2 && hit==0; h=h+1) begin
					if(MCache[h][15:8]==address) begin
							MCache[h][7:0] = dataIn;//Atualiza o dado na linha de cache; não precisa atualizar o endereço já que é o mesmo.
							MCache[h][18] = 1'b1;//Seta 1 no bit de validade.
							MCache[h][17] = 1'b1;//Seta 1 no bit de sujeira (indica que o dado deve ser escito na memória RAM).
							MCache[h][16] = 1'b1;//Seta 1 no Bit de LRU, indica que o dado foi acessado recentemente.
							hit = 1;
						end
				end
				for(i=0; i<2 && hit==0; i=i+1) begin
					if(MCache[i][18]==1'b0 || MCache[i][16]==1'b0) begin //Se o dado na cache for inválido.
						MCache[i][15:8] = address;//Atualiza o endereço do dado na linha de cache.
						MCache[i][7:0] = dataIn;//Atualiza o dado na linha de cache.
						MCache[i][18] = 1'b1;//Seta 1 no bit de validade.
						MCache[i][17] = 1'b1;//Seta 1 no bit de sujeira (indica que o dado deve ser escito na memória RAM).
						MCache[i][16] = 1'b1;//Seta 1 no Bit de LRU, indica que o dado foi acessado recentemente.
						hit = 1;
						for(j=0; j<2; j=j+1) begin
							if(j!=i) begin
								MCache[j][16] = 1'b0;//Atualiza o bit de LRU das outras posições da cache.
							end
						end
					end
				end
			end
		if(!write) begin	
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
		end
	end
endmodule

module cache();
	//SW[17] -> clock.
	//SW[16] -> write.
	//SW[15:7] -> endereÃ§o de acesso Ã  memÃ³ria.
	//SW[7:0] -> dado a ser escrito na memÃ³ria.

	reg clock;
	reg write;
	reg [7:0]address;
	reg [7:0]dataIn;
	wire [7:0]dataOut;//Dado de saÃ­da.
	wire hit;//Aceso indica hit e apagado miss. 
	
	//Bloco de simulaÃ§Ã£o.
	initial begin: init
		clock <= 0;
		write <= 1;
		address <= 8'b00000000;
		dataIn <= 8'b00001111;
		$display("Simulacao: ");
		$monitor("clock: %b, write: %b, address: %b, dataIn: %b, MCache[0]: %b, MCache[1]: %b, dataOut: %b, hit: %b", clock, write, address, dataIn, MCache1.MCache[0], MCache1.MCache[1], dataOut, hit);
	end
	
	always begin: main_process
	 #1 clock = ~clock;
	 #1 dataIn = dataIn + 8'b00000001; 
	 #1  write = ~write;
	end
	
	always @ (dataOut) begin
	  if(address==8'b00000001)
	    address <= 8'b00000000;
	  else
	    address <= address + 8'b00000001;
	end
	
	initial begin: stop_at
	 #200 $stop;
	end
	
	//InstanciaÃ§Ã£o do bloco de memÃ³ria.
	memoriaCache MCache1(clock, address, dataIn, write, dataOut, hit);
endmodule
