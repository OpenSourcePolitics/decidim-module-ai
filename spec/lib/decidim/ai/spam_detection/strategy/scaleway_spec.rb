# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::Ai::SpamDetection::Strategy::Scaleway do
  let(:strategy) { described_class.new(options) }
  let(:endpoint) { "https://example.com/api" }
  let(:secret) { "secret_key" }
  let(:klass) { "Decidim::Proposals::Proposal" }
  let(:options) do
    {
      endpoint:,
      secret:
    }
  end

  describe "#third_party_content" do
    context "when body contains valid JSON with choices" do
      let(:body) do
        {
          "choices" => [
            {
              "message" => {
                "content" => "SPAM"
              }
            }
          ]
        }.to_json
      end

      it "returns the content of the first choice" do
        expect(strategy.third_party_content(body)).to eq("SPAM")
      end
    end

    context "when body contains valid JSON without choices" do
      let(:body) do
        {
          "choices" => []
        }.to_json
      end

      it "returns nil" do
        expect(strategy.third_party_content(body)).to be_nil
      end
    end

    context "when body contains invalid JSON" do
      let(:body) { "invalid json" }

      it "raises a JSON::ParserError" do
        expect { strategy.third_party_content(body) }.to raise_error(JSON::ParserError)
      end
    end

    context "when body is empty" do
      let(:body) { "" }

      it "returns nil" do
        expect(strategy.third_party_content(body)).to be_empty
      end
    end
  end

  describe "#classify" do
    let(:response_double) { double(Net::HTTPResponse, body: '{"choices": [{"message": {"spam": "NOT_SPAM"}}]}', is_a?: true, error: "Error message") }
    let(:uri_double) { double(URI, host: "example.com", port: 443, path: "/api", method: :POST) }
    let(:http_double) { double(Net::HTTP, :use_ssl= => true) }

    before do
      allow(URI).to receive(:parse).and_return(uri_double)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:post).and_return(double(Net::HTTPResponse, code: Net::HTTPSuccess, body: '{"choices": [{"message": {"spam": "NOT_SPAM"}}]}'))
      allow(http_double).to receive(:headers=).and_return({ "Accept" => "application/json", "Content-Type" => "application/json", "Decidim" => "decidim.example.org", "Host" => "decidim.example.org", "X-Auth-Token" => "secret_key" })
      allow(strategy).to receive(:request).and_return(response_double)
    end

    it "classifies content as not spam" do
      expect(strategy.classify("Test content", "decidim.example.org", klass)).to eq(0)
    end

    context "when response is invalid" do
      before do
        allow(response_double).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(response_double).to receive(:error).and_return("Error message")
      end

      it "raises InvalidEntity error" do
        expect { strategy.classify("Test content", "decidim.example.org", klass) }.not_to raise_error(Decidim::Ai::SpamDetection::Strategy::ThirdParty::InvalidEntity)
        expect(strategy.instance_variable_get(:@score)).to eq(0)
      end
    end

    context "when response format is invalid" do
      before { allow(strategy).to receive(:valid_output_format?).and_return(false) }

      it "raises InvalidOutputFormat error" do
        expect { strategy.classify("Test content", "decidim.example.org", klass) }.not_to raise_error(Decidim::Ai::SpamDetection::Strategy::ThirdParty::InvalidOutputFormat)
        expect(strategy.instance_variable_get(:@score)).to eq(0)
      end
    end
  end

  describe "#headers" do
    it "returns the correct headers" do
      expect(strategy.headers("decidim.example.org")).to eq(
        "X-Auth-Token" => "secret_key",
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Host" => "decidim.example.org",
        "Decidim" => "decidim.example.org"
      )
    end
  end

  describe "#payload" do
    it "returns the correct payload" do
      expect(strategy.payload("Test content", "Decidim::Proposals::Proposal")).to eq({
                                                                                       text: "Test content",
                                                                                       type: "Decidim::Proposals::Proposal"
                                                                                     })
    end
  end
end
