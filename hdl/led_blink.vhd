----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/19/2024 07:58:29 PM
-- Design Name: 
-- Module Name: led_blink - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


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

entity led_blink is
    Generic(
        G_SIMULATE : boolean := false;
        G_USE_REGS : boolean := true
    );
    Port ( clk         : in STD_LOGIC;
           aresetn     : in STD_LOGIC;
           button_in   : in STD_LOGIC:='0';
           control_reg : in std_logic_vector(31 downto 0);
           buffer_led: out STD_LOGIC:='0');
end led_blink;



architecture Behavioral of led_blink is

signal counter_limit : integer := 0;

type state_type is (reset_state, first_press, blink_on, blink_off, blink_hold);
signal state, next_state : state_type;

signal buffer_button_r  :std_logic;
signal buffer_button_rr :std_logic;
signal buffer_button_rrr :std_logic;
signal start_blink  : std_logic;
signal blink_led    : std_logic;
signal button_count : integer ;
signal counter_led  : integer ;


begin

counter_limit <= 5000 when G_SIMULATE = true else 100000000;

gen_use_register : if G_USE_REGS generate
    ctrl_reg_blink : process(clk, aresetn)
    begin
        if (aresetn = '0') then
            blink_led        <='0';
            button_count     <= 0;
            state            <= reset_state;
            counter_led      <= 0;
            start_blink      <= '0';               
        elsif (rising_edge(clk)) then
            if control_reg(0)= '1' then
                if counter_led <= counter_limit  then
                    counter_led <= counter_led + 1;
                    blink_led <= '1';                                  
                elsif counter_led > counter_limit and counter_led < counter_limit*2 then
                   counter_led <=  counter_led + 1;
                   blink_led   <= '0'; 
                else 
                    counter_led <=  0;   
                end if;                                 
            end if;        
        end if;
    end process;
end generate;   

gen_use_button : if not G_USE_REGS generate
    button_blink : process(clk, aresetn)   
    begin
        if (aresetn = '0') then
            blink_led        <='0';
            button_count     <= 0;
            state            <= reset_state;
            counter_led      <= 0;
            buffer_button_r  <= '1';
            buffer_button_rr <= '1';
            buffer_button_rrr <= '1';
            start_blink      <= '0';       
            
        elsif (rising_edge(clk)) then
           
            buffer_button_r    <= button_in;
            buffer_button_rr   <= buffer_button_r;
            buffer_button_rrr  <= buffer_button_rr;
            if buffer_button_rrr = '0' then
                start_blink <= '1';
            end if; 
            if start_blink = '1' then
                if counter_led <= counter_limit  then
                    counter_led <= counter_led + 1;
                    blink_led <= '1';                                  
                elsif counter_led > counter_limit and counter_led < counter_limit*2 then
                   counter_led <=  counter_led + 1;
                   blink_led   <= '0'; 
                else 
                    counter_led <=  0;   
                end if;                                 
            end if;
            
        end if;
    end process;
end generate;   

 
 
 obuf_inst : OBUF
 port map
    (I => blink_led,
     O => buffer_led
    );
 

end Behavioral;
