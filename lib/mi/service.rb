# frozen_string_literal: true

require_relative "service/version"
require_relative "service/account"
require_relative "service/mina"
require_relative "service/miio"

module Mi
  module Service
    class Error < StandardError; end
    # Your code goes here...
  end
end
