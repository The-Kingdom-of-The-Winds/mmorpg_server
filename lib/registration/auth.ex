defmodule Registration.Auth do
  def login(username, password) do
    # Just a dummy check for now...

    case {username, password} do
      {"Admin", "1234"} -> {:ok, 15}
      {"User2", "1234"} -> {:ok, 999_998}
      _ -> {:error, :wrong_password}
    end
  end

  def valid_resume?(token, _name, _player_id) do
    case token do
      "abc123456" -> {:ok}
      _ -> {:error}
    end
  end
end
