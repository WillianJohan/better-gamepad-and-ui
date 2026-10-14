-- tests/run_all.lua — harness de lógica pura (fora do jogo)
package.path = package.path
  .. ";../mod/42/media/lua/shared/?.lua"
  .. ";../mod/42/media/lua/shared/?/?.lua"
  .. ";../mod/42/media/lua/client/?.lua"
  .. ";../mod/42/media/lua/client/?/?.lua"
  .. ";./?.lua"

local failed = 0
local function run(file)
  print("==> " .. file)
  local ok, err = pcall(function()
    dofile(file)
  end)
  if not ok then
    failed = failed + 1
    print("FAIL: " .. tostring(err))
  else
    print("OK")
  end
end

local tests = {
  "test_input_router.lua",
  "test_focus_stack.lua",
  "test_category_filter.lua",
  "test_radial_slice.lua",
  "test_button_legend.lua",
  "test_ui_shell.lua",
  "test_dual_pane.lua",
  "test_radial_hub.lua",
  "test_radial_satellites.lua",
  "test_dualsense_policy.lua",
}
for _, t in ipairs(tests) do
  local f = io.open(t, "r")
  if f then
    f:close()
    run(t)
  else
    print("SKIP (missing): " .. t)
  end
end

if failed > 0 then
  os.exit(1)
end
print("ALL PRESENT TESTS PASSED")
