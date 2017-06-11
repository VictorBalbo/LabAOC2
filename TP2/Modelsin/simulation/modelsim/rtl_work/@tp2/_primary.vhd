library verilog;
use verilog.vl_types.all;
entity Tp2 is
    port(
        SW              : in     vl_logic_vector(17 downto 0);
        LEDR            : in     vl_logic_vector(17 downto 0);
        KEY             : in     vl_logic_vector(1 downto 0)
    );
end Tp2;
