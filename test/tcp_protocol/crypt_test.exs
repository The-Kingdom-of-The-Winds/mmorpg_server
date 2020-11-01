defmodule TCPProtocol.CryptTest do
  use ExUnit.Case
  alias TCPProtocol.Crypt

  # describe "static_key/3" do
  #   test "encrypts the data with specified key" do
  #     data = "The quick brown fox jumps over the lazy dog"
  #     key = "KeyKeyKey" |> to_charlist()

  #     encrypted =
  #       <<30, 12, 29, 106, 21, 13, 35, 7, 19, 106, 6, 10, 37, 19, 22, 106, 2, 23, 48, 70, 16, 61, 11, 10, 59, 70, 21,
  #         63, 2, 9, 105, 19, 19, 44, 71, 23, 47, 26, 5, 110, 4, 19, 41>>

  #     assert encrypted == Crypt.static_key(data, 1, key)
  #   end
  # end

  # describe "static_key_fast/3" do
  #   test "encrypts the data with specified key" do
  #     data = "The quick brown fox jumps over the lazy dog"
  #     key = "KeyKeyKey"

  #     encrypted =
  #       <<30, 12, 29, 106, 21, 13, 35, 7, 19, 106, 6, 10, 37, 19, 22, 106, 2, 23, 48, 70, 16, 61, 11, 10, 59, 70, 21,
  #         63, 2, 9, 105, 19, 19, 44, 71, 23, 47, 26, 5, 110, 4, 19, 41>>

  #     assert encrypted == Crypt.static_key_fast(data, 1, key)
  #   end

  #   test "matches slow encryption" do
  #     data = String.duplicate("The quick brown fox jumps over the lazy dog", 20)
  #     key = "KeyKeyKey"

  #     assert Crypt.static_key(data, 1, key |> to_charlist()) == Crypt.static_key_fast(data, 1, key)
  #   end

  #   test "matches slow encryption over group 255" do
  #     data = String.duplicate("The quick brown fox jumps over the lazy dog", 200)
  #     key = "KeyKeyKey"

  #     assert Crypt.static_key(data, 1, key |> to_charlist()) == Crypt.static_key_fast(data, 1, key)
  #   end
  # end

  describe "encode_iv/1" do
    test "encrypts the iv" do
      assert ".$t" == Crypt.encode_iv({5, 10})
    end
  end

  describe "derive_iv_from_rand/0" do
    test "generates a random iv" do
      {iv_1, iv_2} = Crypt.derive_iv_from_rand()
      assert Enum.member?(100..254, iv_1)
      assert Enum.member?(256..65532, iv_2)
    end
  end

  describe "derive_iv_from_trailer/1" do
    test "extracts the trailer" do
      assert {32, 9573} = Crypt.derive_iv_from_trailer(<<1, 2, 3, 4, 5, 6>>)
    end
  end
end
