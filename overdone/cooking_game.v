`timescale 1ns/1ns


module cooking_game
	(
		CLOCK_50,						//	On Board 50 MHz
		KEY,							// On Board Keys
		SW,
		HEX0,
		HEX1,
		HEX2,
		HEX3,
		HEX4,
		HEX5,
		LEDR,
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input	CLOCK_50;
	input	[3:0]	KEY;
	input [1:0] SW;
	output [9:0] LEDR;
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	output [6:0]HEX0;
	output [6:0]HEX1;
	output [6:0]HEX2;
	output [6:0]HEX3;
	output [6:0]HEX4;
	output [6:0]HEX5;
	
	wire resetn;
	assign resetn = SW[0]; //REASSIGN KEY 0 AFTER TESTING!!!!!!!!!!!!!!!!!!!!!!!!!
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [11:0] colour;
	wire [8:0] x;
	wire [7:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 4;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.	
	VGA_output v1(LEDR, CLOCK_50, resetn, KEY[3:0], SW[1], writeEn, x, y, colour, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
	
endmodule

module VGA_output(LEDR, clock, resetn, keys, space, writeEn, x_out, y_out, colour, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
	
	output [9:0]LEDR;
	input clock;
	input resetn;
	input [3:0]keys;
	input space;
	output writeEn;
	output [8:0]x_out;
	output [7:0]y_out;
	output [11:0]colour;
	output [6:0]HEX0;
	output [6:0]HEX1;
	output [6:0]HEX2;
	output [6:0]HEX3;
	output [6:0]HEX4;
	output [6:0]HEX5;
	
	wire [3:0]game_state;
	wire [3:0]area;
	wire space;
	wire [8:0]x_coord;
	wire [7:0]y_coord;
	
	wire bg_done;
	wire player_done;
	wire delay_done;
	wire bun_done;
	wire patty_done;
	wire top_bun_done;
	
	wire ld_bg;
	wire ld_player;
	wire ld_delay;
	wire ld_bun;
	wire ld_patty;
	wire ld_top_bun;
	
	wire increment;
	wire [3:0]digit1;
	wire [3:0]digit2;
	wire [3:0]digit3;
	wire [3:0]digit4;
	
//	reg [9:0]burgs_left = 10'b1111111111;
//	
//	always@(posedge increment) begin
//		if(increment)
//			burgs_left <= (burgs_left >> 1);
//	end
//	
//	assign LEDR = burgs_left;
	
	keyboard_coords kc1(clock, keys, resetn, x_coord, y_coord);
	keyboard_decoder k1(space, x_coord, y_coord, resetn, area);
	assembly_control c1(clock, resetn, space, area, game_state, digit1, digit2, digit3, digit4, increment);	
	
	hex_decoder h0(4'b0, HEX0);
	hex_decoder h1(4'b0, HEX1);
	hex_decoder h2(digit1, HEX2);
	hex_decoder h3(digit2, HEX3);
	hex_decoder h4(digit3, HEX4);
	hex_decoder h5(digit4, HEX5);	
	
	//output to the display FSM is x_coord, y_coord, and control.
	
	displayFSM d1(game_state, clock, resetn, bg_done, player_done, delay_done, bun_done, patty_done, top_bun_done, ld_bg, ld_player, ld_delay, ld_bun, ld_patty, ld_top_bun);
	displayDatapath data1(clock, x_coord, y_coord, ld_bg, ld_player, ld_delay, ld_bun, ld_patty, ld_top_bun, x_out, y_out, colour, writeEn, bg_done, player_done, delay_done, bun_done, patty_done, top_bun_done);

endmodule

module displayFSM(game_state, clock, resetn, bg_done, player_done, delay_done, bun_done, patty_done, top_bun_done, ld_bg, ld_player, ld_delay, ld_bun, ld_patty, ld_top_bun);

	input resetn;
	input [3:0]game_state;
	input clock;
	input bg_done;
	input player_done;
	input delay_done;
	input bun_done;
	input patty_done;
	input top_bun_done;
	output reg ld_bg;
	output reg ld_player;
	output reg ld_delay;
	output reg ld_bun;
	output reg ld_patty;
	output reg ld_top_bun;
	
	reg [4:0] current_state, next_state; 
   localparam reset				= 4'd0,
					background 		= 4'd1,
					bg_reset 		= 4'd2,
					player 			= 4'd3,
					player_reset	= 4'd4,
					bun				= 4'd5,
					bun_reset		= 4'd6,
					patty				= 4'd7,
					patty_reset		= 4'd8,
					top_bun			= 4'd9,
					top_bun_reset	= 4'd10,
					delay				= 4'd11;

    // Mealy state table
    always@(*)
    begin: state_table 
        case (current_state)
			
			reset: begin
				next_state = background;
			end
			
			background: begin
				next_state = bg_done ? bg_reset : background;
			end
			
			bg_reset: begin
				next_state = player;
			end
			
			player: begin
				next_state = player_done ? player_reset : player;
			end
			
			player_reset:begin
				if(game_state == 4'b0001)
					next_state = bun;
				else if( game_state == 4'b0010)
					next_state = patty;
				else if( game_state == 4'b0011)
					next_state = top_bun;
				else
					next_state = delay;
			end
			
			bun: begin
				next_state = bun_done ? bun_reset : bun;
			end
			
			bun_reset: begin
				next_state = delay;
			end
			
			patty: begin
				next_state = patty_done ? patty_reset : patty;
			end
			
			patty_reset: begin
				next_state = delay;
			end
			
			top_bun: begin
				next_state = top_bun_done ? top_bun_reset : top_bun;
			end
			
			top_bun_reset: begin
				next_state = delay;
			end
			
			delay: begin
				next_state = delay_done ? background : delay;
			end
					
			default:	next_state = background;
        endcase
    end // state_table
   

    //datapath control signals
    always @(*)
    begin: enable_signals
	 ld_bg <= 1'b0;
	 ld_player <= 1'b0;
	 ld_delay <= 1'b0;
	 ld_bun <= 1'b0;
	 ld_patty <= 1'b0;
	 ld_top_bun <= 1'b0;
        case (current_state)
				background: begin
					ld_bg <= 1'b1;
				end
				player: begin
					ld_player <= 1'b1;
				end	
				bun: begin
					ld_bun <= 1'b1;
				end
				patty: begin
					ld_patty <= 1'b1;
				end
				top_bun: begin
					ld_top_bun <= 1'b1;
				end
				delay: begin
					ld_delay <= 1'b1;
				end
				reset: begin
					ld_bg <= 1'b0;
					ld_player <= 1'b0;
					ld_delay <= 1'b0;
					ld_bun <= 1'b0;
					ld_patty <= 1'b0;
					ld_top_bun <= 1'b0;
				end
        endcase
    end
	
    // current_state registers
    always@(posedge clock)
    begin: state_FFs
        if(~resetn)
            current_state <= reset;
        else
            current_state <= next_state;
    end
	
endmodule

module displayDatapath(clock, player_x, player_y, ld_bg, ld_player, ld_delay, ld_bun, ld_patty, ld_top_bun, x, y, colour, write, bg_done, player_done, delay_done, bun_done, patty_done, top_bun_done);
	
	input clock;
	input [8:0]player_x;
	input [7:0]player_y;
	input ld_bg;
	input ld_player;
	input ld_delay;
	input ld_bun;
	input ld_patty;
	input ld_top_bun;
	output [8:0]x;
	output [7:0]y;
	output [11:0]colour;
	output write;
	output reg bg_done=1'b0;
	output reg player_done=1'b0;
	output reg delay_done=1'b0;
	output reg bun_done=1'b0;
	output reg patty_done=1'b0;
	output reg top_bun_done=1'b0;
	
	
	// MUX selection for ROMS
	
	localparam 	bg = 4'd1,
					player = 4'd2,
					bun = 4'd3,
					patty = 4'd4,
					top_bun = 4'd5;

	reg write_reg;
	reg ld;
	reg [3:0]sprite_reg;
	reg [8:0]width_reg;
	reg [7:0]height_reg;
	reg [8:0]start_x_reg;
	reg [7:0]start_y_reg;
	
	always@(*) begin
		sprite_reg <= 4'b0;
		write_reg <= 1'b0;
		width_reg <= 9'b0;
		height_reg <= 8'b0;
		start_x_reg <= 9'b0;
		start_y_reg <= 8'b0;
		ld <= 1'b0;
		
		if(ld_bg) begin
			write_reg <= 1'b1;
			sprite_reg <= bg;
			width_reg <= 9'd319;
			height_reg <= 8'd239;
			ld <= 1'b1;
		end
		else if(ld_player) begin
			if(colour == 12'b000011110001) begin
				write_reg <= 1'b0;
			end
			else begin
				write_reg <= 1'b1;
			end
			sprite_reg <= player;
			width_reg <= 5'd21;
			height_reg <= 6'd43;
			start_x_reg <= player_x;
			start_y_reg <= player_y;
			ld <= 1'b1;
		end
		else if(ld_bun) begin
			if(colour == 12'b000000001111) begin
				write_reg <= 1'b0;
			end
			else begin
				write_reg <= 1'b1;
			end
			sprite_reg <= bun;
			width_reg <= 6'd11;
			height_reg <= 6'd7;
			start_x_reg <= 8'd221;
			start_y_reg <= 7'd70;
			ld <= 1'b1;
		end
		else if(ld_patty) begin
			if(colour == 12'b000000001111) begin
				write_reg <= 1'b0;
			end
			else begin
				write_reg <= 1'b1;
			end
			sprite_reg <= patty;
			width_reg <= 5'd15;
			height_reg <= 6'd12;
			start_x_reg <= 8'd219;
			start_y_reg <= 7'd65;
			ld <= 1'b1;
		end
		else if(ld_top_bun) begin
			if(colour == 12'b000000001111) begin
				write_reg <= 1'b0;
			end
			else begin
				write_reg <= 1'b1;
			end
			sprite_reg <= top_bun;
			width_reg <= 5'd15;
			height_reg <= 6'd16;
			start_x_reg <= 8'd219;
			start_y_reg <= 7'd60;
			ld <= 1'b1;
		end		
		else if(ld_delay) begin
			write_reg <= 1'b0;
		end
	end
	
	//delay
	
	reg [22:0]counter=23'b0;
	
	always@(posedge clock) begin
		if(~ld_delay) begin
			counter <= 23'b0;
			delay_done <= 1'b0;
		end
		else if(counter == 23'd800000) begin
			counter <= 23'b0;
			delay_done <= 1'b1;
		end
		else begin
			counter <= counter + 1'b1;
			delay_done <= 1'b0;
		end
	end
	
	wire [3:0]sprite;
	wire [8:0]width;
	wire [7:0]height;
	wire [8:0]start_x;
	wire [7:0]start_y;
	wire done;
	
	assign write = write_reg;
	assign sprite = sprite_reg;
	assign width = width_reg;
	assign height = height_reg;
	assign start_x = start_x_reg;
	assign start_y = start_y_reg;
	
	readROM r1(sprite, width, height, start_x, start_y, clock, ld, x, y, colour, done);
	
	always@(*) begin
		player_done <= 1'b0;
		bg_done <= 1'b0;
		bun_done <= 1'b0;
		patty_done <= 1'b0;
		top_bun_done <= 1'b0;
		
		if(done)
			//assign default values
			if(ld_bg) begin
				bg_done <= 1'b1;
			end
			else if (ld_player) begin
				player_done <= 1'b1;
			end
			else if (ld_bun) begin
				bun_done <= 1'b1;
			end
			else if (ld_patty) begin
				patty_done <= 1'b1;
			end
			else if (ld_top_bun) begin
				top_bun_done <= 1'b1;
			end
	end
	
endmodule

module readROM(sprite, width, height, start_x, start_y, clock, ld, x, y, colour, done);
	
	input [3:0]sprite;
	input [8:0]width; //USE WIDTH AND HEIGHT VALUES STARTING FROM 0!!
	input [7:0]height; //ie a 240px img uses a width of 239
	input [8:0]start_x;
	input [7:0]start_y;
	input clock; //onboard clock
	input ld;
	output [8:0]x;
	output [7:0]y;
	output reg [11:0]colour;
	output reg done = 1'b0;
	
	reg [8:0]x_reg=9'b0;
	reg [7:0]y_reg=8'b0;
	
	always@(posedge clock) begin
		if(~ld) begin
			x_reg <= 9'b0;
			y_reg <= 8'b0;
			done <= 1'b0;
		end
		else begin
			if(x_reg < width && y_reg <= height) begin
				x_reg <= x_reg + 9'd1;
			end
			else if (x_reg == width && y_reg < height) begin
				x_reg <= 9'b0;
				y_reg <= y_reg + 8'd1;
			end
			else if (x_reg == width && y_reg == height) begin
				x_reg <= x_reg;
				y_reg <= y_reg;
				done <= 1'b1;
			end	
			else begin
				x_reg <= x_reg;
				y_reg <= y_reg;
			end
		end
	end
	
	wire [16:0]add_bg;
	wire [11:0]q_bg;
	wire [9:0]add_player;
	wire [11:0]q_player;
	wire [6:0]add_bun;
	wire [11:0]q_bun;
	wire [7:0]add_patty;
	wire [11:0]q_patty;
	wire [8:0]add_top_bun;
	wire [11:0]q_top_bun;
	
	reg [16:0]add_bg_reg;
	reg [9:0]add_player_reg;
	reg [6:0]add_bun_reg;
	reg [7:0]add_patty_reg;
	reg [8:0]add_top_bun_reg;
	
	assign add_bg = add_bg_reg;
	assign add_player = add_player_reg;
	assign add_bun = add_bun_reg;
	assign add_patty = add_patty_reg;
	assign add_top_bun = add_top_bun_reg;
	
	always@(*) begin
		add_bg_reg <= 16'b0;
		add_player_reg <= 9'b0;
		add_bun_reg <= 7'b0;
		add_patty_reg <= 8'b0;
		add_top_bun_reg <= 9'b0;
		colour <= 12'b0;
		case(sprite)
			4'd1: begin
				colour <= q_bg;
				add_bg_reg <= y_reg*(width+1)+x_reg;
			end
			4'd2: begin
				colour <= q_player;
				add_player_reg <= y_reg*(width+1)+x_reg;
			end
			4'd3: begin
				colour <= q_bun;
				add_bun_reg <= y_reg*(width+1)+x_reg;
			end
			4'd4: begin
				colour <= q_patty;
				add_patty_reg <= y_reg*(width+1)+x_reg;
			end
			4'd5: begin
				colour <= q_top_bun;
				add_top_bun_reg <=  y_reg*(width+1)+x_reg;
			end
			default: begin
				colour <= 12'b0;
				add_player_reg <= 10'b0;
				add_bg_reg <= 17'b0;
				add_bun_reg <= 7'b0;
				add_patty_reg <= 8'b0;
				add_top_bun_reg <= 9'b0;
			end
		endcase
	end
	
	bg ROM1(add_bg, clock, q_bg);
	player ROM2(add_player, clock, q_player);
	bun ROM3(add_bun, clock, q_bun);
	patty ROM4(add_patty, clock, q_patty);
	top_bun ROM5(add_top_bun, clock, q_top_bun);
	
	assign x = x_reg+start_x;
	assign y = y_reg+start_y;
	
endmodule

module hex_decoder(in,out);
	
	input [3:0]in;
	output [6:0]out;
	
	//how I got assignments and the corresponding truth table is in an excel file
	
	assign out[0] = (~in[3]&~in[2]&~in[1]&in[0])|(~in[3]&in[2]&~in[1]&~in[0])|(in[3]&~in[2]&in[1]&in[0])|(in[3]&in[2]&~in[1]&in[0]);
	assign out[1] = (~in[3]&in[2]&~in[1]&in[0])|(~in[3]&in[2]&in[1]&~in[0])|(in[3]&~in[2]&in[1]&in[0])|(in[3]&in[2]&~in[1]&~in[0])|(in[3]&in[2]&in[1]&~in[0])|(in[3]&in[2]&in[1]&in[0]);
	assign out[2] = (~in[3]&~in[2]&in[1]&~in[0])|(in[3]&in[2]&~in[1]&~in[0])|(in[3]&in[2]&in[1]&~in[0])|(in[3]&in[2]&in[1]&in[0]);
	assign out[3] = (~in[3]&~in[2]&~in[1]&in[0])|(~in[3]&in[2]&~in[1]&~in[0])|(~in[3]&in[2]&in[1]&in[0])|(in[3]&~in[2]&~in[1]&in[0])|(in[3]&~in[2]&in[1]&~in[0])|(in[3]&in[2]&in[1]&in[0]);
	assign out[4] = (~in[3]&~in[2]&~in[1]&in[0])|(~in[3]&~in[2]&in[1]&in[0])|(~in[3]&in[2]&~in[1]&~in[0])|(~in[3]&in[2]&~in[1]&in[0])|(~in[3]&in[2]&in[1]&in[0])|(in[3]&~in[2]&~in[1]&in[0]);
	assign out[5] = (~in[3]&~in[2]&~in[1]&in[0])|(~in[3]&~in[2]&in[1]&~in[0])|(~in[3]&~in[2]&in[1]&in[0])|(~in[3]&in[2]&in[1]&in[0])|(in[3]&in[2]&~in[1]&in[0]);
	assign out[6] = (~in[3]&~in[2]&~in[1]&~in[0])|(~in[3]&~in[2]&~in[1]&in[0])|(~in[3]&in[2]&in[1]&in[0])|(in[3]&in[2]&~in[1]&~in[0]);
	
endmodule

// Keyboard decoder takes in coordinates from the keyboard
// and outputs area when the space bar is hit.

module keyboard_coords(clock, keys, resetn, x_out, y_out);
	input clock;
	input [3:0]keys;
	input resetn;
	output [8:0]x_out;
	output [7:0]y_out;
	
	reg enable;
	reg [8:0]x;
	reg [7:0]y;
	reg [23:0]counter;
	
	wire en;
	
	assign en = enable;
	
	always@(posedge clock, negedge resetn) begin
		if(~resetn) begin
			counter <= 24'b0;
			enable <= 1'b0;
		end
		else if(counter == 24'd499999) begin
			counter <= 24'b0;
			enable <= 1'b1;
		end
		else begin
			counter <= counter + 1'b1;
			enable <= 1'b0;
		end
	end
	
	always@(posedge clock, negedge resetn) begin
		if(~resetn) begin
			x <= 9'd159;
			y <= 8'd119;
		end
		else if(en) begin
			case(keys)
				4'b1110: begin 	//KEY 0 = right
					if(x < 261) begin
						x <= x + 1'b1;
					end
				end
				4'b1101: begin 	//KEY 1 = down
					if(y < 154) begin
						y <= y + 1'b1;
					end
				end
				4'b1011: begin 	//KEY 2 = up
					if(y > 80) begin
						y <= y - 1'b1;
					end
				end
				4'b0111: begin 	//KEY 3 = left
					if(x > 0) begin
						x <= x - 1'b1;
					end
				end
				default: begin
					x<=x;
					y<=y;
				end
			endcase
		end
	end
	
	assign x_out = x;
	assign y_out = y;
	
endmodule

module keyboard_decoder(space, x, y, reset, area);
	
	input space;
	input reset; //active low
	input [8:0]x;
	input [7:0]y;
	output reg [3:0]area;
	
	
	localparam 	beef    = 4'b0001,
					fish    = 4'b0010,
					patty   = 4'b0011,
					fillet  = 4'b0100,
					flour   = 4'b0101,
					rice    = 4'b0110,
					buns    = 4'b0111,
					c_rice  = 4'b1000, //cooked rice
					station = 4'b1001,
					def     = 4'b0000;
	
	
	always@(*) begin
		if (~reset) begin
			area = def;
		end
		if(space) begin
			if(y>152 && x<=156) begin
				if(x>0 && x<=23) begin
					area = c_rice;
				end
				else if(x>23 && x<=58) begin
					area = buns;
				end
				else if(x>58 && x<=93) begin
					area = patty;
				end
				else if(x>93 && x<=128) begin
					area = fillet;
				end
				else if(x>128 && x<=163) begin
					area = flour;
				end
				else if(x>163 && x<=198) begin
					area = rice;
				end
				else if(x>198 && x<=233) begin
					area = buns;
				end
				else if(x>233 && x<268) begin
					area = c_rice;
				end
				else begin
					area = def;
				end
			end
			else if(x>50 && x<100 && y>30 && y<=90) begin
				area = station;
			end
			else begin
				area = def;
			end
		end
		else begin
			area = def;
		end
	end
endmodule

// assembly_control takes care of the game's current state

module assembly_control(
    input clk,
    input resetn,
    input space,
    input [3:0]area,
    output reg [3:0]state,
	 output reg [3:0]digit_1=4'b0,
	 output reg [3:0]digit_2=4'd3,
	 output reg [3:0]digit_3=4'b0,
	 output reg [3:0]digit_4=4'b0,
	 output reg increment
    );
	 
	 reg decrement_timer;
	 
	 reg [25:0]timer_counter=26'b0;
	
	always@(posedge clk) begin
		if(timer_counter == 26'd49999999) begin
			decrement_timer <= 1'b1;
			timer_counter <= 26'b0;
		end
		else begin
			timer_counter <= timer_counter+26'b1;
			decrement_timer <= 1'b0;
		end
	end
	 
	 always@(posedge clk, negedge resetn) begin
		if(~resetn) begin
			digit_1 <= 4'd0;
			digit_2 <= 4'd3;
			digit_3 <= 4'd0;
			digit_4 <= 4'd0;
		end
		else if(decrement_timer)begin
			if(digit_1 != 4'd0) begin
				digit_1 <= digit_1-1'b1;
			end
			else if(digit_2 != 4'd0) begin
				digit_1 <= 4'd9;
				digit_2 <= digit_2-1'b1;
			end
			else if(digit_3 != 4'd0) begin
				digit_1 <= 4'd9;
				digit_2 <= 4'd9;
				digit_3 <= digit_3-1'b1;
			end
			else if(digit_4 != 4'd0) begin
				digit_1 <= 4'd9;
				digit_2 <= 4'd9;
				digit_3 <= 4'd9;
				digit_4 <= digit_4-1'b1;
			end
			else begin
				digit_1 <= 4'd0;
				digit_2 <= 4'd0;
				digit_3 <= 4'd0;
				digit_4 <= 4'd0;
			end
		end
	 end
	 
    reg [5:0] current_state, next_state; 
    
    localparam  blank 			= 5'd0,
					 b_blank_wait  = 5'd1,
					 c_blank_wait  = 5'd2,
                first_bun		= 5'd3,
                first_bun_wait= 5'd4,
                patty			= 5'd5,
                patty_wait 	= 5'd6,
                last_bun		= 5'd7,
                last_bun_wait = 5'd8,
                c_rice			= 5'd9,
                c_rice_wait	= 5'd10,
                fillet			= 5'd11,
                fillet_wait 	= 5'd12,
					 delay			= 5'd13;

    // Mealy state table
    always@(*)
    begin: state_table 
        case (current_state)
        	blank: begin
        		if (area==4'b0111) //buns
        			next_state = space ? b_blank_wait : blank;
        		else if (area == 4'b1000) //cooked rice
        			next_state = space ? c_blank_wait : blank;
        		else
        			next_state = blank;
        	end

        	b_blank_wait: begin
        		next_state = space ? b_blank_wait : first_bun;
        	end

        	c_blank_wait: begin
        		next_state = space ? c_blank_wait : c_rice;
        	end
        	
        	first_bun: begin
        		if(area == 4'b0011) //patty
        			next_state = space ? first_bun_wait : first_bun;
        		else
        			next_state = first_bun;
        	end

        	first_bun_wait: begin
        		next_state = space ? first_bun_wait : patty;
        	end

        	patty: begin
        		if(area == 4'b0111) //buns
        			next_state = space ? patty_wait : patty;
        		else
        			next_state = patty;
        	end

        	patty_wait: begin
        		next_state = space ? patty_wait : last_bun;
        	end

        	last_bun: begin
        		next_state = delay_done ? blank : last_bun;
        	end

        	c_rice: begin
        		if(area == 4'b0100)
        			next_state = space ? c_rice_wait : c_rice;
        		else
        			next_state = c_rice;
        	end

        	c_rice_wait: begin
        		next_state = space ? c_rice_wait : fillet;
        	end

        	fillet: begin
        		next_state = delay;
        	end
         default:	next_state = blank;
        endcase
    end // state_table
   
	
	reg delay_signal;
	reg delay_done=1'b0;
	
	reg [25:0]counter=26'b0;
	
	always@(posedge clk) begin
		if(~delay_signal) begin
			counter <= 26'b0;
			delay_done <= 1'b0;
		end
		else if(counter == 26'd64000000) begin
			counter <= 26'b0;
			delay_done <= 1'b1;
		end
		else begin
			counter <= counter + 1'b1;
			delay_done <= 1'b0;
		end
	end
	
    //datapath control signals
    always @(*)
    begin: enable_signals
			delay_signal <= 1'b0;
			state <= 4'b0000;
			increment = 1'b0;

        case (current_state)
        	blank: begin
        		state <= 4'b0000;
        	end
        	
        	first_bun: begin
        		state <= 4'b0001;
        	end

        	patty: begin
        		state <= 4'b0010;
        	end

        	last_bun: begin
        		state <= 4'b0011;
				delay_signal <= 1'b1;
        		increment = 1'b1;
        	end

        	c_rice: begin
        		state <= 4'b0100;
        	end

        	fillet: begin
        		state <= 4'b0101;
        		increment = 1'b1;
        	end
        endcase
    end
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= blank;
        else
            current_state <= next_state;
    end
endmodule



