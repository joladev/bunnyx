defmodule Bunnyx.S3.XML do
  @moduledoc false
  # Minimal XML parsing for S3 responses using Erlang's built-in :xmerl.
  @compile {:no_warn_undefined, [:xmerl_scan, :xmerl_xpath]}

  def parse_list_objects(xml) when is_binary(xml) do
    doc = parse(xml)

    %{
      contents:
        doc
        |> xpath_all(~c"//Contents")
        |> Enum.map(&parse_object/1),
      common_prefixes:
        doc
        |> xpath_all(~c"//CommonPrefixes")
        |> Enum.map(fn node -> xpath_text(node, ~c"./Prefix") end),
      is_truncated: xpath_text(doc, ~c"//IsTruncated") == "true",
      next_continuation_token: xpath_text(doc, ~c"//NextContinuationToken")
    }
  end

  def parse_copy_result(xml) when is_binary(xml) do
    doc = parse(xml)

    %{
      etag: xpath_text(doc, ~c"//ETag"),
      last_modified: xpath_text(doc, ~c"//LastModified")
    }
  end

  defp parse_object(node) do
    %{
      key: xpath_text(node, ~c"./Key"),
      last_modified: xpath_text(node, ~c"./LastModified"),
      etag: xpath_text(node, ~c"./ETag"),
      size:
        node
        |> xpath_text(~c"./Size")
        |> to_integer()
    }
  end

  defp parse(xml) do
    charlist = String.to_charlist(xml)
    {doc, _} = :xmerl_scan.string(charlist, quiet: true)
    doc
  end

  defp xpath_all(doc, path) do
    :xmerl_xpath.string(path, doc)
  end

  defp xpath_text(doc, path) do
    case :xmerl_xpath.string(path ++ ~c"/text()", doc) do
      [text_node | _] -> extract_text(text_node)
      [] -> nil
    end
  end

  defp extract_text({:xmlText, _, _, _, value, :text}), do: List.to_string(value)

  defp to_integer(nil), do: nil
  defp to_integer(str), do: String.to_integer(str)
end
