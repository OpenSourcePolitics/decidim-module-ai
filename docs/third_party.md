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
end
```
