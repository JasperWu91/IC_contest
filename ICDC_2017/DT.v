module DT(
	input 			clk, 
	input			reset,
	output	reg		done ,
	output	reg		sti_rd ,
	output	reg 	[9:0]	sti_addr ,
	input		[15:0]	sti_di,
	output	reg		res_wr ,
	output	reg		res_rd ,
	output	reg 	[13:0]	res_addr ,
	output	reg 	[7:0]	res_do,
	input		[7:0]	res_di,
	output reg forward_complete

	);

	parameter IDLE = 0,
			  READ_STI = 1,
			  FORWARD = 2,
			  REST_0 =3,
			  READ_B = 4,
			  BACKWARD = 5,
			  WRITE_B = 6,
			  DONE = 7;
	integer i;
	reg [4:0] cnt , n_cnt;
	reg [2:0] sti_cnt;
	reg [7:0] w_cnt,row_cnt;
	// reg [15:0] sti_data_reg;
	// reg [7:0] res_data_reg;
	reg [7:0] min_val;

	reg [3:0] c_state, n_state;

	reg [7:0] x_po;
	reg [7:0] F_temp[0:3];
	reg [7:0] F_target;

	reg [7:0] sti_buf [0:127];
	reg [7:0] sti_buf_0 [0:127];

	reg [7:0] minTemp;
	reg [3:0] cnt;

	always @(posedge clk or negedge reset) begin
		if (!reset) begin
			c_state <= IDLE;
		end else c_state <= n_state;
	end

	always @(*) begin
		n_state = c_state;
		case (c_state)
			IDLE : n_state = READ_STI;

			READ_STI : begin
				if (sti_cnt == 7) begin
					n_state = FORWARD;
				end
			end

			FORWARD : begin
				if (w_cnt == 127) begin
					n_state = REST_0;
				end
			end

			REST_0 : begin
				if (row_cnt == 127) begin
					n_state = READ_B;
				end
				else n_state = READ_STI;
			end
			//================BACKWARD =================
			READ_B:
			begin
				if(res_di) n_state = BACKWARD;
				else
				begin
					if(res_addr == 14'd128) n_state = DONE;
					else n_state = READ_B;
				end
			end
			BACKWARD:
			begin
				if(cnt == 4'd5) n_state = WRITE_B;
				else n_state = BACKWARD;
			end
			WRITE_B:
			begin
				if(res_addr == 14'd128) n_state = DONE;
				else n_state = READ_B;
			end

			DONE: n_state = DONE;


			default: n_state = c_state;
		endcase
	end
	//====================================================
	// cnt 
	//====================================================

	always @(posedge clk or negedge reset) begin
		if (!reset) begin
			sti_cnt <= 0;
		end
		else if (c_state == REST_0) begin
			sti_cnt <= 0;
		end
		else if (c_state == READ_STI) begin
			sti_cnt <= sti_cnt + 1;
		end
	end

	always @(posedge clk or negedge reset) begin
		if (!reset) begin
			row_cnt <= 0;
		end
		else if (c_state == REST_0) begin
			row_cnt <= row_cnt + 1;
		end
	end

	always @(posedge clk or negedge reset) begin
		if (!reset) begin
			w_cnt <= 0;
		end
		else if (c_state == REST_0) begin
			w_cnt <= 0;
		end
		else if (c_state == FORWARD) begin
			w_cnt <= w_cnt + 1;
		end
	end

	//cnt
	always@(posedge clk or negedge reset)
	begin
		if(!reset) cnt <= 4'd15;
		else if( n_state == BACKWARD) cnt <= cnt + 4'd1;
		else if( n_state == WRITE_B) cnt <= 4'd0;
	end

	//====================================================
	// STI MEM CONTROL
	//====================================================
	always @(*) begin
		if (c_state == READ_STI) begin
			sti_addr = ((row_cnt << 3) + sti_cnt);
		end
		else  sti_addr =  0;
	end
	always @(*) begin
		if (c_state == READ_STI) begin
			sti_rd = 1;
		end
		else  sti_rd =  0;
	end

	// sti buffer
	always @(posedge clk or negedge reset) begin
		if (!reset) begin
			for (i = 0 ; i < 128 ; i=i+1 ) begin
				sti_buf[i] <= 0;
			end	
		end
		else if (c_state == READ_STI) begin
			for (i = 0 ; i < 16 ; i=i+1) begin
				sti_buf[(sti_cnt << 4) + i ] <= sti_di[15-i];
			end
		end
		else if (c_state == FORWARD) begin
			if (sti_buf[w_cnt]) begin
				sti_buf[w_cnt] <= min_val + 1;
			end
		end
	end

	always @(posedge clk or negedge reset) begin
		if (!reset) begin
			for (i = 0 ; i < 128 ; i=i+1 ) begin
				sti_buf_0[i] <= 0;
			end	
		end
		else if (c_state == REST_0) begin
			sti_buf_0 <= sti_buf;	
		end
	end
	//====================================================
	// FORWARD CONTROL
	//====================================================
	always @(*) begin
		if (c_state == FORWARD) begin
			F_target = sti_buf[w_cnt];
		end
		else F_target = 0;
	end

	always @(*) begin
		if (c_state == FORWARD && (F_target != 0) && (w_cnt > 0) && (w_cnt != 127)) begin
			F_temp[0] = ((w_cnt -1 ) >= 0) ? sti_buf_0 [w_cnt -1 ] : 0 ;
			F_temp[1] = sti_buf_0 [w_cnt];
			F_temp[2] = ((w_cnt -1 ) <= 127) ? sti_buf_0 [w_cnt + 1] : 0;
			F_temp[3] = ((w_cnt -1 ) >= 0) ? sti_buf [w_cnt - 1]: 0 ;
		end
		else begin
			F_temp[0] = 0;
			F_temp[1] = 0;
			F_temp[2] = 0;
			F_temp[3] = 0;
		end
	end


	reg [7:0] min_temp [0:2];

	always @(*) begin
		min_temp[0] = F_temp[0];
		min_temp[1] = ( F_temp[1] > min_temp[0]) ? min_temp[0] : F_temp[1];
		min_temp[2] = ( F_temp[2] > min_temp[1]) ? min_temp[1] : F_temp[2];
		min_val = ( F_temp[3] > min_temp[2]) ? min_temp[2] : F_temp[3];
	end

	//====================================================
	// RES MEM CONTROL
	//====================================================
	always @(posedge clk or negedge reset) begin
		if (!reset) begin
			res_wr <= 0;
		end		
		else if (c_state == FORWARD || n_state == WRITE_B) begin
            res_wr <= 1;
        end
		else res_wr <= 1'd0; 
	end

	//res_rd
	always@(posedge clk or negedge reset) begin
		if(!reset) res_rd <= 1'd0;
		else if( n_state == READ_B || n_state == BACKWARD) res_rd <= 1'd1;
		else res_rd <= 1'd0;
	end

	always @(posedge clk or negedge reset) begin
		if (!reset) begin
			res_addr <= 0;
		end		
		else if (c_state == FORWARD) begin
            res_addr <= (row_cnt << 7) + w_cnt;
        end
		else if(c_state == REST_0 && row_cnt == 127 ) begin
			res_addr <= 14'd16255;
		end
		else if(n_state == BACKWARD || c_state == BACKWARD)begin
				case(cnt)
				4'd0: res_addr <= res_addr + 14'd129;
				4'd1: res_addr <= res_addr - 14'd1;
				4'd2: res_addr <= res_addr - 14'd1;
				4'd3: res_addr <= res_addr - 14'd126;
				4'd4: res_addr <= res_addr - 14'd1;
				endcase
		end
		else if(c_state == READ_B || c_state == WRITE_B) begin
			res_addr <= res_addr - 14'd1;
		end
	end	

	//done
	always@(posedge clk or negedge reset) begin
		if(!reset) done <= 1'd0;
		else if(c_state == DONE) done <= 1'd1;
	end

	always @(posedge clk or negedge reset) begin
		if (!reset) begin
			res_do <= 0;
		end		
		else if (c_state == FORWARD) begin
            res_do <= (sti_buf[w_cnt]) ? (min_val + 1) : 0;
        end
		else if(n_state == WRITE_B) res_do <= minTemp;
	end	

	wire [7:0] res_di_addOne;
	assign res_di_addOne = res_di + 1'd1;

	//minTemp
	always@(posedge clk or negedge reset)
	begin
		if(!reset) minTemp <= 8'd0;

		else if(c_state == READ_B) minTemp <= res_di;
		else if(c_state == BACKWARD)
		begin
			if(minTemp > res_di_addOne) minTemp <= res_di_addOne;
		end
	end

	//forward_complete
	always@(posedge clk or negedge reset)
	begin
		if(!reset) forward_complete <= 1'd0;
		else if(c_state == REST_0 && row_cnt == 127 ) forward_complete <= 1'd1;
	end
endmodule

// always @(posedge clk or negedge reset) begin
// 	if (!reset) begin
		
// 	end
// end