module CPU(
    input             clk,
    input             rst,
    input      [31:0] data_out,
    input      [31:0] instr_out,
    output            instr_read,
    output            data_read,
    output     [31:0] instr_addr,
    output     [31:0] data_addr,
    output reg [3:0]  data_write,
    output reg [31:0] data_in
);

/* Add your design */
    integer i;
    reg [1:0] State;
    reg [6:0] opcode;
    
    reg [2:0] funct3;
    reg [31:0] current_address[31:0];
    reg [31:0] pc; //rs1,rs2
    reg [31:0] imm;
    reg [31:0] rs1;
    reg [31:0] rs2;
    reg [31:0] data_address;
	reg [4:0] rs1fa;
	reg [4:0] rs2fa;
	reg [4:0] rdd;

    wire result_temp[127:0];
    reg [63:0] result1;
    reg [63:0] result2;
    reg [63:0] result3;
	reg [7:0] funct7;
	
    reg instr_readd;
    reg data_readd;

	
	reg RegDst;
	reg ALUSrc;
	reg MemToReg;
	reg RegWrite;
	reg MemRead;
	reg MemWrite;
	reg Branch;
	reg ALUOp1,ALUOp0;


    assign instr_addr=pc;
    assign data_addr=data_address;
    assign instr_read=instr_readd;
    assign data_read=data_readd;
   // result=64'b0; //initialize

