cas_config_path = "#{Rails.root.to_s}/config/rubycas.yml"
cas_config = YAML.safe_load(ERB.new(File.read(cas_config_path)).result, [], [], true)[Rails.env].with_indifferent_access
RubyCAS::Server::Core::setup(cas_config)

auth = []

begin
  # attempt to instantiate the authenticator
  cas_config[:authenticator] = [cas_config[:authenticator]] unless cas_config[:authenticator].instance_of? Array
  cas_config[:authenticator].each { |authenticator| auth << authenticator[:class].constantize}
rescue NameError
  if cas_config[:authenticator].instance_of? Array
    cas_config[:authenticator].each do |authenticator|
      if !authenticator[:source].nil?
        # rubycas.yml explicitly names source file
        require authenticator[:source]
      end
      auth << authenticator[:class].constantize
    end
  else
    if cas_config[:authenticator][:source]
      # cas_config.yml explicitly names source file
      require cas_config[:authenticator][:source]
    end

    auth << cas_config[:authenticator][:class].constantize
    cas_config[:authenticator] = [cas_config[:authenticator]]
  end
end

auth.zip(cas_config[:authenticator]).each_with_index{ |auth_conf, index|
  authenticator, conf = auth_conf
  authenticator.setup(conf.merge('auth_index' => index)) if authenticator.respond_to?(:setup)
}

RubyCAS::Server::Core::Settings._settings[:auth] = auth
