use mlua::prelude::*;

fn main() -> LuaResult<()> {
    let lua = Lua::new();
    let g = lua.globals();
    g.set(
        "readfile",
        lua.create_function(|_, path: String| {
            std::fs::read_to_string(&path).map_err(|e| LuaError::external(format!("{path}: {e}")))
        })?,
    )?;
    g.set(
        "loadchunk",
        lua.create_function(|lua, (source, name, env): (String, String, LuaTable)| {
            lua.load(source).set_name(name).set_environment(env).into_function()
        })?,
    )?;
    for name in ["TEST_DIR", "CACHE_DIR", "SRC_DIR"] {
        g.set(name, std::env::var(name).unwrap_or_default())?;
    }
    let path = std::env::args().nth(1).expect("usage: luau-runner <script.luau>");
    let source = std::fs::read_to_string(&path).map_err(LuaError::external)?;
    lua.load(source).set_name(path).exec()
}
