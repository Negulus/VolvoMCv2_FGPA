`timescale 1ns / 1ps

module main(
	input mem_read,
	input mem_sync,
	input[11:0] mem_adr,
	inout[7:0] mem_data,
	
	input lcd_sync,
	input lcd_frame,
	input lcd_en,
	output lcd_rdy,
	input lcd_res1,
	input lcd_res2,
	input[7:0] lcd_data,
	
	output park_sync,
	input park_in,
	
	input[5:0] in_but,
	
	input[5:0] in_din,
	
	output[5:0] out_dout,
	
	output led1,
	output led2,
	output led3,
	output led4,
	output led5,
	output led6
);

//Заглушка для вероятного парктроника
assign park_sync = park_in;

//-------------------------------------------
//Память
//-------------------------------------------
reg[7:0] data_lcd[2047:0];
reg[7:0] data_park[8:0];
reg[7:0] data_in[1:0];
reg[7:0] data_out[1:0];
reg[7:0] data = 0;
reg[7:0] data_1 = 0;
reg[7:0] data_2 = 0;
reg[7:0] data_3 = 0;

reg[11:0] i;
initial
begin
for (i = 0; i < 2048; i = i + 1)
	data_lcd[i] = i / 8;
	
for (i = 0; i < 8; i = i + 1)
	data_park[i] = 0;
data_park[8] = 0;

data_in[0] = 0;
data_in[1] = 0;

data_out[0] = 0;
data_out[1] = 0;
end

always @(posedge mem_sync)
begin
	if (mem_adr < 2048)
		assign data = data_1;
	else if (mem_adr < 2057)
		assign data = data_2;
	else if (mem_adr < 2059)
		assign data = data_3;
		
	if (mem_read)
	begin
		if (mem_adr < 2048)
			data_1 = data_lcd[mem_adr];
		else if (mem_adr < 2057)
			data_2 = data_park[mem_adr - 2048];
		else if (mem_adr < 2059)
			data_3 = data_in[mem_adr - 2057];
	end
	else
	begin
		if (mem_adr > 2058 && mem_adr < 2061)
			data_out[mem_adr - 2059] = mem_data;
	end
end

assign mem_data = mem_read ? data : 8'bz;

//-------------------------------------------
//Дисплей
//-------------------------------------------

reg[11:0] lcd_cnt = 0;
(* keep="true" *) reg lcd_cmd = 0;
(* keep="true" *) reg lcd_rdy_r = 0;

assign lcd_rdy = lcd_rdy_r;

always @(posedge lcd_sync)
begin
	if (!lcd_frame)
	begin
		lcd_cnt = 0;
		if (lcd_en && lcd_data == 132)
		begin
			lcd_cmd = 1;
			lcd_rdy_r = 0;
		end
	end
	else
	begin
		if (lcd_cnt < 2048)
		begin
			if (lcd_cmd)
			begin
				data_lcd[lcd_cnt] = lcd_data;
			end
					
			lcd_cnt = lcd_cnt + 1;
			if (lcd_cnt > 2047)
			begin
				lcd_cmd = 0;
				lcd_rdy_r = 1;
			end
		end
	end
end

//-------------------------------------------
//Дискретные входы
//-------------------------------------------
always @(in_din)
begin
	data_in[0] = ~in_din & 63;
end

//-------------------------------------------
//Кнопки
//-------------------------------------------
always @(in_but)
begin
	data_in[1] = ~in_but & 63;
end

//-------------------------------------------
//Дискретные выходы
//-------------------------------------------
assign led1 = data_out[0][0];
assign led2 = data_out[0][1];
assign led3 = data_out[0][2];
assign led4 = data_out[0][3];
assign led5 = data_out[0][4];
assign led6 = data_out[0][5];

assign out_dout[0] = (data_out[0] & 1) ? 1 : 0;
assign out_dout[1] = (data_out[0] & 2) ? 1 : 0;
assign out_dout[2] = (data_out[0] & 4) ? 1 : 0;
assign out_dout[3] = (data_out[1] & 8) ? ((data_out[0] & 8) ? 1 : 0) : !in_din[5];
assign out_dout[4] = (data_out[0] & 16) ? 1 : 0;
assign out_dout[5] = (data_out[0] & 32) ? 1 : 0;

endmodule