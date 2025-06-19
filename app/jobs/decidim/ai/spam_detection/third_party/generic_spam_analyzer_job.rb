# frozen_string_literal: true

module Decidim
  module Ai
    module SpamDetection
      module ThirdParty
        class GenericSpamAnalyzerJob < Decidim::Ai::SpamDetection::GenericSpamAnalyzerJob
          def perform(reportable, author, locale, fields)
            @author = author
            @organization = reportable.organization
            klass = reportable.class.to_s
            overall_score = I18n.with_locale(locale) do
              fields.map do |field|
                classifier.classify(translated_attribute(reportable.send(field)), @organization.host, klass)
                classifier.score
              end
            end

            overall_score = overall_score.inject(0.0, :+) / overall_score.size

            return unless overall_score >= Decidim::Ai::SpamDetection.resource_score_threshold

            Decidim::CreateReport.call(form, reportable)
          rescue StandardError => e
            Rails.logger.error e.backtrace.first(15).join("\n")
            Rails.logger.error "Error in GenericSpamAnalyzerJob: #{e.message}"
          end
        end
      end
    end
  end
end
