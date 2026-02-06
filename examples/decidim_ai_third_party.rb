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
        model: Decidim::Env.new("DECIDIM_AI_MODEL").to_s,
        endpoint: Decidim::Env.new("DECIDIM_AI_ENDPOINT").to_s,
        secret: Decidim::Env.new("DECIDIM_AI_SECRET").to_s,
        max_tokens: Decidim::Env.new("DECIDIM_AI_MAX_TOKENS").to_i,
        temperature: Decidim::Env.new("DECIDIM_AI_TEMPERATURE").to_f,
        top_p: Decidim::Env.new("DECIDIM_AI_TOP_P").to_i,
        presence_penalty: Decidim::Env.new("DECIDIM_AI_PRESENCE_PENALTY").to_i,
        stream: Decidim::Env.new("DECIDIM_AI_STREAM") == "true",
        system_message: Decidim::Env.new("DECIDIM_AI_SYSTEM_MESSAGE").to_s,
        reporting_user_email: Decidim::Env.new("DECIDIM_AI_REPORTING_USER_EMAIL").to_s
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
