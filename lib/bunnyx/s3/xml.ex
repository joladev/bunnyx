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

  def parse_initiate_multipart(xml) when is_binary(xml) do
    doc = parse(xml)
    %{upload_id: xpath_text(doc, ~c"//UploadId")}
  end

  def parse_list_parts(xml) when is_binary(xml) do
    doc = parse(xml)

    %{
      parts:
        doc
        |> xpath_all(~c"//Part")
        |> Enum.map(&parse_part/1),
      is_truncated: xpath_text(doc, ~c"//IsTruncated") == "true"
    }
  end

  def parse_complete_multipart(xml) when is_binary(xml) do
    doc = parse(xml)

    %{
      etag: xpath_text(doc, ~c"//ETag"),
      key: xpath_text(doc, ~c"//Key")
    }
  end

  def parse_list_multipart_uploads(xml) when is_binary(xml) do
    doc = parse(xml)

    %{
      uploads:
        doc
        |> xpath_all(~c"//Upload")
        |> Enum.map(&parse_upload/1),
      is_truncated: xpath_text(doc, ~c"//IsTruncated") == "true"
    }
  end

  def build_complete_body(parts) do
    parts_xml =
      Enum.map_join(parts, fn %{part_number: n, etag: etag} ->
        "<Part><PartNumber>#{n}</PartNumber><ETag>#{etag}</ETag></Part>"
      end)

    "<CompleteMultipartUpload>#{parts_xml}</CompleteMultipartUpload>"
  end

  defp parse_part(node) do
    %{
      part_number:
        node
        |> xpath_text(~c"./PartNumber")
        |> to_integer(),
      etag: xpath_text(node, ~c"./ETag"),
      size:
        node
        |> xpath_text(~c"./Size")
        |> to_integer()
    }
  end

  defp parse_upload(node) do
    %{
      key: xpath_text(node, ~c"./Key"),
      upload_id: xpath_text(node, ~c"./UploadId")
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

    {doc, _} =
      :xmerl_scan.string(charlist,
        quiet: true,
        acc_fun: &xmerl_acc/3,
        fetch_fun: &xmerl_fetch/2
      )

    doc
  end

  # Disable external entity fetching to prevent XXE attacks.
  defp xmerl_fetch(_uri, state), do: {:ok, {:string, ~c""}, state}

  # Default accumulator — required when overriding fetch_fun.
  defp xmerl_acc(parsed, acc, state), do: {[parsed | acc], state}

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
