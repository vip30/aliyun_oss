defmodule Aliyun.Oss.Object do
  @moduledoc """
  Object 相关操作
  """

  import Aliyun.Oss.Config, only: [endpoint: 0, access_key_id: 0]

  alias Aliyun.Oss.Client
  alias Aliyun.Oss.Client.{Request, Response, Error}

  @type error() :: Error.t() | atom()

  @doc """
  GetObject 用于获取某个 Object

  ## Examples

      iex> Aliyun.Oss.Object.get_object("some-bucket", "some-object")
      {:ok, %Aliyun.Oss.Client.Response{
          data: <<208, 207, 17, 224, 161, 177, 26, 225, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 62, 0, 3, 0, 254, 255, 9, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 18,
            0, 0, 0, ...>>,
          headers: [
            {"Date", "Wed, 05 Dec 2018 02:34:57 GMT"},
            ...
          ]
        }
      }


  亦可用于获取某个 Object 指定 SubResource(GetObjectXXX)。

  ## Examples

      iex> Aliyun.Oss.Object.get_object("some-bucket", "some-object", %{}, %{"acl" => nil})
      {:ok, %Aliyun.Oss.Client.Response{
        data: %{
          "AccessControlPolicy" => %{
            "AccessControlList" => %{"Grant" => "default"},
            "Owner" => %{
              "DisplayName" => "1111111111111111",
              "ID" => "1111111111111111"
            }
          }
        },
        headers: [
          {"Date", "Wed, 05 Dec 2018 02:34:57 GMT"}
        ]
      }
  """
  @spec get_object(String.t(), String.t(), map(), map()) ::
          {:error, error()} | {:ok, Response.t()}
  def get_object(bucket, object, headers \\ %{}, sub_resources \\ %{}) do
    Client.request(%{
      verb: "GET",
      host: "#{bucket}.#{endpoint()}",
      path: "/#{object}",
      headers: headers,
      resource: "/#{bucket}/#{object}",
      query_params: %{},
      sub_resources: sub_resources
    })
  end

  @doc """
  GetObjectACL 用来获取某个Bucket下的某个Object的访问权限。

  ## Examples

      iex> Aliyun.Oss.Object.get_object_acl("some-bucket", "some-object")
      {:ok, %Aliyun.Oss.Client.Response{
        data: %{
          "AccessControlPolicy" => %{
            "AccessControlList" => %{"Grant" => "default"},
            "Owner" => %{
              "DisplayName" => "1111111111111111",
              "ID" => "1111111111111111"
            }
          }
        },
        headers: [
          {"Date", "Wed, 05 Dec 2018 02:34:57 GMT"}
        ]
      }
  """
  @spec get_object_acl(String.t(), String.t()) :: {:error, error()} | {:ok, Response.t()}
  def get_object_acl(bucket, object) do
    get_object(bucket, object, %{}, %{"acl" => nil})
  end

  @doc """
  HeadObject只返回某个Object的meta信息，不返回文件内容。

  ## Examples

      iex> Aliyun.Oss.Object.head_object("some-bucket", "some-object")
      {:ok,
      %Aliyun.Oss.Client.Response{
        data: "",
        headers: [
          {"Server", "AliyunOSS"},
          {"Date", "Wed, 05 Dec 2018 05:50:02 GMT"},
          {"Content-Type", "application/octet-stream"},
          {"Content-Length", "0"},
          {"Connection", "keep-alive"},
          {"x-oss-request-id", "5C0000000000000000000000"},
          {"Accept-Ranges", "bytes"},
          {"ETag", "\"D4100000000000000000000000000000\""},
          {"Last-Modified", "Mon, 15 Oct 2018 01:38:47 GMT"},
          {"x-oss-object-type", "Normal"},
          {"x-oss-hash-crc64ecma", "0"},
          {"x-oss-storage-class", "IA"},
          {"Content-MD5", "1B2M2Y8AsgTpgAmY7PhCfg=="},
          {"x-oss-server-time", "19"}
        ]
      }}
      iex> Aliyun.Oss.Object.head_object("some-bucket", "unknown-object")
      {:error, %Aliyun.Oss.Client.Error{status_code: 404, body: "", parsed_details: nil}}
  """
  @spec head_object(String.t(), String.t(), map()) :: {:error, error()} | {:ok, Response.t()}
  def head_object(bucket, object, headers \\ %{}) do
    Client.request(%{
      verb: "HEAD",
      host: "#{bucket}.#{endpoint()}",
      path: "/#{object}",
      headers: headers,
      resource: "/#{bucket}/#{object}",
      query_params: %{},
      sub_resources: %{}
    })
  end

  @doc """
  生成包含签名的 URL

  ## Examples

      iex> expires = Timex.now() |> Timex.shift(days: 1) |> Timex.to_unix()
      iex> Aliyun.Oss.Object.object_url("some-bucket", "some-object", expires)
      "http://oss-example.oss-cn-hangzhou.aliyuncs.com/oss-api.pdf?OSSAccessKeyId=nz2pc56s936**9l&Expires=1141889120&Signature=vjbyPxybdZaNmGa%2ByT272YEAiv4%3D"
  """
  @spec object_url(String.t(), String.t(), integer()) :: String.t()
  def object_url(bucket, object, expires) do
    signature =
      Request.gen_signature(%Request{
        verb: "GET",
        host: "#{bucket}.#{endpoint()}",
        path: "",
        resource: "/#{bucket}/#{object}",
        query_params: %{},
        sub_resources: %{},
        headers: %{
          "Date" => Integer.to_string(expires),
          "Content-Type" => ""
        }
      })

    URI.to_string(%URI{
      scheme: "https",
      host: "#{bucket}.#{endpoint()}",
      path: "/#{object}",
      query:
        URI.encode_query(%{
          "Expires" => expires,
          "OSSAccessKeyId" => access_key_id(),
          "Signature" => signature
        })
    })
  end

  @doc """
  PutObject接口用于上传文件（Object）。
   - 添加的文件大小不得超过5 GB。
   - 如果已经存在同名的Object，并且有访问权限，则新添加的文件将覆盖原来的文件，并成功返回200 OK。

  ## Examples

      iex> Aliyun.Oss.Object.put_object("some-bucket", "some-object", "CONTENT")
      {:ok, %Aliyun.Oss.Client.Response{
          data: "",
          headers: [
            {"Server", "AliyunOSS"},
            {"Date", "Wed, 05 Dec 2018 02:34:57 GMT"},
            ...
          ]
        }
      }
  """
  @spec put_object(String.t(), String.t(), String.t(), map(), map()) :: {:error, error()} | {:ok, Response.t()}
  def put_object(bucket, object, body, headers \\ %{}, sub_resources \\ %{}) do
    Client.request(%{
      verb: "PUT",
      host: "#{bucket}.#{endpoint()}",
      path: "/#{object}",
      headers: headers,
      resource: "/#{bucket}/#{object}",
      query_params: %{},
      sub_resources: sub_resources,
      body: body
    })
  end


  @doc """
  PutObjectACL接口用于修改Object的访问权限。

  ## Examples

      iex> Aliyun.Oss.Object.put_object_acl("some-bucket", "some-object", "private")
      {:ok, %Aliyun.Oss.Client.Response{
          data: "",
          headers: [
            {"Server", "AliyunOSS"},
            {"Date", "Wed, 05 Dec 2018 02:34:57 GMT"},
            ...
          ]
        }
      }
  """
  @spec put_object_acl(String.t(), String.t(), String.t()) :: {:error, error()} | {:ok, Response.t()}
  def put_object_acl(bucket, object, acl) do
    put_object(bucket, object, "", %{"x-oss-object-acl" => acl}, %{"acl" => nil})
  end
end
