# frozen_string_literal: true

if Decidim.module_installed?(:ai)
  if Rails.application.secrets.dig(:decidim, :ai, :endpoint).blank? || Rails.application.secrets.dig(:decidim, :ai, :secret).blank?
    Rails.logger.warn "[decidim-ai] Initializer - AI endpoint or secret not configured. AI features will be disabled."
    return
  end

  # Module configuration
  Decidim::Ai::SpamDetection.reporting_user_email = Rails.application.secrets.dig(:decidim, :ai, :reporting_user_email)
  Decidim::Ai::Language.formatter = "Decidim::Ai::Language::Formatter"
  Decidim::Ai::SpamDetection.user_models = {
    "Decidim::User" => "Decidim::Ai::SpamDetection::Resource::UserBaseEntity"
  }
  Decidim::Ai::SpamDetection.resource_models = begin
    models = {}
    models["Decidim::Comments::Comment"] = "Decidim::Ai::SpamDetection::Resource::Comment" if Decidim.module_installed?("comments")
    models["Decidim::Debates::Debate"] = "Decidim::Ai::SpamDetection::Resource::Debate" if Decidim.module_installed?("debates")
    models["Decidim::Initiative"] = "Decidim::Ai::SpamDetection::Resource::Initiative" if Decidim.module_installed?("initiatives")
    models["Decidim::Meetings::Meeting"] = "Decidim::Ai::SpamDetection::Resource::Meeting" if Decidim.module_installed?("meetings")
    models["Decidim::Proposals::Proposal"] = "Decidim::Ai::SpamDetection::Resource::Proposal" if Decidim.module_installed?("proposals")
    if Decidim.module_installed?("proposals")
      models["Decidim::Proposals::CollaborativeDraft"] =
        "Decidim::Ai::SpamDetection::Resource::CollaborativeDraft"
    end
    models
  end

  # Configuring Third Party strategy
  analyzers = [
    {
      name: :third_party,
      strategy: Decidim::Ai::SpamDetection::Strategy::ThirdParty,
      options: {
        model: Rails.application.secrets.dig(:decidim, :ai, :model),
        endpoint: Rails.application.secrets.dig(:decidim, :ai, :endpoint),
        secret: Rails.application.secrets.dig(:decidim, :ai, :secret),
        max_tokens: Rails.application.secrets.dig(:decidim, :ai, :max_tokens),
        temperature: Rails.application.secrets.dig(:decidim, :ai, :temperature),
        top_p: Rails.application.secrets.dig(:decidim, :ai, :top_p),
        presence_penalty: Rails.application.secrets.dig(:decidim, :ai, :presence_penalty),
        stream: Rails.application.secrets.dig(:decidim, :ai, :stream),
        system_message: Rails.application.secrets.dig(:decidim, :ai, :system_message),
        reporting_user_email: Rails.application.secrets.dig(:decidim, :ai, :reporting_user_email)
      }
    }
  ]

  Decidim::Ai::SpamDetection.resource_analyzers = analyzers
  Decidim::Ai::SpamDetection.user_analyzers = analyzers

  # Configuring Third Party services
  Decidim::Ai::SpamDetection.user_detection_service = "Decidim::Ai::SpamDetection::ThirdPartyService"
  Decidim::Ai::SpamDetection.resource_detection_service = "Decidim::Ai::SpamDetection::ThirdPartyService"

  # Configuring Third Party jobs
  Decidim::Ai::SpamDetection.user_spam_analyzer_job = "Decidim::Ai::SpamDetection::ThirdParty::UserSpamAnalyzerJob"
  Decidim::Ai::SpamDetection.generic_spam_analyzer_job = "Decidim::Ai::SpamDetection::ThirdParty::GenericSpamAnalyzerJob"
end
