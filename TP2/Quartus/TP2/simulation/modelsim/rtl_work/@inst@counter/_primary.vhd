library verilog;
use verilog.vl_types.all;
entity InstCounter is
    port(
        MClock          : in     vl_logic;
        Resetn          : in     vl_logic;
        \out\           : out    vl_logic_vector(4 downto 0)
    );
end InstCounter;
