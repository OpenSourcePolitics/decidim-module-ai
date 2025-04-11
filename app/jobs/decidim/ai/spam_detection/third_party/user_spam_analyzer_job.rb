# frozen_string_literal: true

module Decidim
  module Ai
    module SpamDetection
      module ThirdParty
        class UserSpamAnalyzerJob < Decidim::Ai::SpamDetection::UserSpamAnalyzerJob
          def perform(reportable)
            @author = reportable
            organization_host = reportable.organization.host
            klass = reportable.class.to_s
            classifier.classify(reportable.about, organization_host, klass)

            return unless classifier.score >= Decidim::Ai::SpamDetection.user_score_threshold

            Decidim::CreateUserReport.call(form, reportable)
          end
        end
      end
    end
  end
end
