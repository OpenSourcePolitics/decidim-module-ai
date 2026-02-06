# Configure a Scaleway Third Party AI system to detect spam

## Introduction to Scaleway Strategy

We've added a Scaleway strategy which inherits from the Third Party Strategy to abstract the AI system configuration to a third party service. It reduces considerably the configuration on the Decidim instance by defining only a endpoint and a secret parameters to connect to the Scaleway AI service.

### How it works

The Scaleway strategy uses the Scaleway AI service to analyze content for spam detection. It sends the content to the Scaleway endpoint, which processes it and returns a response indicating whether the content is considered spam or not.

Outputs expected are JSON objects with the following structure:

```json
{
  "SPAM": "SPAM"
}
```
or
```json
{
  "SPAM": "NOT_SPAM"
}
```

Every time a contribution is made on Decidim, a POST request is sent to a serverless function endpoint. This endpoint retrieve the corresponding prompt based on the resource being analyzed (e.g., proposal, comment, etc.) and the type of analysis (resource or user). And it performs a POST request to the [Scaleway AI service](https://www.scaleway.com/en/docs/generative-apis/concepts/) with the content to be analyzed, the prompt, and the necessary parameters (temperature, top_p, etc…).

The whole AI specifications prompts, parameters, etc… are defined in a [Langfuse](https://github.com/langfuse/langfuse) self-hosted instance which allows to get metrics on the AI usage and to improve the prompts over time.

Every Decidim application connected to this system has the same prompts and parameters, which are defined in the Langfuse instance. This allows for a consistent spam detection experience across all applications using this strategy.

## Infrastructure

⚠️ We plan to share the Terraform (OpenTofu) project to deploy the serverless endpoint located at : https://github.com/OpenSourcePolitics/serverless/tree/main/faas_ai/infra


## Getting started

To use a third-party AI system to detect spam, you need to configure the `decidim_ai` gem in your Decidim application. This guide will help you set up the necessary configurations.

## Configure the AI module

Define a decidim-ai initializer in your application configuration : `config/initializers/decidim_ai.rb`:

```ruby
# frozen_string_literal: true

if Decidim.module_installed?(:ai)
  analyzers = [
    {
      name: :scaleway,
      strategy: Decidim::Ai::SpamDetection::Strategy::Scaleway,
      options: {
        endpoint: Rails.application.secrets.dig(:decidim, :ai, :endpoint),
        secret: Rails.application.secrets.dig(:decidim, :ai, :secret),
      }
    }
  ]

  Decidim::Ai::SpamDetection.resource_analyzers = analyzers
  Decidim::Ai::SpamDetection.user_analyzers = analyzers
end
```

**A full example of configuration is available at examples/scaleway.rb**


Add the secrets to your `config/secrets.yml` file:

```yaml
decidim:
  ai:
    endpoint: <%= Decidim::Env.new("DECIDIM_AI_ENDPOINT").to_s %>
    secret: <%= Decidim::Env.new("DECIDIM_AI_SECRET").to_s %>
```
You can now run your server and start using the Scaleway AI service for spam detection !
