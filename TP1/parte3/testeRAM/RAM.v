module memoriaRAM(clock, address, dataIn, write, dataOut, hit);
	input clock;//Clock.
	input [7:0]address;//Endere�o de acesso � cache.
	input [7:0]dataIn;//Dado de entrada da cache.
	input write;//Bit que indica leitura e escrita (0 habilita leitura e 1 habilita escrita). 
	output reg [7:0]dataOut;//Dado de sa�da da cache.
	output reg hit;//Valor de sa�da (0 para miss e 1 para hit).
	integer i, j;//Vari�vel contadora a ser utilizada dentro do la�o for.
	
	//[15:8] -> Endere�o de acesso � RAM.
	//[7:0] -> Dado armazenado na linha de RAM.
	reg [15:0]MRAM[3:0];
	
	//Carregamento da mem�ria RAM com os dados especificados no roteiro da pr�tica.
	initial begin
		//Dados iniciais da primeira linha de RAM
		MRAM[0][15:8] = 8'b00000000;//Endere�o da primeira linha de RAM (100 em decimal).
		MRAM[0][7:0] = 8'b00000101;//Dado da primeira linha de RAM (5 em decimal).
		
		//Dados iniciais da segunda linha de RAM
		MRAM[1][15:8] = 8'b0000001;//Endere�o da segunda linha de RAM (101 em decimal).
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
		if(write) begin
		  hit = 0;//Seta a vari�vel "hit" inicialmente como 0 (miss).
			for(i=0; i<4 && hit==0; i=i+1)
			if(MRAM[i][15:8]==address) begin
				MRAM[i][7:0] = dataIn;//Atualiza o dado na linha de RAM.
				hit = 1;
			end
		end
		if(!write) begin
		  hit = 0;//Seta a vari�vel "hit" inicialmente como 0 (miss).
			for(j=0; j<4 && hit==0; j=j+1)
				if(MRAM[j][15:8]==address) begin 
					dataOut = MRAM[j][7:0];//Encontrou o dado na RAM.
					hit = 1;
				end
		end
	end
endmodule

module RAM();
	//SW[17] -> clock.
	//SW[16] -> write.
	//SW[15:7] -> endereço de acesso �  memória.
	//SW[7:0] -> dado a ser escrito na memória.

	reg clock;
	reg write;
	reg [7:0]address;
	reg [7:0]dataIn;
	wire [7:0]dataOut;//Dado de saída.
	wire hit;//Aceso indica hit e apagado miss. 
	
	//Bloco de simulação.
	initial begin: init
		clock = 0;
		write = 1;
		address = 8'b00000000;
		dataIn = 8'b00001111;
		$display("Simulacao: ");
		$monitor("clock: %b, write: %b, address: %b, dataIn: %b, MRAM[0]: %b, MRAM[1]: %b, MRAM[2]: %b, MRAM[3]: %b, dataOut: %b", clock, write, address, dataIn, MRAM1.MRAM[0], MRAM1.MRAM[1], MRAM1.MRAM[2], MRAM1.MRAM[3], dataOut);
	end
	
	always begin: main_process
	 #1 clock = ~clock;
	 #1 dataIn = dataIn + 8'b00000001; 
	 #1  write = ~write;
	end
	
	always @ (dataOut) begin
	  if(address==8'b00000011)
	    address <= 8'b00000000;
	  else
	    address <= address + 8'b00000001;
	end
	
	initial begin: stop_at
	 #200 $stop;
	end
	
	//Instanciação do bloco de memória.
	memoriaRAM MRAM1(clock, address, dataIn, write, dataOut, hit);
endmodule