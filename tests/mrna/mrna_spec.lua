local plugin = require("mrna")

describe("setup", function()
  it("works with default", function()
    assert( plugin.hello() == "hi", "my first function with param = Hello!")
  end)

  it("works with custom var", function()
    plugin.setup({ opt = "custom" })
    assert("my first function with param = custom", plugin.hello())
  end)
end)
