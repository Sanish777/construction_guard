# frozen_string_literal: true

require "net/http"
require "json"
require "rest-client"
require "dotenv/load"

module GithubAuthentication
  #
  # Handles authentication
  #
  module GithubAppAuth
    GITHUB_APP_CLIENT_ID = ENV["GITHUB_APP_CLIENT_ID"]
    GITHUB_APP_CLIENT_SECRET = ENV["GITHUB_APP_CLIENT_SECRET"]
    GITHUB_ORG = ENV["GITHUB_ORGANIZATION"]

    class << self
      #
      # Parses the response body
      #
      # @param [<Type>] response <description>
      #
      # @return [<Type>] <description>
      #
      def parse_response(response)
        case response
        when Net::HTTPOK, Net::HTTPCreated
          JSON.parse(response.body)
        else
          ConstructionGuard::LOGGER.info(" Response #{response}")
          ConstructionGuard::LOGGER.info(" Response #{response.body}")
          # puts response.body
          nil
        end
      end

      #
      # <Description>
      #
      # @return [<Type>] <description>
      #
      def request_device_code
        uri = URI("https://github.com/login/device/code")
        parameters = URI.encode_www_form("client_id" => GITHUB_APP_CLIENT_ID)
        headers = {"Accept" => "application/json"}
        response = Net::HTTP.post(uri, parameters, headers)
        parse_response(response)
      end

      #
      # <Description>
      #
      # @param [<Type>] device_code <description>
      #
      # @return [<Type>] <description>
      #
      def request_token(device_code)
        uri = URI("https://github.com/login/oauth/access_token")
        parameters = URI.encode_www_form({
                                           "client_id" => GITHUB_APP_CLIENT_ID,
                                           "device_code" => device_code,
                                           "grant_type" => "urn:ietf:params:oauth:grant-type:device_code"
                                         })
        headers = {"Accept" => "application/json"}
        response = Net::HTTP.post(uri, parameters, headers)
        parse_response(response)
      end

      #
      # <Description>
      #
      # @param [<Type>] device_code <description>
      # @param [<Type>] interval <description>
      #
      # @return [String] access token
      #
      def poll_for_token(device_code, interval)
        access_token = nil

        loop do
          response = request_token(device_code)
          error, access_token = response.values_at("error", "access_token")
          if error
            case error
            when "authorization_pending"
              # The user has not yet entered the code.
              # Wait, then poll again.
              sleep interval
              next
            when "slow_down"
              # The app polled too fast.
              # Wait for the interval plus 5 seconds, then poll again.
              sleep interval + 5
              next
            when "expired_token"
              # The `device_code` expired, and the process needs to restart.
              puts "The device code has expired. Please run `login` again."
              exit 1
            when "access_denied"
              # The user cancelled the process. Stop polling.
              puts "Login cancelled by user."
              exit 1
            else
              puts response
              exit 1
            end
          end
          break
        end
        access_token
      end

      #
      # <Description>
      #
      # @param [<Type>] access_token <description>
      #
      # @return [<Type>] <description>
      #
      def retrieve_user_details(access_token)
        uri = URI("https://api.github.com/user")

        # begin
        #   token = File.read("./.token").strip
        # rescue Errno::ENOENT => e
        #   puts "You are not authorized. Run the `login` command."
        #   exit 1
        # end

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          body = {"access_token" => access_token}.to_json
          headers = {
            "Accept" => "application/vnd.github+json",
            "X-GitHub-Api-Version" => "2022-11-28",
            "Authorization" => "Bearer #{access_token}"
          }

          http.send_request("GET", uri.path, body, headers)
        end

        parsed_response = parse_response(response)
        p parsed_response
        puts "You are #{parsed_response['email']}"
        parsed_response
      end

      #
      # <Description>
      #
      # @return [<Type>] <description>
      #
      def login
        verification_uri, user_code, device_code, interval =
          request_device_code.values_at("verification_uri",
                                        "user_code", "device_code", "interval")

        ConstructionGuard::LOGGER.info("Please visit: #{verification_uri}")
        ConstructionGuard::LOGGER.info("and enter code: #{user_code}")

        access_token = poll_for_token(device_code, interval)

        ConstructionGuard::LOGGER.info("Successfully authenticated!") if access_token
        access_token
      end

      #
      # Check organization membership for a user
      #
      # @param [String] user <description>
      # @param [String] access_token <description>
      #
      # @return [<Type>] <description>
      #
      # def retrieve_organization_membership(user, access_token)
      #   uri = URI("https://api.github.com/orgs/#{GITHUB_ORG}/members/#{user}")

      #   # Create an HTTP object
      #   http = Net::HTTP.new(uri.host, uri.port)
      #   http.use_ssl = (uri.scheme == "https")

      #   # Set the headers using add_field
      #   headers = {
      #     "Accept" => "application/vnd.github+json",
      #     "X-GitHub-Api-Version" => "2022-11-28",
      #     "Authorization" => "Bearer #{access_token}"
      #   }

      #   # Create a GET request object
      #   request = Net::HTTP::Get.new(uri.path, headers)

      #   headers.each { |key, value| request.add_field(key, value) }

      #   # Send the request and get the response
      #   http.request(request)
      # end

      #
      # Check organization membership for a user
      #
      # @param [<Type>] user_name <description>
      # @param [<Type>] token <description>
      #
      # @return [RestClient::Response] The response from the GitHub API containing membership details.
      #
      def retrieve_organization_membership(user_name, token)
        url = URI("https://api.github.com/orgs/#{GITHUB_ORG}/members/#{user_name}").to_s

        headers = {
          "Accept" => "application/vnd.github+json",
          "X-GitHub-Api-Version" => "2022-11-28",
          "Authorization" => "Bearer #{token}"
        }

        RestClient.get(url, headers: headers)
      end
    end
  end
end
