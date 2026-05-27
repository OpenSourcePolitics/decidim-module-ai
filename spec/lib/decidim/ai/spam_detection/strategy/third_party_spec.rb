# frozen_string_literal: true

require "spec_helper"

describe Decidim::Ai::SpamDetection::Strategy::ThirdParty do
  let(:strategy) { described_class.new(options) }
  let(:endpoint) { "https://example.com/api" }
  let(:secret) { "secret_key" }
  let(:options) do
    {
      endpoint:,
      secret:,
      model: "model_name",
      system_message: "System message",
      max_tokens: 100,
      temperature: 0.7,
      top_p: 0.9,
      presence_penalty: 0,
      stream: false
    }
  end
  let(:content) { "Test contribution input." }

  before do
    stub_request(:post, "https://example.com/api")
      .to_return(status: 200, body: "", headers: {})
  end

  describe "#initialize" do
    it "initializes with options" do
      expect(strategy.instance_variable_get(:@endpoint)).to eq(endpoint)
      expect(strategy.instance_variable_get(:@secret)).to eq(secret)
      expect(strategy.instance_variable_get(:@options)).to eq(options)
    end
  end

  describe "train" do
    it "returns nothing" do
      expect(strategy.train(:spam, "text")).to be_nil
    end
  end

  describe "untrain" do
    it "returns nothing" do
      expect(strategy.untrain(:spam, "text")).to be_nil
    end
  end

  describe "#log" do
    context "when score is below threshold" do
      before { allow(strategy).to receive(:score).and_return(0) }

      it "returns a non-spam message" do
        expect(strategy.log).to eq("AI system didn't marked this content as spam")
      end
    end

    context "when score is above threshold" do
      before { allow(strategy).to receive(:score).and_return(1) }

      it "returns a spam message" do
        expect(strategy.log).to eq("AI system marked this as spam")
      end
    end
  end

  describe "#classify" do
    let(:response_double) { double("Net::HTTPResponse", body: '{"choices": [{"message": {"content": "NOT_SPAM"}}]}', is_a?: true) }

    before do
      allow(strategy).to receive(:third_party_request).and_return(response_double)
    end

    it "classifies content as not spam" do
      expect(strategy.classify(content)).to eq(0)
    end

    context "when response is invalid" do
      before do
        allow(response_double).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(response_double).to receive(:error).and_return("Error message")
      end

      it "raises InvalidEntity error" do
        expect { strategy.classify(content) }.not_to raise_error
        expect(strategy.score).to eq(0)
      end
    end

    context "when response format is invalid" do
      before do
        allow(response_double).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(strategy).to receive(:third_party_content).and_return("INVALID_FORMAT")
      end

      it "raises InvalidOutputFormat error" do
        expect { strategy.classify(content) }.not_to raise_error
        expect(strategy.score).to eq(0)
      end
    end
  end

  describe "#request" do
    let(:uri_double) { double("URI", host: "example.com", port: 443, path: "/api") }
    let(:http_double) { double("Net::HTTP", :use_ssl= => true) }

    before do
      allow(URI).to receive(:parse).and_return(uri_double)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:post).and_return(double("Net::HTTPResponse", body: '{"category": "NOT_SPAM"}'))
    end

    it "sends a request to the third-party service" do
      expect(http_double).to receive(:post).with("/api", anything, anything)
      strategy.third_party_request(content)
    end
  end

  describe "#headers" do
    it "returns the correct headers" do
      expect(strategy.headers).to eq(
        "Authorization" => "Bearer secret_key",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      )
    end
  end

  describe "#payload" do
    it "returns the correct payload" do
      expect(strategy.payload(content)).to eq(
        model: "model_name",
        messages: [
          { role: "system", content: "System message" },
          { role: "user", content: }
        ],
        max_tokens: 100,
        temperature: 0.7,
        top_p: 0.9,
        presence_penalty: 0,
        stream: false
      )
    end
  end

  describe "#score" do
    context "when category is 'spam'" do
      before { strategy.instance_variable_set(:@category, "spam") }

      it "returns 1" do
        expect(strategy.score).to eq(1)
      end
    end

    context "when category is not 'spam'" do
      before { allow(strategy).to receive(:@category).and_return("not_spam") }

      it "returns 0" do
        expect(strategy.score).to eq(0)
      end
    end
  end

  describe "#valid_output_format?" do
    it "returns true for valid output" do
      expect(strategy.send(:valid_output_format?, "SPAM")).to be true
      expect(strategy.send(:valid_output_format?, "NOT_SPAM")).to be true
    end

    it "returns false for invalid output" do
      expect(strategy.send(:valid_output_format?, "INVALID")).to be false
      expect(strategy.send(:valid_output_format?, nil)).to be false
    end
  end

  describe "#score_threshold" do
    before { allow(Decidim::Ai::SpamDetection).to receive(:user_score_threshold).and_return(0.5) }

    context "when name is :third_party_user" do
      before { allow(strategy).to receive(:name).and_return(:third_party_user) }

      it "returns user score threshold" do
        expect(strategy.send(:score_threshold)).to eq(0.5)
      end
    end

    context "when name is not :third_party_user" do
      before { allow(strategy).to receive(:name).and_return(:other_name) }

      it "returns resource score threshold" do
        expect(strategy.send(:score_threshold)).to eq(Decidim::Ai::SpamDetection.resource_score_threshold)
      end
    end
  end

  describe "#system_log" do
    let(:logger_double) { double("Rails.logger") }

    before { allow(Rails.logger).to receive(:send).and_return(logger_double) }

    it "logs a message with info level" do
      expect(Rails.logger).to receive(:send).with(:info, "[decidim-ai] Decidim::Ai::SpamDetection::Strategy::ThirdParty - Test message")
      strategy.send(:system_log, "Test message")
    end

    it "logs a message with error level" do
      expect(Rails.logger).to receive(:send).with(:error, "[decidim-ai] Decidim::Ai::SpamDetection::Strategy::ThirdParty - Error message")
      strategy.send(:system_log, "Error message", level: :error)
    end
  end
end
