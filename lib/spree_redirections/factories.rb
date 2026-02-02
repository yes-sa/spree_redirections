# frozen_string_literal: true

require 'ffaker'

FactoryBot.define do
  # Define your Spree extensions Factories within this file to enable applications, and other extensions to use and override them.
  #
  # Example adding this to your spec_helper will load these Factories for use:
  # require 'spree_redirections/factories'
  factory :redirection, class: SpreeRedirections::Redirection do
    store_url { Faker::Internet.domain_name }
    sequence(:old_url) { |n| "/#{Faker::Internet.slug}-#{n}" }
    sequence(:new_url) { |n| "/#{Faker::Internet.slug}-#{n}" }
    http_status { %w[301 302 303].sample }
    external_redirection { false }
    deleted_at { nil }

    created_by { Faker::Name.name }
    deleted_by { nil }

    trait :external do
      external_redirection { true }

      new_url do
        "https://www.#{Faker::Internet.domain_name}/#{Faker::Internet.slug}"
      end
    end

    trait :soft_deleted do
      deleted_at { Time.current }
      deleted_by { Faker::Name.name }
    end
  end
end
