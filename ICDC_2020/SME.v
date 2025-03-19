module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output reg match;
output reg [4:0] match_index;
output reg valid;
// reg match;
// reg [4:0] match_index;
// reg valid;

parameter IDLE          = 4'd0,
          READ_STRING   = 4'd1,
          READ_PATTERN  = 4'd2,
          FIND_C        = 4'd3,
          MATCH         = 4'd4,
          MATCH_S       = 4'd5,
          FAIL          = 4'd6, 
          OUT           = 4'd7,
          FIND_C_2      = 4'd8,
          FIND_C_3      = 4'd9;

parameter SPACE  = 8'h20;
parameter SKIP   = 8'h2e;
parameter IGNORE = 8'h2A;
parameter BEGIN_WITH   = 8'h5e;
parameter END_WITH   = 8'h24;

reg [3:0] c_state, n_state;
reg [7:0] str_reg   [0:33]; // 1 start sign + 32 bit + 1 end sign
reg [7:0] pat_reg [0:7];
reg [7:0] pat_reg_1 [0:7];
reg [7:0] pat_reg_2 [0:7];
reg [5:0] cnt, n_cnt;
reg find_FC ;
reg [7:0] FC_reg;
reg [3:0] pat_len;
reg [3:0] pat_len_2;
reg [6:0] str_len;
reg PAT_char;
reg STR_char;
reg [5:0] pat_cnt,n_pat_cnt;
reg [5:0] pat_cnt_s;
reg match_flag;
reg [5:0] fc_idx;
reg find_FC_idx;
reg match_fail_sign;
reg begin_with_sign;
reg end_with_sign;
reg pass_sign;
reg find_FC_2;
reg [5:0] fc_idx_history;
reg astroid_sign;
integer  i;
reg [6:0] temp_idx;
reg [7:0] FC_reg_s;
reg [6:0] fc_idx_2;
reg find_c_s;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        c_state = IDLE;
    end else c_state = n_state;
end

always @(*) begin
    n_state = c_state;
    case (c_state)
        IDLE: n_state = (!reset) ? READ_STRING : IDLE;
        
        READ_STRING: begin
            if (!isstring) begin
                n_state = READ_PATTERN;
            end
        end

        READ_PATTERN: begin
            if (!ispattern) begin
                n_state = FIND_C;
            end
        end

        FIND_C: begin
            if (!find_FC) begin
                n_state = FAIL;
            end
            else if (find_FC_idx) begin
                n_state = MATCH;
            end
        end

        FIND_C_2: begin
            if (find_FC_idx) begin
                n_state = MATCH;
            end
            else if ((cnt + fc_idx_history) == 31) begin
                n_state = FAIL;
            end
        end

        MATCH: begin
            if ( ((FC_reg == SPACE) && (str_reg[fc_idx + cnt +1] == SPACE) && (str_reg[fc_idx + cnt +2] == SPACE) && (str_reg[fc_idx + cnt ] == SPACE))) begin
                n_state = FAIL;
            end
            else if (pat_len == pat_cnt) begin
                n_state = OUT;
            end
            else if(astroid_sign) begin
                n_state = FIND_C_3;
            end
            else if (match_fail_sign) begin
                n_state =  FIND_C_2;
            end
            else if (cnt == 31) begin
                n_state = FIND_C_2;
            end
        end

        FIND_C_3: begin
            if (find_c_s) begin
                n_state = MATCH_S;
            end
            else if ((cnt + temp_idx) == 31) begin
                n_state = FAIL;
            end
        end

        MATCH_S : begin
            if (pat_len == pat_cnt) begin
                n_state = OUT;
            end 
            else if (match_fail_sign) begin
                n_state =  FIND_C_3;
            end
            else if (cnt == 31) begin
                n_state = FIND_C_3;
            end
        end
        FAIL :begin
            if (ispattern) begin
                n_state = READ_PATTERN;
            end
            else if (isstring) begin
                n_state = READ_STRING;
            end
            else n_state = IDLE;
        end

        OUT : begin
            if (isstring) begin
                n_state = READ_STRING;
            end
            else if (ispattern) begin
                n_state = READ_PATTERN;
            end
            else n_state = IDLE;
        end

        default: n_state = c_state;
    endcase
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        cnt <= 6'd0;
    end
    else begin
        cnt <= n_cnt;
    end
