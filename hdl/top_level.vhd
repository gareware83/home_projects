

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;
library work;
use work.all;
use work.pkg.all;

entity top_level is
    Generic(
        G_SIMULATE : boolean := false
    );
    Port ( sys_clk_100  : in STD_LOGIC;
           --ext_reset    : in STD_LOGIC; --pull reset in and use sw register for soft reset, but also see if there is a pll lock tied in from the board
           UART_0_txd   : out std_logic;
           UART_0_rxd   : in std_logic;
           button_press : in STD_LOGIC;
           buffer_led   : out STD_LOGIC
           );
end top_level;

architecture Behavioral of top_level is

component clk_wiz_0
port
 (-- Clock in ports
  -- Clock out ports
  clk_out1          : out    std_logic;
  -- Status and control signals
  reset             : in     std_logic;
  locked            : out    std_logic;
  clk_in1           : in     std_logic
 );
end component;

--put these in a pkg file and define a clean read/write function interface to all registers
--and define space for read only status registers



signal clk_100mhz             : std_logic;
signal clk_wiz_reset          : std_logic := '1';
signal locked                 : std_logic;
signal buffer_button          : std_logic;
signal m_axi_user_regs_awaddr : STD_LOGIC_VECTOR ( 31 downto 0 ); 
signal m_axi_user_regs_awprot : STD_LOGIC_VECTOR ( 2 downto 0 );  
signal m_axi_user_regs_awvali : STD_LOGIC;                        
signal m_axi_user_regs_awread : STD_LOGIC;                         
signal m_axi_user_regs_wdata  : STD_LOGIC_VECTOR ( 31 downto 0 ); 
signal m_axi_user_regs_wstrb  : STD_LOGIC_VECTOR ( 3 downto 0 );  
signal m_axi_user_regs_wvalid : STD_LOGIC;                        
signal m_axi_user_regs_wready : STD_LOGIC;                         
signal m_axi_user_regs_bresp  : STD_LOGIC_VECTOR ( 1 downto 0 );   
signal m_axi_user_regs_bvalid : STD_LOGIC;                         
signal m_axi_user_regs_bready : STD_LOGIC;                        
signal m_axi_user_regs_araddr : STD_LOGIC_VECTOR ( 31 downto 0 ); 
signal m_axi_user_regs_arprot : STD_LOGIC_VECTOR ( 2 downto 0 );  
signal m_axi_user_regs_arvali : STD_LOGIC;                        
signal m_axi_user_regs_arread : STD_LOGIC;                         
signal m_axi_user_regs_rdata  : STD_LOGIC_VECTOR ( 31 downto 0 );  
signal m_axi_user_regs_rresp  : STD_LOGIC_VECTOR ( 1 downto 0 );   
signal m_axi_user_regs_rvalid : STD_LOGIC;                         
signal m_axi_user_regs_rready : STD_LOGIC;  

--fpga register interface
signal fpga_reg               : fpgaReg32;

signal led_ctrl_reg           : std_logic_vector(31 downto 0):=(others => '0');


signal reset_counter  : natural   := 0;
signal aresetn        : std_logic := '0';
signal areset         : std_logic := '1';
signal control_reg    : std_logic_vector(C_ADDR_WIDTH - 1  downto 0);
--attribute MARK_DEBUG : string;
--attribute MARK_DEBUG of sys_clk_100 : signal is "TRUE";
--attribute MARK_DEBUG of UART_0_txd  : signal is "TRUE";
--attribute MARK_DEBUG of UART_0_rxd : signal is "TRUE";
                  
begin

 ibuf_inst : IBUF
 port map
    (I => button_press,
     O => buffer_button
    );
    
--I want to use just the ublaze on the PL with no PS or this design, jsut for embedded fun.
--I am using the pynq1 oscillator which doesnt provide a locked signal like an MMCM or PLL in the PS
--So using a counter to wait for clock to stabilize and provide a reset for now
--Using negative asserted reset as if looking for a locked signal from a clock gen or PLL
--TODO: enable sw reset via user registers, so will need a clock gen process to honor both resets

clk_reset_proc : process (sys_clk_100)
begin 
    if rising_edge(sys_clk_100) then
        
        if reset_counter > 100000 then
            clk_wiz_reset <= '0';
        else
            reset_counter <= reset_counter + 1;
        end if;
    end if;
end process;    
reset_process : process (sys_clk_100)
begin
    if clk_wiz_reset = '1' then
        aresetn <= '0';
        areset  <= '1';   
    elsif rising_edge(sys_clk_100) then        
        if locked = '0' then
            aresetn <= '0';
            areset  <= '1';
        else
            aresetn <= '1';
            areset  <= '0';
        end if;
    end if;
end process;


led_ctrl_reg <= fpga_reg(C_LED_CONTROL_ADDR_IND);

sys_clk_inst: clk_wiz_0
   port map ( 
      -- Clock out ports  
      clk_out1 => clk_100mhz,
      -- Status and control signals                
      reset => clk_wiz_reset,
      locked => locked,
      -- Clock in ports
      clk_in1 => sys_clk_100
    );
    
