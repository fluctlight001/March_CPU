module mul (
  input wire [31:0] ina,
  input wire [31:0] inb,
  output wire [63:0] out
);
  wire [63:0] mul_temp [31:0];

  assign mul_temp[ 0] = ina[ 0] ? {32'd0,inb      } : 64'd0;
  assign mul_temp[ 1] = ina[ 1] ? {31'd0,inb, 1'd0} : 64'd0;
  assign mul_temp[ 2] = ina[ 2] ? {30'd0,inb, 2'd0} : 64'd0;
  assign mul_temp[ 3] = ina[ 3] ? {29'd0,inb, 3'd0} : 64'd0;
  assign mul_temp[ 4] = ina[ 4] ? {28'd0,inb, 4'd0} : 64'd0;
  assign mul_temp[ 5] = ina[ 5] ? {27'd0,inb, 5'd0} : 64'd0;
  assign mul_temp[ 6] = ina[ 6] ? {26'd0,inb, 6'd0} : 64'd0;
  assign mul_temp[ 7] = ina[ 7] ? {25'd0,inb, 7'd0} : 64'd0;
  assign mul_temp[ 8] = ina[ 8] ? {24'd0,inb, 8'd0} : 64'd0;
  assign mul_temp[ 9] = ina[ 9] ? {23'd0,inb, 9'd0} : 64'd0;
  assign mul_temp[10] = ina[10] ? {22'd0,inb,10'd0} : 64'd0;
  assign mul_temp[11] = ina[11] ? {21'd0,inb,11'd0} : 64'd0;
  assign mul_temp[12] = ina[12] ? {20'd0,inb,12'd0} : 64'd0;
  assign mul_temp[13] = ina[13] ? {19'd0,inb,13'd0} : 64'd0;
  assign mul_temp[14] = ina[14] ? {18'd0,inb,14'd0} : 64'd0;
  assign mul_temp[15] = ina[15] ? {17'd0,inb,15'd0} : 64'd0;
  assign mul_temp[16] = ina[16] ? {16'd0,inb,16'd0} : 64'd0;
  assign mul_temp[17] = ina[17] ? {15'd0,inb,17'd0} : 64'd0;
  assign mul_temp[18] = ina[18] ? {14'd0,inb,18'd0} : 64'd0;
  assign mul_temp[19] = ina[19] ? {13'd0,inb,19'd0} : 64'd0;
  assign mul_temp[20] = ina[20] ? {12'd0,inb,20'd0} : 64'd0;
  assign mul_temp[21] = ina[21] ? {11'd0,inb,21'd0} : 64'd0;
  assign mul_temp[22] = ina[22] ? {10'd0,inb,22'd0} : 64'd0;
  assign mul_temp[23] = ina[23] ? { 9'd0,inb,23'd0} : 64'd0;
  assign mul_temp[24] = ina[24] ? { 8'd0,inb,24'd0} : 64'd0;
  assign mul_temp[25] = ina[25] ? { 7'd0,inb,25'd0} : 64'd0;
  assign mul_temp[26] = ina[26] ? { 6'd0,inb,26'd0} : 64'd0;
  assign mul_temp[27] = ina[27] ? { 5'd0,inb,27'd0} : 64'd0;
  assign mul_temp[28] = ina[28] ? { 4'd0,inb,28'd0} : 64'd0;
  assign mul_temp[29] = ina[29] ? { 3'd0,inb,29'd0} : 64'd0;
  assign mul_temp[30] = ina[30] ? { 2'd0,inb,30'd0} : 64'd0;
  assign mul_temp[31] = ina[31] ? { 1'd0,inb,31'd0} : 64'd0;

  wire [63:0] temp1 [21:0];

  add unit0(.ina(mul_temp[2]), .inb(mul_temp[1]), .inc(mul_temp[0]), .s(temp1[1]), .c(temp1[0]));
  add unit1(.ina(mul_temp[5]), .inb(mul_temp[4]), .inc(mul_temp[3]), .s(temp1[3]), .c(temp1[2]));
  add unit2(.ina(mul_temp[8]), .inb(mul_temp[7]), .inc(mul_temp[6]), .s(temp1[5]), .c(temp1[4]));
  add unit3(.ina(mul_temp[11]), .inb(mul_temp[10]), .inc(mul_temp[9]), .s(temp1[7]), .c(temp1[6]));
  add unit4(.ina(mul_temp[14]), .inb(mul_temp[13]), .inc(mul_temp[12]), .s(temp1[9]), .c(temp1[8]));
  add unit5(.ina(mul_temp[17]), .inb(mul_temp[16]), .inc(mul_temp[15]), .s(temp1[11]), .c(temp1[10]));
  add unit6(.ina(mul_temp[20]), .inb(mul_temp[19]), .inc(mul_temp[18]), .s(temp1[13]), .c(temp1[12]));
  add unit7(.ina(mul_temp[23]), .inb(mul_temp[22]), .inc(mul_temp[21]), .s(temp1[15]), .c(temp1[14]));
  add unit8(.ina(mul_temp[26]), .inb(mul_temp[25]), .inc(mul_temp[24]), .s(temp1[17]), .c(temp1[16]));
  add unit9(.ina(mul_temp[29]), .inb(mul_temp[28]), .inc(mul_temp[27]), .s(temp1[19]), .c(temp1[18]));
  add unit10(.ina(64'd0), .inb(mul_temp[31]), .inc(mul_temp[30]), .s(temp1[21]), .c(temp1[20]));

  wire [63:0] temp2 [13:0]; // temp1 0-20 rest 21

  add unit11(.ina(temp1[2]), .inb(temp1[1]), .inc(temp1[0]), .s(temp2[1]), .c(temp2[0]));
  add unit12(.ina(temp1[5]), .inb(temp1[4]), .inc(temp1[3]), .s(temp2[3]), .c(temp2[2]));
  add unit13(.ina(temp1[8]), .inb(temp1[7]), .inc(temp1[6]), .s(temp2[5]), .c(temp2[4]));
  add unit14(.ina(temp1[11]), .inb(temp1[10]), .inc(temp1[9]), .s(temp2[7]), .c(temp2[6]));
  add unit15(.ina(temp1[14]), .inb(temp1[13]), .inc(temp1[12]), .s(temp2[9]), .c(temp2[8]));
  add unit16(.ina(temp1[17]), .inb(temp1[16]), .inc(temp1[15]), .s(temp2[11]), .c(temp2[10]));
  add unit17(.ina(temp1[20]), .inb(temp1[19]), .inc(temp1[18]), .s(temp2[13]), .c(temp2[12]));

  wire [63:0] temp3 [9:0];//temp2 14 + temp1[21]

  add unit18(.ina(temp2[2]), .inb(temp2[1]), .inc(temp2[0]), .s(temp3[1]), .c(temp3[0]));
  add unit19(.ina(temp2[5]), .inb(temp2[4]), .inc(temp2[3]), .s(temp3[3]), .c(temp3[2]));
  add unit20(.ina(temp2[8]), .inb(temp2[7]), .inc(temp2[6]), .s(temp3[5]), .c(temp3[4]));
  add unit21(.ina(temp2[11]), .inb(temp2[10]), .inc(temp2[9]), .s(temp3[7]), .c(temp3[6]));
  add unit22(.ina(temp1[21]), .inb(temp2[13]), .inc(temp2[12]), .s(temp3[9]), .c(temp3[8]));
    
  wire [63:0] temp4 [5:0]; //temp3 0-8 rest 9

  add unit23(.ina(temp3[2]), .inb(temp3[1]), .inc(temp3[0]), .s(temp4[1]), .c(temp4[0]));
  add unit24(.ina(temp3[5]), .inb(temp3[4]), .inc(temp3[3]), .s(temp4[3]), .c(temp4[2]));
  add unit25(.ina(temp3[8]), .inb(temp3[7]), .inc(temp3[6]), .s(temp4[5]), .c(temp4[4]));

  wire [63:0] temp5 [3:0]; // temp4 0-5 and temp3 rest temp 3

  add unit26(.ina(temp4[2]), .inb(temp4[1]), .inc(temp4[0]), .s(temp5[1]), .c(temp5[0]));
  add unit27(.ina(temp4[5]), .inb(temp4[4]), .inc(temp4[3]), .s(temp5[3]), .c(temp5[2]));

  wire [63:0] temp6 [2:0];

  add unit28(.ina(temp5[2]), .inb(temp5[1]), .inc(temp5[0]), .s(temp6[1]), .c(temp6[0]));
  assign temp6[2] = temp3[9] + temp5[3];

  wire [63:0] temp7 [1:0];

  add unit29(.ina(temp6[2]), .inb(temp6[1]), .inc(temp6[0]), .s(temp7[1]), .c(temp7[0]));

  assign out = temp7[0]+temp7[1];

endmodule
