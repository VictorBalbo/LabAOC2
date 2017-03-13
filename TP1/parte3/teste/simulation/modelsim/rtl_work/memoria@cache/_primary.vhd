library verilog;
use verilog.vl_types.all;
entity memoriaCache is
    port(
        clock           : in     vl_logic;
        address         : in     vl_logic_vector(7 downto 0);
        dataIn          : in     vl_logic_vector(7 downto 0);
        write           : in     vl_logic;
        dataOut         : out    vl_logic_vector(7 downto 0);
        hit             : out    vl_logic
    );
end memoriaCache;
