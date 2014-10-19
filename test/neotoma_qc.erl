-module(neotoma_qc).
-include("neotoma.hrl").
-ifdef(EQC).
-include_lib("eqc/include/eqc.hrl").
-compile(export_all).

prop_peephole_equiv() ->
    %% The peephole optimizer should not add or change existing errors in the 
    ?FORALL(G, grammar(),
            begin
                Normal = neotoma_analyze:analyze(G),
                PeepOpt = neotoma_peephole:optimize(G),
                case Normal of
                    {ok, _G0} ->
                        case neotoma_analyze:analyze(PeepOpt) of
                            {ok, _G1} -> true;
                            _ -> false
                        end;
                    Errs ->
                        equals(Errs, neotoma_analyze:analyze(PeepOpt))
                end
            end).

%% Grammar generator
grammar() ->
    #grammar{declarations=non_empty(list(declaration())),
             code = code()}.

declaration() ->        
    #declaration{name = name(), 
                 expr = expr(), 
                 code = code(),
                 index = index()}.

name() ->
    elements([a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z]).

index() ->
    {{line, nat()}, {column, nat()}}.

code() ->
    %% TODO
    undefined.

expr() ->
    ?SIZED(Size, expr(Size)).

expr(Size) ->
    oneof([primary(Size),
           choice(Size),
           sequence(Size)]).

sequence(Size) ->
    #sequence{exprs = non_empty(list(primary(Size div 2))),
              index = index()}.

choice(Size) ->
    #choice{alts=non_empty(list(oneof([sequence(Size div 2), primary(Size div 2)]))),
            index = index()}.

primary(Size) ->
    Expr = oneof([terminal(),
                  nonterminal()] ++ 
                 [expr(Size div 2) || Size > 1]),
    #primary{expr = Expr,
             label = undefined,
             modifier = modifier(),
             index = index()}.

terminal() ->
    oneof([string(), regexp(), charclass(), anything()]).

nonterminal() ->
    #nonterminal{name = name(), index = index()}.

string() ->
    #string{string = non_empty(list(char())),
            index = index()}.

regexp() ->
    #regexp{regexp = non_empty(list(char())),
            index = index()}.

charclass() ->
    #charclass{charclass = non_empty(list(char())),
               index = index()}.

anything() ->
    #anything{index = index()}.

epsilon() ->
    #epsilon{index = index()}.

modifier() ->
    elements([undefined, 
              one_or_more, 
              zero_or_more,
              optional,
              assert,
              deny]).
-endif.