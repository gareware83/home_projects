

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

entity reg_rw_interface is
    Generic(
        G_SIMULATE : boolean := false
    );
    Port ( clk                     : in std_logic;
           aresetn                  : in std_logic;                                  
           s_axi_user_regs_awaddr  : in STD_LOGIC_VECTOR ( 31 downto 0 );  
           s_axi_user_regs_awprot  : in STD_LOGIC_VECTOR ( 2 downto 0 );   
           s_axi_user_regs_awvalid : in STD_LOGIC;                                               
           s_axi_user_regs_wdata   : in STD_LOGIC_VECTOR ( 31 downto 0 );   
           s_axi_user_regs_wstrb   : in STD_LOGIC_VECTOR ( 3 downto 0 );    
           s_axi_user_regs_wvalid  : in STD_LOGIC;   
           s_axi_user_regs_awready : out STD_LOGIC;                       
           s_axi_user_regs_wready  : out STD_LOGIC;                          
           s_axi_user_regs_bresp   : out STD_LOGIC_VECTOR ( 1 downto 0 );     
           s_axi_user_regs_bvalid  : out STD_LOGIC;                          
           s_axi_user_regs_bready  : in STD_LOGIC;                         
           s_axi_user_regs_araddr  : in STD_LOGIC_VECTOR ( 31 downto 0 );  
           s_axi_user_regs_arprot  : in STD_LOGIC_VECTOR ( 2 downto 0 );   
           s_axi_user_regs_arvalid : in STD_LOGIC;                        
           s_axi_user_regs_arready : out STD_LOGIC;                         
           s_axi_user_regs_rdata   : out STD_LOGIC_VECTOR ( 31 downto 0 );    
           s_axi_user_regs_rresp   : out STD_LOGIC_VECTOR ( 1 downto 0 );     
           s_axi_user_regs_rvalid  : out STD_LOGIC;                          
           s_axi_user_regs_rready  : in STD_LOGIC;
           fpga_reg                : fpgaReg32                                                     
);                
end reg_rw_interface;

architecture Behavioral of reg_rw_interface is

COMPONENT blk_mem_gen_1
  PORT (
    clka      : IN STD_LOGIC;
    rsta      : IN STD_LOGIC;
    ena       : IN STD_LOGIC;
    wea       : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    addra     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dina      : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    douta     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rsta_busy : OUT STD_LOGIC 
  );
END COMPONENT;

signal rsta      : std_logic:='1';
signal ena       : std_logic;
signal wea       : std_logic_vector(3 downto 0);
signal addra     : std_logic_vector(31 downto 0);
signal dina      : std_logic_vector(31 downto 0);
signal douta     : std_logic_vector(31 downto 0);
signal rsta_busy : std_logic;

--internal axi signals
--writes
signal awready : std_logic;--address write ready
signal wready  : std_logic; --data write ready
signal bvalid  : std_logic;--data valid
--reads
signal arready : std_logic;
signal rvalid  : std_logic;
signal rdata   : std_logic_vector( 31 downto 0);
begin

rsta <= not aresetn; 

--bram enable process
bram_en_proc : process (clk, rsta)
begin 
    if (rsta = '1') then --bram ip is reset active high
        ena <= '0';
    elsif (rising_edge(clk)) then
        ena <= '1';--what other conditions should hold the enable low ? only ena high is read enable
    end if;
end process;    

s_axi_user_regs_awready <= awready;
s_axi_user_regs_wready  <= wready;
s_axi_user_regs_bvalid  <= bvalid;
s_axi_user_regs_bresp   <= "00";

--address register, awready (address write ready) signal is not enabled by default, read take precendence, could use a concurrent ternary statement
addr_proc : process (clk, aresetn)
begin
    if (aresetn = '0') then
        addra <= (others => '0');
        arready <= '0';
    elsif (rising_edge(clk)) then
        if (s_axi_user_regs_awvalid = '1' and awready = '0') then
            addra <= s_axi_user_regs_awaddr;
            awready <= '1';
        else 
            --addra <=  s_axi_user_regs_araddr;--default to read address benefit to using concurrent ternary statement?
            awready <= '0';
        end if;  
        
         if (s_axi_user_regs_arvalid = '1' and arready = '0') then
            arready <= '1';
            addra <=  s_axi_user_regs_araddr;
        else
            arready <= '0';
        end if;
        
    end if;
end process;

write_data_proc : process (clk, aresetn)
begin
    if (aresetn = '0') then
         dina   <= (others => '0');
         wea    <= "0000";
         wready <= '0';
         bvalid <= '0';
    elsif rising_edge(clk) then
        if (s_axi_user_regs_wvalid ='1' and wready = '0')   then
            wea    <= "0000";
            wready <= '1';
            dina   <= s_axi_user_regs_wdata;
            bvalid <= '1';
        elsif (s_axi_user_regs_bready and bvalid) = '1' then
            bvalid <= '0';
            wea    <= "0000";
        else 
            wready <= '0';    
            wea    <= "0000";
        end if;
    end if;
end process;

--TODO: create fpga register interface. If a write to fpga reg, pass data on axi bus to appropriate register
--TODO: create reado only register space and read from fpga read only register and pass to axi bus 

s_axi_user_regs_arready <= arready;
s_axi_user_regs_rvalid  <= rvalid;
s_axi_user_regs_rdata   <= rdata;
s_axi_user_regs_rresp   <= "00";

/*read_addr_proc : process (clk, aresetn)
begin
    if (aresetn = '0') then
        arready <= '0';
        addra   <= (others => '0');
    elsif (rising_edge(clk)) then
        if (s_axi_user_regs_arvalid = '1' and arready = '0') then
            arready <= '1';
            addra <=  s_axi_user_regs_araddr;
        else
            arready <= '0';
        end if;
    
    end if;
end process;
*/
read_data_proc : process (clk, aresetn)
begin 
    if (aresetn ='0') then
        rdata  <= (others => '0');
        rvalid <= '0';
    elsif (rising_edge(clk)) then
        if arready = '1' then 
            rdata <= douta;
            rvalid <= '1';
        elsif ( s_axi_user_regs_rready and rvalid) ='1' then
            rvalid <= '0';
       end if;
    end if;
end process;
        
        
register_space_bram: blk_mem_gen_1
  PORT MAP(
     clka      => clk
    ,rsta      => rsta
    ,ena       => ena
    ,wea       => wea
    ,addra     => addra
    ,dina      => dina
    ,douta     => douta
    ,rsta_busy => rsta_busy
  );
end;
