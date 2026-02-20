defmodule ManaWeb.ServiceControllerTest do
  use ManaWeb.ConnCase, async: true

  describe "GET /version" do
    test "returns version information", %{conn: conn} do
      conn = get(conn, ~p"/version")

      assert %{"sha" => sha} = json_response(conn, 200)
      assert is_binary(sha)
      assert String.length(sha) > 0
    end
  end

  describe "GET /healthz" do
    test "returns 200 and db connected", %{conn: conn} do
      conn = get(conn, ~p"/healthz")

      assert json_response(conn, 200) == %{
               "status" => "ok",
               "database" => "connected"
             }
    end
  end
end
