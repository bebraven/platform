# frozen_string_literal: true

module RowanBot
  # Tasks class for tasks to be done
  class Tasks
    attr_writer :zoom_api, :salesforce_api, :docusign_api, :slack_api
    # I do not want to break api
    def initialize(zoom_api = nil, salesforce_api = nil, docusign_api = nil, slack_api = nil)
      @zoom_api = zoom_api
      @salesforce_api = salesforce_api
      @docusign_api = docusign_api
      @slack_api = slack_api
    end

    def add_participants_to_meetings(meeting_id, participants)
      logger.info('Started adding participants')
      participants.map do |participant|
        response = zoom_api.add_registrant(meeting_id, participant)
        participant.merge({ 'join_url' => response['join_url'] })
      end
    end

    def cancel_registrants_from_meeting(meeting_id, participants)
      logger.info('Started cancelling from meeting')
      participants = participants.map { |participant| participant['email'] }
      zoom_api.cancel_registrants(meeting_id, participants)
    end

    def create_weekly_zoom_meeting(user_id, meeting_details)
      logger.info('Started creating weekly meeting')
      zoom_api.create_meeting(user_id, meeting_details)
    end

    def sync_booster_signed_waivers_to_salesforce(days = 1)
      logger.info('Started syncing waiver details to salesforce')
      signed_emails = docusign_api.recently_signed_emails(days)
      return [] if signed_emails.empty?

      record_type = 'Booster_Student'
      salesforce_api.find_participants_by_emails(signed_emails, record_type)
      salesforce_api.sign_participants_waivers_by_email(signed_emails, record_type)
    end

    def assign_peer_groups_to_booster_users(emails)
      logger.info("Started assigning peer groups to users: #{emails}")
      salesforce_api.assign_peer_groups_to_user_emails(emails, 'Booster_Student')
    end

    def assign_slack_to_users(emails)
      logger.info("Started assigning slack to users: #{emails}")
      slack_api.invite_users_to_slack(emails)
    end

    def find_booster_participants_by_emails(emails)
      salesforce_api.find_participants_by_emails(emails, 'Booster_Student')
    end

    def sync_zoom_links_for_record_type(program_id, record_type, force_update: false)
      all_participants = salesforce_api.all_participants(program_id, record_type)
      enrolled_emails = all_participants.filter { |participant| participant.status.eql?('Enrolled') }.map(&:email)
      assign_zoom_links_to_participants(enrolled_emails, record_type, force_update)
      dropped_emails = all_participants.filter { |participant| participant.status.eql?('Dropped') }.map(&:email)
      unassign_zoom_links_to_participants(dropped_emails, record_type)
    end

    def assign_zoom_links_to_booster_participants(emails)
      assign_zoom_links_to_participants(emails, 'Booster_Student')
    end

    def sync_zoom_links_for_program(program_id, force_update)
      sync_zoom_links_for_record_type(program_id, 'Leadership_Coach', force_update: force_update)
      sync_zoom_links_for_record_type(program_id, 'Fellow', force_update: force_update)
    end

    def assign_zoom_links_to_participants(emails, record_type, force_update=false)
      logger.info("Started assigning zoom links to users: #{emails}")
      emails.each do |email|
        participant = salesforce_api.find_participant_by_email(email, record_type)
        prefix = if record_type.eql?('Leadership_Coach') && participant.coaching_partner_role.eql?('Coach Partner')
                    'CP'
                 elsif record_type.eql?('Leadership_Coach')
                    'LC'
                 elsif !(participant.peer_group_lc_name.nil? || participant.peer_group_lc_name.empty?)
                   participant.peer_group_lc_name
                 else
                   'Fellow'
                 end
        registration_details = {
          'email' => participant.email,
          'first_name' => "#{prefix} -",
          'last_name' => participant.last_name
        }
        join_url1 = nil
        join_url2 = nil
        if !participant.webinar_registration_1.nil? && (participant.webinar_link_1.nil? || force_update)
          join_url1 = zoom_api.add_registrant(
            participant.webinar_registration_1,
            registration_details
          )['join_url']
        end

        if !participant.webinar_registration_2.nil? && (participant.webinar_link_2.nil? || force_update)
          join_url2 = zoom_api.add_registrant(
            participant.webinar_registration_2,
            registration_details
          )['join_url']
        end

        if join_url1.nil? && join_url2.nil?
          logger.warn("Skipping #{participant.email}")
        else
          salesforce_api.update_participant_webinar_links(participant.id, join_url1, join_url2)
          logger.info("Added zoom link to: #{email}")
        end
      end
    end

    def unassign_zoom_links_to_participants(emails, record_type)
      logger.info("Started removing zoom links for these users: #{emails}")
      emails.each do |email|
        participant = salesforce_api.find_participant_by_email(email, record_type)
        if !participant.webinar_registration_1.nil? && !participant.webinar_link_1.nil?
          zoom_api.cancel_registrants(
            participant.webinar_registration_1, [email]
          )
        end

        if !participant.webinar_registration_2.nil? && !participant.webinar_link_2.nil?
          zoom_api.cancel_registrants(
            participant.webinar_registration_2, [email]
          )
        end

        salesforce_api.update_participant_webinar_links(participant.id, nil, nil)
        logger.info("Removed zoom link for: #{email}")
      end
    end

    def send_onboarding_notification(emails)
      logger.info('Sending notification')
      slack_api.send_onboarding_notification(emails.join(', '))
    end

    def assign_to_channel_name_in_slack(emails, channel_name, admins)
      logger.info("Started assigning users to channel in slack #{channel_name}")
      admins = admins.map { |ad| { email: ad } }
      users = emails
              .map do |email|
                { email: email, peer_group: channel_name }
              end
      add_users_to_peer_group_channels(users, admins)
    end

    def assign_to_booster_peer_group_channel_in_slack(emails, admins)
      logger.info('Started assigning users to cohort channels in slack')
      admins = admins.map { |ad| { email: ad } }
      users = emails
              .map { |email| salesforce_api.find_participant_by_email(email, 'Booster_Student') }
              .map do |p|
                pname = p.peer_group.split.last(5)
                peer_group = ['peer', 'group', 'run', pname[0].to_i.to_s] + pname[1..-3]
                { email: p.email, peer_group: peer_group.join('-').downcase }
              end
      add_users_to_peer_group_channels(users, admins)
    end

    def assign_to_booster_run_channels_in_slack(emails, admins)
      logger.info('Started assigning users to run channels in slack')
      salesforce_api.find_participants_by_emails(emails, 'Booster_Student')
      admins = admins.map { |ad| { email: ad } }
      users = emails
              .map { |email| salesforce_api.find_participant_by_email(email, 'Booster_Student') }
              .map do |p|
                pname = p.peer_group.split.last(5)
                peer_group = ['run', pname[0].to_i.to_s, 'announcements']
                { email: p.email, peer_group: peer_group.join('-').downcase }
              end
      add_users_to_peer_group_channels(users, admins)
    end

    def add_users_to_peer_group_channels(users, admins = [])
      channel_names = users.map { |entry| entry[:peer_group] }.uniq
      channels, newly = slack_api.create_peer_group_channels(channel_names)
      admins_ids = slack_api.add_slack_ids_to_users(admins).map { |adms| adms[:slack_id] }
      transformed_users = slack_api.add_slack_ids_to_users(users)
      transformed_users = transformed_users.map do |t_user|
        channel = channels.find { |c| c[:name].eql?(t_user[:peer_group]) }
        t_user[:channel_id] = channel[:id]
        t_user
      end
      transformed = transformed_users.each_with_object({}) do |user, acc|
        if acc[user[:channel_id]].nil?
          acc[user[:channel_id]] = [user[:slack_id]]
        else
          acc[user[:channel_id]] << user[:slack_id]
        end
      end

      newly.each do |newl|
        slack_api.add_users_to_peer_group_channel(newl[:id], admins_ids)
      end
      # Add users
      transformed.each do |channel_id, user_ids|
        slack_api.add_users_to_peer_group_channel(channel_id, user_ids)
      end
    end

    def sync_program_to_slack(program_id, slack_admins)
      sync_program_for_record_type_to_slack(program_id, 'Fellow', slack_admins)
      sleep(10)
      sync_program_for_record_type_to_slack(program_id, 'Leadership_Coach', slack_admins)
    end

    def sync_program_for_record_type_to_slack(program_id, record_type, slack_admins)

      all_participants = salesforce_api.all_participants(program_id, record_type)
      participants = all_participants.filter { |participant| participant.status.eql?('Enrolled') || participant.status.eql?('Dropped') }

      has_cohort = participants.filter { |participant| !participant.peer_group.nil? }
      has_cohort = has_cohort.map { |p| { email: p.email, participant: p } }
      has_cohort = slack_api.add_slack_ids_to_users(has_cohort)
      x = has_cohort.inject({}) do |acc, obj|
        parts = obj[:participant]
        channel = cohort_channel_name(parts)
        obj = { email: parts.email, is_enrolled: parts.status.eql?('Enrolled'), slack_id: obj[:slack_id] }
        if acc[channel].nil?
          acc[channel] = [obj]
        else
          acc[channel] << obj
        end
        acc
      end

      slack_channels = slack_api.create_peer_group_channels(x.keys).first
      slack_channels = slack_channels.inject({}) do |acc, chan|
        acc[chan[:name]] = chan[:id]
        acc
      end

      slack_admin_users = slack_api.add_slack_ids_to_users(slack_admins)

      current_pairing = {}
      slack_channels.each do |channel, channel_id|
        mems = slack_api.get_channel_members(channel_id)
        mems.each do |mem|
          current_pairing[mem] = { name: channel, id: channel_id }
        end
      end

      x.each do |cohort_name, objs|
        slack_users = objs.map { |obj| { email: obj[:email], is_enrolled: obj[:is_enrolled], slack_id: obj[:slack_id] } }
        to_add = slack_admin_users.map { |u| u[:slack_id] }
        slack_users.each do |sl_u|
          sl_id = sl_u[:slack_id]
          if !sl_u[:is_enrolled] && !current_pairing[sl_id].nil?
            # User is dropped
            slack_api.remove_user_from_channel(current_pairing[sl_id][:id], sl_id)
            next
          end

          if current_pairing[sl_id].nil?
            to_add << sl_id
          elsif !current_pairing[sl_id][:name].eql?(cohort_name)
            to_add << sl_id
            slack_api.remove_user_from_channel(current_pairing[sl_id][:id], sl_id)
          end
        end
        slack_api.add_users_to_peer_group_channel(slack_channels[cohort_name], to_add)
      end
    end

    def cohort_channel_name(participant)
      day = participant.peer_group.split[1]
      first_name = participant.peer_group_lc_name.scan(/\w+/)
      last_name = participant.peer_group_lc_last_name.gsub(/\w+/)
      ['cohort', day, *first_name, *last_name].join('-').downcase
    end

    private

    attr_reader :zoom_api, :salesforce_api, :docusign_api, :slack_api

    def logger
      RowanBot.logger
    end
  end
end
