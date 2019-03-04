/*******************************************************************************************
*  Name         :sdram_core.v
*  Description  :a simple SDRAM controller in full page burst mode,该模块意指在使用最简单的
*                状态转换机的前提下完成CMOS->VGA的图像缓存任务，SDRAM设置为简单的全页读写模
*                式，由于中间不能被refresh打断，为保证最短刷新时间，读写前后都有 失选和刷
*                新。读写个数越大效率越高，但不能超过列数; 流程 : 固定的初始化后，用户设置起
*                始bank、行、列地址，发送请求进行固定长度连续单页读写(请求必然导致读写操作！
*                即发一次写请求后用户必须依照wr_allow信号去写一次...)，到达规定个数(wr_num)，
*                该模块将给出信号。注意：该模块仅读取单页(一行，读写字数可控,需要读取另一行，
*                必更换地址)。该模块将SDRAM当成显存来用。不支持随机读写。该模块
*                不含FIFO。CAS==3;clk leads the 80 degree of sdram_clk(Different results
*                for different boards).Recommended sdram_clk phase shift -80 degrees.
*                Note:xx_request effective time should less than 8 clk,and do not Repeat 
*                xx_request until xx_allow finished.wr_data no pre-fetch need!
*  Origin       :190119
*                190122
*                190124 - add init_done
*  Author       :helrori2011@gmail.com
*  Reference    :https://github.com/stffrdhrn/sdram-controller
********************************************************************************************/
module sdram_core #(
//------------------------------------------------------------------------------------------
parameter   ROW_WIDTH       = 13    ,  //ROW_WIDTH > COL_WIDTH
parameter   COL_WIDTH       = 9     ,  //ROW_WIDTH > COL_WIDTH
parameter   BANK_WIDTH      = 2     ,
parameter   CLK_FREQUENCY   = 100   ,  // (Mhz)
parameter   REFRESH_TIME    = 64    ,  // (ms)     
parameter   REFRESH_COUNT   = 8192  ,  // 2**ROW_WIDTH (how many refreshes required per refresh_time)
`ifdef _DEBUG_
parameter   CK_TDLY         = 20,//0_00,  //(clk),>200_000ns
`else
parameter   CK_TDLY         = 200_00,  //(clk),>200_000ns
`endif
parameter   CK_TRP          = 2     ,  //(clk) PRECHARGE command period,>=20ns
parameter   CK_TRFC         = 7     ,  //(clk) AUTO REFRESH period,>=66ns
parameter   CK_TMRD         = 2     ,  //(clk) LOAD MODE REGISTER command to ACTIVE or REFRESH command
parameter   CK_TRCD         = 2     ,  //(clk) ACTIVE-to-READ or WRITE delay,>=20ns
parameter   CK_TWR          = 2     ,  //(clk) WRITE recovery time,>=15ns
parameter   TAC             = 5.4   ,  //(ns)  Access time from CLK,==5.4ns,not use
parameter   TOH             = 3.0   ,  //(ns)  Data-out hold time,==3.0ns,not use

parameter   TT              = 1000/CLK_FREQUENCY,//(ns) 周期,not use
parameter   TSU             = 6.5,//(ns) FPGA setup time
parameter   HADDR_WIDTH     = (BANK_WIDTH + ROW_WIDTH + COL_WIDTH),
parameter   _CLK_LEAD_TIME_ = TSU-TOH+(TT-TAC+TOH)/2     //(ns)  clk leads the _CLK_LEAD_TIME_ degree of sdram_clk,not use,仅参考


//------------------------------------------------------------------------------------------

)
(
    //CLOCK
    input   wire    clk,
    input   wire    clk_ref,
    input   wire    rst_n,
    //HOST
    input   wire    [HADDR_WIDTH-1:0]wr_addr,       //{bank_addr,row_addr,col_addr}
    input   wire    [COL_WIDTH    :0]wr_num,//1024  //写入这行的字数(请 <= 2^COL_WIDTH,一般小于等于512)
    input   wire    wr_request,                     //Effective time should less than 8,and do not Repeat request until wr_busy==0.
    input   wire    [15:0]wr_data,                  //XXXXXXXX| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |XXXX
    output  reg     wr_allow,                       //____|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|_______________
    output  wire    wr_busy,                        //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|____
    
    input   wire    [HADDR_WIDTH-1:0]rd_addr,       //{bank_addr,row_addr,col_addr}
    input   wire    [COL_WIDTH    :0]rd_num,//1024  //读取这行的字数(请 <= 2^COL_WIDTH,一般小于等于512)
    input   wire    rd_request,                     //Effective time should less than 8,and do not Repeat request until rd_busy==0.
    output  reg     [15:0]rd_data,                  //XXXX| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |XXXX
    output  reg     rd_allow,                       //____|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|_______________
    output  wire    rd_busy,                        //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|____
    
    output  wire    init_done,
    //TEST
    output  reg     busy,                           //(或者用户在xx_allow后等待20clk)
    output  reg     state_fly_error,
    //SDRAM
    output  wire    [ROW_WIDTH-1    :  0]sdram_addr     ,//(init,read,write)
    output  wire    [BANK_WIDTH-1   :  0]sdram_bkaddr   ,//(init,read,write)
    inout   wire    [15             :  0]sdram_data     ,//仅支持16bits (read,write)
    output  wire    sdram_clk      ,
    output  wire    sdram_cke      ,//always 1
    output  wire    sdram_cs_n     ,//always 0
    output  wire    sdram_ras_n    ,
    output  wire    sdram_cas_n    ,
    output  wire    sdram_we_n     ,
    output  wire    sdram_dqml     ,//not use,always 0
    output  wire    sdram_dqmh      //not use,always 0
);
localparam  CK_REFRESH_TICK = (CLK_FREQUENCY*1_000* REFRESH_TIME) / REFRESH_COUNT;//(clk)
localparam  CMD_PRECHARGE   = 5'b10010,//PRECHARGE (Deactivate row in bank or banks) 
            CMD_REFRESH     = 5'b10001,//AUTO REFRESH
            CMD_NOP         = 5'b10111,//NO OPERATION
            CMD_LMR         = 5'b10000,//LOAD MODE REGISTER
            CMD_ACTIVE      = 5'b10011,//ACTIVE (select bank and activate row) 
            CMD_READ        = 5'b10101,//READ (select bank and column, and start READ burst)
            CMD_WRITE       = 5'b10100,//WRITE (select bank and column, and start WRITE burst)
            CMD_BSTP        = 5'b10110;//BURST TERMINATE,注意使用BSTP时禁止使用read\write auto precharge
assign sdram_clk = clk_ref;
assign sdram_dqml = 0;
assign sdram_dqmh = 0;
/* reg    [BANK_WIDTH-1:0]bank_addr = 'd0;//
reg    [ROW_WIDTH-1 :0]row_addr  = 'd0;//
reg    [COL_WIDTH-1 :0]col_addr  = 'd0;// */
reg    [4:0]sdram_cmd;
reg    [BANK_WIDTH+ROW_WIDTH-1:0]BA_A;

reg    [HADDR_WIDTH-1:0]rd_addr_b,wr_addr_b;
reg    [COL_WIDTH:0]rd_num_b,wr_num_b;
reg    rd_request_b,wr_request_b;
wire   [BANK_WIDTH-1:0 ]rd_bank_addr_b    ,wr_bank_addr_b ;
wire   [ROW_WIDTH-1 :0 ]rd_row_addr_b     ,wr_row_addr_b  ;
wire   [COL_WIDTH-1 :0 ]rd_col_addr_b     ,wr_col_addr_b  ;

assign {rd_bank_addr_b,rd_row_addr_b,rd_col_addr_b} = rd_addr_b;//
assign {wr_bank_addr_b,wr_row_addr_b,wr_col_addr_b} = wr_addr_b;//
assign {sdram_bkaddr,sdram_addr} = BA_A;
assign {sdram_cke,sdram_cs_n,sdram_ras_n,sdram_cas_n,sdram_we_n} = sdram_cmd;


/*******************************************************************************************
*   state machine
*******************************************************************************************/ 
localparam TDLY         = 5'h10,
           INIT_NOP1    = 5'h11,
           PRECHARGE    = 5'h12,
           TRP          = 5'h13,
           REFRESH1     = 5'h14,
           TRFC1        = 5'h15,
           REFRESH2     = 5'h16,
           TRFC2        = 5'h17,
           LMR          = 5'h18,
           TMRD         = 5'h19,
           
           IDLE         = 5'h00,
           
           PRECHARGE2   = 5'h01,
           TRP2         = 5'h02,
           REFRESH3     = 5'h03,
           TRFC3        = 5'h04,
           
           ACTIVE1      = 5'h0A,
           TRCD1        = 5'h0B,      
           READ         = 5'h0C,
           RD_WORD      = 5'h0D, 

           ACTIVE2      = 5'h0E,
           WR_WORD      = 5'h0F;  
           
reg     [4:0 ]state,nxt_state;
reg     [1 :0]nxt_rd_flag,nxt_wr_flag,rd_flag,wr_flag;
assign  wr_busy = wr_flag[0];
assign  rd_busy = rd_flag[0];
reg     [15:0]dly_cnt; 
reg     [7 :0]ck_cnt; 
reg     [13:0]refresh_cnt;
reg     [COL_WIDTH:0]word_cnt;  //1024
wire    [15:0]data_o;           //FPGA->SDRAM
wire    data_output =   state == WR_WORD;
assign  data_o      =   wr_data;//WR_WORD 时 wr_data 直通到SDRAM数据脚,请在 wr_allow写数据(no pre-fetch need)
assign  sdram_data  =   (data_output)?data_o:16'dz;//仅当写SDRAM时才不是高阻
assign  init_done   =   ~state[4];
/*
*   busy signal for test
*/  
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        busy <= 'd0;
    end 
        busy <= state != IDLE;
end
/*
*   refresh counter
*/  
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        refresh_cnt <= 'd0;
    end else if(state == REFRESH3)begin//refresh done 清零
        refresh_cnt <= 'd0;
    end else begin
        refresh_cnt <= refresh_cnt + 1'd1;
    end
end
/*
*   state process
*/  
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        state       <=  TDLY;
        rd_flag     <=  'd0;
        wr_flag     <=  'd0;
        dly_cnt     <=  'd0;
        ck_cnt      <=  'd0;
        word_cnt    <=  'd0;
        sdram_cmd   <=   CMD_NOP;
        BA_A        <=  'd0;
        rd_data     <=  'd0;
        rd_allow    <=   1'd0;
        wr_allow    <=   1'd0;
        state_fly_error <= 1'd0;
    end else begin
        state       <= nxt_state;
        rd_flag     <= nxt_rd_flag;
        wr_flag     <= nxt_wr_flag;
        case(nxt_state)
// INIT //------------------------------------------------------------------------
        TDLY:begin
            dly_cnt <=  dly_cnt + 1'd1;
        end
        INIT_NOP1:begin
            dly_cnt     <= 'd0;
            sdram_cmd   <=  CMD_NOP;
        end
        PRECHARGE:begin     //--->
            sdram_cmd   <=  CMD_PRECHARGE;
            BA_A[10]    <=  1'd1;           //Precharge all banks
        end                 //   |
        TRP:begin           //<--+
            ck_cnt      <=  ck_cnt + 1'd1;
            sdram_cmd   <=  CMD_NOP;
        end
        REFRESH1:begin           //--->
            ck_cnt      <= 'd0;  //   |
            sdram_cmd   <=  CMD_REFRESH;
        end                      //   |
        TRFC1:begin              //<--+
            ck_cnt      <=  ck_cnt + 1'd1;
            sdram_cmd   <=  CMD_NOP;
        end
        REFRESH2:begin           //--->
            ck_cnt      <= 'd0;  //   |
            sdram_cmd   <=  CMD_REFRESH;   
        end                      //   |
        TRFC2:begin              //<--+
            ck_cnt      <=  ck_cnt + 1'd1;
            sdram_cmd   <=  CMD_NOP;        
        end 
        LMR:begin                //--->
            ck_cnt      <= 'd0;  //   |
            BA_A        <= {{BANK_WIDTH{1'b0}},{(ROW_WIDTH-10){1'b0}},10'b0_00_011_0111};//Programmed Burst Length,full page,CAS 3
            sdram_cmd   <=  CMD_LMR;        
        end                      //   |
        TMRD:begin               //<--+
            ck_cnt      <=  ck_cnt + 1'd1;
            sdram_cmd   <=  CMD_NOP;        
        end
// IDLE //------------------------------------------------------------------------
        IDLE:begin
            ck_cnt      <= 'd0;
            word_cnt    <= 'd0;
        end
//REFRESH//------------------------------------------------------------------------
        PRECHARGE2:begin
            ck_cnt      <= 'd0;
            sdram_cmd   <=  CMD_PRECHARGE;
            BA_A[10]    <=  1'd1;           //Precharge all banks
        end
        TRP2:begin
            ck_cnt      <=  ck_cnt + 1'd1;
            sdram_cmd   <=  CMD_NOP;
        end
        REFRESH3:begin
            ck_cnt      <= 'd0;  
            sdram_cmd   <=  CMD_REFRESH;   
        end
        TRFC3:begin
            ck_cnt      <=  ck_cnt + 1'd1;
            sdram_cmd   <=  CMD_NOP;
        end//->IDLE/ACTIVE1/ACTIVE2
//READ //------------------------------------------------------------------------
        ACTIVE1:begin
            ck_cnt      <= 'd0;
            sdram_cmd   <=  CMD_ACTIVE;
            BA_A        <=  {rd_bank_addr_b,rd_row_addr_b};//选中行与bank
        end
        TRCD1:begin
            ck_cnt      <=  ck_cnt + 1'd1;
            sdram_cmd   <=  CMD_NOP;
        end
        READ:begin
            ck_cnt      <=  'd0;
            BA_A        <=  {rd_bank_addr_b,4'd0,rd_col_addr_b};//选中列与bank,disable auto_precharge
            sdram_cmd   <=  CMD_READ;
        end
        RD_WORD:begin
            //send other cmd
            word_cnt <= word_cnt + 1'd1;
            if(word_cnt == rd_num_b - 1)begin
                sdram_cmd   <=  CMD_BSTP;
            end else begin
                sdram_cmd   <=  CMD_NOP;
            end
            //make rd_allow
            if(word_cnt == 3)//***caution!!***这里的取值实际与仿真有出入，按照理论这里的取值应等于CAS，实际在板调试取值等于CAS即可,仿真MT的模型取CAS-1
                rd_allow <= 1'd1;
            else if(word_cnt == 3 + rd_num_b)//***caution!!***这里的取值实际与仿真有出入，按照理论这里的取值应等于CAS+rd_num_b,仿真MT的模型取CAS-1+rd_num_b
                rd_allow <= 1'd0;
            else
                rd_allow <= rd_allow;
            //寄存,注意RD_WORD&&rd_allow时rd_data数据有效，RD_WORD的其他时候高阻
            rd_data <= sdram_data;
        end
            
            

//WRITE//------------------------------------------------------------------------
        ACTIVE2:begin
            sdram_cmd   <=  CMD_ACTIVE;
            BA_A        <=  {wr_bank_addr_b,wr_row_addr_b};//选中行与bank
        end
        WR_WORD:begin
            //send other cmd,ACTIVE后面的操作全部合并
            word_cnt <= word_cnt + 1'd1;
            if(word_cnt == CK_TRCD)begin
                sdram_cmd   <=  CMD_WRITE;
                BA_A        <=  {wr_bank_addr_b,4'd0,wr_col_addr_b};//选中列与bank,disable auto_precharge
            end else if(word_cnt == CK_TRCD + wr_num_b)begin
                sdram_cmd   <=  CMD_BSTP;
            end else begin
                sdram_cmd   <=  CMD_NOP;
            end
            //make wr_allow
            if(word_cnt == CK_TRCD - 1) //wr_allow相对于输入数据 提早1clk,no pre-fetch
                wr_allow <= 1'd1;
            else if(word_cnt == wr_num_b + CK_TRCD - 1)
                wr_allow <= 1'd0;
            else
                wr_allow <= wr_allow;
        end

            
        default:state_fly_error <= 1'd1;
        endcase

        
        
        
    end
end
/*
*   state change
*/
always@(*)begin
    nxt_state = state;
    nxt_rd_flag = rd_flag;
    nxt_wr_flag = wr_flag;
    case(state)
// INIT //------------------------------------------------------------------------
        TDLY:begin
            nxt_state = (dly_cnt >= CK_TDLY)?INIT_NOP1:TDLY;
        end
        INIT_NOP1:begin
            nxt_state = PRECHARGE;
        end
        PRECHARGE:begin     //--->
            nxt_state = TRP;//   |
        end                 //   |
        TRP:begin           //<--+
            nxt_state = (ck_cnt == CK_TRP )?REFRESH1:TRP;
        end
        REFRESH1:begin           //--->
            nxt_state = TRFC1;   //   |
        end                      //   |
        TRFC1:begin              //<--+
            nxt_state = (ck_cnt == CK_TRFC)?REFRESH2:TRFC1;
        end
        REFRESH2:begin           //--->
            nxt_state = TRFC2;   //   |
        end                      //   |
        TRFC2:begin              //<--+
            nxt_state = (ck_cnt == CK_TRFC)?LMR:TRFC2;
        end 
        LMR:begin                //--->
            nxt_state = TMRD;    //   |
        end                      //   |
        TMRD:begin               //<--+
            nxt_state = (ck_cnt == CK_TMRD)?IDLE:TMRD;
        end
// IDLE //------------------------------------------------------------------------
        IDLE:begin
            if(refresh_cnt  >  CK_REFRESH_TICK)begin
                nxt_state = PRECHARGE2;
            end else if(rd_request_b)begin//读写之前也要刷新(precharge and refresh before rd/wr)
            //1.注意：rd_request优先，这说明：当不间断读请求时(在 rd_allow 下降沿后，且 
            //  busy仍是1时，又进行读操作)，写操作被搁置。
            //  当不间断写操作时(在 wr_allow 下降沿后，且 busy仍是1时，又进行写操作)，
            //  读操作(在 rd_allow 下降沿后，且 busy仍是1时的读操作)可以先于写操作。
            //2.rd_request_b,wr_request_b同时置位时，读优先。
            //3.建议读写请求在allow信号变0后 且 busy变0后(IDLE后)给出，不会有写操作被
            //  搁置的情况，但要注意同时读写时 读优先。
                nxt_state   = PRECHARGE2;
                nxt_rd_flag[0] = 1'd1;
                nxt_rd_flag[1] = 1'd1;
            end else if(wr_request_b)begin
                nxt_state = PRECHARGE2;
                nxt_wr_flag[0] = 1'd1;
                nxt_wr_flag[1] = 1'd1;
            end else begin
                nxt_state = IDLE;
            end
        end
//REFRESH//------------------------------------------------------------------------
        PRECHARGE2:begin
            nxt_state = TRP2;
        end
        TRP2:begin
            nxt_state = (ck_cnt == CK_TRP )?REFRESH3:TRP2;
        end
        REFRESH3:begin
            nxt_state = TRFC3;
        end
        TRFC3:begin
            if(ck_cnt == CK_TRFC)begin
                if(rd_flag[1])
                    nxt_state = ACTIVE1;
                else if(wr_flag[1])
                    nxt_state = ACTIVE2;
                else begin
                    nxt_state = IDLE;
                    nxt_rd_flag[0] = 1'd0;
                    nxt_wr_flag[0] = 1'd0;
                end
            end else begin
                nxt_state = TRFC3;
            end
        end
//READ //------------------------------------------------------------------------进入前请确保已经失选(disactive),计数器word_cnt为0
        ACTIVE1:begin
            nxt_state = TRCD1;
        end
        TRCD1:begin
            nxt_state = (ck_cnt == CK_TRCD )?READ:TRCD1;
        end
        READ:begin
            nxt_state = RD_WORD;
        end
        RD_WORD:begin//原本应是3个CAS NOP然后读512字、发BSTP。这里直接与后边合并//读写完毕后也要刷新
            nxt_state = (word_cnt == rd_num_b + 3 + 2)?PRECHARGE2:RD_WORD;//RD_WORD持续rd_num + 3(CAS==3) + 2个周期,最后5个是NOP,2:可以增大也可为0
            nxt_rd_flag[1] = 1'd0;
        end
        
        
//WRITE//------------------------------------------------------------------------进入前请确保已经失选(disactive),计数器word_cnt为0
        ACTIVE2:begin
            nxt_state = WR_WORD;
        end
        WR_WORD:begin//The operations following ACTIVE are all merged
            nxt_state = (word_cnt == CK_TRCD + wr_num_b + 1 + CK_TWR)?PRECHARGE2:WR_WORD;//读写完毕后也要刷新
            nxt_wr_flag[1] = 1'd0;
        end
    default:nxt_state = TDLY;
    endcase
    
end
/*******************************************************************************************
*   read & write request register
*******************************************************************************************/ 
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_addr_b   <= 'd0;
        rd_num_b    <= 'd0;
        rd_request_b<= 'd0;
        wr_addr_b   <= 'd0;
        wr_num_b    <= 'd0;
        wr_request_b<= 'd0;
    end else begin
        if(rd_request)begin
            rd_addr_b   <=  rd_addr;    //保存地址
            rd_num_b    <=  rd_num;     //保存
            rd_request_b<=  1'd1;       //保存请求
        end else if(state == RD_WORD)
            rd_request_b<=  1'd0;       //任务完成，撤回请求
        else
            rd_request_b<=  rd_request_b;
            
            
        if(wr_request)begin
            wr_addr_b   <=  wr_addr;    //保存地址
            wr_num_b    <=  wr_num;     //保存
            wr_request_b<=  1'd1;       //保存请求
        end else if(state == WR_WORD)
            wr_request_b<=  1'd0;       //任务完成，撤回请求
        else
            wr_request_b<=  wr_request_b;
    end
end
          
endmodule
