defmodule Bunnyx.CountryTest do
  use ExUnit.Case, async: true
  use Mimic

  setup do
    %{client: Bunnyx.new(api_key: "sk-test")}
  end

  describe "list/1" do
    test "returns parsed countries", %{client: client} do
      response = [
        %{
          "Name" => "Germany",
          "IsoCode" => "DE",
          "IsEU" => true,
          "TaxRate" => 19.0,
          "TaxPrefix" => "DE",
          "FlagUrl" => "https://example.com/de.png",
          "PopList" => ["fra1", "fra2"]
        }
      ]

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/country", _opts ->
        {:ok, response}
      end)

      assert {:ok, [country]} = Bunnyx.Country.list(client)
      assert country.name == "Germany"
      assert country.iso_code == "DE"
      assert country.is_eu == true
      assert country.pop_list == ["fra1", "fra2"]
    end

    test "returns error on failure", %{client: client} do
      error = %Bunnyx.Error{status: 500, message: "Server error"}

      expect(Bunnyx.HTTP, :request, fn _req, :get, "/country", _opts ->
        {:error, error}
      end)

      assert {:error, ^error} = Bunnyx.Country.list(client)
    end
  end
end
