# Mi::Service

XiaoMi Cloud Service for mi.com, inspired by [Yonsm/MiService](https://github.com/Yonsm/MiService) and [yihong0618/MiService](https://github.com/yihong0618/MiService)

## Installation

```
gem install mi-service
```

## Usage

Login

```ruby
require 'mi/service'
account = Mi::Service::Account.new('userID', 'password', debug: true)
account.login_all
account.info # => {"userId"=>"15759xxxx", "security"=>"******", "serviceToken"=>"", "ssecurity"=>"", "userId"=>"15759xxxx", "security"=>"******", "serviceToken"=>"", "ssecurity"=>""}
```
account.success?
```

Login from data persisted

```ruby
account = Mi::Service::Account.new('user_id', 'password', debug: true)
account.login_from_data(info) # info is the data from account.info persisted
```
account.device_list
```

Miot Action

```ruby
xiaoai = account.device_list[0]
account.miot_action(xiaoai["miotDID"], [5,1], "Hello world")
```

Text to Speech

```ruby
account.text_to_speech(xiaoai["deviceID"], "Hello world")
```

Message List

```ruby
account.message_list(device_id: xiaoai["deviceID"], hardware: xiaoai["hardware"], limit: 3)
```

Player Pause

```ruby
account.player_pause(xiaoai["deviceID"])
```

Player Stop

```ruby
account.player_stop(xiaoai["deviceID"])
```

Player get status

```ruby
account.player_get_status(xiaoai["deviceID"])
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/mi-service. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/mi-service/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Mi::Service project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/mi-service/blob/main/CODE_OF_CONDUCT.md).
