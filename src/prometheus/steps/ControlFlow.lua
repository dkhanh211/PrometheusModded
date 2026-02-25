-- ControlFlow.lua
local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local visitAst = require("prometheus.visitast");
local Scope = require("prometheus.scope");

local ControlFlow = Step:extend();
ControlFlow.Name = "ControlFlow";
ControlFlow.Description = "This step adds bogus control flow, mutations, and wraps statements to confuse readers and decompilers.";

function ControlFlow:init(settings) end

function ControlFlow:apply(ast, pipeline)
    local safeToWrap = {
        ["AssignmentStatement"] = true,
        ["FunctionCallStatement"] = true,
        ["DoStatement"] = true,
        ["WhileStatement"] = true,
        ["RepeatStatement"] = true,
        ["IfStatement"] = true,
        ["ForStatement"] = true,
        ["ForInStatement"] = true,
    }

    local function createOpaquePredicateFalse()
        -- (1 == 0)
        return Ast.EqualsExpression(Ast.NumberExpression(1), Ast.NumberExpression(0))
    end
    
    local function createOpaquePredicateTrue()
        -- (1 == 1)
        return Ast.EqualsExpression(Ast.NumberExpression(1), Ast.NumberExpression(1))
    end

    local function generateRandomArithmetic(depth)
        if depth <= 0 or math.random() > 0.7 then
            return Ast.NumberExpression(math.random(1, 100000))
        end
        local op = math.random(1, 5)
        local lhs = generateRandomArithmetic(depth - 1)
        local rhs = generateRandomArithmetic(depth - 1)
        if op == 1 then return Ast.AddExpression(lhs, rhs) end
        if op == 2 then return Ast.SubExpression(lhs, rhs) end
        if op == 3 then return Ast.MulExpression(lhs, rhs) end
        if op == 4 then return Ast.DivExpression(lhs, rhs) end
        if op == 5 then return Ast.ModExpression(lhs, rhs) end
    end

    local function generateJunkCode(scope, depth)
        depth = depth or 0
        if depth > 1 then return {} end

        local statements = {};
        for i = 1, math.random(1, 3) do
            local type = math.random(1, 6);
            if type == 1 then
                -- fake number
                local id = scope:addVariable();
                table.insert(statements, Ast.LocalVariableDeclaration(scope, {id}, {generateRandomArithmetic(2)}));
            elseif type == 2 then
                -- fake local
                local id = scope:addVariable();
                local str = "";
                for k = 1, math.random(10, 40) do
                    str = str .. string.char(math.random(1, 255));
                end
                table.insert(statements, Ast.LocalVariableDeclaration(scope, {id}, {Ast.StringExpression(str)}));
            elseif type == 3 then
                -- do ... end
                local s = Scope:new(scope);
                table.insert(statements, Ast.DoStatement(Ast.Block(generateJunkCode(s, depth + 1), s)));
            elseif type == 4 then
                -- function
                local s = Scope:new(scope);
                local id = scope:addVariable();
                table.insert(statements, Ast.LocalFunctionDeclaration(scope, id, {}, Ast.Block(generateJunkCode(s, depth + 1), s)));
            elseif type == 5 then
                -- while
                local s = Scope:new(scope);
                table.insert(statements, Ast.WhileStatement(Ast.Block(generateJunkCode(s, depth + 1), s), Ast.BooleanExpression(false), scope));
            elseif type == 6 then
                -- for
                local s = Scope:new(scope);
                local id = s:addVariable();
                table.insert(statements, Ast.ForStatement(s, id, Ast.NumberExpression(1), Ast.NumberExpression(10), Ast.NumberExpression(1), Ast.Block(generateJunkCode(s, depth + 1), s), scope));
            end
        end
        return statements;
    end

    visitAst(ast, nil, function(node, data)
        if node.kind == Ast.AstKind.AddExpression and math.random() < 0.5 then
             -- a + b -> a - (-b)
             return Ast.SubExpression(node.lhs, Ast.NegateExpression(node.rhs));
        elseif node.kind == Ast.AstKind.SubExpression and math.random() < 0.5 then
             -- a - b -> a + (-b)
             return Ast.AddExpression(node.lhs, Ast.NegateExpression(node.rhs));
        end

        if safeToWrap[node.kind] then
            local r = math.random()
            if r < 0.2 then
                 local doScope = Scope:new(data.scope);
                 local block = Ast.Block({ node }, doScope);
                 local doStmt = Ast.DoStatement(block);
                 return doStmt;
            elseif r < 0.35 then
                local junkScope = Scope:new(data.scope);
                local junkBlock = Ast.Block(generateJunkCode(junkScope), junkScope);
                local realScope = Scope:new(data.scope);
                local realBlock = Ast.Block({node}, realScope);
                return Ast.IfStatement(createOpaquePredicateFalse(), junkBlock, {}, realBlock);
            elseif r < 0.5 then
                 local realScope = Scope:new(data.scope);
                 local realBlock = Ast.Block({node}, realScope);
                 local junkScope = Scope:new(data.scope);
                 local junkBlock = Ast.Block(generateJunkCode(junkScope), junkScope);
                 return Ast.IfStatement(createOpaquePredicateTrue(), realBlock, {}, junkBlock);
            end
        end
    end)
    return ast;
end

return ControlFlow
