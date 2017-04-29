library verilog;
use verilog.vl_types.all;
entity ALU is
    port(
        a               : in     vl_logic_vector(15 downto 0);
        b               : in     vl_logic_vector(15 downto 0);
        operacao        : in     vl_logic_vector(2 downto 0);
        Gin             : in     vl_logic;
        Clock           : in     vl_logic;
        result          : out    vl_logic_vector(15 downto 0)
    );
end ALU;
