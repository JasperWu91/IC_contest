module STI_DAC(clk ,reset, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end,
	       so_data, so_valid,
	       oem_finish, oem_dataout, oem_addr,
	       odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr);

input		clk, reset;
input		load, pi_msb, pi_low, pi_end; 
input	[15:0]	pi_data;
input	[1:0]	pi_length;
input		pi_fill;
output	reg	so_data, so_valid;

output  reg oem_finish, odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr;
output  reg [4:0] oem_addr;
output reg [7:0] oem_dataout;

//==============================================================================
parameter IDLE         = 3'd0,
		  LOAD         = 3'd1,
		  SERIAL_OUT   = 3'd2,
		  COMPLETE     = 3'd3;
integer i;
//==============================================================================
reg [4:0] pi_len_reg; // 2'b00:8 , 2'b01:16, 2'b10:24 , 2'b11:32
reg [31:0] in_data_buf;
reg [2:0] c_state, n_state;
reg [4:0] cnt;
reg [3:0] data_cnt;
reg [7:0] mem_select,mem_cnt,dac_buf; // mem_select[0] : for EVEN and ODD ,    mem_select[7:5]: 0,2,4,6 : for ODD , 1,3,5,7 : EVEN
//==============================================================================
always @(posedge clk or posedge reset) begin
	if (reset) begin
		c_state <= IDLE;
	end else c_state = n_state;
end


always @(*) begin
	n_state = c_state;
	case (c_state)
		IDLE: begin
			if (load) begin
				n_state = LOAD;
			end
		end 
		LOAD: begin
			n_state = SERIAL_OUT;
		end
		SERIAL_OUT: begin
			if (cnt == 0 && pi_end) begin
				n_state = COMPLETE;
			end
			else if (!cnt) begin
				n_state = IDLE;
			end
		end

		default: n_state = c_state;
	endcase
end

always @(*) begin
	case (pi_length)
		2'd0 : pi_len_reg = 5'd7;
		2'd1 : pi_len_reg = 5'd15;
		2'd2 : pi_len_reg = 5'd23;
		2'd3 : pi_len_reg = 5'd31;
		default: pi_len_reg = 5'd0;
	endcase
end


always @(posedge clk or posedge reset) begin
	if (reset) begin
		in_data_buf <= 32'd0;
	end
	else if (n_state == IDLE) begin
		in_data_buf <= 32'd0;
	end
	else if(load)begin
		case (pi_length)
			2'b00: begin
				if (pi_low) begin
					in_data_buf[31:24] = pi_data[15:8];
					in_data_buf[23:0]  = 24'd0;
				end else begin
					in_data_buf[31:24] = pi_data[7:0];
					in_data_buf[23:0 ] = 24'd0;
				end
			end 
			2'b01: begin
				in_data_buf[31:16] = pi_data[15:0];
				in_data_buf[15:0 ] = 16'd0;
			end
			2'b10: begin
				if (pi_fill) begin
					in_data_buf[31:16] = pi_data[15:0];
					in_data_buf[15:0 ] = 16'd0;
				end
				else begin
					in_data_buf[23:8] = pi_data[15:0];
					in_data_buf[31:24 ] = 8'd0;	
					in_data_buf[7:0 ] = 8'd0;			
				end
			end
			2'b11: begin
				if (pi_fill) begin
					in_data_buf[31:16] = pi_data[15:0];
					in_data_buf[15:0 ] = 16'd0;
				end
				else begin
					in_data_buf[15:0] = pi_data[15:0];
					in_data_buf[31:16 ] = 16'd0;				
				end
			end
			default: in_data_buf = 32'd0;	
		endcase
	end
	else if (c_state == SERIAL_OUT) begin
		if (pi_msb) begin
			for (i = 0 ; i < 32 ; i = i+1 ) begin
				in_data_buf[i+1] <= in_data_buf[i];
			end
			in_data_buf[0] <= 0;			
		end else begin
			for (i = 0 ; i < 32 ; i = i+1 ) begin
				in_data_buf[i] <= in_data_buf[i+1];
			end
			in_data_buf[31] <= 0;
		end
	end
end


always @(posedge clk or posedge reset) begin
	if (reset) begin
		cnt <= 5'd31;
	end
	else if (c_state == SERIAL_OUT) begin
		cnt <= (cnt - 1);
	end
	else if (n_state == LOAD) begin
		case (pi_length)
			2'b00: cnt <= 5'd7;
			2'b01: cnt <= 5'd15;
			2'b10: cnt <= 5'd23;
			2'b11: cnt <= 5'd31;
			default: cnt <= 5'd0;
		endcase
	end
	else cnt <= cnt; 
end

always @(*) begin
	if (c_state == SERIAL_OUT) begin
		so_valid = 1;
	end else so_valid = 0;
end
always @(*) begin
	if (c_state == SERIAL_OUT) begin
		if (pi_msb) begin
			case (pi_length)
				2'b00: so_data = in_data_buf[31];
				2'b01: so_data = in_data_buf[31];
				2'b10: so_data = in_data_buf[31];
				2'b11: so_data = in_data_buf[31];
				default: so_data = 0;
			endcase
		end
		else begin
			case (pi_length)
				2'b00: so_data = in_data_buf[24];
				2'b01: so_data = in_data_buf[16];
				2'b10: so_data = in_data_buf[8];
				2'b11: so_data = in_data_buf[0];
				default: so_data = 0;
			endcase		
		end
	end
end

//==============================================================================
//      DAC
//==============================================================================

