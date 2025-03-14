# Decidim::Ai

The Decidim::Ai is a library that aims to provide Artificial Intelligence tools for Decidim. This plugin has been initially developed aiming to analyze the content and provide spam classification using Naive Bayes algorithm.
All AI related functionality provided by Decidim should be included in this same module.

For more documentation on the AI tools API, please refer to [documentation](https://docs.decidim.org/en/develop/develop/ai_tools.html)

## Installation

In order to install use this module, you need at least Decidim 0.30 to be installed.

To install this module, run in your console:

```bash
bundle add decidim-ai
```

After that, add an initializer file as presented in the [documentation](https://docs.decidim.org/en/develop/services/aitools.html#_configuration)

Then, you need to run the below command, so that the reporting user is created.

```ruby
bin/rails decidim:ai:spam:create_reporting_user
```

Then you can use the below command to train the engine with the module dataset:

```ruby
bin/rails decidim:ai:spam:load_module_dataset
```

Add the queue name to `config/sidekiq.yml` file:

```yaml
:queues:
- ["default", 1]
- ["spam_analysis", 1]
# The other yaml entries
```

## Configure third-party service

To use the third-party service, you need to add the following configuration to your `config/initilizers/decidim_ai.rb` file:

```ruby

# frozen_string_literal: true

if Decidim.module_installed?(:ai)
  Decidim::Ai::SpamDetection.user_analyzers = [
    {
      name: :bayes,
      strategy: Decidim::Ai::SpamDetection::Strategy::Scaleway,
      options: {
        model: Rails.application.secrets.ai.model,
        endpoint: Rails.application.secrets.ai.endpoint,
        secret: Rails.application.secrets.ai.secret,
        max_tokens: Rails.application.secrets.ai.max_tokens,
        temperature: Rails.application.secrets.ai.temperature,
        top_p: Rails.application.secrets.ai.top_p,
        presence_penalty: Rails.application.secrets.ai.presence_penalty,
        stream: Rails.application.secrets.ai.stream,
        system_message: Rails.application.secrets.ai.system_message
      }
    }
  ]
end
```

Add secrets to your `config/secrets.yml` file:

```yaml

default: &default
  decidim:
      ai:
        model: ENV.fetch("SCW_AI_MODEL", "deepseek-r1-distill-llama-70b")
        endpoint: ENV.fetch("SCW_AI_ENDPOINT")
        secret: ENV.fetch("SCW_SECRET")
        max_tokens: ENV.fetch("SCW_MAX_TOKENS", "100")&.to_i
        temperature: ENV.fetch("SCW_MAX_TEMPERATURE", "0.7")&.to_f
        top_p: ENV.fetch("SCW_TOP_P", "1")&.to_i
        presence_penalty: ENV.fetch("SCW_PRESENCE_PENALTY", "0")&.to_i
        stream: ENV.fetch("SCW_STREAM", "false") == "true"
        system_message: ENV.fetch("SCW_SYSTEM_MESSAGE", "You are an expert content moderator for participatory democracy platforms like Decidim. Your task is to classify user-submitted content in any language as either legitimate civic participation or spam.")
```

## Contributing

See [Decidim](https://github.com/decidim/decidim).

## License

See [Decidim](https://github.com/decidim/decidim).
