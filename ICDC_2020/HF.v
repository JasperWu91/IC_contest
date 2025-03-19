module HF(
    // Input signals
    input [24:0] symbol_freq,
    // Output signals
    output reg [19:0] out_encoded
);

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment

//================================================================
//    DESIGN
//================================================================
//reg [4:0] a_freg, b_freg, c_freg, d_freg, e_freg;
reg [4:0] freq [0:4];
wire [24:0] in_freq;
wire [4:0] sorted_out[0:4];
wire [2:0] idx[0:4];
wire [2:0] idx0, idx1, idx2, idx3, idx4;

assign in_freq = symbol_freq;

always @(*) begin
    freq[0] = in_freq[24:20];
    freq[1] = in_freq[19:15];
    freq[2] = in_freq[14:10];
    freq[3] = in_freq[9:5  ];
    freq[4] = in_freq[4:0  ];    
end

SN_5 sorting_network (
    .in0(freq[0]), .in1(freq[1]), .in2(freq[2]), .in3(freq[3]), .in4(freq[4]),
    .out0(sorted_out[0]), .out1(sorted_out[1]), .out2(sorted_out[2]), .out3(sorted_out[3]), .out4(sorted_out[4]),
    .idx0(idx[0]), .idx1(idx[1]), .idx2(idx[2]), .idx3(idx[3]), .idx4(idx[4])
);

reg [3:0] encoded_node [0:4];
reg [4:0] node [0:3];
reg [6:0] merge_node [0:3];
reg [6:0] node_1 [0:3];
reg [6:0] node_2 [0:3];
reg [6:0] node_3 [0:3];
reg left_or_right [0:2];
reg sw_0,sw_1;


reg state_0,state_1,state_2;

always @(*) begin
    merge_node [0] = sorted_out[1] + sorted_out[0];
    merge_node [1] = node_1[0] + node_1[1];
    merge_node [2] = node_2[0] + node_2[1];
end

// First stage
always @(*) begin
    if ((merge_node [0] > sorted_out[2]) && (merge_node [0] > sorted_out[3]) && (merge_node [0] > sorted_out[4])) begin
        node_1[0] = sorted_out[2];
        node_1[1] = sorted_out[3];
        node_1[2] = sorted_out[4];
        node_1[3] = merge_node [0];
        sw_0      = 1;
    end
    else if ((merge_node [0] > sorted_out[2]) && (merge_node [0] > sorted_out[3])) begin
        node_1[0] = sorted_out[2];
        node_1[1] = sorted_out[3];
        node_1[2] = merge_node [0];
        node_1[3] = sorted_out [4];
        sw_0      = 1;
    end
    else begin
        node_1[0] = merge_node [0];   
        node_1[1] = sorted_out[2];
        node_1[2] = sorted_out[3];
        node_1[3] = sorted_out[4];     
        sw_0      = 0;
    end
end

reg sw_00;

always @(*) begin
    if (merge_node[1] > merge_node[0] && (merge_node[1] >  sorted_out [4])) begin
        sw_00 = 1;
    end else sw_00 = 0;
end

always @(*) begin
    if (sw_0 && sw_00) begin
        state_0 = (merge_node [0] >  sorted_out [4]) ;
    end
    else if (sw_0) begin
        state_0 = (merge_node [0] > merge_node[1]) ? 1'b1 : 1'b0;
    end
    else begin
        state_0 = (merge_node [0] > node_1[1]) ? 1'b1 : 1'b0;
    end
end


// Second stage
always @(*) begin
    if ((merge_node [1] > node_1[2]) && (merge_node [1] > node_1[3])) begin
        node_2[0] = node_1[2];
        node_2[1] = node_1[3];
        node_2[2] = merge_node [1];
        sw_1      = 1;
    end
    else  begin
        node_2[0] = merge_node [1];
        node_2[1] = node_1[2];
        node_2[2] = node_1[3];
        sw_1      = 0;

    end
end

always @(*) begin
    if (sw_1 && sw_00 && sw_0 ) begin
        state_1 = (merge_node [1] < merge_node[2]) ? 1'b1 : 1'b0;
    end
    else if (sw_1) begin
        state_1 = (merge_node [1] > merge_node[2]) ? 1'b1 : 1'b0;
    end
    else if (sw_0) begin
        state_1 = (merge_node [2] >node_2[2]) ? 1'b1 : 1'b0;
    end
    else begin
        state_1 = (merge_node [1] > node_2[1]) ? 1'b1 : 1'b0;
    end
end

