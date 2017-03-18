library verilog;
use verilog.vl_types.all;
entity RAM_parte2 is
    port(
        SW              : in     vl_logic_vector(14 downto 0);
        HEX0            : out    vl_logic_vector(0 to 6);
        HEX1            : out    vl_logic_vector(0 to 6);
        HEX4            : out    vl_logic_vector(0 to 6);
        HEX5            : out    vl_logic_vector(0 to 6);
        HEX6            : out    vl_logic_vector(0 to 6);
        HEX7            : out    vl_logic_vector(0 to 6);
        LEDG            : out    vl_logic_vector(0 downto 0)
    );
end RAM_parte2;
