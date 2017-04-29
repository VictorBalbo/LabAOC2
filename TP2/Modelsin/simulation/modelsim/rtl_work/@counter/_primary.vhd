library verilog;
use verilog.vl_types.all;
entity Counter is
    port(
        clock           : in     vl_logic;
        clear           : in     vl_logic;
        Done            : in     vl_logic;
        \out\           : out    vl_logic_vector(1 downto 0)
    );
end Counter;
