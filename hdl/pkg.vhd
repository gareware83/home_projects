library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.all;

package pkg is 

constant C_REG_COUNT  : natural := 2;--update this every time you add a register 
constant C_ADDR_WIDTH : natural := 32;--always going to be 32 bit, but avoid magic numbers
constant C_DATA_WIDTH : natural := 32;

type fpgaReg32 is array (0 to C_REG_COUNT-1) of std_logic_vector(C_DATA_WIDTH-1 downto 0);

constant C_UART_BASE_ADDR    : unsigned(31 downto 0) := x"40600000";
constant C_AXI_BASE_ADDR     : unsigned(31 downto 0) := x"44A00000";
constant C_LED_CONTROL_ADDR  : unsigned(31 downto 0) := x"40600004";
constant C_LED_CONTROL_ADDR_IND : natural := 1;

function or_reduct(vec : std_logic_vector) return std_logic;
end pkg;

--define any functions prototyped in package
package body pkg is

function or_reduct(vec : std_logic_vector) return std_logic is
    variable result : std_logic := '0';
begin
    for i in vec'range loop 
        result := result or vec(i);
    end loop;
    return result;
end function;

end pkg;