end

always @(*) begin
    n_cnt = cnt;
    if (c_state != n_state ) begin
        n_cnt = 0;
    end
    else if (ispattern) begin
        n_cnt = cnt + 1;
    end
    else if (c_state == READ_STRING || c_state == READ_PATTERN || c_state == MATCH || c_state == FIND_C || c_state == FIND_C_2  || c_state == FIND_C_3 || c_state == MATCH_S) begin
        n_cnt = cnt + 1;
    end
    else begin
        n_cnt = cnt;
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        for ( i = 0 ; i < 34 ; i = i+1 ) begin
            str_reg[i] <= SPACE;
        end
    end
    else if (isstring) begin
        str_reg[n_cnt+1] <= chardata; // first bit for space
    end
    else if (c_state == READ_PATTERN) begin
        for ( i = 0 ; i < 34 ; i = i+1 ) begin
            if (i > (str_len+1)) begin
                str_reg[i] <= SPACE;
            end
        end
    end
end

reg astr_sign;
always @(posedge clk) begin
    if (ispattern) begin
        if (chardata == IGNORE ) begin
            astr_sign <= 1;
        end
    end
    else if (n_state == FAIL || n_state == OUT) begin
        astr_sign <= 0;
    end   
end


always @(posedge clk or posedge reset) begin
    if (reset) begin
        for ( i = 0 ; i < 32 ; i = i+1 ) begin
            pat_reg[i] <= SPACE;
        end
    end
    else if (n_state == FAIL || n_state == OUT) begin
        for ( i = 0 ; i < 32 ; i = i+1 ) begin
            pat_reg[i] <= SPACE;
        end
    end
    else if (ispattern) begin
        if (chardata == BEGIN_WITH || chardata == END_WITH ) begin
            pat_reg[n_cnt] <= SPACE;
        end
        else pat_reg[n_cnt] <= chardata;
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        begin_with_sign <= 0;
    end
    else if (n_state == FAIL || n_state == OUT) begin
        begin_with_sign <= 0;
    end
    else if (ispattern) begin
        if (chardata == BEGIN_WITH ) begin
            begin_with_sign <= 1;
        end
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        pat_len <= 4'd0;
    end
    else if (n_state == FAIL || n_state == OUT) begin
        pat_len <= 4'd0;
    end 
    else if (ispattern) begin
        pat_len <= pat_len + 1;
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        str_len <= 6'd0;
    end
    else if (c_state != READ_STRING && n_state == READ_STRING) begin
        str_len <= 6'd0;
    end 
    else if (isstring) begin
        str_len <= str_len + 1;
    end
end

