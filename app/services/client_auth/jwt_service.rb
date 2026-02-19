module ClientAuth
  class JwtService
    ALGORITHM = "HS256".freeze

    class << self
      def encode(client_user)
        payload = {
          sub: client_user.id,
          client_id: client_user.client_id,
          role: client_user.role,
          type: "client",
          iat: Time.current.to_i,
          exp: 7.days.from_now.to_i
        }

        JWT.encode(payload, secret_key, ALGORITHM)
      end

      def decode(token)
        decoded, = JWT.decode(token, secret_key, true, { algorithm: ALGORITHM })
        decoded.with_indifferent_access
      rescue JWT::DecodeError
        nil
      end

      private

      def secret_key
        ENV.fetch("DEVISE_JWT_SECRET_KEY") { Rails.application.secret_key_base }
      end
    end
  end
end
