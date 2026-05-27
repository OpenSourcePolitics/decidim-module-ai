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
          "spam" => "SPAM"
        }
      end

      it "returns the content of the first choice" do
        expect(strategy.third_party_content(body)).to eq("SPAM")
      end
    end

    context "when body contains valid JSON without choices" do
      let(:body) do
        {}
      end

      it "returns empty string" do
        expect(strategy.third_party_content(body)).to eq("")
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

      it "returns empty string" do
        expect(strategy.third_party_content(body)).to be_empty
      end
    end
  end

  describe "#classify" do
    let(:http_response_body) { '{"spam": "NOT_SPAM"}' }
    let(:http_response_double) do
      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return(http_response_body)
      response
    end
    let(:http_double) { instance_double(Net::HTTP, :use_ssl= => true) }

    before do
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:request).and_return(http_response_double)
    end

    it "classifies content as not spam" do
      expect(strategy.classify("Test content", "decidim.example.org", klass)).to eq(0)
    end

    context "when response is invalid" do
      let(:http_response_double) do
        response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
        allow(response).to receive(:body).and_return("Error")
        response
      end

      it "raises InvalidEntity error" do
        expect { strategy.classify("Test content", "decidim.example.org", klass) }.to raise_error(Decidim::Ai::SpamDetection::Strategy::ThirdParty::InvalidEntity)
      end
    end

    context "when response format is invalid" do
      let(:http_response_body) { '{"spam": "INVALID_FORMAT"}' }

      it "raises InvalidOutputFormat error" do
        expect { strategy.classify("Test content", "decidim.example.org", klass) }.to raise_error(Decidim::Ai::SpamDetection::Strategy::ThirdParty::InvalidOutputFormat)
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
