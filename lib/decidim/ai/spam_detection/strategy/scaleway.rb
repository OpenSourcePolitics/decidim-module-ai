# frozen_string_literal: true

module Decidim
  module Ai
    module SpamDetection
      module Strategy
        # Scaleway third-party strategy
        # doc: https://www.scaleway.com/en/docs/managed-inference/quickstart/
        class Scaleway < ThirdParty
          # classify calls the third party AI system to classify content
          # @param content [String] Content to classify
          # @param organization_host [String] Decidim host
          # @param klass [String] Stringified klass of reportable
          # @return Integer
          def classify(content, organization_host, klass)
            system_log("classify - Classifying content with Scaleway's strategy...")
            res = third_party_request(content, organization_host, klass)
            body = parse_http_response(res)

            system_log("classify - HTTP response body : #{body}")
            content = third_party_content(body)

            raise InvalidOutputFormat, "Unexpected value received : '#{content}'. Expected to be in #{OUTPUT}" unless valid_output_format?(content)

            @category = content.downcase
            score
          rescue ThirdPartyError => e
            system_log("classify - Error: #{e.message}", level: :error)
            raise e
          end

          def third_party_request(content, organization_host, klass)
            uri = URI(@endpoint)

            payload = payload(content, klass).to_json
            system_log("third_party_request - HTTP Request payload: #{payload}")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            request = Net::HTTP::Post.new(uri.to_s, "Content-Type" => "application/json", "Accept" => "application/json")
            request["X-Auth-Token"] = @secret
            request["X-Host"] = organization_host
            request["X-Decidim-Host"] = organization_host
            request["X-Decidim"] = organization_host
            request["Host"] = organization_host

            request.body = payload

            http.request(request)
          rescue StandardError => e
            system_log("third_party_request - Error: #{e.message}", level: :error)
            system_log("third_party_request - HTTP : (url/#{@endpoint}) (Host/#{organization_host})", level: :error)
            raise ThirdPartyError, "Error during request to third party service: #{e.message}"
          end

          def parse_http_response(response)
            case response
            when Net::HTTPSuccess
              JSON.parse(response.body)
            when Net::HTTPForbidden
              raise Forbidden, "Access forbidden to the third party service. Check your API key or permissions."
            when Net::HTTPRequestTimeout, Net::HTTPGatewayTimeout
              raise TimeoutError, response.body || "Request timed out"
            when Net::HTTPServiceUnavailable
              raise InvalidEntity, response.body || "Service unavailable"
            else
              raise InvalidEntity, "Received unexpected response from third party service: #{response.body}"
            end
          end

          def third_party_content(body)
            return "" if body.blank?

            body.fetch("spam", "")
          end

          def payload(content, klass)
            {
              text: content,
              type: klass
            }
          end
        end
      end
    end
  end
end
