#!/usr/bin/env ruby
# Encoding: utf-8
#
# Copyright:: Copyright 2016, Google Inc. All Rights Reserved.
#
# License:: Licensed under the Apache License, Version 2.0 (the "License");
#           you may not use this file except in compliance with the License.
#           You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#           Unless required by applicable law or agreed to in writing, software
#           distributed under the License is distributed on an "AS IS" BASIS,
#           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#           implied.
#           See the License for the specific language governing permissions and
#           limitations under the License.
#
# This example adds a price extension and associates it with an account.
# Campaign targeting is also set using the specified campaign ID. To get
# campaigns, run basic_operations/get_campaigns.rb.

require 'adwords_api'

def add_prices(campaign_id)
  # AdwordsApi::Api will read a config file from ENV['HOME']/adwords_api.yml
  # when called without parameters.
  adwords = AdwordsApi::Api.new

  # To enable logging of SOAP requests, set the log_level value to 'DEBUG' in
  # the configuration file or provide your own logger:
  # adwords.logger = Logger.new('adwords_xml.log')

  customer_extension_setting_srv =
      adwords.service(:CustomerExtensionSettingService, API_VERSION)

  price_feed_item = {
    :xsi_type => 'PriceFeedItem',
    :price_extension_type => 'SERVICES',
    # Price qualifier is optional.
    :price_qualifier => 'FROM',
    :tracking_url_template => 'http://tracker.example.com/?u={lpurl}',
    :language => 'en',
    :campaign_targeting => {
      :targeting_campaign_id => campaign_id
    },
    :scheduling => {
      :feed_item_schedules => [
        {
          :day_of_week => 'SUNDAY',
          :start_hour => 10,
          :start_minute => 'ZERO',
          :end_hour => 18,
          :end_minute => 'ZERO'
        },
        {
          :day_of_week => 'SATURDAY',
          :start_hour => 10,
          :start_minute => 'ZERO',
          :end_hour => 22,
          :end_minute => 'ZERO'
        }
      ]
    },
    # To create a price extension, at least three table rows are needed.
    :table_rows => [
      {
        :header => 'Scrubs',
        :description => 'Body Scrub, Salt Scrub',
        :final_urls => {
          :urls => ['http://www.example.com/scrubs']
        },
        :price => {
          :money => {
            :micro_amount => 60 * MICROS_PER_DOLLAR
          },
          :currency_code => 'USD'
        },
        :price_unit => 'PER_HOUR'
      },
      {
        :header => 'Hair Cuts',
        :description => 'Once a month',
        :final_urls => {
          :urls => ['http://www.example.com/haircuts']
        },
        :price => {
          :money => {
            :micro_amount => 75 * MICROS_PER_DOLLAR
          },
          :currency_code => 'USD'
        },
        :price_unit => 'PER_MONTH'
      },
      {
        :header => 'Skin Care Package',
        :description => 'Four times a month',
        :final_urls => {
          :urls => ['http://www.example.com/skincarepackage']
        },
        :price => {
          :money => {
            :micro_amount => 250 * MICROS_PER_DOLLAR
          },
          :currency_code => 'USD'
        },
        :price_unit => 'PER_MONTH'
      }
    ]
  }

  customer_extension_setting = {
    :extension_type => 'PRICE',
    :extension_setting => {
      :extensions => [price_feed_item]
    }
  }

  operation = {
    :operator => 'ADD',
    :operand => customer_extension_setting
  }

  result = customer_extension_setting_srv.mutate([operation])

  new_extension_setting = result[:value].first
  puts "Extension setting with type '%s' was added to your account.\n" %
      new_extension_setting[:extension_type]
end

if __FILE__ == $0
  API_VERSION = :v201607

  MICROS_PER_DOLLAR = 1000000

  begin
    # Campaign ID to add site link to.
    campaign_id = 'INSERT_CAMPAIGN_ID_HERE'.to_i
    add_prices(campaign_id)

  # Authorization error.
  rescue AdsCommon::Errors::OAuth2VerificationRequired => e
    puts "Authorization credentials are not valid. Edit adwords_api.yml for " +
        "OAuth2 client ID and secret and run misc/setup_oauth2.rb example " +
        "to retrieve and store OAuth2 tokens."
    puts "See this wiki page for more details:\n\n  " +
        'https://github.com/googleads/google-api-ads-ruby/wiki/OAuth2'

  # HTTP errors.
  rescue AdsCommon::Errors::HttpError => e
    puts "HTTP Error: %s" % e

  # API errors.
  rescue AdwordsApi::Errors::ApiException => e
    puts "Message: %s" % e.message
    puts 'Errors:'
    e.errors.each_with_index do |error, index|
      puts "\tError [%d]:" % (index + 1)
      error.each do |field, value|
        puts "\t\t%s: %s" % [field, value]
      end
    end
  end
end
