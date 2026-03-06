defmodule BunnyxTest do
  use ExUnit.Case, async: true

  describe "new/1" do
    test "builds client with api_key" do
      client = Bunnyx.new(api_key: "sk-test")

      assert %Bunnyx{req: %Req.Request{}} = client
      assert Req.Request.get_header(client.req, "accesskey") == ["sk-test"]
    end

    test "raises on missing api_key" do
      assert_raise KeyError, fn -> Bunnyx.new([]) end
    end

    test "accepts custom finch pool" do
      client = Bunnyx.new(api_key: "sk-test", finch: MyFinch)

      assert client.req.options.finch == MyFinch
    end
  end

  describe "resolve/1" do
    test "passes through a struct" do
      client = Bunnyx.new(api_key: "sk-test")
      assert Bunnyx.resolve(client) == client
    end

    test "builds from keyword list" do
      client = Bunnyx.resolve(api_key: "sk-test")
      assert %Bunnyx{req: %Req.Request{}} = client
    end
  end
end
