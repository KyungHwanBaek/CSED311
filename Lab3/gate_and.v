module gate_and(input in_1,
                input in_2,
                output reg out);

always @(*) begin
    out = (in_1 & in_2);
end

endmodule
