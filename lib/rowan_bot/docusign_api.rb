# frozen_string_literal: true

require 'docusign_esign'

module RowanBot
  # DocuSignAPI class
  class DocuSignAPI
    TOKEN_REPLACEMENT_IN_SECONDS = 10 * 60 # 10 minutes
    TOKEN_EXPIRATION_IN_SECONDS = 60 * 60 # 1 hour

    def initialize
      @client = DocuSign_eSign::ApiClient.new(DocuSign_eSign::Configuration.new)
      @envelope_api = DocuSign_eSign::EnvelopesApi.new(@client)
      @account = nil
      @account_id = nil
      @expires_in = nil
    end

    def recently_signed_emails(days)
      envelop_ids = list_envelopes(days)
                    .filter { |envelop| envelop.status.eql?('completed') }
                    .map(&:envelope_id)
      envelop_ids.inject([]) do |acc, envelop_id|
        acc + list_recipients(envelop_id).map(&:email)
      end
    end

    private

    attr_accessor :client, :envelope_api, :account_id, :expires_in, :account

    def list_recipients(envelop_id)
      check_token

      ensure_array(
        envelope_api
        .list_recipients(account_id, envelop_id)
        .signers
      )
    end

    def list_envelopes(days)
      check_token
      options = DocuSign_eSign::ListStatusChangesOptions.new
      options.from_date = (Date.today - days).strftime('%Y/%m/%d')
      ensure_array(
        envelope_api
        .list_status_changes(account_id, options)
        .envelopes
      )
    end

    def ensure_array(response)
      return [] if response.nil?

      response
    end

    def should_update_token?
      return true if expires_in.nil?

      time_to_update_token = Time.now.to_f + TOKEN_EXPIRATION_IN_SECONDS
      time_to_update_token > expires_in
    end

    def check_token
      update_token if should_update_token?
    end

    def update_token
      client.set_oauth_base_path(ENV['BZ_DOCUSIGN_HOST'])
      response = client.request_jwt_user_token(
        ENV['BZ_DOCUSIGN_API_KEY'],
        ENV['BZ_DOCUSIGN_USER_GUID'],
        ENV['BZ_DOCUSIGN_RSA_PRIVATE_KEY']
      )
      self.account = get_account_info(response.access_token)
      client.config.host = account.base_uri
      self.account_id = account.account_id
      self.expires_in = Time.now.to_f + TOKEN_EXPIRATION_IN_SECONDS # would be better to receive the expires
    end

    def get_account_info(access_token)
      response = client.get_user_info(access_token)
      accounts = response.accounts
      accounts.each do |acct|
        return acct if acct.is_default
      end
    end

    def logger
      RowanBot.logger
    end
  end
end