always @(posedge clk or posedge reset) begin
	if (reset) begin
		dac_buf <= 8'd0;
	end
	else if (so_valid) begin
		dac_buf <=( dac_buf << 1);
		dac_buf[0] <= so_data;
	end
	if (c_state == COMPLETE) begin
		dac_buf <= 8'd0;
	end
end
//oem_dataout

always @(*) begin
	oem_dataout = dac_buf;
end
always @(posedge clk or posedge reset) begin
	if (reset) begin
		data_cnt <= 4'd0;
	end
	else if (c_state == IDLE) begin
		data_cnt <= 4'd0;
	end
	else if (c_state == COMPLETE && (data_cnt[1:0] == 2'b11)) begin
		data_cnt <= 4'd0;
	end
	else if (c_state == COMPLETE) begin
		data_cnt <=data_cnt + 1;
	end
	else if (so_valid) begin
		data_cnt <= data_cnt + 1;
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		mem_select <= 8'd0;
	end
	else if (data_cnt == 4'd7 || data_cnt == 4'd15) begin
		mem_select <= mem_select + 1;
	end
	else if (c_state ==COMPLETE && (data_cnt[1:0] == 2'd11 )) begin
		mem_select <= mem_select + 1;
	end
end
reg [6:0] odd_cnt,even_cnt;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		odd_cnt <= 7'd0;
	end	
	else if (((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3]) ) && c_state == SERIAL_OUT && (data_cnt == 4'd7 || data_cnt == 4'd15)) begin
		odd_cnt <= odd_cnt + 1;
	end
	else if (((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3]) ) && c_state == COMPLETE &&(data_cnt[1:0] == 2'd11 )) begin
		odd_cnt <= odd_cnt + 1;
	end
end
always @(posedge clk or posedge reset) begin
	if (reset) begin
		even_cnt <= 7'd0;
	end	
	else if (~((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3])) && c_state == SERIAL_OUT && (data_cnt == 4'd7 || data_cnt == 4'd15)) begin
		even_cnt <= even_cnt + 1;
	end
	else if (~((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3])) && c_state == COMPLETE  &&(data_cnt[1:0] == 2'd11 )) begin
		even_cnt <= even_cnt + 1;
	end
end

always@(*)begin
	if(c_state == COMPLETE &&(mem_select == 0) ) oem_finish = 1'd1;
	else oem_finish = 1'd0;
end

always @(*) begin
	if (~((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3])) && (c_state == SERIAL_OUT|| c_state == IDLE  ||c_state == COMPLETE) ) begin
		oem_addr = (odd_cnt -1);
	end
	else if (((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3])) && (c_state == SERIAL_OUT || c_state == IDLE || c_state == COMPLETE)) begin
        oem_addr = (even_cnt-1);
	end
	else oem_addr = 8'd0;
end

//odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		odd1_wr <= 0;
	end
	else if (odd_cnt[6:5] == 2'd00 && (data_cnt == 4'd7 || data_cnt == 4'd15) &&( mem_select < 64) && ((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3]))) begin
        odd1_wr <= 1;
	end
	else odd1_wr <= 0;
end
always @(posedge clk or posedge reset) begin
	if (reset) begin
		even1_wr = 0;
	end
	else if (even_cnt[6:5] == 2'd00 && (data_cnt == 4'd7 || data_cnt == 4'd15) && (mem_select < 64) && ~((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3]))) begin
        even1_wr <= 1;
	end
	else even1_wr <= 0;
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		odd2_wr = 0;
	end
	else if (odd_cnt[6:5] == 2'd01 && (data_cnt == 4'd7 || data_cnt == 4'd15) && (mem_select < 128) && ((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3]))) begin
        odd2_wr <= 1;
	end
	else odd2_wr <= 0;
end
always @(posedge clk or posedge reset) begin
	if (reset) begin
		even1_wr = 0;
	end
	else if (even_cnt[6:5] == 2'd01 && (data_cnt == 4'd7 || data_cnt == 4'd15) && (mem_select < 128) && ~((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3]))) begin
        even2_wr <= 1;
	end
	else even2_wr <= 0;
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		odd3_wr = 0;
	end
	else if (odd_cnt[6:5] == 2'd10 && (data_cnt == 4'd7 || data_cnt == 4'd15) && (mem_select < 192) && ((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3]))) begin
        odd3_wr <= 1;
	end
	else odd3_wr <= 0;
end
always @(posedge clk or posedge reset) begin
	if (reset) begin
		even3_wr = 0;
	end
	else if (even_cnt[6:5] == 2'd10 && (data_cnt == 4'd7 || data_cnt == 4'd15) && (mem_select < 192) && ~((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3]))) begin
        even3_wr <= 1;
	end
	else even3_wr <= 0;
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		odd4_wr = 0;
	end
	else if (odd_cnt[6:5] == 2'd11 && (data_cnt == 4'd7 || data_cnt == 4'd15) && (mem_select >= 192) && ((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3]))) begin
        odd4_wr <= 1;
	end
	else if (c_state == COMPLETE && (~((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3]))) &&(data_cnt[1:0] == 2'd11 )) begin
		odd4_wr <= 1;
	end
	else odd4_wr <= 0;
end
always @(posedge clk or posedge reset) begin
	if (reset) begin
		even4_wr = 0;
	end
	else if (even_cnt[6:5] == 2'd11 && (data_cnt == 4'd7 || data_cnt == 4'd15) && (mem_select >= 192) && ~((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3]))) begin
        even4_wr <= 1;
	end
	else if (c_state == COMPLETE && ((!mem_select[0] && !mem_select[3]) ||(mem_select[0] && mem_select[3]))  &&(data_cnt[1:0] == 2'd11 )) begin
		even4_wr <= 1;
	end
	else even4_wr <= 0;
end
endmodule
