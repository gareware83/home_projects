library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



package pkg is 

constant C_REG_COUNT  : natural := 3;--update this every time you add a register 
constant C_ADDR_WIDTH : natural := 32;--always going to be 32 bit, but avoid magic numbers

type fpgaReg32 is array (0 to C_REG_COUNT-1) of std_logic_vector(C_ADDR_WIDTH-1 downto 0);

constant C_AXI_BASE_ADDR     : std_logic_vector(31 downto 0) := x"44A00000";
constant C_UART_BASE_ADDR    : std_logic_vector(31 downto 0) := x"40600000";
constant C_LED_CONTROL_ADDR  : std_logic_vector(31 downto 0) := x"40600004";

end pkg;

--define any functions prototyped in package
package body pkg is

end pkg;