// Third stage
always @(*) begin
    if ((merge_node [2] > node_2[2]) ) begin
        node_3[0] = node_2[2];
        node_3[1] = merge_node [2];
    end

    else  begin
        node_3[0] = merge_node [2];
        node_3[1] = node_2[2];
    end
end

always @(*) begin
    state_2 = (merge_node [2] >node_2[2] )? 1'b1 : 1'b0;
end

always @(*) begin
    encoded_node[0] = 0; //idx[0] = 0
    encoded_node[1] = 0; 
    encoded_node[2] = 0; 
    encoded_node[3] = 0; 
    encoded_node[4] = 0;      
    if (sw_0 && sw_1 && sw_00) begin
        encoded_node[idx[0]] = {1'b0, state_1, state_0, 1'b0}; //idx[0] = 0
        encoded_node[idx[1]] = {1'b0, state_1, state_0, 1'b1}; //idx[1] = 2
        encoded_node[idx[2]] = {1'b0, 1'b0, !state_1, 1'b0}; //idx[2] = 4
        encoded_node[idx[3]] = {1'b0, 1'b0, !state_1, 1'b1}; // idx[3] = 3
        encoded_node[idx[4]] = {1'b0, 1'b0, state_1,!state_0}; //idx[4] = 1        
    end   
    else if (sw_0) begin
        encoded_node[idx[0]] = {1'b0, state_1, state_0, 1'b0}; //idx[0] = 0
        encoded_node[idx[1]] = {1'b0, state_1, state_0, 1'b1}; //idx[1] = 2
        encoded_node[idx[2]] = {1'b0,  state_1,!state_0, 1'b0}; //idx[2] = 4
        encoded_node[idx[3]] = {1'b0,  state_1, !state_0,1'b1}; // idx[3] = 3
        encoded_node[idx[4]] = {1'b0, 1'b0, 1'b0, !state_1}; //idx[4] = 1        
    end
    else if (sw_1) begin
        encoded_node[idx[0]] = {1'b0, state_1, state_0, 1'b0}; //idx[0] = 0
        encoded_node[idx[1]] = {1'b0, state_1, state_0, 1'b1}; //idx[1] = 2
        encoded_node[idx[2]] = {1'b0, 1'b0, state_1, !state_0}; //idx[2] = 4
        encoded_node[idx[3]] = {1'b0, 1'b0, !state_1, 1'b0}; // idx[3] = 3
        encoded_node[idx[4]] = {1'b0, 1'b0, !state_1,1'b1}; //idx[4] = 1        
    end
    else begin
        encoded_node[idx[0]] = {state_2, state_1, state_0, 1'b0}; //idx[0] = 0
        encoded_node[idx[1]] = {state_2, state_1, state_0, 1'b1}; //idx[1] = 2
        encoded_node[idx[2]] = {1'b0, state_2, state_1, !state_0}; //idx[2] = 4
        encoded_node[idx[3]] = {1'b0, 1'b0, state_2 , !state_1}; // idx[3] = 3
        encoded_node[idx[4]] = {1'b0, 1'b0, 1'b0,  !state_2}; //idx[4] = 1           
    end

end


always @(*) begin
    out_encoded ={encoded_node[0] ,encoded_node[1], encoded_node[2], encoded_node[3] , encoded_node[4] };

end


endmodule


module SN_5 (
    input [4:0] in0, in1, in2, in3, in4,          
    output reg [4:0] out0, out1, out2, out3, out4, 
    output reg [2:0] idx0, idx1, idx2, idx3, idx4  
);


    wire [4:0] stage1_0, stage1_1, stage1_2, stage1_3, stage1_4;
    wire [4:0] stage2_0, stage2_1, stage2_2, stage2_3, stage2_4;
    wire [4:0] stage3_0, stage3_1, stage3_2, stage3_3, stage3_4;
    wire [4:0] stage4_0, stage4_1, stage4_2, stage4_3, stage4_4;
    wire [4:0] stage5_2, stage5_3;

    wire [2:0] idx_stage1_0, idx_stage1_1, idx_stage1_2, idx_stage1_3, idx_stage1_4;
    wire [2:0] idx_stage2_0, idx_stage2_1, idx_stage2_2, idx_stage2_3, idx_stage2_4;
    wire [2:0] idx_stage3_0, idx_stage3_1, idx_stage3_2, idx_stage3_3, idx_stage3_4;
    wire [2:0] idx_stage4_0, idx_stage4_1, idx_stage4_2, idx_stage4_3, idx_stage4_4;
    wire [2:0] idx_stage5_2, idx_stage5_3;

    wire [2:0] init_idx0 = 3'd0;
    wire [2:0] init_idx1 = 3'd1; 
    wire [2:0] init_idx2 = 3'd2; 
    wire [2:0] init_idx3 = 3'd3;
    wire [2:0] init_idx4 = 3'd4; 

    cmp cmp1_0 (.in1(in0), .in2(in1), .idx0(init_idx0), .idx1(init_idx1), 
                .out_max(stage1_1), .out_min(stage1_0), .idx_max(idx_stage1_1), .idx_min(idx_stage1_0));
    cmp cmp1_1 (.in1(in2), .in2(in3), .idx0(init_idx2), .idx1(init_idx3), 
                .out_max(stage1_3), .out_min(stage1_2), .idx_max(idx_stage1_3), .idx_min(idx_stage1_2));

    assign stage1_4 = in4;
    assign idx_stage1_4 = init_idx4;

    // stage 2
    assign stage2_0 = stage1_0;
    assign idx_stage2_0 = idx_stage1_0;

    cmp cmp2_0 (.in1(stage1_1), .in2(stage1_3), .idx0(idx_stage1_1), .idx1(idx_stage1_3), 
                .out_max(stage2_3), .out_min(stage2_1), .idx_max(idx_stage2_3), .idx_min(idx_stage2_1));

    cmp cmp2_1 (.in1(stage1_2), .in2(stage1_4), .idx0(idx_stage1_2), .idx1(idx_stage1_4), 
                .out_max(stage2_4), .out_min(stage2_2), .idx_max(idx_stage2_4), .idx_min(idx_stage2_2));


    // stage 3
    cmp cmp3_0 (.in1(stage2_0), .in2(stage2_2), .idx0(idx_stage2_0), .idx1(idx_stage2_2), 
                .out_max(stage3_2), .out_min(stage3_0), .idx_max(idx_stage3_2), .idx_min(idx_stage3_0));

    cmp cmp3_1 (.in1(stage2_1), .in2(stage2_4), .idx0(idx_stage2_1), .idx1(idx_stage2_4), 
                .out_max(stage3_4), .out_min(stage3_1), .idx_max(idx_stage3_4), .idx_min(idx_stage3_1));
    assign stage3_3 = stage2_3;
    assign idx_stage3_3 = idx_stage2_3;


    // stage 4
    cmp cmp4_0 (.in1(stage3_1), .in2(stage3_2), .idx0(idx_stage3_1), .idx1(idx_stage3_2), 
                .out_max(stage4_2), .out_min(stage4_1), .idx_max(idx_stage4_2), .idx_min(idx_stage4_1));
    cmp cmp4_1 (.in1(stage3_4), .in2(stage3_3), .idx0(idx_stage3_4), .idx1(idx_stage3_3), 
                .out_max(stage4_4), .out_min(stage4_3), .idx_max(idx_stage4_4), .idx_min(idx_stage4_3));
    assign stage4_0 = stage3_0;
    assign idx_stage4_0 = idx_stage3_0;

     // stage 5
    cmp cmp5_0 (.in1(stage4_2), .in2(stage4_3), .idx0(idx_stage4_2), .idx1(idx_stage4_3), 
                .out_max(stage5_3), .out_min(stage5_2), .idx_max(idx_stage5_3), .idx_min(idx_stage5_2));
    always @(*) begin
        out0 = stage4_0; idx0 = idx_stage4_0; 
        out1 = stage4_1; idx1 = idx_stage4_1; 
        out2 = stage5_2; idx2 = idx_stage5_2; 
        out3 = stage5_3; idx3 = idx_stage5_3; 
        out4 = stage4_4; idx4 = idx_stage4_4; 
    end

endmodule


module cmp( in1, in2, idx0, idx1, idx_max, idx_min, out_max, out_min);

input  [4:0]  in1, in2;
input  [2:0]  idx0, idx1;
output  reg [4:0] out_max, out_min;
output  reg [2:0] idx_max, idx_min;

always @(*) begin
    if (in1 != in2) begin  
        out_max = (in1 > in2) ? in1 : in2;
        out_min = (in1 > in2) ? in2 : in1;
        idx_max = (in1 > in2) ? idx0 : idx1;
        idx_min = (in1 > in2) ? idx1 : idx0;
    end else begin  
        out_max = in1;  
        out_min = in1;  
        idx_max = (idx0 > idx1) ? idx0 : idx1;  
        idx_min = (idx0 > idx1) ? idx1 : idx0;  
    end
end

endmodule