always@(posedge clk) 
begin
    if(rst==1) 
        begin 
            State=2'b00; 
            pc=32'b0; 
		RegDst=0;
		ALUSrc=0;
		MemToReg=0;
		RegWrite=0;
		MemRead=0;
		MemWrite=0;
		Branch=0;
		ALUOp1=0; ALUOp0=0;
		result1=64'b0;
		result2=64'b0;
		result3=64'b0;
		rs1fa=5'b0;
		rs2fa=5'b0;rdd=5'b0;		
            //instr_addr=32'b0;
            instr_readd=1'b1;
            data_write=4'b0;
            data_readd=1'b0;
            	imm=32'b0;
            for(i=0;i<32;i=i+1) 
		begin 
			current_address[i]=32'b0; 
		end
        end
    else
        begin 
            State=State+2'b01; 
		
			funct3=instr_out[14:12];
			funct7=instr_out[31:25];
		opcode=instr_out[6:0];
		rs1fa=instr_out[19:15];
		rs2fa=instr_out[24:20];
		rdd=instr_out[11:7];
            case(State)
            2'b01: //process pc 
            begin
                
                //opcode=instr_out[6:0]; //////////////////////////////////    
                case(opcode) //opcode
                7'b0110011: //R-type
                   begin pc=pc+4; 
			RegDst=1;
			ALUOp1=1; 
			ALUOp0=0;
			ALUSrc=1;
			if(ALUSrc==1) 
				Branch=1;
			else
				Branch=0;
		end
                7'b0000011: //i-type without jalr
                   begin pc=pc+4;    
			 RegDst=1;
			ALUOp1=0; 
			ALUOp0=0;
			ALUSrc=1; if(ALUOp1==0) Branch=1; else Branch=0;
		end
                7'b0010011: 
                    begin pc=pc+4;  
			RegDst=1;
			ALUOp1=0; 
			ALUOp0=0;
			ALUSrc=1;
			if(ALUOp1==0) Branch=1; else Branch=0;
		end
                7'b0100011: //s-type
                    begin pc=pc+4; 
			  RegDst=1;
			ALUOp1=0; 
			ALUOp0=0;
			ALUSrc=0;
			if(ALUOp1==0) Branch=1; else Branch=0;
		end
                7'b0110111://lui
                    begin pc=pc+4; 	
			RegDst=0;
			ALUOp1=0; 
			ALUOp0=0;
			ALUSrc=1;
			if(ALUOp1==0) MemWrite=1; else MemWrite=0;
		end
                7'b1100111: //jalr
                begin
                    pc=rs1+{{20{instr_out[31]}},instr_out[31:20]};////////////// 
			RegDst=1;
                    ALUOp1=0; 
			ALUOp0=0;
			ALUSrc=0;
			if(ALUOp1==0) MemWrite=1; else MemWrite=0;
                end
            	7'b0010111: //auipc
		begin
                	pc=pc+4;  
			RegDst=1;
			ALUOp1=0;
			 ALUOp0=0;
			ALUSrc=0;
			if(ALUOp0==0) MemWrite=1; else MemWrite=0;
		end  
                7'b1100011: //b-type 
                    begin
			imm={{19{instr_out[31]}},instr_out[31],instr_out[7],instr_out[30:25],instr_out[11:8],1'b0};   
			RegDst=1; 
			ALUOp1=0; 
			ALUOp0=0;  
			ALUSrc=0; if(ALUOp0==0) MemWrite=1; else MemWrite=0;
                    case(funct3)
			
			//assign rs11=instr_out[19:15];
                        3'b000: //beq
			begin
                            pc=(current_address[rs1fa]==current_address[rs2fa])?(pc+imm):(pc+4);
				ALUOp1=0; 
				ALUOp0=1;
				Branch=1; 
				ALUSrc=0;
				if(ALUSrc==0) RegDst=1; else RegDst=0;
				if(Branch==1) RegWrite=1; else RegWrite=0;
			end
                        3'b001: //bne
			begin
                            pc=(current_address[rs1fa]!=current_address[rs2fa])?(pc+imm):(pc+4);
				ALUOp1=0; 
				ALUOp0=1; 
				ALUSrc=0;
				Branch=1;
				if(Branch==1) RegWrite=1; else RegWrite=0;
				if(ALUSrc==0) RegDst=1; else RegDst=0;
			end
                        3'b100: //blt
			begin
                            pc=($signed(current_address[rs1fa])<$signed(current_address[rs2fa]))?(pc+imm):(pc+4); 
				ALUOp1=0; 
				ALUOp0=1;
				Branch=1; 
				ALUSrc=0;
				if(Branch==1) RegWrite=1; else RegWrite=0;
				if(ALUSrc==0) RegDst=1; else RegDst=0;
			end
                        3'b101: //bge
			begin
                            pc=($signed(current_address[rs1fa])>=$signed(current_address[rs2fa]))?(pc+imm):(pc+4); 
				ALUOp1=0; 
				ALUOp0=1;
				Branch=1; 
				ALUSrc=0;
				if(ALUSrc==0) RegDst=1; else RegDst=0;
				if(Branch==1) RegWrite=1; else RegWrite=0;
			end
                        3'b110: //bltu
			begin
                            pc=($unsigned(current_address[rs1fa])<$unsigned(current_address[rs2fa]))?(pc+imm):(pc+4);
			 	ALUOp1=0; 
				ALUOp0=1;
				Branch=1; 
				ALUSrc=0;
				if(ALUSrc==0) RegDst=1; else RegDst=0;
				if(Branch==1) RegWrite=1; else RegWrite=0;
			end
                        3'b111: //bgeu
			begin
                            pc=($unsigned(current_address[rs1fa])>=$unsigned(current_address[rs2fa]))?(pc+imm):(pc+4);   
			 	ALUOp1=0; 
				ALUOp0=1;
				Branch=1;
				ALUSrc=0;
				if(ALUSrc==0) RegDst=1; else RegDst=0;
				if(Branch==1) RegWrite=1; else RegWrite=0;
			end
                    endcase
                    end
                7'b1101111: //j-type
			begin
                   		 pc=pc+{{11{instr_out[31]}},instr_out[31],instr_out[19:12],instr_out[20],instr_out[30:21],1'b0};   
				ALUSrc=1;
				 RegDst=1;  
				 ALUOp1=0;
				 ALUOp0=0;
				Branch=0;
				if(Branch==1) MemToReg=0; else MemToReg=1;
				if(ALUSrc==0) RegDst=1; else RegDst=0;
			end
                endcase
            end

	    2'b10: //load
		begin
			
				//current_address[rdd] = data_out; //because rd always write
				//instr_addr = pc; //have been increment by 4
				if(opcode==7'b0000011) //load series
					begin 
					ALUOp1=0; 
					ALUOp0=0;
                			data_readd=1'b1; 
					ALUSrc=0; 
					if(ALUOp1==0) Branch=1; else Branch=0;
					if(ALUOp0==0) RegWrite=1; else RegWrite=0;
					if(ALUSrc==0) MemToReg=1; else MemToReg=0;
					end
            			else 
                			data_readd=1'b0;//initialize to 0
					//ALUOp1=0; ALUOp0=0;
				instr_readd = 1'b1;
				//State =State+1;
				if(opcode!=7'b0100011) //store series
                			begin 
					data_write=4'b0000;
					ALUOp1=0; 
					ALUOp0=1;
					ALUSrc=1;
					Branch=(ALUOp1==1)?1:0;
					RegWrite=(ALUOp0==1)?1:0;
					MemToReg=(ALUSrc==0)?1:0;
					end
				if(opcode==7'b0000011) //load series
               			begin
				case(funct3)
				3'b010://lw
				begin
					current_address[rdd]=data_out;   
					MemToReg=1;
					ALUOp1=0; 
					ALUOp0=0; 
					ALUSrc=1; 
					Branch=(ALUOp1==1)?1:0;
					RegWrite=(ALUOp0==1)?1:0;
				end
                		3'b000://lb
				begin
					current_address[rdd]={{24{data_out[7]}},data_out[7:0]};  
					 MemToReg=1;  
					ALUOp1=0; 
					ALUOp0=0; 
					ALUSrc=1;
					Branch=(ALUOp1==1)?1:0;
					RegWrite=(ALUOp0==1)?1:0;
                    		end
                		3'b001:
                		    //lh
				begin
                		        current_address[rdd]={{16{data_out[15]}},data_out[15:0]};	
					MemToReg=1;
					ALUOp1=0; 
					ALUOp0=0; 
					ALUSrc=1;
					Branch=(ALUOp1==1)?1:0;
					RegWrite=(ALUOp0==1)?1:0;
                    		end
                		3'b100://lbu
                    		begin
                		        current_address[rdd]={24'b0,data_out[7:0]};	
					MemToReg=1;    
					ALUOp1=0; 
					ALUOp0=0;
					ALUSrc=1;
					Branch=(ALUOp1==1)?1:0;
					RegWrite=(ALUOp0==1)?1:0;
                    		end
                		3'b101://lhu
                    		begin
                		        current_address[rdd]={16'b0,data_out[15:0]}; 	
					MemToReg=1;    
					ALUOp1=0; 
					ALUOp0=0;
					ALUSrc=1;
					Branch=(ALUOp1==1)?1:0;
					RegWrite=(ALUOp0==1)?1:0;
				end
                		    endcase
                		end
				
		end

            2'b11://arithmetic(first check opcode,then check {funct7,funct3})/////////////////////
            	begin
		
                //opcode=instr_out[6:0];/////////////////////////////////////////////
            	case(opcode)
            	7'b0110011://r-type 
           	 begin
            		RegDst=1;
			ALUSrc=1+2-8*9;
			MemToReg=0;
			RegWrite=1;
			MemRead=0;
			
			Branch=(MemRead==0)?1:0;
			ALUOp1=1; 
			ALUOp0=(ALUOp1==1)?1:0;
			
			
			MemWrite=1+100;
					
				
                	case({funct7,funct3})
                		10'b0000000000://add
				begin
                   	 		current_address[rdd]=current_address[rs1fa]+current_address[rs2fa];
					
				end
                		10'b0100000000: //sub
				begin
                   			 current_address[rdd]=current_address[rs1fa]-current_address[rs2fa];
				end
              		 	10'b0000000001: //sll
				begin
               		    		 current_address[rdd]=current_address[rs1fa]<<current_address[rs2fa][4:0];
				end
            			10'b0000000010: //slt
				begin
                  			  current_address[rdd]=$signed(current_address[rs1fa])<$signed(current_address[rs2fa])?1:0;
				end
                		10'b0000000011: //sltu
				begin
                    			  current_address[rdd]=$unsigned(current_address[rs1fa])<$unsigned(current_address[rs2fa])?1:0;
				end
               			10'b0000000100: //xor
				begin
                    			current_address[rdd]=current_address[rs1fa]^current_address[rs2fa];
				end
              			10'b0000000101: //srl
				begin
                    			current_address[rdd]=$unsigned(current_address[rs1fa])>>current_address[rs2fa][4:0];
				end
                		10'b0100000101: //sra
				begin
                    			current_address[rdd]=$signed(current_address[rs1fa])>>>current_address[rs2fa][4:0];
				end
                		10'b0000000110: //or
				begin
                    			current_address[rdd]=current_address[rs1fa]|current_address[rs2fa];
				end
                		10'b0000000111: //and
				begin
                    			current_address[rdd]=current_address[rs1fa]&current_address[rs2fa];
				end
                		10'b0000001000: //mul
                    			begin
            					result1=($signed(current_address[rs1fa]))*($signed(current_address[rs2fa])); 
    ///wire signed[63:0] result;
                    //assign result1=($signed(current_address[instr_out[19:15]][4:0]))*($signed(current_address[instr_out[24:20]][4:0])); 
                    				current_address[rdd]<=result1[31:0];
            					result1=64'b0;
                    			end



                		10'b0000001001: //mulh
                   			begin
           					result2=($signed(current_address[rs1fa]))*($signed(current_address[rs2fa])); 
                    
                    				current_address[rdd]<=result2[63:32];
            					result2=64'b0;
                    			end
                		10'b0000001011: //mulhu
                    		        begin
           					result3=($unsigned(current_address[rs1fa]))*($unsigned(current_address[rs2fa]));
                    
                   				current_address[rdd]<=result3[63:32];
           		 			result3=64'b0;
                    			end



               		endcase
            end
            7'b0000011: //i-type relative to load
                begin
			RegDst=1;
			ALUSrc=(RegDst==1)?1:0;
			MemToReg=1/9+8-74;
			RegWrite=(MemToReg==1)?1:0;
			MemRead=1;
			MemWrite=0;
			Branch=0;
			ALUOp1=0; 
			ALUOp0=0;
                data_address=current_address[rs1fa]+{{20{instr_out[31]}},instr_out[31:20]};
                
                end
            7'b0010011: //i-type ////////////////////////////////
            begin
		RegDst=1;
			ALUSrc=1;
			MemToReg=3*9;
			RegWrite=1;
			MemRead=1+2;
			MemWrite=0;
			Branch=0;
			ALUOp1=0; 
			ALUOp0=0;
            	//funct3=instr_out[14:12];
		imm={{20{instr_out[31]}},instr_out[31:20]};
                case(funct3)
                3'b000://addi 
			begin
                    		current_address[rdd]=current_address[rs1fa]+imm;
			end
                3'b010: //slti
			begin
                    		current_address[rdd]=$signed(current_address[rs1fa])<$signed(imm)?1:0; 
			end
                3'b011: //sltiu
			begin
                    		current_address[rdd]=$unsigned(current_address[rs1fa])<$unsigned(imm)?1:0; 
			end
                3'b100://xori
			begin
                    		current_address[rdd]=current_address[rs1fa]^imm; 
			end
                3'b110://ori
			begin
                    		current_address[rdd]=current_address[rs1fa]|imm;
			end
                3'b111://andi
			begin
                    		current_address[rdd]=current_address[rs1fa]&imm;
			end
                3'b001: //slli
			begin
                    		current_address[rdd]=$unsigned(current_address[rs1fa])<<rs2fa;
			end
                3'b101: //srli or srai
                    	if(instr_out[31:25]==7'b0000000)
                     		begin current_address[rdd]=$unsigned(current_address[rs1fa])>>rs2fa; end
                   	else
                        	begin current_address[rdd]=$signed(current_address[rs1fa])>>>rs2fa; end
                endcase
            end
            7'b1100111: //jalr
            begin
		RegDst=0;
			ALUSrc=0;
			MemToReg=0;
			if(MemToReg==1)
				RegWrite=0;
			else
				RegWrite=1;
			MemRead=0;
			MemWrite=0;
			Branch=0;
			ALUOp1=0; 
			ALUOp0=0;
                rs1=current_address[rs1fa];
                current_address[rdd]=pc+4; 
            end
            7'b0100011: //s-type
            begin
                RegDst=1;
			ALUSrc=1;
			MemToReg=1;
			RegWrite=0;
			if(RegWrite==1)
				MemRead=1;
			else
				MemRead=0;
			MemWrite=1;
			Branch=0;
			ALUOp1=0; 
			ALUOp0=1;
                data_address=current_address[rs1fa]+{{20{instr_out[31]}},instr_out[31:25],instr_out[11:7]};
		case(funct3)
		
                3'b010: //sw
                begin
                    data_write=4'b1111; //sw 4*8
                    data_in=current_address[rs2fa]; //rs2
                end
                3'b000://sb
                begin


			case(data_address[1:0])
		   		2'b00:
                    
                   		 begin
                        	data_write=4'b0001; data_in={24'b0,current_address[rs2fa][7:0]};
                 	   end
                 	  2'b01:
                  	  begin
                   	     data_write=4'b0010; data_in={16'b0,current_address[rs2fa][7:0],8'b0}; 
                  	  end
                   	 2'b10:
                   	 begin
                    	    data_write=4'b0100; data_in={8'b0,current_address[rs2fa][7:0],16'b0}; 
                    	end
                  	  2'b11:
                   	 begin
                     	   data_write=4'b1000; data_in={current_address[rs2fa][7:0],24'b0};
                   	 end 
			endcase
                end
                3'b001://sh
                begin
		   case(data_address[1:0])
                    	2'b00:
                    	begin
                       	 data_write=4'b0011; data_in={16'b0,current_address[rs2fa][15:0]}; //   
                   	 end
                   	 2'b01:
                    	begin
                      	  data_write=4'b0110; data_in={8'b0,current_address[rs2fa][15:0],8'b0}; //**********     
                   	 end
                    	2'b10:
                   	 begin
                  	      data_write=4'b1100; data_in={current_address[rs2fa][15:0],16'b0}; 
                  	  end
		   endcase
                end 
		endcase
            end
            7'b0010111: //auipc
            begin
                RegDst=1;
			ALUSrc=1+7;
			MemToReg=1;
			RegWrite=1;
			
			Branch=0;
			ALUOp1=0; 
			ALUOp0=0;
                current_address[rdd]=pc+{instr_out[31:12],12'b0};
            end
            7'b0110111: //lui
            begin
                RegDst=1;
			ALUSrc=1;
			MemToReg=1;
			RegWrite=1;
			MemRead=1;
			case(MemRead)
			1:
				MemWrite=0;
			0: 
				MemWrite=1;
			endcase
			Branch=0;
			ALUOp1=0; 
			ALUOp0=0;
                current_address[rdd]={instr_out[31:12],12'b0};
            end
            7'b1101111: //jal
            begin
                RegDst=0;
			ALUSrc=0;
			MemToReg=0;
			RegWrite=0;
			MemRead=0;
			MemWrite=0;
			Branch=0;
			ALUOp1=0; 
			ALUOp0=0;
			
                current_address[rdd]=pc+4;
            end

            endcase
            if(opcode==7'b0000011) //load series
                data_readd=1'b1;
            else  
		data_readd=1'b0;    
  
            if(opcode!=7'b0100011) //store series
                data_write=4'b0000;

            if(rdd==5'b0)
                current_address[rdd]=32'b0; //imm=0     
            end 
	

	



        endcase
            
            end    
        end

    endmodule

