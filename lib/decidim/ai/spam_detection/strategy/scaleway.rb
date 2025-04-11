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
            system_log("Starting classification...")
            res = third_party_request(content, organization_host, klass)
            body = res.body

            system_log("Received response from third party service: #{body}")
            raise InvalidEntity, res.error unless res.code == Net::HTTPSuccess

            content = third_party_content(body)
            raise InvalidOutputFormat, "Third party service response isn't valid JSON" unless valid_output_format?(content)

            @category = content.downcase
            system_log(score == 1 ? "SPAM" : "NOT_SPAM")
            score
          rescue InvalidEntity, InvalidOutputFormat => e
            system_log(e.message, level: :error)
            score
          end

          def third_party_request(content, organization_host, klass)
            uri = URI(@endpoint)
            payload = payload(content, klass).to_json
            system_log("Sending request to third party service: #{payload}")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.headers = headers(organization_host)
            http.post(uri.path, payload)
          end

          def third_party_content(body)
            return [] if body.blank?

            choices = JSON.parse(body)&.fetch("choices", [])
            choices.first&.dig("message", "content")
          end

          def payload(content, klass)
            {
              text: content,
              type: klass
            }
          end

          def headers(organization_host)
            @headers ||= {
              "X-Auth-Token" => @secret,
              "Content-Type" => "application/json",
              "Accept" => "application/json",
              "Host" => organization_host,
              "Decidim" => organization_host
            }
          end
        end
      end
    end
  end
end
