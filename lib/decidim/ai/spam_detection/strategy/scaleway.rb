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
            system_log("Starting classification with Scaleway's strategy...")
            res = third_party_request(content, organization_host, klass)
            body = JSON.parse(res.body)

            system_log("Received response from third party service: #{body}")
            raise InvalidEntity, body unless res.is_a? Net::HTTPSuccess

            content = third_party_content(body)
            raise InvalidOutputFormat, "Third party service response isn't valid JSON" unless valid_output_format?(content)

            @category = content.downcase
            score
          rescue InvalidEntity, InvalidOutputFormat => e
            system_log(e.message, level: :error)
            score
          end

          def third_party_request(content, organization_host, klass)
            # TODO: Prevent undefined endpoint
            uri = URI(@endpoint)

            payload = payload(content, klass).to_json
            system_log("Sending request to third party service: #{payload}")
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
            system_log("Error during request to Scaleway service: #{e.message}", level: :error)
            { "error" => "Error during request to third party service" }
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
