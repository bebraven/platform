class JsonStrategy
  def initialize
    @strategy = FactoryBot.strategy_by_name(:build).new
  end

  delegate :association, to: :@strategy

  def result(evaluation)
    result = @strategy.result(evaluation)
    evaluation.notify(:before_json, result)

    result.to_json.tap do |json|
      evaluation.notify(:after_json, json)
    end
  end
end

FactoryBot.register_strategy(:json, JsonStrategy)

# Now you can do something like this to get a JSON representation of a factory:
#FactoryBot.json(:canvas_user)