//===============================================
// FIND FC STAGE
//===============================================
always @(*) begin
    find_FC = !((FC_reg ^ str_reg[0])  &&
              (FC_reg ^ str_reg[1])  && 
              (FC_reg ^ str_reg[2])  && 
              (FC_reg ^ str_reg[3])  && 
              (FC_reg ^ str_reg[4])  && 
              (FC_reg ^ str_reg[5])  && 
              (FC_reg ^ str_reg[6])  && 
              (FC_reg ^ str_reg[7])  && 
              (FC_reg ^ str_reg[8])  && 
              (FC_reg ^ str_reg[9])  && 
              (FC_reg ^ str_reg[10]) && 
              (FC_reg ^ str_reg[11]) && 
              (FC_reg ^ str_reg[12]) && 
              (FC_reg ^ str_reg[13]) && 
              (FC_reg ^ str_reg[14]) && 
              (FC_reg ^ str_reg[15]) && 
              (FC_reg ^ str_reg[16]) && 
              (FC_reg ^ str_reg[17]) && 
              (FC_reg ^ str_reg[18]) && 
              (FC_reg ^ str_reg[19]) && 
              (FC_reg ^ str_reg[20]) && 
              (FC_reg ^ str_reg[21]) && 
              (FC_reg ^ str_reg[22]) && 
              (FC_reg ^ str_reg[23]) && 
              (FC_reg ^ str_reg[24]) && 
              (FC_reg ^ str_reg[25]) && 
              (FC_reg ^ str_reg[26]) && 
              (FC_reg ^ str_reg[27]) && 
              (FC_reg ^ str_reg[28]) && 
              (FC_reg ^ str_reg[29]) && 
              (FC_reg ^ str_reg[30]) && 
              (FC_reg ^ str_reg[31]) &&
              (FC_reg ^ str_reg[32]) )|| FC_reg == SKIP;          
end


reg begin_with_dot_sign;
always @(posedge clk) begin
    if (pat_reg[0] == SKIP) begin
        begin_with_dot_sign = 1;
    end
    else  begin
        begin_with_dot_sign = 0;
    end

end

always @(posedge clk) begin
    if (n_state == FIND_C && (pat_reg[0] == SKIP) && pat_len != 1) begin
        FC_reg = pat_reg[1];
    end
    else if (n_state == FIND_C ) begin
        FC_reg = pat_reg[0];
    end
    else if (n_state == OUT || n_state == FAIL) begin
        FC_reg = SPACE;
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        fc_idx <=  6'd0;
    end
    else if (c_state == READ_PATTERN) begin
        fc_idx <=  6'd0;
    end
    else if (c_state == FIND_C && find_FC && n_state!= MATCH) begin
        if ( (FC_reg == SKIP)) begin
            fc_idx <=  1;
        end
        else if (str_reg[n_cnt ] == FC_reg &&  (fc_idx == 0)) begin
            fc_idx <= n_cnt ;
        end
    end
    else if (c_state == FIND_C_2) begin
        if ((str_reg[n_cnt +  fc_idx_history] == FC_reg) && ((n_cnt +  fc_idx_history) >fc_idx_history ) ) begin
            fc_idx <= (n_cnt +  fc_idx_history );
        end
    end
end
always @(posedge clk or posedge reset) begin
    if (reset) begin
        fc_idx_history <= 6'd0;
    end
    else if (n_state == MATCH) begin
        fc_idx_history <=  fc_idx;
    end
    else if (n_state == MATCH_S) begin
        fc_idx_history <=  fc_idx_2;
    end
end


always @(*) begin
    if (c_state == FIND_C && fc_idx != 0) begin
        find_FC_idx = 1;
    end 
    else if (c_state == FIND_C  && FC_reg == SPACE && pat_reg[1] == SKIP) begin
        find_FC_idx = 1;
    end
    else if (c_state == FIND_C_2 && (fc_idx_history != fc_idx)) begin
        find_FC_idx = 1;
    end
    else find_FC_idx = 0;
end

//===============================================
// MATCH STAGE
//===============================================



always @(*) begin
    if (c_state == MATCH && (str_reg[fc_idx + cnt] == pat_reg[pat_cnt + 1]) && begin_with_sign ) begin
        match_flag = 1;
    end
     else if (c_state == MATCH && (str_reg[fc_idx + cnt-1] == pat_reg[pat_cnt]) && begin_with_dot_sign) begin
        match_flag = 1;
    end 
    else if (c_state == MATCH && (str_reg[fc_idx + cnt] == pat_reg[pat_cnt])) begin
        match_flag = 1;
    end 
    
    else if (c_state == MATCH && ( pat_reg[pat_cnt] == SKIP)) begin
        match_flag = 1;
    end
    else if (c_state == MATCH_S && (str_reg[fc_idx_2 + cnt] == pat_reg[pat_cnt]) ) begin
        match_flag = 1;
    end
    else match_flag = 0;
