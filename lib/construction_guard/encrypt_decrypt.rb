# frozen_string_literal: true

require "openssl"

#
# <Description>
#
module ConstructionGuard
  class EncryptDecrypt
    class << self
      #
      # <Description>
      #
      # @param [<Type>] token <description>
      # @param [<Type>] key <description>
      #
      # @return [<Type>] <description>
      #
      def encrypt(token, key)
        cipher = OpenSSL::Cipher.new("AES-256-CBC")
        cipher.encrypt
        cipher.key = key
        # iv = cipher.random_iv
        encrypted_token = cipher.update(token) + cipher.final
        {encrypted_token: encrypted_token}
      end

      #
      # <Description>
      #
      # @param [<Type>] encrypted_data <description>
      # @param [<Type>] key <description>
      #
      # @return [<Type>] <description>
      #
      def decrypt(encrypted_data, key)
        decipher = OpenSSL::Cipher.new("AES-256-CBC")
        decipher.decrypt
        decipher.key = key
        # decipher.iv = encrypted_data[:iv]
        decipher.update(eval(encrypted_data)[:encrypted_token]) + decipher.final
      rescue StandardError => e
        ""
      end

      def secret_key_32_bytes(secret_key)
        sha256 = OpenSSL::Digest.new("SHA256")
        hash = OpenSSL::HMAC.digest(sha256, "secret_key", secret_key)
        hash[0, 32]
      end
    end
  end
end
