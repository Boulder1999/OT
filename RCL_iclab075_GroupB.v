
module RCL(
    clk,
    rst_n,
    in_valid,
    coef_Q,
    coef_L,
    out_valid,
    out
);

input clk,rst_n,in_valid;
input [4:0] coef_Q,coef_L;
output out_valid;
output [1:0] out;
reg [1:0] ns,cs;
parameter IDLE=2'd0, LOAD=2'd1, PROCESS=2'd2, OUT=2'd3;


reg [30:0]dis;
reg [30:0]dism;
reg [70:0]R;
reg signed [4:0] a,b,c ,m,n;
reg [15:0] k;
reg [15:0]abs_up;
reg signed[30:0] up;
reg [30:0]abs_down;
reg signed[30:0]down;
reg [5:0]cnt;
reg [5:0]cntp;
reg out_valid;
reg [1:0] out;
reg process_flag;




always@(*)
begin
  if(up[7]) 
  begin
    abs_up=~(up)+8'd1;
  end
  else begin
    abs_up=up;
  end
end
always@(*)
begin
  if(down[15]) 
  begin
    abs_down=~(down)+8'd1;
  end
  else begin
    abs_down=down;
  end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cs<=IDLE;
	end
	else begin
		cs<=ns;
	end
end
always@(*) begin
	case(cs)
	IDLE:begin
		if(!rst_n) ns = IDLE;
		else if( in_valid ) ns = LOAD;
		else ns = IDLE;
	end
	LOAD:begin
		if(in_valid) ns = LOAD;
		else ns = PROCESS;
	end
	PROCESS:begin
		if(process_flag) ns = OUT;
		else ns = PROCESS;
	end 
	OUT:begin
		ns = IDLE;
	end
	endcase
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		a<=5'd0;
		b<=5'd0;
		c<=5'd0;
	end
	else if(ns == IDLE) begin
		a<=5'd0;
		b<=5'd0;
		c<=5'd0;
	end
	else if(ns == LOAD) begin
		case(cnt)
		6'd0:a<=coef_L;
		6'd1:b<=coef_L;
		6'd2:c<=coef_L;
		endcase
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		m<=5'd0;
		n<=5'd0;
		k<=5'd0;
	end
	else if(ns == IDLE) begin
		m<=5'd0;
		n<=5'd0;
		k<=5'd0;
	end
	else if(ns == LOAD) begin
		case(cnt)
		6'd0:m<=coef_Q;
		6'd1:n<=coef_Q;
		6'd2:k<=coef_Q;
		endcase
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt<=6'd0;
	end
	else if(ns == IDLE) cnt<=6'd0;
	else if(ns == LOAD) begin
		cnt<=cnt+6'd1;
	end
end
//cal
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cntp<=6'd0;
	end
	else if(ns == IDLE) cntp<=6'd0;
	else if(ns == PROCESS) begin
		cntp<=cntp+6'd1;
	end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		dis<=8'd0;
		process_flag<=1'b0;
	end
	else if(ns == IDLE) begin
		dis<=8'd0;
		process_flag<=1'b0;
	end
	else if(ns == PROCESS) begin
		if(cntp==6'd4) begin
			 dis<=(up/abs_down);
		process_flag<=1'b1;
		end
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		dism<=8'd0;
	end
	else if(ns == IDLE) begin
		dism<=8'd0;
	end
	else if(ns == PROCESS) begin
		if(cntp==6'd4) begin
		dism<=(abs_up%down);
		end
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		up<=8'd0;
	end
	else if(ns == IDLE) up<=8'd0;
	else if(ns == PROCESS) begin
		if(cntp == 6'd1)
		up<=(a*m+b*n+c)*(a*m+b*n+c);
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		down<=8'd0;
	end
	else if(ns == IDLE) down<=8'd0;
	else if(ns == PROCESS) begin
		if(cntp == 6'd2)
		down<=a*a+b*b;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		R<=8'd0;
	end
	else if(ns == IDLE) R<=8'd0;
	else if(ns == PROCESS) begin
		if(cntp == 6'd2) begin
			R<=k;
		end
	end
end

//out
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid<=1'd0;
	end
	else if(ns == IDLE) out_valid<=1'd0;
	else if(ns == OUT) begin
		out_valid<=1'd1;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out<=2'd0;
	end
	else if(ns == IDLE) out<=2'd0;
	else if(ns == OUT) begin
		if(dis > R)
		out<=2'b0;
		else if( dis == R )begin
			if(dism > 0) 	out<=2'd0;
			else if(dism == 0) out<=2'd1;
			else out<=2'd2;
		end
		else if( dis < R )
		out<=2'd2;
	end
end
endmodule
