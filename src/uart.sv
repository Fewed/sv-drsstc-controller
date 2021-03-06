`include "./modules/defines.sv"
`include "./modules/edge_det.sv"
`include "./modules/sync.sv"

typedef enum { CONF_PAR_[6] } Conf_par;

module uart #(parameter
							CONF_PAR_MAX = 255,
							FRAME_CNT_MAX_1 = 3 * 52,
							FRAME_CNT_MAX_2 = 2 * 52,
							DATA_BIT_CNT_MAX = 7
						 )
			 (
				 input wire clk,
				 input wire uart_data,
				 output `reg(CONF_PAR_MAX) storage = 0,	// data bas
				 output `reg(CONF_PAR_5) conf_par_cnt = 0,	// address
				 output reg is_data_ready = 0
				 //output `reg_2d(sh_reg, CONF_PAR_MAX, CONF_PAR_4)
			 );

// cdc synchronizer
sync #(.WIDTH(1))
		 s1(
			 .clk(clk),
			 .data_raw(uart_data),
			 .data(uart_data_s)
		 );

// initializing sh_reg with zeroes
//initial for(int i = 0; i <= CONF_PAR_4; i++) sh_reg[i] = 0;

typedef enum { STATE_[3] } State;

`reg(FRAME_CNT_MAX_1) frame_cnt = FRAME_CNT_MAX_1;
`reg(STATE_2) state = STATE_0;
`reg(DATA_BIT_CNT_MAX) data_bit_cnt = DATA_BIT_CNT_MAX;


// state transition conditions
wire cond_1 = data_edge_n,	// transmission start
		 cond_2 = !frame_cnt,	// first data bit
		 cond_0 = !data_bit_cnt;	// last data bit

edge_det uart_n(.clk(clk), .sgn(uart_data_s), .out_n(data_edge_n));

always @(posedge clk) begin
	// state values
	case(state)
		STATE_0: is_data_ready <= 0;
		STATE_1: frame_cnt <= frame_cnt ? frame_cnt - 1 : FRAME_CNT_MAX_2;
		STATE_2: if (frame_cnt) frame_cnt <= frame_cnt - 1;
			else begin
				frame_cnt <= FRAME_CNT_MAX_2;
				data_bit_cnt <= data_bit_cnt - 1;
				storage <= {uart_data_s, storage[`width(CONF_PAR_MAX)-1:1]};
			end
	endcase

	// state transitions
	case(state)
		STATE_0: if (cond_1) begin
				state <= STATE_1;
				conf_par_cnt <= conf_par_cnt ? conf_par_cnt - 1 : CONF_PAR_5;
			end
		STATE_1: if (cond_2) begin
				state <= STATE_2;
				storage <= {uart_data_s, storage[`width(CONF_PAR_MAX)-1:1]};
			end
		STATE_2: if (cond_0) begin
				state <= STATE_0;
				is_data_ready <= 1;
				frame_cnt <= FRAME_CNT_MAX_1;
				data_bit_cnt <= DATA_BIT_CNT_MAX;
			end
	endcase
end

endmodule
