# frozen_string_literal: true

require 'yaml'
require 'restforce'

module RowanBot
  # SalesforceAPI class
  SFParticipant = Struct.new(:id, :email, :first_name, :last_name,
                             :signed_waiver, :peer_group, :cohort_id,
                             :cohort_letter, :program_id, :program_letter,
                             :webinar_registration_1, :webinar_registration_2,
                             :webinar_link_1, :webinar_link_2,
                             :signed_waiver_complete, :canvas_id,
                             :coaching_partner_role, :peer_group_lc_name,
                             :peer_group_lc_last_name, :status, :candidate_status)
  SFPeerGroup = Struct.new(:id, :name, :index)
  SFProgram = Struct.new(:id, :slack_url, :slack_token, :slack_user, :slack_password, :slack_admin_emails)

  class SalesforceAPI
    # constants
    QUERIES = YAML.load_file(
      File.join(__dir__, 'salesforce_api_queries.yaml')
    )

    def initialize(params = {})
      @client = Restforce.new(
        username: params.fetch(:username, ENV['SALESFORCE_PLATFORM_USERNAME']),
        password: params.fetch(:password, ENV['SALESFORCE_PLATFORM_PASSWORD']),
        host: params.fetch(:host, ENV['SALESFORCE_HOST']),
        security_token: params.fetch(:security_token, ENV['SALESFORCE_PLATFORM_SECURITY_TOKEN']),
        client_id: params.fetch(:client_id, ENV['SALESFORCE_PLATFORM_CONSUMER_KEY']),
        client_secret: params.fetch(:client_secret, ENV['SALESFORCE_PLATFORM_CONSUMER_SECRET']),
        api_version: params.fetch(:api_version, ENV.fetch('SALESFORCE_API_VERSION', '48.0'))
      )
      @participant_record_type_ids = {}
      @last_peer_groups = {}
      @participants = {}
    end

    def sign_participants_waivers_by_email(emails, record_type)
      emails.filter do |email|
        participant = fetch_participant_by_email(email, record_type)
        if participant.nil?
          logger.warn("Participant #{email} is not found in Salesforce")
          false
        else
          set_participant_waiver_field(participant)
        end
      end
    end

    def assign_peer_groups_to_user_emails(emails, record_type)
      emails.each do |email|
        participant = fetch_participant_by_email(email, record_type)
        next unless participant.peer_group.nil?

        assign_peer_groups_to_participant(participant)
      end
    end

    def update_participant_webinar_links(participant_id, first_link, second_link)
      logger.info("SALESFORCE: Making API Call to update participants #{participant_id}")
      client.update(
        'Participant__c',
        Id: participant_id,
        Webinar_Access_1__c: first_link,
        Webinar_Access_2__c: second_link
      )
    end

    def find_program_by_id(program_id)
      query_program_by_id(program_id)
    end

    def all_participants(program_id, record_type)
      fetch_program_participants(program_id, record_type)
    end

    def find_participants_by_emails(emails, record_type)
      fetch_participants_by_emails(emails, record_type)
    end

    def find_participant_by_email(email, record_type)
      fetch_participant_by_email(email, record_type)
    end

    private

    attr_reader :client, :participant_record_type_ids, :participants, :last_peer_groups

    def assign_peer_groups_to_participant(participant, max_cap = 10)
      peer_group = find_or_create_peer_group(participant, max_cap)
      logger.info('SALESFORCE: Making API Call')
      client.update!('Participant__c', Id: participant.id, Cohort__c: peer_group.id)
      participant.peer_group = peer_group.name
      participants[participant.email] = participant
    end

    # Only implemented for Booster students at the moment.
    # If we start doing this for folks who could have multiple Participant objects, we'll
    # have to update this to account for that.
    def set_participant_waiver_field(participant, value = true)
      logger.info("Attempting to set waiver for #{participant.email} to #{value}")
      if participant.signed_waiver
        logger.info("Skipping #{participant.email} - already marked as signed in salesforce")
        return false
      end
      logger.info('SALESFORCE: Making API Call')
      client.update!('Participant__c', Id: participant.id, Student_Waiver_Signed__c: value)
      # Updates our cache
      participant.signed_waiver = value
      participants[participant.email] = participant

      true
    end

    def find_or_create_peer_group(participant, max_cap)
      last_peer_group = fetch_last_peer_group(participant.program_id, participant.cohort_id)

      if should_create_peer_group?(participant, last_peer_group, max_cap)
        group = last_peer_group.nil? ? 1 : last_peer_group.index.to_i + 1
        name = "Booster Session #{participant.program_letter} Cohort #{participant.cohort_letter} Group #{group}"
        logger.debug("Creating new peer group '#{name}' for Program__c '#{participant.program_id}'
                     and Cohort_Schedule__c '#{participant.cohort_id}'")
        logger.info('SALESFORCE: Making API Call')
        peer_group_id = client.create!(
          'Cohort__c',
          'Name': name,
          'Program__c': participant.program_id,
          'Cohort_Schedule__c': participant.cohort_id,
          'Peer_Group_ID__c': group
        )
        last_peer_group = SFPeerGroup.new(peer_group_id, name, group)
        last_peer_groups["#{participant.program_id}_#{participant.cohort_id}"] = last_peer_group
      end
      last_peer_group
    end

    def should_create_peer_group?(participant, last_peer_group, max_cap)
      return true if last_peer_group.nil?

      logger.info('SALESFORCE: Making API Call')
      participant_count = client.query(
        format(
          QUERIES['PARTICIPANT_COUNT_BY_COHORT_AND_SCHEDULE'], {
            cohort_schedule_id: stringify(participant.cohort_id),
            cohort_id: stringify(last_peer_group.id)
          }
        )
      ).first&.expr0&.to_i
      if participant_count >= max_cap
        logger.debug("participants in Cohort__c '#{last_peer_group.id}' has hit #{max_cap}")
      end
      participant_count >= max_cap
    end

    def fetch_last_peer_group(program_id, cohort_schedule_id)
      last_peer_groups["#{program_id}_#{cohort_schedule_id}"] ||= query_last_peer_group(
        program_id,
        cohort_schedule_id
      )
    end

    def query_last_peer_group(program_id, cohort_schedule_id)
      logger.info('SALESFORCE: Making API Call getting peer group')
      response = client.query(
        format(
          QUERIES['LAST_COHORT_BY_SCHEDULE_AND_PROGRAM'], {
            cohort_schedule_id: stringify(cohort_schedule_id),
            program_id: stringify(program_id)
          }
        )
      ).first
      return response if response.nil?

      SFPeerGroup.new(response.Id, response.Name, response.Peer_Group_ID__c)
    end

    def query_program_by_id(program_id)
      logger.info('SALESFORCE: Making API Call to get program')
      response = client.query(
        format(
          QUERIES['PROGRAM_BY_ID'], {
            program_id: stringify(program_id)
          }
        )
      ).first
      return response if response.nil?

      transform_program(response)
    end

    def fetch_participants_by_emails(emails, record_type)
      fetch_participants(
        QUERIES['PARTICIPANTS_BY_EMAILS'],
        email_list: listify(emails),
        record_type: stringify(record_type)
      )
    end

    def fetch_program_participants(program_id, record_type)
      fetch_participants(
        QUERIES['PROGRAM_PARTICIPANTS'],
        record_type: stringify(record_type),
        program_id: stringify(program_id)
      )
    end


    def fetch_participants(query, **kwargs)
      logger.info('SALESFORCE: Making API Call fetch participants')
      response = client.query(format(query, **kwargs))
      response.map do |res|
        participant = transform_participant(res)
        participants[participant.email] = participant
      end
    end

    def fetch_participant_by_email(email, record_type)
      participants[email] ||= query_participant_by_email(email, record_type)
    end

    def query_participant_by_email(email, record_type)
      record_type_id = fetch_participant_record_type_by_id(record_type)
      logger.info('SALESFORCE: Making API Call fetching participant')
      response = client.query(
        format(
          QUERIES['LAST_PARTICIPANT_BY_EMAIL_AND_RECORD'],
          email: stringify(email),
          record_type_id: stringify(record_type_id)
        )
      ).first
      return response if response.nil?

      transform_participant(response)
    end

    # Gets and caches the RecordTypeId for a Participant__c object given the "developername".
    # An example developername is "Booster_Student"
    def fetch_participant_record_type_by_id(developer_name)
      logger.info("Fetching record type for #{developer_name}")
      participant_record_type_ids[developer_name] ||= query_participant_record_type_by_id(developer_name)
    end

    def query_participant_record_type_by_id(developer_name)
      logger.info('SALESFORCE: Making API Call')
      client.query(
        format(
          QUERIES['FIRST_PARTICIPANT_RECORD_TYPE'],
          {
            developer_name: stringify(developer_name)
          }
        )
      ).first&.Id
    end

    def transform_participant(response)
      SFParticipant.new(response.Id, response.Contact__r&.Email,
                        response.Contact__r&.Preferred_First_Name__c,
                        response.Contact__r&.Name,
                        response.Student_Waiver_Signed__c,
                        response.Cohort__r&.Name, response.Cohort_Schedule__r&.Id,
                        response.Cohort_Schedule__r&.Letter__c,
                        response.Program__r&.Id,
                        response.Program__r&.Session__c,
                        response.Cohort_Schedule__r&.Webinar_Registration_1__c,
                        response.Cohort_Schedule__r&.Webinar_Registration_2__c,
                        response.Webinar_Access_1__c,
                        response.Webinar_Access_2__c,
                        response.Candidate__r&.Esig_Validated_CPP__c,
                        response.Contact__r&.Canvas_User_ID__c,
                        response.Candidate__r&.Coach_Partner_Role__c,
                        response.Cohort__r&.DLRS_LC_FirstName__c,
                        response.Cohort__r&.DLRS_LC_LastName__c,
                        response.Status__c,
                        response.Candidate__r&.Status__c)
    end

    def transform_program(response)
      SFProgram.new(response.Id,
                    response.SLACK_URL__c,
                    response.SLACK_TOKEN__c,
                    response.SLACK_USER__c,
                    response.SLACK_PASSWORD__c,
                    response.SLACK_ADMIN_EMAILS__c
      )

    end

    def listify(list)
      list.map { |email| stringify(email) }.join(',')
    end

    def stringify(object)
      "'#{object}'"
    end

    def logger
      RowanBot.logger
    end
  end
end