end


reg match_fail_sign;
always @(*) begin
    if (c_state == MATCH && match_flag == 0) begin
        match_fail_sign = 1;
    end
    else if (c_state == MATCH_S && match_flag == 0) begin
        match_fail_sign = 1;
    end
    else match_fail_sign = 0;
end
//===============================================
// FIND C 3 STAGE
//===============================================


always @(posedge clk) begin
    if (astroid_sign) begin
        FC_reg_s = pat_reg[pat_cnt + 1];
    end
end


always @(posedge clk or posedge reset) begin
    if (reset) begin
        fc_idx_2 <=  6'd0;
    end
    else if (c_state == READ_PATTERN) begin
        fc_idx_2 <=  6'd0;
    end
    else if (c_state == FIND_C_3) begin
        if ((str_reg[cnt +  temp_idx] == FC_reg_s) && ((cnt +  temp_idx) > fc_idx_history ) ) begin
            fc_idx_2 <= (cnt +  temp_idx);
        end
    end    
end


always @(*) begin
    if (c_state == FIND_C_3 && fc_idx_2 != 0 && (fc_idx_history != fc_idx_2)) begin
        find_c_s = 1;
    end 
    else find_c_s = 0;
end



//===============================================
// MATCH SPECIAL STAGE
//===============================================
always @(posedge clk or posedge reset) begin
    if (reset) begin
        pat_cnt <= 6'd0;
    end
    else begin
        pat_cnt <= n_pat_cnt;
    end
end

always @(*) begin
    n_pat_cnt = pat_cnt;
    if(c_state == FIND_C_3 && n_state == MATCH_S) begin
        n_pat_cnt = pat_cnt_s;
    end
    // else if ((n_state == MATCH || n_state == MATCH_S) && begin_with_dot_sign) begin
    //     n_pat_cnt = 0;
    // end
    else if (c_state != n_state && (n_state != MATCH_S || n_state != FIND_C_3)) begin
        n_pat_cnt = 0;
    end
    else if (c_state == MATCH && astroid_sign) begin
        n_pat_cnt = pat_cnt + 1;
    end    
    else if (c_state == MATCH_S && match_flag) begin
        n_pat_cnt = pat_cnt + 1;
    end
    else if (c_state == MATCH && match_flag) begin
        n_pat_cnt = pat_cnt + 1;
    end
    else begin
        n_pat_cnt = pat_cnt;
    end
end

always @(posedge clk) begin
    if (astroid_sign) begin
        pat_cnt_s = pat_cnt + 1;
    end
end

always @(posedge clk) begin
    if (astroid_sign) begin
        temp_idx = fc_idx + cnt ;
    end
end
always @(*) begin
    if (c_state == MATCH &&  pat_reg[pat_cnt] == IGNORE) begin
        astroid_sign = 1;
    end else astroid_sign = 0;
end

always @(*) begin
    if (str_reg[fc_idx_2 + cnt] == SPACE && str_reg[fc_idx_2 + cnt + 1] == SPACE ) begin
        pass_sign = 1;
    end
    else pass_sign = 0;
end

//===============================================
always @(*) begin
    if (c_state ==FAIL) begin
        valid = 1;
        match = 0;
    end
    else if (c_state == OUT) begin
        valid = 1;
        match = 1;        
    end
    else begin
        valid = 0;
        match = 0;       
    end
end

always @(posedge clk) begin
    if (n_state == FAIL) begin
        match_index = 0;
    end
    else if (begin_with_dot_sign && (pat_len > 1)) begin
        match_index =(fc_idx-2);
    end
    else if (begin_with_sign) match_index =(fc_idx);
    else match_index =(fc_idx-1);
end
endmodule
