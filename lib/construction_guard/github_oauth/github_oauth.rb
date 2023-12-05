# frozen_string_literal: true

require "net/http"
require "rest-client"

module ConstructionGuard::GithubOauth
  BASE_GITHUB_API_URL = "https://api.github.com"
  class << self
    #
    # <Description>
    #
    # @param [<Type>] access_token <description>
    #
    # @return [<Type>] <description>
    #
    def retrieve_user_details(access_token)
      uri = URI("#{BASE_GITHUB_API_URL}/user")

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

      parsed_response = ConstructionGuard.parse_response(response)
      p parsed_response
      p "You are #{parsed_response['email']}"
      parsed_response
    end

    #
    # Check organization membership for a user
    #
    # @param [<Type>] user_name <description>
    # @param [<Type>] token <description>
    #
    # @return [RestClient::Response] The response from the GitHub API containing membership details.
    #
    def retrieve_organization_membership(user_name, token)
      url = URI("#{BASE_GITHUB_API_URL}/orgs/#{ORGANIZATION}/members/#{user_name}").to_s

      headers = {
        "Accept" => "application/vnd.github+json",
        "X-GitHub-Api-Version" => "2022-11-28",
        "Authorization" => "Bearer #{token}"
      }
      RestClient.get(url, headers: headers)
    rescue RestClient::ExceptionWithResponse => e
      e.response
    end
  end
end
