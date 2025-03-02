`include "DW_sqrt.v"
module geofence ( clk,reset,X,Y,R,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
input [10:0] R;
output reg valid;
output reg is_inside;
//reg valid;
//reg is_inside;

reg [2:0] c_state, n_state;
reg [2:0] cnt, n_cnt;
reg [9:0] x_po [0:5];
reg [9:0] y_po [0:5];
reg [10:0] r_dis [0:5];
// reg [2:0] tri_idx [0:5];
reg [20:0] tri_dis [0:5];
reg sort_complete;
reg [9:0] x_po_fix;
reg [9:0] y_po_fix;
reg isneg;
reg [2:0] round, target;
reg signed [20:0] product_dis [0:4];
reg [9:0] d_x_in[0:1];
reg [9:0] d_y_in[0:1];

reg signed [11:0] temp_x, temp_y;

reg [20:0] squ_x,squ_y;


wire signed [3:0] x_po_idx0, x_po_idx,po_idx0, po_idx;
integer  i;
parameter IDLE         = 3'd0,
          LOAD_DATA     =3'd1,
          SORT_DATA     =3'd2,
          CALC_DISTANCE =3'd3,
          CALC_AREA     =3'd4,
          CALC_POLY     =3'd5,
          COMP     =3'd6;
//========================================================

// step 1: sorting the receiver

// step 2; calculate the length if side

// step 2: estimate if the object is in the fence

//========================================================


always @(posedge clk or posedge reset) begin
    if (reset) begin
        c_state <= IDLE;
    end else c_state <= n_state;
end
always @(*) begin
    sort_complete = (target == 5) ? 1: 0;
end

always @(*) begin
    n_state = c_state;
    case (c_state)

        IDLE: n_state = (!reset)? LOAD_DATA : IDLE;

        LOAD_DATA: begin
            if (cnt == 6) begin
                n_state = SORT_DATA;
            end 
        end

        SORT_DATA: begin
            if (sort_complete) begin
                n_state = CALC_DISTANCE;
            end
        end

        CALC_DISTANCE: begin
            if (cnt == 5) begin
                n_state = CALC_AREA;
            end
        end

        CALC_AREA: begin
            if (cnt == 5) begin
                n_state = CALC_POLY;
            end
        end
        CALC_POLY: begin
            if (cnt == 5) begin
                n_state = COMP;
            end
        end
        COMP: begin
            n_state = IDLE;
        end
        default: n_state = c_state;
    endcase
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        cnt <= 0;
    end else cnt <= n_cnt;
end

always @(*) begin
    if (n_state == SORT_DATA && c_state == LOAD_DATA || (n_state == IDLE)) begin
        n_cnt = 0;
    end
    else if ((n_state == CALC_DISTANCE && c_state == SORT_DATA) || (n_state == CALC_AREA && c_state == CALC_DISTANCE) || (n_state == CALC_POLY && c_state == CALC_AREA)) begin
        n_cnt = 0;
    end 
    else if (n_state == LOAD_DATA || c_state == SORT_DATA || c_state == CALC_DISTANCE || c_state == CALC_AREA || c_state == CALC_POLY) begin
        n_cnt = cnt + 1;
    end 

    else n_cnt = cnt;
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        for (i = 0 ; i <6 ; i=i+1 ) begin
            x_po[i] <= 0;
            y_po[i] <= 0;
            r_dis[i] <= 0;
        end
    end
    else if (n_state == LOAD_DATA) begin
        x_po[cnt] <= X;
        y_po[cnt] <= Y;
        r_dis[cnt] <= R;
    end
    else if (n_state == IDLE) begin
        for (i = 0 ; i <6 ; i=i+1 ) begin
            x_po[i] <= 0;
            y_po[i] <= 0;
            r_dis[i] <= 0;
        end
    end
    else begin
        for (i = 0 ; i <6 ; i=i+1 ) begin
            x_po[i]    <= x_po[i];
            y_po[i]    <=  y_po[i];
            r_dis[i]   <= r_dis[i];
        end        
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        for (i = 0 ; i <6 ; i=i+1 ) begin
            x_po_fix <= 0;
            y_po_fix <= 0;
        end
    end  
    else if (c_state == LOAD_DATA) begin
        x_po_fix <= x_po[0];
        y_po_fix <= y_po[0];
    end
end

reg signed [10:0] l_x_in[0:1], l_y_in[0:1];
reg signed [10:0] l_x_diff, l_y_diff;
reg signed [10:0] l_x_diff_arr[0:4];
reg signed [10:0] l_y_diff_arr[0:4];

always @(posedge clk or posedge reset) begin
    if (reset) begin
        l_x_in[0] <= 0;
        l_x_in[1] <= 0;
        l_y_in[0] <= 0;
        l_y_in[1] <= 0;
    end    
    else if (c_state ==IDLE && n_state == LOAD_DATA) begin
        l_x_in[0] <= X;
        l_y_in[0] <= Y;
    end  
    else if (c_state == LOAD_DATA) begin
        l_x_in[1] <= X;
        l_y_in[1] <= Y;
    end  
end

always @(*) begin
    l_x_diff = l_x_in[1] - l_x_in[0] ;
    l_y_diff = l_y_in[1] - l_y_in[0];
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        for (i = 0 ; i <5 ; i=i+1 ) begin
            l_x_diff_arr[i] <= 0;
            l_y_diff_arr[i] <= 0;
        end
    end    
    else if (c_state == LOAD_DATA && cnt > 0) begin
        l_x_diff_arr[cnt-2] <= l_x_diff;
        l_y_diff_arr[cnt-2] <= l_y_diff;
    end   
end
reg  sorted_bit_dis [0:5];
reg signed [20:0] sorted_x[0:6];
reg signed [20:0] sorted_y[0:6];
reg  [2:0] sorted_idx_dis [0:5];
//outer dot_product calculation
reg signed [10:0] x_in[0:1], y_in[0:1];
reg signed [20:0] temp[0:1];
reg signed [20:0] dot_product;

always @(*) begin
    if (reset) begin
        for (i = 0 ; i <2 ; i=i+1 ) begin
            x_in[i] <= 0;
            y_in[i] <= 0;
        end
    end    
    else if (n_state == SORT_DATA) begin
        x_in[1] <= l_x_diff_arr[target];
        y_in[1] <= l_y_diff_arr[target];
        x_in[0] <= sorted_x[4-round];
        y_in[0] <= sorted_y[4-round];

    end   
    else if (n_state == CALC_POLY) begin

        x_in[0] <= x_po[sorted_idx_dis[n_cnt]];
        x_in[1] <= x_po[sorted_idx_dis[x_po_idx]];

        y_in[0] <= y_po[sorted_idx_dis[n_cnt]];
        y_in[1]  <= y_po[sorted_idx_dis[x_po_idx]];

    end   
end


// Sorting the points

always @(*) begin
    temp[0] = x_in[0] * y_in[1];
    temp[1] = x_in[1] * y_in[0];
    dot_product = temp[0] - temp[1];
end
assign isneg = (dot_product[20] )? 1 : 0;


always @(posedge clk or posedge reset) begin
    if (reset) begin
        round <= 0;
        target <= 0;
    end    
    else if (c_state == SORT_DATA) begin
        if (isneg) begin
            round <= round + 1;
            target <= target;
        end
        else  begin
            round <= 0;
            if (round == 5 || !isneg) begin
                target <= target + 1;
            end
        end
 
    end   
    else if (c_state == IDLE) begin
        round <= 0;
        target <= 0;
    end   
end

always @(*) begin
    if (reset) begin
        for ( i = 0 ; i < 5; i=i+1) begin
            sorted_bit_dis [i] = 0;
        end
        sorted_bit_dis [5] = 0;
    end
    
    else if (c_state == SORT_DATA) begin
        sorted_bit_dis [4-round] = (isneg) ? 1:0;
        if (round == 0) begin
            sorted_bit_dis [3] = 0;
            sorted_bit_dis [2] = 0;
        end
    end
    else begin
        for ( i = 0 ; i < 5 ; i=i+1) begin
            sorted_bit_dis [i] = 0;
        end     
        sorted_bit_dis [5] = 1;
    end
end

always @(posedge clk) begin
    if (reset) begin
        for ( i = 0 ; i < 6 ; i=i+1) begin
            sorted_idx_dis [i] <= 0;
            sorted_x     [i] <= 0;
            sorted_y     [i] <= 0;
        end 
    end
    else if (c_state == SORT_DATA && !isneg) begin
        for (i = 5 ; i > 0 ; i = i - 1) begin
            sorted_x [i-1] <= ({sorted_bit_dis[i],sorted_bit_dis[i-1]} == 2'b10 ) ? l_x_diff_arr[target] : ({sorted_bit_dis[i],sorted_bit_dis[i-1]} == 2'b11) ? sorted_x [i-1] : sorted_x [i];
            sorted_y [i-1] <= ({sorted_bit_dis[i],sorted_bit_dis[i-1]} == 2'b10) ? l_y_diff_arr[target] : ({sorted_bit_dis[i],sorted_bit_dis[i-1]} == 2'b11) ? sorted_y [i-1] : sorted_y [i];
            sorted_idx_dis [i-1] <= ({sorted_bit_dis[i],sorted_bit_dis[i-1]} == 2'b10) ? target+1 : ({sorted_bit_dis[i],sorted_bit_dis[i-1]} == 2'b11) ? sorted_idx_dis [i-1] : sorted_idx_dis [i];
        end
    end
    else if (c_state == IDLE) begin
        for ( i = 0 ; i < 6 ; i=i+1) begin
            sorted_idx_dis [i] <= 0;
            sorted_x     [i] <= 0;
            sorted_y     [i] <= 0;
        end 
    end
    else begin
        for ( i = 0 ; i < 5 ; i=i+1) begin
            sorted_idx_dis [i] <= sorted_idx_dis [i];
            sorted_x     [i] <= sorted_x     [i];
            sorted_y     [i] <= sorted_y     [i];
        end     
    end
end

// Calculate the triangle


assign x_po_idx0 = (n_cnt + 1) ;
assign x_po_idx = ((n_cnt + 1) == 6) ? 0 : x_po_idx0;

assign po_idx0 = (cnt + 1) ;
assign po_idx = ((cnt + 1) == 6) ? 0 : po_idx0;

always @(posedge clk) begin
    if (reset) begin
        for (i = 0 ; i < 2; i=i+1 ) begin
            d_x_in[i] <= 0;
            d_y_in[i] <= 0;
        end
    end
    else if (n_state == CALC_DISTANCE) begin
        d_x_in[0] <= x_po[sorted_idx_dis[n_cnt]];
        d_x_in[1] <= x_po[sorted_idx_dis[x_po_idx]];

        d_y_in[0] <= y_po[sorted_idx_dis[n_cnt]];
        d_y_in[1] <= y_po[sorted_idx_dis[x_po_idx]];
    end
end


always @(*) begin
    temp_x = d_x_in[0] - d_x_in[1];
    temp_y = d_y_in[0] - d_y_in[1];
end

always @(*) begin
    squ_x = temp_x * temp_x;
    squ_y = temp_y * temp_y;
end

reg [20:0]  pre_sqrt_0;
reg  [20:0] pre_sqrt;

always @(*) begin
    pre_sqrt_0 = squ_x + squ_y;
    pre_sqrt =  pre_sqrt_0;

end

wire [11:0] sqrt_root;
DW_sqrt_inst dw(pre_sqrt, sqrt_root);

reg [11:0] s_len [0:5];
always @(posedge clk or posedge reset) begin
    if (reset) begin
        for (i =  0 ; i < 6 ; i= i+1 ) begin
            s_len [i] <= 0;
        end
    end
    else if (c_state == IDLE) begin
        for (i =  0 ; i < 6 ; i= i+1 ) begin
            s_len [i] <= 0;
        end
    end
    else if (c_state == CALC_DISTANCE) begin
        s_len [cnt] <= sqrt_root;
    end    
end
// assign  rad = 23'd100;

// reg [19:0] rad_in_c;
// Calculate the are of triangle
reg [15:0] tri_sl [0:2];

always @(posedge clk) begin
    if (n_state == CALC_AREA) begin
        tri_sl[0] <= r_dis[sorted_idx_dis[n_cnt]];
        tri_sl[1] <= r_dis[sorted_idx_dis[x_po_idx]];
        tri_sl[2] <= s_len[n_cnt];
    end
end

reg [20:0] tri_s ;

always @(*) begin
    tri_s = (tri_sl[0] + tri_sl[1] + tri_sl[2]) >> 1;
end

reg signed [23:0] sqrt_in[0:1];
reg  [23:0] sqrt_in_[0:1];
wire [11:0] sqrt_root_1, sqrt_root_2;
always @(*) begin
    sqrt_in[0] =( tri_s*(tri_s - tri_sl[0]) );
    sqrt_in[1] = (tri_s - tri_sl[1])*(tri_s - tri_sl[2]);
end
always @(*) begin
    sqrt_in_[0] =(sqrt_in[0] >= 0 )? sqrt_in[0] : sqrt_in[0] *(-1);
    sqrt_in_[1] = (sqrt_in[1] >= 0)? sqrt_in[1] : sqrt_in[1] *(-1);
end


DW_sqrt_inst dw1(sqrt_in_[0], sqrt_root_1);
DW_sqrt_inst dw2(sqrt_in_[1], sqrt_root_2);


reg [26:0] tri_area;

always @(*) begin
    tri_area = sqrt_root_1 * sqrt_root_2;
end

reg [26:0] total_tri_area;
reg signed [26:0] total_poly_area,total_poly_area1;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        total_tri_area <= 0;
    end
    else if (c_state == CALC_AREA) begin
        total_tri_area <= total_tri_area + tri_area;
    end
    else if (c_state == IDLE) begin
        total_tri_area <= 0;
    end
end
always @(posedge clk or posedge reset) begin
    if (reset) begin
        total_poly_area <= 0;
    end
    else if (n_state == CALC_POLY) begin
        total_poly_area <= total_poly_area + dot_product;
    end
    else if (c_state == IDLE) begin
        total_poly_area <= 0;
    end
end
always @(*) begin
    total_poly_area1 = (total_poly_area >= 0) ? total_poly_area >> 1 : total_poly_area >> 1;
end


always @(*) begin
    if (c_state == COMP) begin
        valid = 1;
    end else  valid = 0;
end

always @(*) begin
    if (c_state == COMP &&  (total_poly_area1 >= total_tri_area )) begin
        is_inside = 1;
    end else  is_inside = 0;
end

endmodule



// module DW_sqrt_inst_c (radicand, square_root);
// parameter radicand_width = 24;
// parameter tc_mode = 1;
// input [radicand_width-1 : 0] radicand;
// output [(radicand_width+1)/2-1 : 0] square_root;
// DW_sqrt #(radicand_width, tc_mode) 
// U1 (.a(radicand), .root(square_root));
// endmodule

module DW_sqrt_inst (radicand, square_root);
parameter radicand_width = 25;
parameter tc_mode = 0;
input [radicand_width-1 : 0] radicand;
output [(radicand_width+1)/2-1 : 0] square_root;
DW_sqrt #(radicand_width, tc_mode) 
U1 (.a(radicand), .root(square_root));
endmodule

module DW_sqrt_inst_s (radicand, square_root);
parameter radicand_width = 25;
parameter tc_mode = 1;
input [radicand_width-1 : 0] radicand;
output [(radicand_width+1)/2-1 : 0] square_root;
DW_sqrt #(radicand_width, tc_mode) 
U1 (.a(radicand), .root(square_root));
endmodule
