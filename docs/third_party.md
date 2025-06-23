# Configure a Third Party AI system to detect spam

## Getting started

To use a third-party AI system to detect spam, you need to configure the `decidim_ai` gem in your Decidim application. This guide will help you set up the necessary configurations.

## Configure the AI module

Define a decidim-ai initializer in your application configuration : `config/initializers/decidim_ai.rb`:

```ruby
# frozen_string_literal: true

if Decidim.module_installed?(:ai)
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
end
```

**A full example of configuration is available at examples/decidim_ai_third_party.rb**

Add the secrets to your `config/secrets.yml` file:

```yaml
decidim:
  ai:
    model: <%= Decidim::Env.new("DECIDIM_AI_MODEL").to_s %>
    endpoint: <%= Decidim::Env.new("DECIDIM_AI_ENDPOINT").to_s %>
    secret: <%= Decidim::Env.new("DECIDIM_AI_SECRET").to_s %>
    max_tokens: <%= Decidim::Env.new("DECIDIM_AI_MAX_TOKENS").to_i %>
    temperature: <%= Decidim::Env.new("DECIDIM_AI_TEMPERATURE").to_f %>
    top_p: <%= Decidim::Env.new("DECIDIM_AI_TOP_P").to_i %>
    presence_penalty: <%= Decidim::Env.new("DECIDIM_AI_PRESENCE_PENALTY").to_i %>
    stream: <%= Decidim::Env.new("DECIDIM_AI_STREAM") == "true" %>
    system_message: <%= Decidim::Env.new("DECIDIM_AI_SYSTEM_MESSAGE").to_s %>
    reporting_user_email: <%= Decidim::Env.new("DECIDIM_AI_REPORTING_USER_EMAIL").to_s %>
```

You can now run your server and start using the third-party AI service for spam detection !