--populating port maps with bogus signals , just wanted to get started on modulse and top level instances
led_control_inst : entity work.led_blink
    generic map (
         G_SIMULATE => true
        ,G_USE_REGS => true
    )
    port map(
         clk        => clk_100mhz
        ,aresetn    => aresetn
        ,button_in  => buffer_button
        ,control_reg => led_ctrl_reg
        ,buffer_led => buffer_led
    );

register_interace_inst : entity work.reg_rw_interface
   
    port map ( 
         clk                     => clk_100mhz  
        ,aresetn                 => aresetn
        ,s_axi_user_regs_awaddr  => m_axi_user_regs_awaddr     
        ,s_axi_user_regs_awprot  => m_axi_user_regs_awprot     
        ,s_axi_user_regs_awvalid => m_axi_user_regs_awvali     
        ,s_axi_user_regs_awready => m_axi_user_regs_awread     
        ,s_axi_user_regs_wdata   => m_axi_user_regs_wdata      
        ,s_axi_user_regs_wstrb   => m_axi_user_regs_wstrb      
        ,s_axi_user_regs_wvalid  => m_axi_user_regs_wvalid     
        ,s_axi_user_regs_wready  => m_axi_user_regs_wready     
        ,s_axi_user_regs_bresp   => m_axi_user_regs_bresp      
        ,s_axi_user_regs_bvalid  => m_axi_user_regs_bvalid     
        ,s_axi_user_regs_bready  => m_axi_user_regs_bready     
        ,s_axi_user_regs_araddr  => m_axi_user_regs_araddr     
        ,s_axi_user_regs_arprot  => m_axi_user_regs_arprot     
        ,s_axi_user_regs_arvalid => m_axi_user_regs_arvali     
        ,s_axi_user_regs_arready => m_axi_user_regs_arread     
        ,s_axi_user_regs_rdata   => m_axi_user_regs_rdata      
        ,s_axi_user_regs_rresp   => m_axi_user_regs_rresp      
        ,s_axi_user_regs_rvalid  => m_axi_user_regs_rvalid     
        ,s_axi_user_regs_rready  => m_axi_user_regs_rready  
        ,fpga_reg                => fpga_reg   
                                
);     

md_bd_inst : entity work.ublaze_ps_wrapper 

  port map(
      clk_100mhz           => clk_100mhz                --: in STD_LOGIC;
     ,areset               => areset             --: in STD_LOGIC;   
    ,uart_rtl_0_txd        => UART_0_txd              --: out STD_LOGIC;
    ,uart_rtl_0_rxd        => UART_0_rxd              --: in STD_LOGIC;
    ,axi_user_regs_awaddr  => m_axi_user_regs_awaddr--: out STD_LOGIC_VECTOR ( 31 downto 0 ); 
    ,axi_user_regs_awprot  => m_axi_user_regs_awprot--: out STD_LOGIC_VECTOR ( 2 downto 0 );  
    ,axi_user_regs_awvalid => m_axi_user_regs_awvali--: out STD_LOGIC;                       
    ,axi_user_regs_awready => m_axi_user_regs_awread--: in STD_LOGIC;                        
    ,axi_user_regs_wdata   => m_axi_user_regs_wdata --: out STD_LOGIC_VECTOR ( 31 downto 0 );  
    ,axi_user_regs_wstrb   => m_axi_user_regs_wstrb --: out STD_LOGIC_VECTOR ( 3 downto 0 );   
    ,axi_user_regs_wvalid  => m_axi_user_regs_wvalid--: out STD_LOGIC;                        
    ,axi_user_regs_wready  => m_axi_user_regs_wready--: in STD_LOGIC;                         
    ,axi_user_regs_bresp   => m_axi_user_regs_bresp --: in STD_LOGIC_VECTOR ( 1 downto 0 );    
    ,axi_user_regs_bvalid  => m_axi_user_regs_bvalid--: in STD_LOGIC;                         
    ,axi_user_regs_bready  => m_axi_user_regs_bready--: out STD_LOGIC;                        
    ,axi_user_regs_araddr  => m_axi_user_regs_araddr--: out STD_LOGIC_VECTOR ( 31 downto 0 ); 
    ,axi_user_regs_arprot  => m_axi_user_regs_arprot--: out STD_LOGIC_VECTOR ( 2 downto 0 );  
    ,axi_user_regs_arvalid => m_axi_user_regs_arvali--: out STD_LOGIC;                       
    ,axi_user_regs_arready => m_axi_user_regs_arread--: in STD_LOGIC;                        
    ,axi_user_regs_rdata   => m_axi_user_regs_rdata --: in STD_LOGIC_VECTOR ( 31 downto 0 );   
    ,axi_user_regs_rresp   => m_axi_user_regs_rresp --: in STD_LOGIC_VECTOR ( 1 downto 0 );    
    ,axi_user_regs_rvalid  => m_axi_user_regs_rvalid--: in STD_LOGIC;                         
    ,axi_user_regs_rready  => m_axi_user_regs_rready--: out STD_LOGIC;                        
  
  );               
 
end;
